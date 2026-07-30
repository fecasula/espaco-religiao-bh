# Prepara e valida os lockfiles e o manifesto usados pelo Shiny
# -------------------------------------------------------------

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

find_root_manifest_collisions <- function(project_root) {
  files <- list.files(
    project_root,
    pattern = "^manifest\\.json$",
    ignore.case = TRUE,
    full.names = TRUE
  )

  normalizePath(
    files,
    winslash = "/",
    mustWork = FALSE
  )
}

prepare_shiny_deployment_main <- function() {
  project_root <- find_project_root()
  old_working_directory <- getwd()
  on.exit(setwd(old_working_directory), add = TRUE)
  setwd(project_root)

  source(file.path(project_root, "R", "config.R"))
  source(file.path(project_root, "R", "deployment.R"))

  config <- read_deployment_config()
  app_dir <- file.path(project_root, "shiny")

  root_collisions <- find_root_manifest_collisions(project_root)
  if (length(root_collisions)) {
    message(
      "Arquivo com nome equivalente a manifest.json encontrado na raiz:"
    )
    for (path in root_collisions) {
      message("- ", path)
    }
    message(
      "O script 05 fará o deploy de dentro da pasta shiny para ",
      "evitar colisão no Windows."
    )
  }

  validate_local_terra_version(config)
  prepare_deployment_lockfiles(config = config)
  validate_shiny_dependencies(app_dir, config)

  manifest_path <- write_validated_shiny_manifest(
    app_dir = app_dir,
    config = config
  )
  on.exit(unlink(manifest_path, force = TRUE), add = TRUE)

  manifest <- jsonlite::read_json(
    manifest_path,
    simplifyVector = FALSE
  )

  stopifnot(
    identical(manifest$metadata$appmode, "shiny"),
    identical(
      normalizePath(
        manifest_path,
        winslash = "/",
        mustWork = TRUE
      ),
      normalizePath(
        file.path(app_dir, "manifest.json"),
        winslash = "/",
        mustWork = TRUE
      )
    )
  )

  message("Manifesto pré-validado: ", manifest_path)
  message(
    "A validação confirmou metadata$appmode, os metadados ",
    "Github* e o caminho exato dentro da pasta shiny."
  )
  message(
    "O arquivo temporário será removido ao término deste script; ",
    "o script 05 o recriará e executará o deploy a partir da pasta shiny."
  )

  invisible(TRUE)
}

prepare_shiny_deployment_main()
