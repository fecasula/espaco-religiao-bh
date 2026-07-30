test_that("ICR permanece entre zero e um", {
  mock <- tibble::tibble(
    icr = c(0, .5, 1),
    populacao_coberta = c(0, 50, 100)
  )
  expect_invisible(validate_coverage(mock))
  expect_error(
    validate_coverage(
      tibble::tibble(icr = 1.1, populacao_coberta = 100)
    )
  )
})

test_that("cobertura não depende do nome da coluna geométrica", {
  tract_polygon <- sf::st_polygon(list(matrix(
    c(
      -43.95, -19.93,
      -43.94, -19.93,
      -43.94, -19.92,
      -43.95, -19.92,
      -43.95, -19.93
    ),
    ncol = 2,
    byrow = TRUE
  )))

  tracts <- sf::st_sf(
    populacao = 100,
    geom = sf::st_sfc(tract_polygon, crs = 4674),
    sf_column_name = "geom"
  )

  points <- sf::st_as_sf(
    tibble::tibble(
      confissao = "Católica",
      longitude = -43.945,
      latitude = -19.925
    ),
    coords = c("longitude", "latitude"),
    crs = 4674
  )

  result <- coverage_by_confession(
    points = points,
    tracts = tracts,
    speed_kmh = 4,
    time_min = 9.7
  )

  expect_equal(nrow(result), length(confessions))
  expect_true(all(result$icr >= 0 & result$icr <= 1))
})
