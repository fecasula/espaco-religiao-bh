test_that("raio é calculado em unidades coerentes", {
  expect_equal(radius_m(4, 9.7), 646.6666667, tolerance=1e-6)
  expect_equal(radius_m(4, 9.74), 649.3333333, tolerance=1e-6)
})

test_that("parâmetros inválidos falham", {
  expect_error(radius_m(0,10))
  expect_error(radius_m(4,-1))
})
