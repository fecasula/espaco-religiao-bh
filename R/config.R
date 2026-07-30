project_path <- function(...) here::here(...)

confessions <- c(
  "Católica", "Protestante/Evangélica", "Espírita", "Afro-brasileira"
)

project_crs_geographic <- 4674L
project_crs_metric <- 31983L # SIRGAS 2000 / UTM zona 23S; homologado para BH.
bh_code <- "3106200"        # Compatibilidade com os demais módulos do projeto.

spatial_scope_status <- list(
  supported_code = "3106200",
  supported_name = "Belo Horizonte",
  supported_state = "MG",
  supported_year = 2022L,
  status = paste(
    "A análise espacial está homologada somente para Belo Horizonte;",
    "a generalização municipal está em desenvolvimento."
  )
)

.parse_config_bool <- function(x, default = FALSE) {
  if (is.null(x) || length(x) == 0L || is.na(x)) return(default)
  if (is.logical(x)) return(isTRUE(x))
  tolower(trimws(as.character(x))) %in% c(
    "1", "true", "t", "yes", "y", "sim", "s"
  )
}

.choose_config_value <- function(current, override) {
  if (
    is.null(override) ||
      length(override) == 0L ||
      is.na(override) ||
      !nzchar(trimws(as.character(override)))
  ) {
    current
  } else {
    override
  }
}

.is_absolute_path <- function(path) {
  path <- as.character(path)[[1L]]
  grepl("^[A-Za-z]:[/\\\\]", path) ||
    startsWith(path, "/") ||
    startsWith(path, "\\\\")
}

.resolve_project_file <- function(path) {
  path <- trimws(as.character(path))
  if (!nzchar(path)) return(path)
  if (.is_absolute_path(path)) path else project_path(path)
}

read_census_config <- function(path = project_path("config", "censo.yml")) {
  if (!file.exists(path)) {
    rlang::abort(c(
      "Arquivo de configuração censitária não encontrado.",
      "i" = paste0("Esperado em: ", path)
    ))
  }

  config <- yaml::read_yaml(path)
  required <- c(
    "municipio", "ano", "fonte", "saida", "download", "validacao"
  )
  missing <- setdiff(required, names(config))

  if (length(missing)) {
    rlang::abort(c(
      "O arquivo config/censo.yml está incompleto.",
      "i" = paste0("Seções ausentes: ", paste(missing, collapse = ", "), ".")
    ))
  }

  config$municipio$codigo_ibge <- trimws(
    as.character(config$municipio$codigo_ibge)
  )
  config$municipio$nome <- trimws(as.character(config$municipio$nome))
  config$municipio$uf <- toupper(trimws(as.character(config$municipio$uf)))
  config$ano <- as.integer(config$ano)

  config$fonte$tipo <- tolower(trimws(as.character(config$fonte$tipo)))
  config$fonte$referencia <- trimws(as.character(config$fonte$referencia))
  config$fonte$arquivo_uf <- trimws(as.character(config$fonte$arquivo_uf))
  config$fonte$url_uf <- trimws(as.character(config$fonte$url_uf))
  config$fonte$camada <- trimws(as.character(config$fonte$camada))
  config$fonte$coluna_setor <- trimws(as.character(config$fonte$coluna_setor))
  config$fonte$coluna_municipio <- trimws(
    as.character(config$fonte$coluna_municipio)
  )
  config$fonte$coluna_populacao <- trimws(
    as.character(config$fonte$coluna_populacao)
  )

  config$saida$formato <- toupper(trimws(as.character(config$saida$formato)))
  config$saida$arquivo_municipal <- trimws(
    as.character(config$saida$arquivo_municipal)
  )
  config$saida$arquivo_shiny <- trimws(as.character(config$saida$arquivo_shiny))
  config$saida$diretorio_auditoria <- trimws(
    as.character(config$saida$diretorio_auditoria)
  )
  config$saida$copiar_para_shiny <- .parse_config_bool(
    config$saida$copiar_para_shiny,
    TRUE
  )

  config$download$metodo <- tolower(trimws(as.character(config$download$metodo)))
  config$download$tentativas_por_metodo <- max(
    1L,
    as.integer(config$download$tentativas_por_metodo)
  )
  config$download$timeout_segundos <- max(
    60L,
    as.integer(config$download$timeout_segundos)
  )
  config$download$reutilizar_arquivo_validado <- .parse_config_bool(
    config$download$reutilizar_arquivo_validado,
    TRUE
  )
  config$download$tamanho_minimo_bytes <- max(
    1,
    as.numeric(config$download$tamanho_minimo_bytes)
  )

  config$validacao$dissolver_codigos_multipartidos <- .parse_config_bool(
    config$validacao$dissolver_codigos_multipartidos,
    TRUE
  )
  config$validacao$exigir_codigo_setor_15_digitos <- .parse_config_bool(
    config$validacao$exigir_codigo_setor_15_digitos,
    TRUE
  )
  config$validacao$setores_esperados <- as.integer(
    config$validacao$setores_esperados
  )
  config$validacao$populacao_esperada <- as.numeric(
    config$validacao$populacao_esperada
  )
  config$validacao$tolerancia_populacao <- max(
    0,
    as.numeric(config$validacao$tolerancia_populacao)
  )
  config$validacao$calcular_md5_fonte <- .parse_config_bool(
    config$validacao$calcular_md5_fonte,
    TRUE
  )

  if (is.null(config$historico)) config$historico <- list()
  config$historico$permitir_base_preliminar <- .parse_config_bool(
    config$historico$permitir_base_preliminar,
    FALSE
  )

  config
}

