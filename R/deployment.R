# Utilitários de publicação do aplicativo Shiny
# ----------------------------------------------

.deployment_scalar <- function(x, default = NULL) {
  if (is.null(x) || length(x) == 0L) return(default)

  value <- x[[1L]]
  if (is.null(value) || is.na(value)) return(default)

  value <- trimws(as.character(value))
  if (!nzchar(value)) default else value
}

.normalize_package_version <- function(x) {
  value <- .deployment_scalar(x)

  if (is.null(value)) {
    return(NA_character_)
  }

  # R aceita ponto e hífen como separadores em versões de pacotes.
  # packageVersion() costuma imprimir "1.9.41", enquanto DESCRIPTION
  # e renv.lock podem registrar a mesma versão como "1.9-41".
  normalized <- gsub("-", ".", value, fixed = TRUE)
  components <- strsplit(normalized, ".", fixed = TRUE)[[1L]]

  if (
    !length(components) ||
      any(!nzchar(components)) ||
      any(!grepl("^[0-9]+$", components))
  ) {
    stop("Versão de pacote inválida: ", value, call. = FALSE)
  }

  paste(as.integer(components), collapse = ".")
}

.package_versions_equal <- function(x, y) {
  identical(
    .normalize_package_version(x),
    .normalize_package_version(y)
  )
}

.read_json_file <- function(path) {
  if (!requireNamespace("jsonlite", quietly = TRUE)) {
    stop("Instale o pacote jsonlite.", call. = FALSE)
  }

  if (!file.exists(path)) {
    stop("Arquivo não encontrado: ", path, call. = FALSE)
  }

  jsonlite::read_json(path, simplifyVector = FALSE)
}

.write_json_atomic <- function(object, path) {
  dir.create(dirname(path), recursive = TRUE, showWarnings = FALSE)

  temporary <- tempfile(
    pattern = paste0(basename(path), "-"),
    tmpdir = dirname(path),
    fileext = ".tmp"
  )

  on.exit(unlink(temporary, force = TRUE), add = TRUE)

  jsonlite::write_json(
    object,
    path = temporary,
    auto_unbox = TRUE,
    pretty = TRUE,
    null = "null",
    na = "null"
  )
  cat("\n", file = temporary, append = TRUE)

  if (file.exists(path)) {
    unlink(path, force = TRUE)
  }

  moved <- file.rename(temporary, path)
  if (!isTRUE(moved)) {
    copied <- file.copy(temporary, path, overwrite = TRUE)
    if (!isTRUE(copied)) {
      stop("Não foi possível gravar: ", path, call. = FALSE)
    }
  }

  invisible(normalizePath(path, winslash = "/", mustWork = TRUE))
}

read_deployment_config <- function(
  path = project_path("config", "deployment.yml")
) {
  if (!requireNamespace("yaml", quietly = TRUE)) {
    stop("Instale o pacote yaml.", call. = FALSE)
  }

  if (!file.exists(path)) {
    stop("Configuração de deploy não encontrada: ", path, call. = FALSE)
  }

  config <- yaml::read_yaml(path)

  required_shinyapps <- c(
    "account_env",
    "server_env",
    "app_name_env",
    "app_title_env",
    "default_server",
    "default_app_name",
    "default_app_title"
  )

  missing_shinyapps <- setdiff(
    required_shinyapps,
    names(config$shinyapps)
  )

  if (length(missing_shinyapps)) {
    stop(
      "Campos ausentes em config/deployment.yml: ",
      paste(missing_shinyapps, collapse = ", "),
      call. = FALSE
    )
  }

  terra <- config$dependencies$terra
  required_terra <- c(
    "version",
    "source",
    "github_username",
    "github_repo",
    "github_ref",
    "github_sha1"
  )

  missing_terra <- setdiff(required_terra, names(terra))
  if (length(missing_terra)) {
    stop(
      "Campos ausentes na configuração do terra: ",
      paste(missing_terra, collapse = ", "),
      call. = FALSE
    )
  }

  if (!identical(tolower(terra$source), "github")) {
    stop("A fonte configurada para terra deve ser GitHub.", call. = FALSE)
  }

  if (!grepl("^[0-9a-f]{40}$", terra$github_sha1)) {
    stop("github_sha1 de terra deve conter 40 caracteres hexadecimais.", call. = FALSE)
  }

  config
}

