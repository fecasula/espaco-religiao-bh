# Preparação da base censitária espacial definitiva do IBGE
# ---------------------------------------------------------
# ESCOPO HOMOLOGADO: Belo Horizonte (3106200), Censo 2022.
# A fonte padrão é o GeoPackage estadual definitivo do IBGE, que reúne
# geometrias e população no mesmo produto. A generalização municipal está em
# desenvolvimento e permanece bloqueada por validate_census_config().

.find_column <- function(data, candidates) {
  current <- names(data)
  idx <- match(tolower(candidates), tolower(current), nomatch = 0L)
  idx <- idx[idx > 0L]
  if (!length(idx)) return(NA_character_)
  current[[idx[[1L]]]]
}

.first_existing <- function(paths) {
  paths <- unique(paths[nzchar(paths)])
  existing <- paths[file.exists(paths)]
  if (!length(existing)) return(NA_character_)
  existing[[1L]]
}

.format_integer_pt <- function(x) {
  format(
    x,
    big.mark = ".",
    decimal.mark = ",",
    scientific = FALSE,
    trim = TRUE
  )
}

.census_download_methods <- function(config) {
  method <- config$download$metodo

  if (!identical(method, "auto")) {
    if (identical(method, "wininet") && !identical(.Platform$OS.type, "windows")) {
      rlang::abort("O método wininet está disponível somente no Windows.")
    }
    return(method)
  }

  if (identical(.Platform$OS.type, "windows")) {
    c("wininet", "libcurl")
  } else {
    "libcurl"
  }
}

.validate_source_gpkg <- function(path, config, quiet = FALSE) {
  if (!file.exists(path)) return(FALSE)

  size <- file.info(path)$size
  if (
    is.na(size) ||
      size < config$download$tamanho_minimo_bytes
  ) {
    if (!quiet) {
      message(
        "GeoPackage estadual ausente ou menor que o limite de integridade: ",
        normalizePath(path, winslash = "/", mustWork = FALSE)
      )
    }
    return(FALSE)
  }

  layers <- tryCatch(
    sf::st_layers(path),
    error = function(e) NULL
  )

  if (is.null(layers) || !(config$fonte$camada %in% layers$name)) {
    if (!quiet) {
      message(
        "A camada esperada não foi encontrada no GeoPackage: ",
        config$fonte$camada
      )
    }
    return(FALSE)
  }

  TRUE
}

.download_ibge_source <- function(
    config,
    destination = census_source_path(config),
    force = FALSE) {
  validate_census_config(config)

  if (
    !isTRUE(force) &&
      isTRUE(config$download$reutilizar_arquivo_validado) &&
      .validate_source_gpkg(destination, config, quiet = TRUE)
  ) {
    message(
      "GeoPackage estadual do IBGE já existe e passou pela validação: ",
      normalizePath(destination, winslash = "/")
    )
    return(invisible(destination))
  }

  fs::dir_create(dirname(destination))
  methods <- .census_download_methods(config)
  attempts <- config$download$tentativas_por_metodo
  timeout <- config$download$timeout_segundos
  old_timeout <- getOption("timeout", 60)
  options(timeout = max(timeout, old_timeout))
  on.exit(options(timeout = old_timeout), add = TRUE)

  errors <- character()

  for (method in methods) {
    for (attempt in seq_len(attempts)) {
      temp_file <- paste0(destination, ".download.gpkg")
      if (file.exists(temp_file)) unlink(temp_file, force = TRUE)

      message(
        "IBGE: método ", method,
        ", tentativa ", attempt, "/", attempts, "."
      )

      result <- tryCatch(
        {
          status <- utils::download.file(
            url = config$fonte$url_uf,
            destfile = temp_file,
            method = method,
            mode = "wb",
            quiet = FALSE,
            cacheOK = FALSE
          )

          if (!isTRUE(status == 0)) {
            stop("download.file retornou status ", status, ".", call. = FALSE)
          }

          if (!.validate_source_gpkg(temp_file, config, quiet = TRUE)) {
            stop(
              "O arquivo recebido não passou pela validação de tamanho e camada.",
              call. = FALSE
            )
          }

          TRUE
        },
        error = function(e) {
          errors <<- c(
            errors,
            paste0(method, " tentativa ", attempt, ": ", conditionMessage(e))
          )
          FALSE
        }
      )

      if (isTRUE(result)) {
        if (file.exists(destination)) unlink(destination, force = TRUE)

        moved <- file.rename(temp_file, destination)
        if (!isTRUE(moved)) {
          copied <- file.copy(temp_file, destination, overwrite = TRUE)
          unlink(temp_file, force = TRUE)
          if (!isTRUE(copied)) {
            rlang::abort(
              "O download terminou, mas o GeoPackage não pôde ser movido para o destino."
            )
          }
        }

        message(
          "GeoPackage estadual baixado e validado: ",
          normalizePath(destination, winslash = "/"),
          "\nTamanho: ", .format_integer_pt(file.info(destination)$size),
          " bytes."
        )
        return(invisible(destination))
      }

      if (file.exists(temp_file)) unlink(temp_file, force = TRUE)
      if (attempt < attempts) Sys.sleep(5L * attempt)
    }
  }

  rlang::abort(c(
    "Não foi possível baixar o GeoPackage definitivo do IBGE.",
    "i" = paste(unique(errors), collapse = " | "),
    "i" = paste0("URL: ", config$fonte$url_uf),
    "i" = paste0(
      "Também é possível baixar o arquivo manualmente e salvá-lo em ",
      destination,
      "."
    )
  ))
}

