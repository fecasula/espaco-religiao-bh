test_that("a configuração de deploy fixa terra em commit reproduzível", {
  config <- read_deployment_config(
    test_project_path("config", "deployment.yml")
  )

  expect_identical(config$dependencies$terra$version, "1.9-41")
  expect_identical(config$dependencies$terra$source, "GitHub")
  expect_identical(config$dependencies$terra$github_username, "rspatial")
  expect_identical(config$dependencies$terra$github_repo, "terra")
  expect_match(
    config$dependencies$terra$github_sha1,
    "^[0-9a-f]{40}$"
  )
})

test_that("campos Remote do renv são traduzidos para o formato aceito", {
  record <- list(
    Package = "terra",
    Version = "1.9-41",
    Source = "GitHub",
    RemoteUsername = "rspatial",
    RemoteRepo = "terra",
    RemoteRef = "master",
    RemoteSha = "afe97b775cc963a5c8b1b70459eeabbd287012d4"
  )

  result <- .add_legacy_github_fields(record)

  expect_identical(result$GithubUsername, "rspatial")
  expect_identical(result$GithubRepo, "terra")
  expect_identical(result$GithubRef, "master")
  expect_identical(
    result$GithubSHA1,
    "afe97b775cc963a5c8b1b70459eeabbd287012d4"
  )
})

test_that("os dois lockfiles contêm os metadados aceitos pelo shinyapps.io", {
  config <- read_deployment_config(
    test_project_path("config", "deployment.yml")
  )

  expect_invisible(validate_deployment_lockfile(
    test_project_path("renv.lock"),
    config
  ))
  expect_invisible(validate_deployment_lockfile(
    test_project_path("shiny", "renv.lock"),
    config
  ))
})

test_that("versões aceitam ponto e hífen como separadores equivalentes", {
  expect_identical(.normalize_package_version("1.9.41"), "1.9.41")
  expect_identical(.normalize_package_version("1.9-41"), "1.9.41")
  expect_true(.package_versions_equal("1.9.41", "1.9-41"))
  expect_false(.package_versions_equal("1.9.40", "1.9-41"))
})

test_that("o registro do manifesto recebe metadados GitHub completos", {
  manifest_record <- list(
    Source = "github",
    description = list(Version = "1.9.41")
  )
  lock_record <- list(
    Package = "terra",
    Version = "1.9-41",
    Source = "GitHub",
    GithubUsername = "rspatial",
    GithubRepo = "terra",
    GithubRef = "master",
    GithubSHA1 = "afe97b775cc963a5c8b1b70459eeabbd287012d4"
  )

  result <- .patch_manifest_github_record(
    manifest_record,
    lock_record
  )

  expect_identical(result$Source, "github")
  expect_identical(result$GithubUsername, "rspatial")
  expect_identical(result$GithubRepo, "terra")
  expect_identical(result$GithubRef, "master")
  expect_identical(
    result$GithubSHA1,
    "afe97b775cc963a5c8b1b70459eeabbd287012d4"
  )
  expect_identical(result$description$GithubUsername, "rspatial")
})

test_that("o manifesto sintético é corrigido e validado", {
  temp_dir <- tempfile("manifest-test-")
  dir.create(temp_dir, recursive = TRUE)
  on.exit(unlink(temp_dir, recursive = TRUE, force = TRUE), add = TRUE)

  config <- read_deployment_config(
    test_project_path("config", "deployment.yml")
  )
  source_lock <- .read_json_file(
    test_project_path("shiny", "renv.lock")
  )

  lock_path <- file.path(temp_dir, "renv.lock")
  manifest_path <- file.path(temp_dir, "manifest.json")
  .write_json_atomic(source_lock, lock_path)

  manifest <- list(
    version = 1,
    metadata = list(appmode = "shiny"),
    packages = list(
      terra = list(
        Source = "github",
        description = list(Version = "1.9.41")
      )
    )
  )
  .write_json_atomic(manifest, manifest_path)

  expect_invisible(patch_shiny_manifest(
    manifest_path,
    lock_path,
    config
  ))
  expect_invisible(validate_shiny_manifest(
    manifest_path,
    lock_path,
    config
  ))

  patched <- .read_json_file(manifest_path)
  expect_identical(patched$metadata$appmode, "shiny")
  expect_identical(
    patched$packages$terra$GithubUsername,
    "rspatial"
  )
})

test_that("o script de deploy publica o manifesto validado", {
  script <- readLines(
    test_project_path("scripts", "05_deploy_shiny.R"),
    warn = FALSE,
    encoding = "UTF-8"
  )
  text <- paste(script, collapse = "\n")

  expect_match(text, "write_validated_shiny_manifest")
  expect_match(text, 'manifestPath\\s*=\\s*"manifest.json"')
  expect_false(grepl("manifestPath\\s*=\\s*manifest_path", text))
  expect_match(text, "on.exit\\(unlink\\(manifest_path")
})

test_that("o script de preparação valida e remove o manifesto temporário", {
  script <- readLines(
    test_project_path("scripts", "08_prepare_shiny_lockfile.R"),
    warn = FALSE,
    encoding = "UTF-8"
  )
  text <- paste(script, collapse = "\n")

  expect_match(text, "write_validated_shiny_manifest")
  expect_match(text, "on.exit\\(unlink\\(manifest_path")
})