.add_legacy_github_fields <- function(record) {
  source <- tolower(.deployment_scalar(record$Source, ""))
  if (!identical(source, "github")) return(record)

  record$GithubUsername <- .deployment_scalar(
    record$GithubUsername,
    .deployment_scalar(record$RemoteUsername)
  )
  record$GithubRepo <- .deployment_scalar(
    record$GithubRepo,
    .deployment_scalar(record$RemoteRepo)
  )
  record$GithubRef <- .deployment_scalar(
    record$GithubRef,
    .deployment_scalar(record$RemoteRef)
  )
  record$GithubSHA1 <- .deployment_scalar(
    record$GithubSHA1,
    .deployment_scalar(record$RemoteSha)
  )

  required <- c("GithubUsername", "GithubRepo", "GithubSHA1")
  missing <- required[vapply(
    required,
    function(field) is.null(.deployment_scalar(record[[field]])),
    logical(1)
  )]

  if (length(missing)) {
    stop(
      "Registro GitHub incompleto para o pacote ",
      .deployment_scalar(record$Package, "desconhecido"),
      ": ",
      paste(missing, collapse = ", "),
      call. = FALSE
    )
  }

  if (is.null(.deployment_scalar(record$GithubRef))) {
    record$GithubRef <- record$GithubSHA1
  }

  record
}

.apply_terra_deployment_pin <- function(record, specification) {
  package_name <- .deployment_scalar(record$Package)
  if (!identical(package_name, "terra")) {
    stop("O registro fornecido não pertence ao pacote terra.", call. = FALSE)
  }

  record_version <- .deployment_scalar(record$Version)
  expected_version <- as.character(specification$version)

  if (!.package_versions_equal(record_version, expected_version)) {
    stop(
      "A versão de terra em renv.lock é ", record_version,
      ", mas config/deployment.yml fixa ", expected_version,
      ". Atualize versão e commit de forma conjunta.",
      call. = FALSE
    )
  }

  # Mantém no lockfile a grafia canônica definida na configuração,
  # mesmo quando a instalação local usa pontos em todos os componentes.
  record$Version <- expected_version
  record$Source <- "GitHub"
  record$RemoteType <- "github"
  record$RemoteHost <- "api.github.com"
  record$RemoteUsername <- specification$github_username
  record$RemoteRepo <- specification$github_repo
  record$RemoteRef <- specification$github_ref
  record$RemoteSha <- specification$github_sha1

  # rsconnect mantém estes nomes legados ao montar o manifesto do
  # shinyapps.io. Os campos Remote* são preservados para o renv.
  record$GithubUsername <- specification$github_username
  record$GithubRepo <- specification$github_repo
  record$GithubRef <- specification$github_ref
  record$GithubSHA1 <- specification$github_sha1

  .add_legacy_github_fields(record)
}

normalize_deployment_lockfile <- function(
  path,
  config = read_deployment_config()
) {
  lock <- .read_json_file(path)
  original_lock <- lock

  if (is.null(lock$Packages) || !length(lock$Packages)) {
    stop("Lockfile sem registros de pacotes: ", path, call. = FALSE)
  }

  package_names <- names(lock$Packages)
  for (package_name in package_names) {
    lock$Packages[[package_name]] <- .add_legacy_github_fields(
      lock$Packages[[package_name]]
    )
  }

  if (is.null(lock$Packages$terra)) {
    stop("O pacote terra não está registrado em: ", path, call. = FALSE)
  }

  lock$Packages$terra <- .apply_terra_deployment_pin(
    lock$Packages$terra,
    config$dependencies$terra
  )

  if (!identical(lock, original_lock)) {
    .write_json_atomic(lock, path)
  }

  validate_deployment_lockfile(path, config)

  invisible(path)
}

validate_deployment_lockfile <- function(
  path,
  config = read_deployment_config()
) {
  lock <- .read_json_file(path)
  packages <- lock$Packages

  if (is.null(packages$terra)) {
    stop("O pacote terra não está registrado em: ", path, call. = FALSE)
  }

  terra <- packages$terra
  specification <- config$dependencies$terra

  expected <- c(
    Source = "GitHub",
    GithubUsername = specification$github_username,
    GithubRepo = specification$github_repo,
    GithubRef = specification$github_ref,
    GithubSHA1 = specification$github_sha1
  )

  actual <- vapply(
    names(expected),
    function(field) .deployment_scalar(terra[[field]], ""),
    character(1)
  )

  mismatches <- names(expected)[actual != expected]

  if (!.package_versions_equal(
    .deployment_scalar(terra$Version),
    specification$version
  )) {
    mismatches <- c("Version", mismatches)
  }

  mismatches <- unique(mismatches)
  if (length(mismatches)) {
    stop(
      "Metadados de terra incompatíveis em ", path, ": ",
      paste(mismatches, collapse = ", "),
      call. = FALSE
    )
  }

  github_packages <- packages[vapply(
    packages,
    function(record) identical(
      tolower(.deployment_scalar(record$Source, "")),
      "github"
    ),
    logical(1)
  )]

  for (record in github_packages) {
    .add_legacy_github_fields(record)
  }

  invisible(TRUE)
}