.read_ibge_state_layer <- function(path, config) {
  if (!.validate_source_gpkg(path, config)) {
    rlang::abort("O GeoPackage estadual do IBGE está ausente ou inválido.")
  }

  data <- tryCatch(
    sf::st_read(
      path,
      layer = config$fonte$camada,
      quiet = TRUE,
      stringsAsFactors = FALSE
    ),
    error = function(e) {
      rlang::abort(c(
        "Não foi possível ler a camada censitária do IBGE.",
        "i" = conditionMessage(e),
        "i" = paste0("Arquivo: ", path),
        "i" = paste0("Camada: ", config$fonte$camada)
      ))
    }
  )

  if (!inherits(data, "sf") || !nrow(data)) {
    rlang::abort("A camada oficial do IBGE não produziu um objeto sf válido.")
  }

  data
}

.standardise_ibge_census <- function(data, config) {
  validate_census_config(config)

  tract_col <- .find_column(
    data,
    c(
      config$fonte$coluna_setor,
      "CD_SETOR", "code_tract", "COD_SETOR"
    )
  )
  municipality_col <- .find_column(
    data,
    c(
      config$fonte$coluna_municipio,
      "CD_MUN", "CD_MUNICIPIO", "code_muni", "COD_MUN"
    )
  )
  population_col <- .find_column(
    data,
    c(
      config$fonte$coluna_populacao,
      "v0001", "V0001", "populacao", "POP_TOTAL", "PESSOAS"
    )
  )

  identified <- c(
    code_tract = tract_col,
    code_muni = municipality_col,
    populacao = population_col
  )

  if (any(is.na(identified))) {
    rlang::abort(c(
      "Não foi possível identificar todas as colunas necessárias no GeoPackage do IBGE.",
      "i" = paste0(
        "Colunas identificadas: ",
        paste(names(identified), identified, sep = "=", collapse = "; ")
      )
    ))
  }

  municipality_code <- config$municipio$codigo_ibge
  keep_rows <- trimws(as.character(data[[municipality_col]])) == municipality_code
  data <- data[keep_rows, , drop = FALSE]

  if (!nrow(data)) {
    rlang::abort(paste0(
      "A camada oficial não contém setores de ",
      config$municipio$nome, " (", municipality_code, ")."
    ))
  }

  data$code_tract <- trimws(as.character(data[[tract_col]]))
  data$populacao <- suppressWarnings(as.numeric(data[[population_col]]))
  data <- data[, c("code_tract", "populacao"), drop = FALSE]

  if (is.na(sf::st_crs(data))) {
    rlang::abort("A malha censitária do IBGE não possui CRS definido.")
  }
  if (any(sf::st_is_empty(data))) {
    rlang::abort("A malha censitária oficial contém geometrias vazias.")
  }
  if (any(is.na(data$populacao))) {
    rlang::abort("A base censitária oficial contém população ausente.")
  }
  if (any(!is.finite(data$populacao) | data$populacao < 0)) {
    rlang::abort("A base censitária oficial contém população inválida.")
  }
  if (
    isTRUE(config$validacao$exigir_codigo_setor_15_digitos) &&
      any(!grepl("^[0-9]{15}$", data$code_tract))
  ) {
    rlang::abort("Foram encontrados códigos de setor diferentes de 15 dígitos.")
  }
  if (any(substr(data$code_tract, 1L, 7L) != municipality_code)) {
    rlang::abort("A seleção municipal contém códigos de setor de outro município.")
  }

  data
}

