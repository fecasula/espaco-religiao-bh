# Publicação validada do aplicativo no shinyapps.io
# -------------------------------------------------

find_project_root <- function() {
  candidates <- c(getwd())

  frames <- sys.frames()
  source_files <- vapply(
    frames,
    function(frame) {
      value <- frame$ofile
      if (is.null(value)) "" else as.character(value)
    },
    character(1)
  )

  source_files <- source_files[nzchar(source_files)]
  if (length(source_files)) {
    candidates <- c(
      candidates,
      dirname(normalizePath(
        source_files,
        winslash = "/",
        mustWork = FALSE
      ))
    )
  }

  for (candidate in unique(candidates)) {
    current <- normalizePath(
      candidate,
      winslash = "/",
      mustWork = FALSE
    )

    repeat {
      if (
        file.exists(file.path(current, "DESCRIPTION")) &&
          file.exists(file.path(current, "shiny", "app.R"))
      ) {
        return(current)
      }

      parent <- dirname(current)
      if (identical(parent, current)) break
      current <- parent
    }
  }

  stop(
    "Não foi possível localizar a raiz do projeto.",
    call. = FALSE
  )
}

deploy_from_shiny_directory <- function(
  app_dir,
  settings,
  manifest_path
) {
  app_dir <- normalizePath(
    app_dir,
    winslash = "/",
    mustWork = TRUE
  )

  manifest_path <- normalizePath(
    manifest_path,
    winslash = "/",
    mustWork = TRUE
  )

  expected_manifest <- normalizePath(
    file.path(app_dir, "manifest.json"),
    winslash = "/",
    mustWork = TRUE
  )

  if (!identical(manifest_path, expected_manifest)) {
    stop(
      "O manifesto validado não corresponde a shiny/manifest.json.\n",
      "Esperado: ", expected_manifest, "\n",
      "Recebido: ", manifest_path,
      call. = FALSE
    )
  }

  manifest <- jsonlite::read_json(
    manifest_path,
    simplifyVector = FALSE
  )

  if (
    is.null(manifest$metadata) ||
      !identical(manifest$metadata$appmode, "shiny")
  ) {
    stop(
      "O manifesto enviado ao deploy não contém ",
      "metadata$appmode = 'shiny': ",
      manifest_path,
      call. = FALSE
    )
  }

  terra_manifest <- manifest$packages$terra
  if (
    is.null(terra_manifest) ||
      !identical(terra_manifest$GithubUsername, "rspatial") ||
      !identical(terra_manifest$GithubRepo, "terra") ||
      is.null(terra_manifest$GithubSHA1) ||
      !nzchar(terra_manifest$GithubSHA1)
  ) {
    stop(
      "O registro do pacote terra no manifesto não contém ",
      "os metadados Github* exigidos.",
      call. = FALSE
    )
  }

  message("Manifesto efetivamente enviado: ", manifest_path)
  message("App mode confirmado: ", manifest$metadata$appmode)
  message(
    "terra confirmado: ",
    terra_manifest$GithubUsername,
    "/",
    terra_manifest$GithubRepo,
    "@",
    substr(terra_manifest$GithubSHA1, 1L, 8L)
  )

  # O rsconnect 1.10.1 resolve manifestPath relativamente ao
  # diretório de trabalho antes de considerar appDir. No Windows,
  # MANIFEST.json e manifest.json também podem colidir por causa da
  # insensibilidade a maiúsculas e minúsculas. Executar o deploy de
  # dentro da pasta shiny elimina essa ambiguidade.
  old_working_directory <- setwd(app_dir)
  on.exit(setwd(old_working_directory), add = TRUE)

  local_manifest <- normalizePath(
    "manifest.json",
    winslash = "/",
    mustWork = TRUE
  )

  if (!identical(local_manifest, manifest_path)) {
    stop(
      "O rsconnect resolveria um manifesto diferente do validado.\n",
      "Validado: ", manifest_path, "\n",
      "Resolvido: ", local_manifest,
      call. = FALSE
    )
  }

  rsconnect::deployApp(
    appDir = ".",
    manifestPath = "manifest.json",
    appName = settings$app_name,
    appTitle = settings$app_title,
    account = settings$account,
    server = settings$server,
    forceUpdate = TRUE
  )
}

deploy_shiny_main <- function() {
  project_root <- find_project_root()
  old_working_directory <- getwd()
  on.exit(setwd(old_working_directory), add = TRUE)
  setwd(project_root)

  required_packages <- c(
    "rsconnect",
    "jsonlite",
    "yaml",
    "sf",
    "terra"
  )

  missing_packages <- required_packages[!vapply(
    required_packages,
    requireNamespace,
    quietly = TRUE,
    FUN.VALUE = logical(1)
  )]

  if (length(missing_packages)) {
    stop(
      "Instale os pacotes: ",
      paste(missing_packages, collapse = ", "),
      call. = FALSE
    )
  }

  source(file.path(project_root, "R", "config.R"))
  source(file.path(project_root, "R", "spatial_population.R"))
  source(file.path(project_root, "R", "deployment.R"))

  message("Projeto: ", project_root)

  census_config <- resolve_census_config()
  tract_path <- census_shiny_path(census_config)

  if (!file.exists(tract_path)) {
    stop(
      "A base espacial ativa do Shiny não foi encontrada. ",
      "Execute scripts/02_prepare_census.R antes da publicação.",
      call. = FALSE
    )
  }

  tracts <- sf::st_read(tract_path, quiet = TRUE)
  .validate_final_census(
    tracts,
    census_config,
    strict_reference = TRUE
  )

  app_dir <- file.path(project_root, "shiny")
  deployment_config <- read_deployment_config()

  validate_shiny_deployment_files(app_dir)
  validate_local_terra_version(deployment_config)
  prepare_deployment_lockfiles(config = deployment_config)
  validate_shiny_dependencies(app_dir, deployment_config)

  manifest_path <- write_validated_shiny_manifest(
    app_dir = app_dir,
    config = deployment_config
  )
  on.exit(unlink(manifest_path, force = TRUE), add = TRUE)

  settings <- resolve_shinyapps_settings(deployment_config)

  message(
    "Publicando ", settings$app_name,
    " em ", settings$account, "/", settings$server, "..."
  )

  result <- deploy_from_shiny_directory(
    app_dir = app_dir,
    settings = settings,
    manifest_path = manifest_path
  )

  invisible(result)
}

deploy_shiny_main()
