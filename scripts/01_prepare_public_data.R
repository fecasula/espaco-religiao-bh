source("R/config.R"); source("R/io.R"); source("R/spatial_points.R"); source("R/validation.R")
input <- "data/private/pontos_reli_categorizado.csv"
if (!file.exists(input)) stop("Copie pontos_reli_categorizado.csv para data/private/.")
raw <- readr::read_csv(input, show_col_types=FALSE)
clean <- prepare_establishment_points(raw)
public <- clean |>
  dplyr::transmute(id_estabelecimento=dplyr::row_number(), cod_setor, latitude, longitude, dsc_estabe, categoria_original=Categoria, confissao)
validate_public_universe(public)
write_csv_atomic(public, "data/public/pontos_religiosos_bh.csv")
