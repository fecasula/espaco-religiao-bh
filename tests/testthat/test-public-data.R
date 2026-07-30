testthat::test_that("universo público reproduz 3.848 pontos", {
  path <- test_project_path(
    "data", "public", "pontos_religiosos_bh.csv"
  )

  testthat::expect_true(
    file.exists(path),
    info = paste("Arquivo público não encontrado:", path)
  )

  x <- readr::read_csv(path, show_col_types = FALSE)

  testthat::expect_equal(nrow(x), 3848)
  testthat::expect_false(any(
    stringr::str_to_upper(stringr::str_squish(x$dsc_estabe)) == "IGREJA"
  ))
  testthat::expect_true(all(x$confissao %in% c(confessions, "Outra")))
})

testthat::test_that("base pública de deslocamentos é desidentificada", {
  path <- test_project_path(
    "data", "public", "od_religiao_public.csv"
  )

  testthat::expect_true(
    file.exists(path),
    info = paste("Arquivo público não encontrado:", path)
  )

  x <- readr::read_csv(path, show_col_types = FALSE)

  testthat::expect_equal(nrow(x), 86)
  testthat::expect_false(any(
    c("person_id", "bairro_resid", "bairro_relig") %in% names(x)
  ))
})
