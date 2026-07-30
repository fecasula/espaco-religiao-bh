# Instalação reprodutível das dependências do projeto
# --------------------------------------------------
# Este script foi preparado para funcionar especialmente no Windows,
# utilizando o espelho global do CRAN, pacotes binários e o método
# de download "wininet" solicitado para redes com restrições de SSL/TLS.

project_root <- normalizePath(".", winslash = "/", mustWork = TRUE)
description_file <- file.path(project_root, "DESCRIPTION")

if (!file.exists(description_file)) {
  stop(
    "Execute este script a partir da raiz do projeto, onde está o arquivo DESCRIPTION.",
    call. = FALSE
  )
}

is_windows <- identical(.Platform$OS.type, "windows")
cran_repo <- "https://cloud.r-project.org"
package_type <- if (is_windows) "binary" else getOption("pkgType", "source")

options(
  repos = c(CRAN = cran_repo),
  pkgType = package_type
)

if (is_windows) {
  options(download.file.method = "wininet")
}

message("Projeto: ", project_root)
message("Repositório CRAN: ", cran_repo)
message("Tipo de pacote: ", package_type)
if (is_windows) message("Método de download: wininet")

r_major_minor <- paste(
  R.version$major,
  strsplit(R.version$minor, "\\.", fixed = FALSE)[[1]][1],
  sep = "."
)

user_library <- path.expand(Sys.getenv("R_LIBS_USER"))

if (!nzchar(user_library)) {
  if (is_windows && nzchar(Sys.getenv("LOCALAPPDATA"))) {
    user_library <- file.path(
      Sys.getenv("LOCALAPPDATA"),
      "R",
      "win-library",
      r_major_minor
    )
  } else {
    user_library <- file.path(path.expand("~"), "R", "library", r_major_minor)
  }
}

dir.create(user_library, recursive = TRUE, showWarnings = FALSE)

if (file.access(user_library, 2) != 0) {
  stop(
    "A biblioteca pessoal não possui permissão de escrita: ",
    user_library,
    call. = FALSE
  )
}

.libPaths(unique(c(user_library, .libPaths())))
message("Biblioteca pessoal utilizada: ", user_library)

remove_stale_locks <- function(libraries) {
  libraries <- unique(normalizePath(
    libraries[dir.exists(libraries)],
    winslash = "/",
    mustWork = FALSE
  ))

  for (library_path in libraries) {
    if (file.access(library_path, 2) != 0) next

    locks <- list.files(
      library_path,
      pattern = "^00LOCK",
      full.names = TRUE
    )

    if (length(locks)) {
      message("Removendo travas antigas em: ", library_path)
      unlink(locks, recursive = TRUE, force = TRUE)
    }
  }

  invisible(TRUE)
}

install_cran_binary <- function(packages, lib) {
  packages <- unique(packages[nzchar(packages) & !is.na(packages)])
  if (!length(packages)) return(invisible(character()))

  installed_before <- rownames(utils::installed.packages(lib.loc = lib))
  missing_before <- setdiff(packages, installed_before)

  if (!length(missing_before)) {
    message("Pacotes já instalados na biblioteca de destino: ", paste(packages, collapse = ", "))
    return(invisible(character()))
  }

  message("Instalando: ", paste(missing_before, collapse = ", "))

  utils::install.packages(
    missing_before,
    lib = lib,
    repos = cran_repo,
    type = package_type,
    dependencies = NA
  )

  installed_after <- rownames(utils::installed.packages(lib.loc = lib))
  missing_after <- setdiff(missing_before, installed_after)

  if (length(missing_after)) {
    stop(
      paste0(
        "Falha ao instalar: ",
        paste(missing_after, collapse = ", "),
        ". Feche todas as sessões do R/RStudio, remova pastas 00LOCK restantes e execute novamente."
      ),
      call. = FALSE
    )
  }

  invisible(missing_before)
}

remove_stale_locks(.libPaths())

# Pacotes necessários antes da leitura e do gerenciamento do projeto.
install_cran_binary(c("rlang", "yaml", "renv"), user_library)

# Inicializa ou carrega o ambiente isolado do projeto.
if (!file.exists(file.path(project_root, "renv", "activate.R"))) {
  renv::init(
    project = project_root,
    bare = TRUE,
    restart = FALSE
  )
}

renv::load(project = project_root)
project_library <- renv::paths$library(project = project_root)
dir.create(project_library, recursive = TRUE, showWarnings = FALSE)
remove_stale_locks(c(project_library, .libPaths()))

# O projeto mantém suas dependências ativas no DESCRIPTION.
# O modo explícito evita que scripts históricos em archive/ sejam tratados
# como dependências obrigatórias da aplicação atual.
desc <- read.dcf(description_file)
fields <- intersect(c("Depends", "Imports", "Suggests", "LinkingTo"), colnames(desc))
raw_dependencies <- paste(desc[1, fields], collapse = ",")
packages <- trimws(unlist(strsplit(raw_dependencies, ",", fixed = TRUE)))
packages <- sub("\\s*\\(.*\\)$", "", packages)
packages <- unique(packages[nzchar(packages) & !is.na(packages)])
packages <- setdiff(packages, c("R"))

install_cran_binary(packages, project_library)

# Registra as versões efetivamente instaladas sem abrir perguntas interativas.
renv::snapshot(
  project = project_root,
  type = "explicit",
  prompt = FALSE
)

# Mantém os metadados de origem GitHub exigidos pelo manifesto do
# shinyapps.io. A validação falha de forma explícita se terra e o commit
# fixado em config/deployment.yml deixarem de corresponder.
source(file.path(project_root, "R", "config.R"))
source(file.path(project_root, "R", "deployment.R"))

tryCatch(
  prepare_deployment_lockfiles(config = read_deployment_config()),
  error = function(error) {
    warning(
      "O ambiente foi instalado, mas o lockfile de deploy requer revisão: ",
      conditionMessage(error),
      call. = FALSE
    )
  }
)

status <- renv::status(project = project_root)

cat(
  "\nInstalação concluída.\n",
  "- Dependências registradas em renv.lock.\n",
  "- Modo de snapshot: explicit (DESCRIPTION).\n",
  "- Confirme também a instalação do Quarto CLI.\n",
  sep = ""
)

invisible(status)
