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
    
    # Fatores
    sexo        = factor(sexo),
    raca        = factor(raca),
    estadocivil = factor(estadocivil),
    dif_andar   = factor(dif_andar),
    renda       = factor(renda),
    idade1      = as.numeric(idade1)
  )

#-------------------------------------------------------
# Modelos
#-------------------------------------------------------
formula_demo  <- ~ idade1 + sexo + raca + estadocivil
formula_socio <- ~ idade1 + sexo + raca + estadocivil + renda
formula_geral <- ~ idade1 + sexo + raca + estadocivil + renda + dif_andar

# Base limpa comum a todos os modelos (essencial para AIC/BIC comparáveis)
vars_modelos <- c("religiao", "religiao2", all.vars(formula_geral))
df_reg_clean <- df_reg %>% 
  drop_na(all_of(vars_modelos))

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
# EXTRAÇÃO E AGRUPAMENTO DOS PSEUDO R2
#------------------------------------------------------------

# 1. Criar uma lista nomeada com todos os modelos
lista_modelos <- list(
  "Demo (1 Deslocamento)"   = m_demo_1_desc,
  "Socio (1 Deslocamento)"  = m_socio_1_desc,
  "Geral (1 Deslocamento)"  = m_geral_1_desc,
  "Demo (2+ Deslocamentos)"  = m_demo_2_desc,
  "Socio (2+ Deslocamentos)" = m_socio_2_desc,
  "Geral (2+ Deslocamentos)" = m_geral_2_desc
)

# 2. Extrair as métricas e estruturar em formato de tabela (tibble)
tabela_pseudo_r2 <- lista_modelos %>%
  # Executa a função pR2 para cada modelo e transforma o resultado em data frame
  map_dfr(~ as.data.frame(t(pscl::pR2(.x))), .id = "Modelo") %>%
  # Seleciona e renomeia apenas as métricas mais comuns de Pseudo R2
  select(
    Modelo, 
    `Log-Likelihood (Null)` = llhNull, 
    `Log-Likelihood (Model)` = llh, 
    `McFadden (McFadden)` = McFadden, 
    `Cox & Snell (ML)` = r2ML, 
    `Nagelkerke (CU)` = r2CU
  )

# 3. Visualizar o resultado
print(tabela_pseudo_r2)

write.csv(tabela_pseudo_r2, paste0(base_path, '/dados/tratados/teste_modelos_rl.csv'))
