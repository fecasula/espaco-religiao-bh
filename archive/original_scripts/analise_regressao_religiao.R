#=======================================================
# TESTE MODELOS LOGÍSTIVOS (DEMOGRAFICO, SOCIODEMO., GERAL)
#=======================================================
# OBJETIVO:

#-------------------------------------------------------
rm(list = ls(all = TRUE))

# Bibliotecas 
library(tidyverse)
library(pROC)
library(pscl) 
library(broom)
library(modelsummary)

#-------------------------------------------------------
# Carregar dados 
#-------------------------------------------------------

base_path <- "D:/deslocamentos_religiao"
base_regressao_bh <- read.csv(paste0(base_path, '/dados/tratados/base_bh_regressao.csv'))


# Limpeza e estruturação das variáveis
df_reg <- base_regressao_bh %>%
  mutate(
    # Garante que os outcomes sejam fatores ou numéricos (0 e 1)
    religiao    = as.numeric(as.character(religiao)),
    religiao2   = as.numeric(as.character(religiao2)),
    renda = factor(renda, levels = c("Até R$1620", "R$1620 a R$2600", 
                                     "R$2300 a R$4600", "Acima de R$4600")),
    sexo = factor(sexo, levels = c("Masculino", "Feminino")),
    raca = factor(raca, levels = c("Brancos", "Negros")),
    dif_andar = factor(dif_andar, levels = c("Sem mobilidade reduzida", "Com mobilidade reduzida")),
    estadocivil = factor(estadocivil, levels = c("Solteiro/a", "Separado/a", "Casado/a", "Viúvo/a"))
  )

#-------------------------------------------------------
# Modelos
#-------------------------------------------------------
formula_demo  <- ~ idade1 + sexo + raca + estadocivil
formula_socio <- ~ idade1 + sexo + raca + estadocivil + renda
formula_geral <- ~ idade1 + sexo + raca + estadocivil + renda + dif_andar

# Base limpa comum a todos os modelos
vars_modelos <- c("religiao", "religiao2", all.vars(formula_geral))
df_reg_clean <- df_reg %>% 
  drop_na(all_of(vars_modelos))

glimpse(df_reg_clean)
#------------------------------------------------------------
# LOGISTIC MODELS: PELO MENOS UM DESLOCAMENTO
#------------------------------------------------------------

m_demo_1_desc <- glm(
  religiao ~ idade1 + sexo + raca + estadocivil,
  family = binomial,
  data = df_reg_clean
)

m_socio_1_desc <- glm(
  religiao ~ idade1 + sexo + raca + estadocivil + renda,
  family = binomial,
  data = df_reg_clean
)

m_geral_1_desc <- glm(
  religiao ~ idade1 + sexo + raca + estadocivil + renda + dif_andar,
  family = binomial,
  data = df_reg_clean
)

#------------------------------------------------------------
# LOGISTIC MODELS: MAIS DE UM DESLOCAMENTO
#------------------------------------------------------------

m_demo_2_desc <- glm(
  religiao2 ~ idade1 + sexo + raca + estadocivil,
  family = binomial,
  data = df_reg_clean
)

m_socio_2_desc <- glm(
  religiao2 ~ idade1 + sexo + raca + estadocivil + renda,
  family = binomial,
  data = df_reg_clean
)

m_geral_2_desc <- glm(
  religiao2 ~ idade1 + sexo + raca + estadocivil + renda + dif_andar,
  family = binomial,
  data = df_reg_clean
)

#------------------------------------------------------------
# MODEL SUMMARIES WITH CONFIDENCE INTERVALS AND PSEUDO R2
#------------------------------------------------------------
# 1. Create a named list of your models
models_list <- list(
  "Pelo menos 1: Demo"   = m_demo_1_desc,
  "Pelo menos 1: Socio"  = m_socio_1_desc,
  "Pelo menos 1: Geral"  = m_geral_1_desc,
  "Mais de 1: Demo"      = m_demo_2_desc,
  "Mais de 1: Socio"     = m_socio_2_desc,
  "Mais de 1: Geral"     = m_geral_2_desc
)

# 2. Extract McFadden's Pseudo-R2 for each model dynamically
mcfadden_values <- sapply(models_list, function(m) {
  round(pscl::pR2(m)["McFadden"], 3)
})

# 3. Format the Pseudo-R2 as an extra row data frame
# The first column is the row label; subsequent columns contain the values
rows_extra <- data.frame(
  term = "Pseudo R² (McFadden)",
  m1 = mcfadden_values[1],
  m2 = mcfadden_values[2],
  m3 = mcfadden_values[3],
  m4 = mcfadden_values[4],
  m5 = mcfadden_values[5],
  m6 = mcfadden_values[6]
)

# 4. Generate the publication-ready table (Layout Option A)
modelsummary(
  models_list,
  exponentiate = TRUE, 
  statistic = "conf.int",       # Replaces standard errors with 95% Confidence Intervals
  stars = TRUE,                 # Adds significance stars (* p < 0.1, ** p < 0.05, *** p < 0.01)
  add_rows = rows_extra,        # Appends the Pseudo-R2 row to the bottom
  metrics = "AIC",              # Displays AIC for fit comparison
  title = "Regressão Logística para População Residente em Belo Horizonte: Razão de Chance (OR), 95% IC",
  notes = c(
    "Nota: Os coeficientes estão apresentados como Razões de Chance (Odds Ratios). Os Intervalos de Confiança de 95% estão entre colchetes abaixo.",
  "Interpretação do Pseudo R² (McFadden): Ajuste moderado (0,11 e 0,3); Ajuste forte (>0,3)"
))