prepare_deployment_lockfiles <- function(
  project_lock = project_path("renv.lock"),
  shiny_lock = project_path("shiny", "renv.lock"),
  config = read_deployment_config()
) {
  paths <- c(project_lock, shiny_lock)

  for (path in paths) {
    normalize_deployment_lockfile(path, config)
  }

  message("Lockfiles normalizados para publicação no shinyapps.io:")
  for (path in paths) message("- ", normalizePath(path, winslash = "/"))

  invisible(paths)
}

resolve_shinyapps_settings <- function(
  config = read_deployment_config()
) {
  if (!requireNamespace("rsconnect", quietly = TRUE)) {
    stop("Instale o pacote rsconnect.", call. = FALSE)
  }

  shinyapps <- config$shinyapps
  server <- Sys.getenv(
    shinyapps$server_env,
    unset = shinyapps$default_server
  )
  account <- Sys.getenv(shinyapps$account_env, unset = "")

  accounts <- rsconnect::accounts()
  account_column <- if ("name" %in% names(accounts)) "name" else "username"
  matching <- accounts[accounts$server == server, , drop = FALSE]

  if (!nzchar(account)) {
    if (nrow(matching) == 1L) {
      account <- as.character(matching[[account_column]][[1L]])
    } else {
      stop(
        "Defina ", shinyapps$account_env,
        " no .Renviron ou registre apenas uma conta para ", server, ".",
        call. = FALSE
      )
    }
  }

  registered <- any(
    matching[[account_column]] == account,
    na.rm = TRUE
  )

  if (!registered) {
    stop(
      "A conta ", account, " não está registrada para ", server,
      ". Verifique rsconnect::accounts().",
      call. = FALSE
    )
  }

  app_name <- Sys.getenv(
    shinyapps$app_name_env,
    unset = shinyapps$default_app_name
  )
  app_title <- Sys.getenv(
    shinyapps$app_title_env,
    unset = shinyapps$default_app_title
  )

  list(
    account = account,
    server = server,
    app_name = app_name,
    app_title = app_title
  )
}

validate_shiny_deployment_files <- function(
  app_dir = project_path("shiny")
) {
  required <- c(
    "app.R",
    "renv.lock",
    file.path("data", "icr_publicacao.csv"),
    file.path("data", "perfis_metodologicos.csv"),
    file.path("data", "pontos_religiosos_bh.csv"),
    file.path("data", "setores_ativos.gpkg"),
    file.path("R", "config.R"),
    file.path("R", "coverage.R"),
    file.path("R", "io.R"),
    file.path("R", "spatial_points.R"),
    file.path("R", "validation.R"),
    file.path("www", "app.css")
  )

  missing <- required[!file.exists(file.path(app_dir, required))]
  if (length(missing)) {
    stop(
      "Arquivos obrigatórios ausentes no aplicativo: ",
      paste(missing, collapse = ", "),
      call. = FALSE
    )
  }

  invisible(TRUE)
}

validate_local_terra_version <- function(
  config = read_deployment_config()
) {
  if (!requireNamespace("terra", quietly = TRUE)) {
    stop("Instale o pacote terra antes do deploy.", call. = FALSE)
  }

  installed <- as.character(utils::packageVersion("terra"))
  expected <- as.character(config$dependencies$terra$version)

  if (!.package_versions_equal(installed, expected)) {
    stop(
      "A biblioteca local possui terra ", installed,
      ", mas o lockfile de publicação fixa terra ", expected, ".",
      call. = FALSE
    )
  }

  message(
    "Versão local de terra validada: ", installed,
    " (equivalente ao registro ", expected, ")."
  )

  invisible(TRUE)
}

