map_confession <- function(category) {
  dplyr::case_when(
    category == "CATÓLICA" ~ "Católica",
    category == "ESPÍRITA" ~ "Espírita",
    category == "AFRO-BRASILEIRA" ~ "Afro-brasileira",
    category %in% c("PENTECOSTAL CLÁSSICA", "PROTESTANTE/EVANGÉLICA GENÉRICA", "PROTESTANTE HISTÓRICA", "NEOPENTECOSTAL") ~ "Protestante/Evangélica",
    TRUE ~ "Outra"
  )
}

prepare_establishment_points <- function(data, municipality_code = bh_code) {
  required <- c("cod_munici", "cod_setor", "latitude", "longitude", "dsc_estabe", "Categoria")
  missing <- setdiff(required, names(data))
  if (length(missing)) rlang::abort(paste("Colunas ausentes:", paste(missing, collapse=", ")))
  data |>
    dplyr::mutate(
      cod_munici = as.character(cod_munici),
      dsc_estabe_norm = stringr::str_to_upper(stringr::str_squish(dsc_estabe)),
      confissao = map_confession(Categoria)
    ) |>
    dplyr::filter(cod_munici == municipality_code, dsc_estabe_norm != "IGREJA") |>
    dplyr::filter(!is.na(latitude), !is.na(longitude)) |>
    dplyr::distinct(latitude, longitude, dsc_estabe_norm, .keep_all=TRUE)
}

points_to_sf <- function(data) {
  sf::st_as_sf(data, coords=c("longitude","latitude"), crs=project_crs_geographic, remove=FALSE)
}
