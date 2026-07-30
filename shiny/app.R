library(shiny)
library(bslib)
library(dplyr)
library(readr)
library(sf)
library(leaflet)
library(DT)
library(scales)
library(htmltools)

source("R/config.R")
source("R/io.R")
source("R/spatial_points.R")
source("R/coverage.R")
source("R/validation.R")

confessions <- c("Católica", "Protestante/Evangélica", "Espírita", "Afro-brasileira")
profiles <- read_csv("data/perfis_metodologicos.csv", show_col_types = FALSE)
points_df <- read_csv("data/pontos_religiosos_bh.csv", show_col_types = FALSE)
points_sf <- st_as_sf(points_df, coords = c("longitude", "latitude"), crs = 4674, remove = FALSE)
tract_path <- "data/setores_ativos.gpkg"
tracts_available <- file.exists(tract_path)
tracts <- if (tracts_available) st_read(tract_path, quiet = TRUE) else NULL

labels <- list(
  pt = list(title = "Índice de Cobertura Religiosa — Belo Horizonte", establishments = "Estabelecimentos", coverage = "Cobertura estimada", table = "Síntese", map = "Mapa", base = "Base censitária: IBGE, Censo 2022, malha com atributos definitiva.", missing = "A geometria censitária ainda não foi preparada. Execute scripts/02_prepare_census.R e publique novamente o aplicativo.", scope = spatial_scope_notice_pt()),
  es = list(title = "Índice de Cobertura Religiosa — Belo Horizonte", establishments = "Establecimientos", coverage = "Cobertura estimada", table = "Síntesis", map = "Mapa", base = "Base censal: IBGE, Censo 2022, malla con atributos definitiva.", missing = "La geometría censal todavía no fue preparada. Ejecute scripts/02_prepare_census.R y vuelva a publicar la aplicación.", scope = spatial_scope_notice_es())
)

ui <- page_sidebar(
  title = uiOutput("title"),
  theme = bs_theme(version = 5, bootswatch = "flatly", primary = "#173f5f", success = "#2f7d62"),
  tags$head(tags$link(rel = "stylesheet", href = "app.css")),
  sidebar = sidebar(
    selectInput("lang", "Idioma / Idioma", choices = c("Português" = "pt", "Español" = "es"), selected = "pt"),
    selectInput("profile", "Perfil metodológico / Perfil metodológico", choices = setNames(profiles$perfil, profiles$rotulo_pt), selected = "recomendado"),
    sliderInput("speed", "Velocidade média / Velocidad media (km/h)", min = 2, max = 6.5, value = 4, step = .1),
    sliderInput("time", "Tempo / Tiempo de caminhada (min)", min = 3, max = 30, value = 9.7, step = .1),
    actionButton("apply", "Recalcular", class = "btn-primary w-100"),
    hr(),
    div(class = "alert alert-info small", uiOutput("scope_notice")),
    uiOutput("method_text"),
    open = "desktop"
  ),
  uiOutput("main_ui")
)

server <- function(input, output, session) {
  L <- reactive(labels[[input$lang]])

  output$title <- renderUI(tags$span(L()$title))
  output$scope_notice <- renderUI(tags$span(L()$scope))

  observeEvent(input$lang, {
    choices <- if (identical(input$lang, "es")) profiles$rotulo_es else profiles$rotulo_pt
    updateSelectInput(session, "profile", choices = setNames(profiles$perfil, choices), selected = input$profile)
  }, ignoreInit = TRUE)

  observeEvent(input$profile, {
    p <- profiles |> filter(perfil == input$profile)
    if (nrow(p) == 1) {
      updateSliderInput(session, "speed", value = p$velocidade_kmh[[1]])
      updateSliderInput(session, "time", value = p$tempo_min[[1]])
    }
  }, ignoreInit = TRUE)

  params <- eventReactive(input$apply, {
    p <- profiles |> filter(perfil == input$profile)
    fixed <- identical(input$profile, "texto_manuscrito")
    radius <- if (fixed && nrow(p) == 1) p$raio_m[[1]] else radius_m(input$speed, input$time)
    list(speed = input$speed, time = input$time, radius = radius, fixed = fixed)
  }, ignoreNULL = FALSE)

  result <- reactive({
    req(tracts_available)
    p <- params()
    effective_time <- if (p$fixed) p$radius / (p$speed * 1000) * 60 else p$time
    coverage_by_confession(points_sf, tracts, p$speed, effective_time)
  }) |> bindCache(params()$radius)

  output$method_text <- renderUI({
    p <- params()
    txt <- if (identical(input$lang, "es")) {
      "Cobertura potencial por buffers euclidianos; no representa rutas, pendientes ni calidad de aceras."
    } else {
      "Cobertura potencial por buffers euclidianos; não representa rotas, declividade ou qualidade das calçadas."
    }
    div(class = "methodology", tags$strong(sprintf("Raio / Radio: %.1f m", p$radius)), tags$p(txt), tags$p(class = "small text-muted", L()$base))
  })

  output$main_ui <- renderUI({
    if (!tracts_available) {
      return(div(class = "alert alert-warning", role = "alert", L()$missing))
    }
    panels <- lapply(confessions, function(conf) {
      nav_panel(
        conf,
        layout_columns(
          value_box(title = L()$establishments, value = textOutput(paste0("n_", make.names(conf))), showcase = icon("location-dot"), theme = "primary"),
          value_box(title = L()$coverage, value = textOutput(paste0("icr_", make.names(conf))), showcase = icon("people-group"), theme = "success"),
          card(full_screen = TRUE, card_header(L()$map), leafletOutput(paste0("map_", make.names(conf)), height = "620px")),
          col_widths = c(6, 6, 12)
        )
      )
    })
    panels[[length(panels) + 1]] <- nav_panel(L()$table, card(DTOutput("summary_table")))
    do.call(navset_card_tab, panels)
  })

  observe({
    req(tracts_available)
    res <- result()
    for (conf in confessions) local({
      cconf <- conf
      id <- make.names(cconf)
      row <- res |> filter(confissao == cconf)
      output[[paste0("n_", id)]] <- renderText(format(row$estabelecimentos, big.mark = "."))
      output[[paste0("icr_", id)]] <- renderText(percent(row$icr, accuracy = .1, decimal.mark = ","))
      output[[paste0("map_", id)]] <- renderLeaflet({
        cover <- st_transform(row, 4326)
        pts <- points_sf |> filter(confissao == cconf)
        tr <- st_transform(tracts, 4326)
        leaflet(options = leafletOptions(preferCanvas = TRUE)) |>
          addProviderTiles(providers$CartoDB.Positron) |>
          addPolygons(data = tr, fill = FALSE, color = "#666", weight = .25, opacity = .35) |>
          addPolygons(data = cover, fillColor = "#2f7d62", fillOpacity = .25, color = "#173f5f", weight = 1) |>
          addCircleMarkers(data = pts, radius = 3, stroke = FALSE, fillOpacity = .65, clusterOptions = markerClusterOptions()) |>
          fitBounds(lng1 = -44.08, lat1 = -20.06, lng2 = -43.85, lat2 = -19.75)
      })
    })
    output$summary_table <- renderDT({
      res |>
        st_drop_geometry() |>
        transmute(
          Confissão = confissao,
          Estabelecimentos = estabelecimentos,
          `Raio (m)` = round(raio_m, 1),
          `População coberta` = round(populacao_coberta),
          ICR = percent(icr, accuracy = .1, decimal.mark = ",")
        ) |>
        datatable(rownames = FALSE, options = list(dom = "t", pageLength = 10))
    })
  })
}

shinyApp(ui, server)