remove_stale_shiny_manifest <- function(
  app_dir = project_path("shiny")
) {
  manifest_path <- file.path(app_dir, "manifest.json")

  if (file.exists(manifest_path)) {
    unlink(manifest_path, force = TRUE)
  }

  if (file.exists(manifest_path)) {
    stop(
      "Não foi possível remover o manifest.json residual: ",
      manifest_path,
      call. = FALSE
    )
  }

  invisible(manifest_path)
}

.validate_terra_dependency_record <- function(
  dependencies,
  config = read_deployment_config()
) {
  if (!is.data.frame(dependencies)) {
    stop("As dependências precisam ser fornecidas como data.frame.", call. = FALSE)
  }

  required_columns <- c("Package", "Version", "Source")
  missing_columns <- setdiff(required_columns, names(dependencies))
  if (length(missing_columns)) {
    stop(
      "Colunas ausentes nas dependências: ",
      paste(missing_columns, collapse = ", "),
      call. = FALSE
    )
  }

  terra <- dependencies[
    dependencies$Package == "terra",
    ,
    drop = FALSE
  ]

  if (nrow(terra) != 1L) {
    stop(
      "Era esperada exatamente uma dependência terra; encontradas: ",
      nrow(terra),
      call. = FALSE
    )
  }

  specification <- config$dependencies$terra
  source <- tolower(.deployment_scalar(terra$Source, ""))
  version <- .deployment_scalar(terra$Version)

  if (!identical(source, "github")) {
    stop(
      "A dependência terra precisa ser resolvida via GitHub; fonte encontrada: ",
      .deployment_scalar(terra$Source, "ausente"),
      call. = FALSE
    )
  }

  if (!.package_versions_equal(version, specification$version)) {
    stop(
      "A dependência terra foi resolvida como ", version,
      ", mas a configuração fixa ", specification$version, ".",
      call. = FALSE
    )
  }

  invisible(terra)
}

validate_shiny_dependencies <- function(
  app_dir = project_path("shiny"),
  config = read_deployment_config()
) {
  if (!requireNamespace("rsconnect", quietly = TRUE)) {
    stop("Instale o pacote rsconnect.", call. = FALSE)
  }

  dependencies <- rsconnect::appDependencies(
    appDir = app_dir,
    appMode = "shiny",
    dependencyResolution = "strict"
  )

  terra <- .validate_terra_dependency_record(dependencies, config)

  message(
    "Dependências validadas: terra ",
    .deployment_scalar(terra$Version),
    " via GitHub."
  )

  invisible(dependencies)
}

# Geração e correção do manifesto enviado ao shinyapps.io
# -------------------------------------------------------

.manifest_github_fields <- c(
  "GithubUsername",
  "GithubRepo",
  "GithubRef",
  "GithubSHA1"
)

.patch_manifest_github_record <- function(
  manifest_record,
  lock_record
) {
  lock_record <- .add_legacy_github_fields(lock_record)

  manifest_record$Source <- "github"

  for (field in .manifest_github_fields) {
    manifest_record[[field]] <- .deployment_scalar(lock_record[[field]])
  }

  # O shinyapps.io ainda consome os campos Github* do manifesto legado.
  # Eles são mantidos no nível do pacote e também na descrição embutida,
  # porque versões distintas do serviço já consultaram ambos os locais.
  description <- manifest_record$description
  if (is.null(description) || !is.list(description)) {
    description <- list()
  }

  description$Source <- "github"
  for (field in .manifest_github_fields) {
    description[[field]] <- manifest_record[[field]]
  }

  manifest_record$description <- description
  manifest_record
}

