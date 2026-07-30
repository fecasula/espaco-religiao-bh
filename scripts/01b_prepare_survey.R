source("R/config.R")
source("R/io.R")
source("R/clean_survey.R")

people_path <- "data/private/banco_idosos_v0.9.5.csv"
od_path <- "data/private/OD_banco_idosos_v0.9.5.csv"
people <- read_private_survey(people_path)
od <- read_private_survey(od_path)

bh_model <- prepare_survey_model_base(people, municipality = "Belo Horizonte")
rmbh_model <- prepare_survey_model_base(people)
religious_od <- prepare_religious_od(od)

write_csv_atomic(bh_model, "data/derived/base_bh_regressao.csv")
write_csv_atomic(rmbh_model, "data/derived/base_rmbh_regressao.csv")
# Esta saída ainda contém person_id e bairros; deve permanecer privada até desidentificação.
write_csv_atomic(religious_od, "data/private/od_religiao_tratado.csv")
cat("Bases analíticas preparadas. Revise o arquivo privado antes de qualquer exportação pública.\n")