.consolidate_multipart_tracts <- function(data, config) {
  duplicate_counts <- data |>
    sf::st_drop_geometry() |>
    dplyr::count(code_tract, name = "numero_feicoes") |>
    dplyr::filter(numero_feicoes > 1L)

  multipart_details <- tibble::tibble(
    code_tract = character(),
    populacao = numeric(),
    area_m2 = numeric(),
    tipo_geometria = character()
  )

  if (nrow(duplicate_counts)) {
    duplicate_features <- data |>
      dplyr::filter(code_tract %in% duplicate_counts$code_tract)

    consistency <- duplicate_features |>
      sf::st_drop_geometry() |>
      dplyr::group_by(code_tract) |>
      dplyr::summarise(
        numero_feicoes = dplyr::n(),
        numero_valores_populacao = dplyr::n_distinct(populacao),
        valores_populacao = paste(sort(unique(populacao)), collapse = "; "),
        .groups = "drop"
      )

    inconsistent <- consistency |>
      dplyr::filter(numero_valores_populacao != 1L)

    if (nrow(inconsistent)) {
      rlang::abort(c(
        "Há códigos de setor multipartidos com valores populacionais diferentes.",
        "i" = paste(inconsistent$code_tract, collapse = ", ")
      ))
    }

    areas <- as.numeric(
      sf::st_area(
        sf::st_transform(duplicate_features, project_crs_metric)
      )
    )

    multipart_details <- duplicate_features |>
      sf::st_drop_geometry() |>
      dplyr::transmute(
        code_tract,
        populacao,
        area_m2 = areas,
        tipo_geometria = as.character(
          sf::st_geometry_type(duplicate_features)
        )
      )

    if (!isTRUE(config$validacao$dissolver_codigos_multipartidos)) {
      rlang::abort(c(
        "A fonte possui códigos de setor com mais de uma feição.",
        "i" = paste(duplicate_counts$code_tract, collapse = ", "),
        "i" = "Ative validacao.dissolver_codigos_multipartidos para consolidá-los."
      ))
    }
  }

  consolidated <- data |>
    dplyr::group_by(code_tract) |>
    dplyr::summarise(
      populacao = dplyr::first(populacao),
      do_union = TRUE,
      .groups = "drop"
    ) |>
    sf::st_make_valid()

  list(
    data = consolidated,
    duplicate_counts = duplicate_counts,
    multipart_details = multipart_details
  )
}

.validate_final_census <- function(data, config, strict_reference = TRUE) {
  if (!inherits(data, "sf") || !nrow(data)) {
    rlang::abort("O produto censitário final não é um objeto sf válido.")
  }

  diagnostics <- tibble::tibble(
    indicador = c(
      "Setores",
      "Códigos distintos",
      "Códigos duplicados",
      "Geometrias vazias",
      "Geometrias inválidas",
      "Populações ausentes",
      "Populações negativas",
      "População total"
    ),
    valor = c(
      nrow(data),
      dplyr::n_distinct(data$code_tract),
      sum(duplicated(data$code_tract)),
      sum(sf::st_is_empty(data)),
      sum(!sf::st_is_valid(data), na.rm = TRUE),
      sum(is.na(data$populacao)),
      sum(data$populacao < 0, na.rm = TRUE),
      sum(data$populacao, na.rm = TRUE)
    )
  )

  errors <- diagnostics |>
    dplyr::filter(
      (indicador == "Códigos duplicados" & valor != 0) |
        (indicador == "Geometrias vazias" & valor != 0) |
        (indicador == "Geometrias inválidas" & valor != 0) |
        (indicador == "Populações ausentes" & valor != 0) |
        (indicador == "Populações negativas" & valor != 0)
    )

  if (nrow(errors)) {
    rlang::abort(c(
      "O produto censitário final não passou pelos controles de integridade.",
      "i" = paste(errors$indicador, errors$valor, sep = "=", collapse = "; ")
    ))
  }

  if (
    isTRUE(config$validacao$exigir_codigo_setor_15_digitos) &&
      any(!grepl("^[0-9]{15}$", data$code_tract))
  ) {
    rlang::abort("O produto final possui códigos de setor inválidos.")
  }

  if (isTRUE(strict_reference)) {
    expected_tracts <- config$validacao$setores_esperados
    expected_population <- config$validacao$populacao_esperada
    tolerance <- config$validacao$tolerancia_populacao
    observed_population <- sum(data$populacao, na.rm = TRUE)

    if (!is.na(expected_tracts) && nrow(data) != expected_tracts) {
      rlang::abort(c(
        "A quantidade de setores difere da referência homologada.",
        "i" = paste0("Esperado: ", expected_tracts, ". Observado: ", nrow(data), ".")
      ))
    }

    if (
      !is.na(expected_population) &&
        abs(observed_population - expected_population) > tolerance
    ) {
      rlang::abort(c(
        "A população total difere da referência homologada.",
        "i" = paste0(
          "Esperado: ", .format_integer_pt(expected_population),
          ". Observado: ", .format_integer_pt(observed_population), "."
        )
      ))
    }
  }

  diagnostics
}