validate_shiny_manifest <- function(
  manifest_path,
  lockfile_path = file.path(dirname(manifest_path), "renv.lock"),
  config = read_deployment_config()
) {
  manifest <- .read_json_file(manifest_path)
  lock <- .read_json_file(lockfile_path)

  appmode <- .deployment_scalar(manifest$metadata$appmode)
  if (!identical(appmode, "shiny")) {
    stop(
      "O manifesto precisa conter metadata$appmode = 'shiny'; encontrado: ",
      .deployment_scalar(appmode, "ausente"),
      call. = FALSE
    )
  }

  if (is.null(manifest$packages) || !length(manifest$packages)) {
    stop("O manifesto não contém registros de pacotes R.", call. = FALSE)
  }

  github_packages <- names(lock$Packages)[vapply(
    lock$Packages,
    function(record) identical(
      tolower(.deployment_scalar(record$Source, "")),
      "github"
    ),
    logical(1)
  )]

  if (!length(github_packages)) {
    stop("O lockfile não contém pacotes GitHub para validar.", call. = FALSE)
  }

  for (package_name in github_packages) {
    manifest_record <- manifest$packages[[package_name]]
    if (is.null(manifest_record)) {
      stop(
        "Pacote GitHub ausente no manifesto: ",
        package_name,
        call. = FALSE
      )
    }

    lock_record <- .add_legacy_github_fields(
      lock$Packages[[package_name]]
    )

    source <- tolower(.deployment_scalar(manifest_record$Source, ""))
    if (!identical(source, "github")) {
      stop(
        "Fonte inválida no manifesto para ", package_name,
        ": ", .deployment_scalar(manifest_record$Source, "ausente"),
        call. = FALSE
      )
    }

    for (field in .manifest_github_fields) {
      actual <- .deployment_scalar(manifest_record[[field]])
      expected <- .deployment_scalar(lock_record[[field]])

      if (!identical(actual, expected)) {
        stop(
          "Campo ", field, " inválido para ", package_name,
          " no manifesto. Esperado: ", expected,
          "; encontrado: ", .deployment_scalar(actual, "ausente"),
          call. = FALSE
        )
      }
    }
  }

  terra <- manifest$packages$terra
  terra_version <- .deployment_scalar(terra$description$Version)
  if (
    !is.null(terra_version) &&
      !.package_versions_equal(
        terra_version,
        config$dependencies$terra$version
      )
  ) {
    stop(
      "O manifesto contém terra ", terra_version,
      ", mas a configuração fixa ",
      config$dependencies$terra$version,
      ".",
      call. = FALSE
    )
  }

  invisible(TRUE)
}

patch_shiny_manifest <- function(
  manifest_path,
  lockfile_path = file.path(dirname(manifest_path), "renv.lock"),
  config = read_deployment_config()
) {
  manifest <- .read_json_file(manifest_path)
  lock <- .read_json_file(lockfile_path)

  if (is.null(manifest$metadata) || !is.list(manifest$metadata)) {
    manifest$metadata <- list()
  }
  manifest$metadata$appmode <- "shiny"

  if (is.null(manifest$packages) || !length(manifest$packages)) {
    stop("O manifesto não contém registros de pacotes R.", call. = FALSE)
  }

  github_packages <- names(lock$Packages)[vapply(
    lock$Packages,
    function(record) identical(
      tolower(.deployment_scalar(record$Source, "")),
      "github"
    ),
    logical(1)
  )]

  for (package_name in github_packages) {
    if (is.null(manifest$packages[[package_name]])) {
      stop(
        "Pacote GitHub ausente no manifesto: ",
        package_name,
        call. = FALSE
      )
    }

    manifest$packages[[package_name]] <- .patch_manifest_github_record(
      manifest$packages[[package_name]],
      lock$Packages[[package_name]]
    )
  }

  .write_json_atomic(manifest, manifest_path)
  validate_shiny_manifest(manifest_path, lockfile_path, config)

  terra <- manifest$packages$terra
  message(
    "Manifesto validado: terra ",
    .deployment_scalar(terra$description$Version, config$dependencies$terra$version),
    " via GitHub (",
    .deployment_scalar(terra$GithubUsername), "/",
    .deployment_scalar(terra$GithubRepo), "@",
    substr(.deployment_scalar(terra$GithubSHA1), 1L, 8L),
    ")."
  )

  invisible(normalizePath(
    manifest_path,
    winslash = "/",
    mustWork = TRUE
  ))
}

write_validated_shiny_manifest <- function(
  app_dir = project_path("shiny"),
  config = read_deployment_config()
) {
  if (!requireNamespace("rsconnect", quietly = TRUE)) {
    stop("Instale o pacote rsconnect.", call. = FALSE)
  }

  manifest_path <- file.path(app_dir, "manifest.json")
  lockfile_path <- file.path(app_dir, "renv.lock")

  remove_stale_shiny_manifest(app_dir)

  rsconnect::writeManifest(
    appDir = app_dir,
    appMode = "shiny",
    quarto = FALSE,
    dependencyResolution = "strict",
    quiet = TRUE
  )

  if (!file.exists(manifest_path)) {
    stop(
      "O rsconnect não criou o manifesto esperado: ",
      manifest_path,
      call. = FALSE
    )
  }

  patch_shiny_manifest(
    manifest_path = manifest_path,
    lockfile_path = lockfile_path,
    config = config
  )
}

