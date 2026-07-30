radius_m <- function(speed_kmh, time_min) {
  stopifnot(
    is.numeric(speed_kmh),
    is.numeric(time_min),
    speed_kmh > 0,
    time_min > 0
  )
  speed_kmh * 1000 * time_min / 60
}

coverage_by_confession <- function(
    points,
    tracts,
    speed_kmh = 4,
    time_min = 9.7,
    confession_col = "confissao",
    population_col = "populacao",
    metric_crs = project_crs_metric) {
  radius <- radius_m(speed_kmh, time_min)
  pts <- sf::st_transform(points, metric_crs)
  sec <- sf::st_make_valid(sf::st_transform(tracts, metric_crs))

  # Não presume que a coluna espacial se chame "geometry". O GeoPackage
  # oficial do IBGE usa "geom" e outros drivers podem adotar nomes distintos.
  sec$area_setor_m2 <- as.numeric(sf::st_area(sec))

  total_population <- sum(sec[[population_col]], na.rm = TRUE)
  if (!is.finite(total_population) || total_population <= 0) {
    rlang::abort("População total inválida.")
  }

  pieces <- purrr::map(confessions, function(conf) {
    p <- pts[pts[[confession_col]] == conf, ]

    if (!nrow(p)) {
      return(sf::st_sf(
        confissao = conf,
        estabelecimentos = 0L,
        raio_m = radius,
        populacao_coberta = 0,
        icr = 0,
        geometry = sf::st_sfc(
          sf::st_geometrycollection(),
          crs = metric_crs
        )
      ))
    }

    cover <- sf::st_union(sf::st_buffer(p, radius))
    cover_sf <- sf::st_sf(confissao = conf, geometry = cover)
    clipped <- suppressWarnings(sf::st_intersection(
      sec[, c(population_col, "area_setor_m2")],
      cover_sf
    ))

    if (!nrow(clipped)) {
      return(sf::st_sf(
        confissao = conf,
        estabelecimentos = nrow(p),
        raio_m = radius,
        populacao_coberta = 0,
        icr = 0,
        geometry = sf::st_sfc(
          sf::st_geometrycollection(),
          crs = metric_crs
        )
      ))
    }

    clipped$area_coberta_m2 <- as.numeric(sf::st_area(clipped))
    clipped <- clipped |>
      dplyr::mutate(
        prop_area = pmin(
          1,
          pmax(0, area_coberta_m2 / area_setor_m2)
        ),
        populacao_coberta_setor = .data[[population_col]] * prop_area
      )

    covered_population <- sum(
      clipped$populacao_coberta_setor,
      na.rm = TRUE
    )

    sf::st_sf(
      confissao = conf,
      estabelecimentos = nrow(p),
      raio_m = radius,
      populacao_coberta = covered_population,
      icr = covered_population / total_population,
      geometry = sf::st_union(sf::st_geometry(clipped))
    )
  })

  do.call(rbind, pieces)
}
