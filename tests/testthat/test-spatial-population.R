make_test_polygons_bh <- function() {
  polygon_1 <- sf::st_polygon(list(matrix(
    c(
      -43.9500, -19.9300,
      -43.9495, -19.9300,
      -43.9495, -19.9295,
      -43.9500, -19.9295,
      -43.9500, -19.9300
    ),
    ncol = 2,
    byrow = TRUE
  )))

  polygon_2 <- sf::st_polygon(list(matrix(
    c(
      -43.9490, -19.9300,
      -43.9485, -19.9300,
      -43.9485, -19.9295,
      -43.9490, -19.9295,
      -43.9490, -19.9300
    ),
    ncol = 2,
    byrow = TRUE
  )))

  list(polygon_1, polygon_2)
}

testthat::test_that("setor multipartido é dissolvido sem duplicar população", {
  config <- resolve_census_config()
  polygons <- make_test_polygons_bh()

  x <- sf::st_sf(
    code_tract = c("310620005670833", "310620005670833"),
    populacao = c(171, 171),
    geometry = sf::st_sfc(polygons[[1]], polygons[[2]], crs = 4674)
  )

  result <- .consolidate_multipart_tracts(x, config)

  testthat::expect_equal(nrow(result$data), 1L)
  testthat::expect_equal(result$data$populacao, 171)
  testthat::expect_equal(result$duplicate_counts$numero_feicoes, 2L)
  testthat::expect_equal(nrow(result$multipart_details), 2L)
  testthat::expect_true(all(sf::st_is_valid(result$data)))
})

testthat::test_that("populações divergentes em partes do mesmo setor são bloqueadas", {
  config <- resolve_census_config()
  polygons <- make_test_polygons_bh()

  x <- sf::st_sf(
    code_tract = c("310620005670833", "310620005670833"),
    populacao = c(171, 172),
    geometry = sf::st_sfc(polygons[[1]], polygons[[2]], crs = 4674)
  )

  testthat::expect_error(
    .consolidate_multipart_tracts(x, config),
    "valores populacionais diferentes"
  )
})
