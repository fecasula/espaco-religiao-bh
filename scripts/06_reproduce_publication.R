# Reproduz tabelas e figuras a partir dos dados públicos e resultados congelados.
source("R/config.R"); source("R/io.R"); source("R/descriptive.R"); source("R/plots.R")
trips <- read_public_trips()
fs::dir_create("outputs")
readr::write_csv(summarise_category(trips, dia, "wald"), "outputs/dias_wald.csv")
readr::write_csv(summarise_category(trips, companhia, "wald"), "outputs/companhia_wald.csv")
readr::write_csv(summarise_modes(trips, "wald"), "outputs/modos_wald.csv")
cat("Resultados descritivos reproduzidos em outputs/.\n")
