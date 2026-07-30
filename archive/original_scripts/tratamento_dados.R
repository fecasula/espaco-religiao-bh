#=======================================================
# TRATAMENTOS DADOS: DESLOCAMENTOS POR MOTIV. RELIGIOSA
#=======================================================
# OBJETIVO:

#-------------------------------------------------------
rm(list = ls(all = TRUE))

# Bibliotecas 
library(tidyverse)

#-------------------------------------------------------
# Carregar dados 
base_path <- "D:/deslocamentos_religiao"
dados_geral <- read.csv(paste0(base_path, "/dados/originais/banco_idosos_v0.9.5.csv"))

#-------------------------------------------------------
# Filtrar dados (município de residência == 'Belo Horizonte') 
table(dados_geral$municipio)
n_total <- count(dados_geral)

dados_bh <- dados_geral %>%
  filter(municipio == 'Belo Horizonte')
n_bh <- count(dados_bh)

#-------------------------------------------------------
# Tratar dados (incluir variáves sobre n de deslocamentos religiosos e alterar tipo das colunas)
dados_bh <- dados_bh %>%
  mutate(
    renda1 = str_replace_all(renda1, "[^0-9,\\.]", ""),
    renda1 = str_replace(renda1, ",", "."),
    renda1 = if_else(renda1 %in% c("99999", "99", "NR", "."), NA_character_, renda1),
    renda1 = as.numeric(renda1)
  )

# Estabelecer faixas de renda por quartil
dados_bh <- dados_bh %>%
  mutate(
    renda1 = cut(
      renda1,
      breaks = c(-1, 1620, 2600, 4600, Inf),
      labels = c("Até R$1620", "R$1620 a R$2600", "R$2300 a R$4600", "Acima de R$4600"),
      right = TRUE
    )
  )

# Contagem de deslocamentos com motivação religiosa
dados_bh <- dados_bh %>%
  mutate(
    n_deslocamentos = rowSums(
      across(
        .cols = ends_with(c("dom", "seg", "ter", "quar", "quin", "sex", "sab")),
        .fns = ~str_count(., "Religi�o")
      ),
      na.rm = TRUE
    )
  )

table(dados_bh$n_deslocamentos)

# Ajuste raça
dados_bh <- dados_bh %>%
  mutate(cor_raca = case_when(
    cor_raca %in% c("Branca", "Amarela") ~ "Brancos",
    cor_raca %in% c("Preta", "Parda") ~ "Negros",
    TRUE ~ cor_raca
  ))


# Ajuste para mobilidade reduzida
dados_bh <- dados_bh %>%
  mutate(
    dif_andar = case_when(
      dif_andar == "n_o_tem_dificuldade" ~ "Sem mobilidade reduzida",
      !is.na(dif_andar) ~ "Com mobilidade reduzida",
      TRUE ~ NA_character_
    )
  )

# Ajuste estado civil
dados_bh <- dados_bh %>%
  mutate(estadocivil = case_when(
    estadocivil %in% c("casado_a__com_pessoa_do_sexo_diferente",
                       "uni_o_est_vel_com_pessoa_do_mesmo_sexo",
                       "uni_o_est_vel_com_pessoa_do_sexo_diferente") ~ "Casado/a",
    estadocivil == "solteiro_a" ~ "Solteiro/a",
    estadocivil == "vi_vo_a" ~ "Viúvo/a",
    estadocivil == "separado_a_desquitado_a" ~ "Separado/a",
    TRUE ~ "Outro"
  ))

# Preparo da base para modelo de regressao
dados_bh <- dados_bh %>%
  rename(
    raca = cor_raca,
    sexo = genero1,
    renda = renda1,
  ) %>%
  mutate(
    religiao = if_else(n_deslocamentos > 0, 1, 0),
    religiao2 = if_else(n_deslocamentos > 1, 1, 0),
    renda = factor(renda, levels = c("Até R$1620", "R$1620 a R$2600", 
                                     "R$2300 a R$4600", "Acima de R$4600")),
# Converter variáveis categóricas para fatores
    sexo = factor(sexo, levels = c("Masculino", "Feminino")),
    raca = factor(raca, levels = c("Brancos", "Negros")),
    dif_andar = factor(dif_andar, levels = c("Sem mobilidade reduzida", "Com mobilidade reduzida")),
    estadocivil = factor(estadocivil, levels = c("Solteiro/a", "Separado/a", "Casado/a", "Viúvo/a"))
  )

base_regressao_bh <- dados_bh %>%
  select(sexo, raca, idade1, estadocivil, renda, dif_andar, religiao, religiao2)

#-------------------------------------------------------
# Salvar dados tratados 
write.csv(base_regressao_bh, paste0(base_path, '/dados/tratados/base_bh_regressao.csv'))