.write_gpkg_atomic <- function(data, output, config) {
  fs::dir_create(dirname(output))
  temp_output <- tempfile(
    pattern = paste0("setores_", config$municipio$codigo_ibge, "_"),
    tmpdir = dirname(output),
    fileext = ".gpkg"
  )
  on.exit(if (file.exists(temp_output)) unlink(temp_output, force = TRUE), add = TRUE)

  sf::st_write(
    data,
    temp_output,
    driver = "GPKG",
    delete_dsn = TRUE,
    quiet = TRUE
  )

  validation <- tryCatch(
    sf::st_read(temp_output, quiet = TRUE),
    error = function(e) NULL
  )

  if (is.null(validation)) {
    rlang::abort("O GeoPackage temporário não pôde ser reaberto.")
  }
  .validate_final_census(validation, config, strict_reference = TRUE)

  if (file.exists(output)) unlink(output, force = TRUE)
  moved <- file.rename(temp_output, output)
  if (!isTRUE(moved)) {
    copied <- file.copy(temp_output, output, overwrite = TRUE)
    if (!isTRUE(copied)) {
      rlang::abort(
        "Não foi possível substituir o GeoPackage definitivo. Feche QGIS e Shiny e tente novamente."
      )
    }
    unlink(temp_output, force = TRUE)
  }

  invisible(output)
}

census_audit_paths <- function(config = resolve_census_config()) {
  audit_dir <- census_audit_dir(config)
  c(
    diagnostico = file.path(audit_dir, "diagnostico_base_ibge_definitiva.csv"),
    multipartidos = file.path(audit_dir, "detalhe_setores_multipartidos.csv"),
    fonte = file.path(audit_dir, "manifesto_fonte_censitaria.csv")
  )
}

.write_census_audit <- function(
    diagnostics,
    multipart_details,
    source_path,
    config) {
  audit_paths <- census_audit_paths(config)
  fs::dir_create(dirname(audit_paths[[1L]]))

  if (!nrow(multipart_details)) {
    multipart_details <- tibble::tibble(
      code_tract = character(),
      populacao = numeric(),
      area_m2 = numeric(),
      tipo_geometria = character()
    )
  }

  source_info <- file.info(source_path)
  source_md5 <- if (isTRUE(config$validacao$calcular_md5_fonte)) {
    unname(tools::md5sum(source_path))
  } else {
    NA_character_
  }

  source_manifest <- tibble::tibble(
    campo = c(
      "fonte_tipo",
      "referencia",
      "url",
      "arquivo_local",
      "camada",
      "tamanho_bytes",
      "modificado_em",
      "md5",
      "municipio_codigo",
      "municipio_nome",
      "ano",
      "crs_geografico",
      "crs_metrico_analise"
    ),
    valor = as.character(c(
      config$fonte$tipo,
      config$fonte$referencia,
      config$fonte$url_uf,
      normalizePath(source_path, winslash = "/"),
      config$fonte$camada,
      source_info$size,
      as.character(source_info$mtime),
      source_md5,
      config$municipio$codigo_ibge,
      config$municipio$nome,
      config$ano,
      project_crs_geographic,
      project_crs_metric
    ))
  )

  readr::write_csv(diagnostics, audit_paths[["diagnostico"]])
  readr::write_csv(multipart_details, audit_paths[["multipartidos"]])
  readr::write_csv(source_manifest, audit_paths[["fonte"]])

  unname(audit_paths)
}

