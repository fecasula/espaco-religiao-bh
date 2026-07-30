# Prepara a base censitária espacial definitiva de Belo Horizonte
# ---------------------------------------------------------------
# ESCOPO ATUAL: somente Belo Horizonte (3106200), Censo 2022.
# A adaptação para outros municípios está em desenvolvimento.
#
# INPUTS OPCIONAIS
# Deixe NULL para utilizar config/censo.yml.
CENSUS_INPUT <- list(
  codigo_municipio = NULL, # Ex.: "3106200"
  nome_municipio = NULL,   # Ex.: "Belo Horizonte"
  uf = NULL,               # Ex.: "MG"
  ano = NULL,              # Ex.: 2022
  arquivo_fonte = NULL,    # Caminho local alternativo para MG_setores_CD2022.gpkg
  metodo_download = NULL   # "auto", "wininet" ou "libcurl"
)

find_project_root <- function() {
  source_files <- vapply(
    sys.frames(),
    function(frame) {
      value <- frame$ofile
      if (is.null(value) || length(value) != 1L || !nzchar(value)) {
        return(NA_character_)
      }
      tryCatch(
        normalizePath(value, winslash = "/", mustWork = TRUE),
        error = function(e) NA_character_
      )
    },
    character(1)
  )

  source_files <- source_files[!is.na(source_files)]
  source_file <- if (length(source_files)) tail(source_files, 1L) else NA_character_
  candidates <- c(
    if (!is.na(source_file)) dirname(dirname(source_file)) else character(),
    normalizePath(getwd(), winslash = "/", mustWork = TRUE)
  )

  candidates <- unique(candidates)
  valid <- candidates[file.exists(file.path(candidates, "DESCRIPTION"))]

  if (!length(valid)) {
    stop(
      "Não foi possível localizar a raiz do projeto. Abra o arquivo .Rproj e execute novamente.",
      call. = FALSE
    )
  }

  valid[[1L]]
}

.parse_bool <- function(x, default = FALSE) {
  if (!nzchar(x)) return(default)
  tolower(trimws(x)) %in% c("1", "true", "t", "yes", "y", "sim", "s")
}

main <- function() {
  project_root <- find_project_root()
  old_wd <- setwd(project_root)
  on.exit(setwd(old_wd), add = TRUE)

  required_packages <- c(
    "dplyr", "fs", "here", "readr", "rlang", "sf", "tibble", "yaml"
  )
  missing_packages <- required_packages[
    !vapply(required_packages, requireNamespace, logical(1), quietly = TRUE)
  ]

  if (length(missing_packages)) {
    stop(
      "Pacotes ausentes: ", paste(missing_packages, collapse = ", "),
      ". Execute source(\"scripts/00_install.R\") antes deste script.",
      call. = FALSE
    )
  }

  source(file.path(project_root, "R", "config.R"), local = environment())
  source(
    file.path(project_root, "R", "spatial_population.R"),
    local = environment()
  )

  config <- resolve_census_config(overrides = CENSUS_INPUT)

  force <- .parse_bool(
    Sys.getenv("CENSUS_FORCE", unset = "false"),
    default = FALSE
  )

  old_timeout <- getOption("timeout", 60)
  options(timeout = max(config$download$timeout_segundos, old_timeout))
  on.exit(options(timeout = old_timeout), add = TRUE)

  output <- census_output_path(config)
  source_file <- census_source_path(config)
  shiny_output <- census_shiny_path(config)

  message("Projeto: ", project_root)
  message("R: ", R.version.string)
  message("sf: ", as.character(utils::packageVersion("sf")))
  message("Município: ", config$municipio$nome, " (", config$municipio$codigo_ibge, ")")
  message("Ano: ", config$ano)
  message("Fonte: ", config$fonte$tipo)
  message("Camada: ", config$fonte$camada)
  message("Arquivo estadual: ", normalizePath(source_file, winslash = "/", mustWork = FALSE))
  message("Arquivo municipal: ", normalizePath(output, winslash = "/", mustWork = FALSE))
  message("Método de download: ", config$download$metodo)
  message("Forçar reconstrução: ", force)
  message("AVISO: ", spatial_scope_notice_pt())

  out <- prepare_census_data(
    config = config,
    output = output,
    source_file = source_file,
    force = force
  )

  if (isTRUE(config$saida$copiar_para_shiny)) {
    copy_census_to_shiny(
      source = out,
      config = config,
      destination = shiny_output
    )
    message(
      "Cópia ativa para o Shiny: ",
      normalizePath(shiny_output, winslash = "/")
    )
  }

  message(
    "Relatórios de auditoria:\n- ",
    paste(
      normalizePath(
        census_audit_paths(config),
        winslash = "/",
        mustWork = FALSE
      ),
      collapse = "\n- "
    )
  )
  message("Preparação censitária concluída com sucesso.")

  invisible(out)
}

main()
