library(targets)

tar_option_set(
  packages = c(
    "dplyr", "readr", "sf", "ggplot2", "purrr", "tidyr",
    "stringr", "here", "yaml", "fs", "tibble"
  ),
  format = "rds"
)

for (f in list.files("R", pattern = "\\.R$", full.names = TRUE)) source(f)

list(
  tar_target(census_config_file, "config/censo.yml", format = "file"),
  tar_target(census_config, resolve_census_config(census_config_file)),

  tar_target(trips, read_public_trips()),
  tar_target(points_raw, read_public_establishments()),
  tar_target(points_valid, validate_public_universe(points_raw)),
  tar_target(days, summarise_category(trips, dia, method = "wilson")),
  tar_target(company, summarise_category(trips, companhia, method = "wilson")),
  tar_target(
    location,
    summarise_category(
      dplyr::mutate(
        trips,
        localizacao = dplyr::if_else(
          mesmo_bairro == 1,
          "Bairro de residência",
          "Fora do bairro de residência"
        )
      ),
      localizacao,
      method = "wilson"
    )
  ),
  tar_target(modes, summarise_modes(trips, method = "wilson")),

  tar_target(
    census_file,
    prepare_census_data(config = census_config),
    format = "file"
  ),
  tar_target(
    census_audit_files,
    {
      census_file
      paths <- census_audit_paths(census_config)
      if (!all(file.exists(paths))) {
        stop("Os relatórios de auditoria censitária não foram produzidos.")
      }
      unname(paths)
    },
    format = "file"
  ),
  tar_target(
    census,
    read_census_tracts(census_file, census_config)
  ),
  tar_target(
    shiny_census_file,
    {
      destination <- census_shiny_path(census_config)
      copy_census_to_shiny(
        source = census_file,
        config = census_config,
        destination = destination
      )
      destination
    },
    format = "file"
  ),

  tar_target(points_sf, points_to_sf(points_raw)),
  tar_target(icr_default, coverage_by_confession(points_sf, census, 4, 9.7)),
  tar_target(icr_valid, validate_coverage(icr_default))
)
