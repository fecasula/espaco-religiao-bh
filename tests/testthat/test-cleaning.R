test_that("contagem de motivos religiosos é robusta a acentos", {
  x <- tibble::tibble(motivo_trajeto1seg = c("Religião", "religiao", "Compras", NA_character_))
  out <- count_religious_trips(x)
  expect_equal(out$n_deslocamentos, c(1, 1, 0, 0))
})

test_that("valores monetários brasileiros são convertidos corretamente", {
  x <- clean_income(c(
    "R$ 1.620,00",
    "1.620",
    "1.620,50",
    "2600",
    "4600"
  ))

  expect_equal(x, c(1620, 1620, 1620.50, 2600, 4600))
})

test_that("códigos de ausência de renda permanecem ausentes", {
  x <- clean_income(c(NA_character_, "", "99", "99999"))
  expect_true(all(is.na(x)))
})

test_that("faixas de renda usam limites e rótulos consistentes", {
  x <- clean_income(c("R$ 1.620,00", "2600", "4600", "99999"))
  expect_equal(x[1:3], c(1620, 2600, 4600))
  expect_true(is.na(x[4]))
})
