testthat::test_that("a configuração censitária padrão usa a base definitiva do IBGE", {
  config <- resolve_census_config()

  testthat::expect_identical(config$municipio$codigo_ibge, "3106200")
  testthat::expect_identical(config$municipio$nome, "Belo Horizonte")
  testthat::expect_identical(config$fonte$tipo, "ibge_definitivo")
  testthat::expect_identical(config$fonte$camada, "MG_setores_CD2022")
  testthat::expect_identical(config$saida$formato, "GPKG")
})

testthat::test_that("municípios não homologados são bloqueados", {
  testthat::expect_error(
    resolve_census_config(
      overrides = list(
        codigo_municipio = "3550308",
        nome_municipio = "São Paulo",
        uf = "SP"
      )
    ),
    "Município ainda não suportado"
  )
})

testthat::test_that("o produto oficial tem nome definitivo", {
  config <- resolve_census_config()

  testthat::expect_identical(
    census_output_basename(config),
    "setores_3106200_2022_definitivo.gpkg"
  )
  testthat::expect_match(
    census_source_path(config),
    "MG_setores_CD2022[.]gpkg$"
  )
  testthat::expect_match(
    census_shiny_path(config),
    "setores_ativos[.]gpkg$"
  )
})

testthat::test_that("auto prioriza wininet no Windows", {
  config <- resolve_census_config()
  methods <- .census_download_methods(config)

  if (identical(.Platform$OS.type, "windows")) {
    testthat::expect_identical(methods, c("wininet", "libcurl"))
  } else {
    testthat::expect_identical(methods, "libcurl")
  }
})