apply_census_overrides <- function(config, overrides = list()) {
  config$municipio$codigo_ibge <- trimws(as.character(.choose_config_value(
    config$municipio$codigo_ibge,
    overrides$codigo_municipio
  )))
  config$municipio$nome <- trimws(as.character(.choose_config_value(
    config$municipio$nome,
    overrides$nome_municipio
  )))
  config$municipio$uf <- toupper(trimws(as.character(.choose_config_value(
    config$municipio$uf,
    overrides$uf
  ))))
  config$ano <- as.integer(.choose_config_value(config$ano, overrides$ano))
  config$fonte$arquivo_uf <- trimws(as.character(.choose_config_value(
    config$fonte$arquivo_uf,
    overrides$arquivo_fonte
  )))
  config$download$metodo <- tolower(trimws(as.character(.choose_config_value(
    config$download$metodo,
    overrides$metodo_download
  ))))

  config
}

apply_census_environment <- function(config) {
  apply_census_overrides(
    config,
    overrides = list(
      codigo_municipio = Sys.getenv("CENSUS_MUNICIPALITY_CODE", unset = ""),
      nome_municipio = Sys.getenv("CENSUS_MUNICIPALITY_NAME", unset = ""),
      uf = Sys.getenv("CENSUS_STATE", unset = ""),
      ano = Sys.getenv("CENSUS_YEAR", unset = ""),
      arquivo_fonte = Sys.getenv("CENSUS_SOURCE_FILE", unset = ""),
      metodo_download = Sys.getenv("CENSUS_DOWNLOAD_METHOD", unset = "")
    )
  )
}

validate_census_config <- function(config, enforce_supported_scope = TRUE) {
  code <- config$municipio$codigo_ibge
  name <- config$municipio$nome
  year <- config$ano

  if (!grepl("^[0-9]{7}$", code)) {
    rlang::abort("O código IBGE do município deve possuir exatamente sete dígitos.")
  }
  if (!nzchar(name)) rlang::abort("O nome do município não pode estar vazio.")
  if (is.na(year) || year < 2000L) {
    rlang::abort("O ano censitário informado é inválido.")
  }
  if (
    isTRUE(enforce_supported_scope) &&
      !identical(year, spatial_scope_status$supported_year)
  ) {
    rlang::abort("A versão espacial atual está homologada somente para o Censo 2022.")
  }
  if (!identical(config$fonte$tipo, "ibge_definitivo")) {
    rlang::abort(
      "O pipeline acadêmico atual exige fonte.tipo = 'ibge_definitivo'."
    )
  }
  if (!nzchar(config$fonte$arquivo_uf) || !nzchar(config$fonte$url_uf)) {
    rlang::abort("A fonte censitária deve informar arquivo_uf e url_uf.")
  }
  if (!nzchar(config$fonte$camada)) {
    rlang::abort("A camada do GeoPackage oficial do IBGE não foi informada.")
  }
  if (!identical(config$saida$formato, "GPKG")) {
    rlang::abort("A versão atual utiliza GeoPackage (GPKG) como formato oficial.")
  }
  if (!(config$download$metodo %in% c("auto", "wininet", "libcurl"))) {
    rlang::abort(
      "download.metodo deve ser 'auto', 'wininet' ou 'libcurl'."
    )
  }

  if (
    isTRUE(enforce_supported_scope) &&
      !identical(code, spatial_scope_status$supported_code)
  ) {
    rlang::abort(c(
      "Município ainda não suportado pela análise espacial desta versão.",
      "i" = paste0("Município solicitado: ", name, " (", code, ")."),
      "i" = "Escopo homologado atualmente: Belo Horizonte (3106200).",
      "i" = "A generalização para outros municípios está em desenvolvimento."
    ))
  }

  invisible(config)
}

resolve_census_config <- function(
    path = project_path("config", "censo.yml"),
    overrides = list(),
    enforce_supported_scope = TRUE) {
  config <- read_census_config(path)
  config <- apply_census_environment(config)
  config <- apply_census_overrides(config, overrides)
  validate_census_config(config, enforce_supported_scope = enforce_supported_scope)
  config
}

census_source_path <- function(config) {
  .resolve_project_file(config$fonte$arquivo_uf)
}

census_output_path <- function(config) {
  .resolve_project_file(config$saida$arquivo_municipal)
}

census_shiny_path <- function(config = resolve_census_config()) {
  .resolve_project_file(config$saida$arquivo_shiny)
}

census_audit_dir <- function(config) {
  .resolve_project_file(config$saida$diretorio_auditoria)
}

census_output_basename <- function(config) {
  basename(census_output_path(config))
}

census_source_label <- function(config) {
  paste0(
    config$fonte$referencia,
    " — ", config$municipio$nome,
    " (", config$municipio$codigo_ibge, ")"
  )
}

spatial_scope_notice_pt <- function() {
  paste(
    "A análise espacial desta versão funciona somente para Belo Horizonte (MG).",
    "A adaptação para outros municípios está em desenvolvimento."
  )
}

spatial_scope_notice_es <- function() {
  paste(
    "El análisis espacial de esta versión funciona solamente para Belo Horizonte (MG).",
    "La adaptación a otros municipios está en desarrollo."
  )
}

read_method_profiles <- function(
    path = project_path("config", "perfis_metodologicos.csv")) {
  readr::read_csv(path, show_col_types = FALSE)
}