copy_census_to_shiny <- function(
    source,
    config = resolve_census_config(),
    destination = census_shiny_path(config)) {
  if (!file.exists(source)) {
    rlang::abort("O GeoPackage municipal não existe e não pode ser copiado para o Shiny.")
  }

  data <- sf::st_read(source, quiet = TRUE)
  .validate_final_census(data, config, strict_reference = TRUE)

  fs::dir_create(dirname(destination))
  temp_destination <- paste0(destination, ".tmp.gpkg")
  if (file.exists(temp_destination)) unlink(temp_destination, force = TRUE)

  copied <- file.copy(source, temp_destination, overwrite = TRUE)
  if (!isTRUE(copied)) {
    rlang::abort("Não foi possível criar a cópia temporária para o Shiny.")
  }

  if (file.exists(destination)) unlink(destination, force = TRUE)
  moved <- file.rename(temp_destination, destination)
  if (!isTRUE(moved)) {
    copied_final <- file.copy(temp_destination, destination, overwrite = TRUE)
    unlink(temp_destination, force = TRUE)
    if (!isTRUE(copied_final)) {
      rlang::abort("Não foi possível atualizar o GeoPackage ativo do Shiny.")
    }
  }

  invisible(destination)
}

prepare_census_data <- function(
    config = resolve_census_config(),
    output = census_output_path(config),
    source_file = census_source_path(config),
    force = FALSE) {
  validate_census_config(config)

  audit_paths <- census_audit_paths(config)
  existing_valid <- FALSE

  if (
    !isTRUE(force) &&
      isTRUE(config$download$reutilizar_arquivo_validado) &&
      file.exists(output)
  ) {
    existing <- tryCatch(
      sf::st_read(output, quiet = TRUE),
      error = function(e) NULL
    )

    existing_valid <- !is.null(existing) && tryCatch(
      {
        .validate_final_census(existing, config, strict_reference = TRUE)
        TRUE
      },
      error = function(e) FALSE
    )

    if (isTRUE(existing_valid) && all(file.exists(audit_paths))) {
      message(
        "GeoPackage municipal definitivo já existe e passou pela validação: ",
        normalizePath(output, winslash = "/")
      )
      return(invisible(output))
    }
  }

  if (!.validate_source_gpkg(source_file, config, quiet = TRUE)) {
    .download_ibge_source(config, destination = source_file, force = force)
  } else {
    message(
      "Fonte oficial local: ",
      normalizePath(source_file, winslash = "/")
    )
  }

  message(
    "1/4 — Lendo a malha com atributos definitiva do IBGE para ",
    config$municipio$uf, "..."
  )
  state_data <- .read_ibge_state_layer(source_file, config)

  message(
    "2/4 — Selecionando e padronizando os setores de ",
    config$municipio$nome, "..."
  )
  municipality_data <- .standardise_ibge_census(state_data, config)
  rm(state_data)
  gc(verbose = FALSE)

  message("3/4 — Consolidando setores multipartidos e validando população...")
  consolidated <- .consolidate_multipart_tracts(municipality_data, config)
  final_data <- consolidated$data
  diagnostics <- .validate_final_census(
    final_data,
    config,
    strict_reference = TRUE
  )

  message("4/4 — Gravando GeoPackage municipal e relatórios de auditoria...")
  .write_gpkg_atomic(final_data, output, config)
  .write_census_audit(
    diagnostics = diagnostics,
    multipart_details = consolidated$multipart_details,
    source_path = source_file,
    config = config
  )

  message(
    "Base censitária definitiva criada com sucesso: ",
    normalizePath(output, winslash = "/"),
    "\nSetores: ", .format_integer_pt(nrow(final_data)),
    "\nPopulação total: ", .format_integer_pt(sum(final_data$populacao)),
    "\nSetores multipartidos consolidados: ",
    .format_integer_pt(nrow(consolidated$duplicate_counts))
  )

  invisible(output)
}

# Compatibilidade com as versões anteriores do projeto.
download_census_tracts <- function(
    config = resolve_census_config(),
    output = census_output_path(config),
    force = FALSE,
    ...) {
  prepare_census_data(
    config = config,
    output = output,
    force = force
  )
}

download_bh_census_tracts <- function(...) {
  download_census_tracts(config = resolve_census_config(), ...)
}

read_census_tracts <- function(
    path = NULL,
    config = resolve_census_config()) {
  validate_census_config(config)
  if (is.null(path)) path <- census_output_path(config)

  if (!file.exists(path)) {
    rlang::abort(c(
      "Geometria censitária definitiva não encontrada.",
      "i" = "Execute Rscript scripts/02_prepare_census.R"
    ))
  }

  tracts <- tryCatch(
    sf::st_read(path, quiet = TRUE),
    error = function(e) NULL
  )

  if (is.null(tracts)) {
    rlang::abort("O GeoPackage censitário não pôde ser lido.")
  }

  .validate_final_census(tracts, config, strict_reference = TRUE)
  tracts
}
