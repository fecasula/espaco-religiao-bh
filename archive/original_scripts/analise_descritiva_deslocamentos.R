#=======================================================
# ANAÁLISE DESCRITIVA DESLOCAMENTO COM MOTIVAÇÃO RELIGIOSA
#=======================================================
# OBJETIVO:

#-------------------------------------------------------
rm(list = ls(all = TRUE))

# Bibliotecas 
library(tidyverse)
library(xlsx)
library(readxl)
library(janitor)
library(lubridate)


#-------------------------------------------------------
# Carregar dados 
base_path <- "D:/deslocamentos_religiao"
od_geral <- read.csv(paste0(base_path, "/dados/originais/OD_banco_idosos_v0.9.5.csv"))%>%
  clean_names()

#-------------------------------------------------------
# Filtrar dados (município de residência == 'Belo Horizonte') 
table(od_geral$municipio)

od_bh <- od_geral %>%
  mutate(person_id = as.character(person_id)) %>%
  filter(municipio == 'Belo Horizonte')

n_bh <- od_bh %>% 
  summarize(n_bh = n_distinct(person_id))

print(n_bh)

#-------------------------------------------------------
# Filtrar por deslocamentos motivados por religião

od_religiao <- od_bh %>%
  filter(str_detect(motivo_trajeto, "^Relig"))

n_religiao <- od_religiao %>% 
  summarize(n_religiao = n_distinct(person_id))

print(n_religiao)
pct_religiao <- n_religiao/n_bh

# df base para analises descritivas
df_base <- od_religiao %>%
  select(person_id, dia, municipio, cidade_destino, bairro, bairro_destino,  
         tempo_desloc, modo_trajeto, companhia) %>%
  rename(municipio_resid = municipio,
         municipio_relig = cidade_destino,
         bairro_resid = bairro,
         bairro_relig = bairro_destino)

#-------------------------------------------------------
# Filtrar por deslocamentos motivados por religião
# Exportar df como excel, realizar correções manuais e retomar análise 
#write.xlsx(df_base, paste0(base_path, '/dados/tratados/od_religiao.xlsx'))

# abrir arquivo corrigido 
df_base <- read_excel(paste0(base_path, '/dados/tratados/od_religiao.xlsx'))


df_tratado <- df_base %>%
  mutate(
    # 1. Força a coluna a ser caractere para que as funções do stringr funcionem sem erro
    tmp_texto = as.character(tmp_corrigido),
    
    # 2. Agora o case_when recebe apenas texto em todas as saídas
    tmp_limpo = case_when(
      str_count(tmp_texto, ":") == 1 ~ str_c(tmp_texto, ":00"),
      TRUE ~ tmp_texto
    ),
    
    # 3. Se a importação original trouxe uma data fantasma junto (ex: "1899-12-31 00:03:00"), 
    # o hms() pode falhar. Usamos hms(str_extract(...)) para garantir que pegamos só o tempo.
    tempo_objeto = hms(str_extract(tmp_limpo, "\\d{2}:\\d{2}:\\d{2}")),
    
    # 4. Transforma em minutos numéricos para os modelos/gráficos
    tempo_minutos = as.numeric(tempo_objeto, "minutes")
  ) %>% 
  # Remove a coluna temporária de texto se quiser deixar o banco limpo
  select(-tmp_texto)

#-------------------------------------------------------
# Analise desc modos de transporte

total_geral <- nrow(df_tratado)

tb_modos_trasp <- df_tratado %>%
  group_by(modo_trajeto) %>%
  summarise(
    n_desloc = n(),
    pct_total = n_desloc / total_geral,
    tmp_medio = mean(tempo_minutos, na.rm = TRUE),
    
    # --- INTERVALO DE CONFIANÇA PARA A PROPORÇÃO (95%) ---
    erro_pct = 1.96 * sqrt((pct_total * (1 - pct_total)) / total_geral),
    pct_inf  = pmax(0, pct_total - erro_pct),  
    pct_sup  = pmin(1, pct_total + erro_pct),  
    
    # --- INTERVALO DE CONFIANÇA PARA A MÉDIA DO TEMPO (95%) ---
    sd_tempo = sd(tempo_minutos, na.rm = TRUE),
    
    # Condicional para evitar o erro de n = 1 ou desvio padrão inexistente
    erro_tempo = if_else(
      n_desloc > 1 & !is.na(sd_tempo),
      qt(0.975, df = n_desloc - 1) * (sd_tempo / sqrt(n_desloc)),
      0 # Se n = 1, a margem de erro é zero (o IC será o próprio valor do ponto)
    ),
    
    tmp_inf = tmp_medio - erro_tempo,
    tmp_sup = tmp_medio + erro_tempo
  ) %>% 
  select(-erro_pct, -sd_tempo, -erro_tempo)

# tempo medio geral
ic_media_geral <- df_tratado %>%
  summarise(
    n_total = n(),
    tmp_medio_geral = mean(tempo_minutos, na.rm = TRUE),
    sd_geral = sd(tempo_minutos, na.rm = TRUE),
    erro_geral = qt(0.975, df = n_total - 1) * (sd_geral / sqrt(n_total)),
    tmp_inf = tmp_medio_geral - erro_geral,
    tmp_sup = tmp_medio_geral + erro_geral
  ) %>% 
  select(n_total, tmp_medio_geral, tmp_inf, tmp_sup)

print(ic_media_geral)
#-------------------------------------------------------
# Analise desc dias da semana

total_geral <- nrow(df_tratado)

analise_frequencia_dias <- df_tratado %>%
  group_by(dia) %>%
  summarise(
    n_desloc = n(),
    pct_total = n_desloc / total_geral,
    
    # --- INTERVALO DE CONFIANÇA PARA A PROPORÇÃO (95%) ---
    # Margem de erro baseada no Z-score de 1.96 (Distribuição Normal)
    erro_pct = 1.96 * sqrt((pct_total * (1 - pct_total)) / total_geral),
    
    # Limites inferior e superior travados entre 0% e 100%
    pct_inf  = pmax(0, pct_total - erro_pct),  
    pct_sup  = pmin(1, pct_total + erro_pct)
  ) %>% 
  # Remove a coluna auxiliar de erro
  select(-erro_pct) %>% 
  
  mutate(
    dia = factor(
      dia, 
      levels = c("seg", "ter", "quar", "quin", "sex", "sab", "dom"),
      labels = c("Segunda", "Terça", "Quarta", "Quinta", "Sexta", "Sábado", "Domingo")
    )
  ) %>% 
  arrange(dia)

#-------------------------------------------------------
# Companhia

total_geral <- nrow(df_tratado)

df_comp <- df_tratado %>%
  mutate(companhia = case_when(
    companhia == 'Sozinho' ~ 'Sozinho',
    companhia %in% c('Familiar residente não pago', 'Familiar residente remunerado') ~ 'Familiar corresidente',
    companhia %in% c('Familiar externo não pago', 'Familiar externo pago') ~ 'Familiar não corresidente',
    TRUE ~ 'Outro'
         ))

analise_frequencia_companhia <- df_comp %>%
  mutate(
    companhia_limpa = str_to_sentence(companhia),
    companhia_limpa = str_trim(companhia_limpa) 
  ) %>% 
  group_by(companhia_limpa) %>%
  summarise(
    # 2. Contagem absoluta de deslocamentos por tipo de companhia
    n_desloc = n(),
    
    # 3. Proporção/Frequência relativa (de 0 a 1)
    pct_total = n_desloc / total_geral,
    
    # --- INTERVALO DE CONFIANÇA PARA A PROPORÇÃO (95%) ---
    erro_pct = 1.96 * sqrt((pct_total * (1 - pct_total)) / total_geral),
    
    # Limites inferior e superior travados estatisticamente entre 0 e 1
    pct_inf  = pmax(0, pct_total - erro_pct),  
    pct_sup  = pmin(1, pct_total + erro_pct)
  ) %>% 
  # Remove a coluna auxiliar de erro e renomeia a coluna final
  select(-erro_pct) %>% 
  rename(companhia = companhia_limpa) %>% 
  # Ordena da companhia mais frequente para a menos frequente
  arrange(desc(pct_total))

#-------------------------------------------------------
# Relação dentro/fora do bairro

f_d_bairro <- df_tratado%>%
  mutate(f_d_bairro = case_when(msm_bairro == 1 ~ 'Bairro de residência',
                                TRUE ~ 'Fora do bairro de residência'))

total_geral <- nrow(f_d_bairro)

analise_frequencia_bairro <- f_d_bairro %>%
  # Remove possíveis espaços em branco nas pontas do texto por garantia
  mutate(f_d_bairro = str_trim(f_d_bairro)) %>% 
  group_by(f_d_bairro) %>%
  summarise(
    # 1. Contagem absoluta de deslocamentos
    n_desloc = n(),
    
    # 2. Proporção/Frequência relativa (de 0 a 1)
    pct_total = n_desloc / total_geral,
    
    # --- INTERVALO DE CONFIANÇA PARA A PROPORÇÃO (95%) ---
    erro_pct = 1.96 * sqrt((pct_total * (1 - pct_total)) / total_geral),
    
    # Limites inferior e superior travados entre 0 e 1
    pct_inf  = pmax(0, pct_total - erro_pct),  
    pct_sup  = pmin(1, pct_total + erro_pct)
  ) %>% 
  # Remove a coluna auxiliar de erro
  select(-erro_pct) %>% 
  # Ordena pela maior frequência
  arrange(desc(pct_total))

base_path <- "D:/deslocamentos_religiao"
resultados_dir <- paste0(base_path, '/resultados')

# Garantir que a pasta 'resultados' existe no seu disco
if (!dir.exists(resultados_dir)) {
  dir.create(resultados_dir, recursive = TRUE)
}

# Guardar os ficheiros corretamente
# write.csv(objeto, file = "caminho/para/o/ficheiro.csv", row.names = FALSE)

write.csv(tb_modos_trasp, file = paste0(resultados_dir, "/modo_transp.csv"), row.names = FALSE)
write.csv(analise_frequencia_bairro, file = paste0(resultados_dir, "/analise_frequencia_bairro.csv"), row.names = FALSE)
write.csv(analise_frequencia_companhia, file = paste0(resultados_dir, "/analise_frequencia_companhia.csv"), row.names = FALSE)
write.csv(analise_frequencia_dias, file = paste0(resultados_dir, "/analise_frequencia_dias.csv"), row.names = FALSE)

#=========================================================================
# PLOTAGENS
#=========================================================================

# ============================================================================
# SCRIPT PARA GRÁFICOS ABNT - DESLOCAMENTOS COM MOTIVAÇÃO RELIGIOSA
# ============================================================================

# Carregar pacotes necessários
library(ggplot2)
library(dplyr)
library(scales)

# Configuração do tema ABNT
tema_abnt <- theme_minimal() +
  theme(
    text = element_text(family = "serif", size = 11),
    axis.title = element_text(size = 11, face = "bold"),
    axis.text = element_text(size = 10, color = "black"),
    axis.text.x = element_text(angle = 45, hjust = 1),
    plot.title = element_text(size = 12, face = "bold", hjust = 0.5),
    plot.subtitle = element_text(size = 10, hjust = 0.5),
    panel.grid.major.x = element_blank(),
    panel.grid.minor = element_blank(),
    panel.grid.major.y = element_line(color = "gray80", linewidth = 0.3),
    axis.line = element_line(color = "black", linewidth = 0.5),
    plot.margin = margin(1, 1, 1, 1, "cm"),
    legend.position = "none"
  )

# ============================================================================
# 1. GRÁFICO: Modos de Transporte
# ============================================================================

# Dados
tb_modos_trasp <- data.frame(
  modo_trajeto = c("A pé", "BRT/Ônibus", "Carro de carona", "Carro próprio", "Transporte público"),
  n_desloc = c(57, 7, 8, 13, 1),
  pct_total = c(0.66279070, 0.08139535, 0.09302326, 0.15116279, 0.01162791),
  pct_inf = c(0.56287245, 0.02360292, 0.03163282, 0.07540447, 0),
  pct_sup = c(0.76270895, 0.13918778, 0.15441369, 0.22682111, 0.03488372)
)

# Ordenar por porcentagem
tb_modos_trasp$modo_trajeto <- reorder(tb_modos_trasp$modo_trajeto, -tb_modos_trasp$pct_total)

# Gráfico
graf_modos <- ggplot(tb_modos_trasp, aes(x = modo_trajeto, y = pct_total)) +
  geom_bar(stat = "identity", fill = "gray40", width = 0.7) +
  geom_errorbar(aes(ymin = pct_inf, ymax = pct_sup), 
                width = 0.2, size = 0.7, color = "black") +
  scale_y_continuous(labels = percent_format(accuracy = 1), 
                     limits = c(0, max(tb_modos_trasp$pct_sup) + 0.05)) +
  labs(x = "Modo de Transporte", 
       y = "Proporção de Deslocamentos (%)",
       title = "Distribuição dos Deslocamentos por Motivação Religiosa por Modo de Transporte",
       subtitle = "População acima de 60 anos residente em Belo Horizonte",
       caption = "Fonte: Elaboração Própria") +
  tema_abnt +
  theme(axis.text.x = element_text(angle = 0, hjust = 0.5))

print(graf_modos)

# ============================================================================
# 2. GRÁFICO: Frequência por Dias da Semana
# ============================================================================

# Dados (corrigindo os valores conforme seu glimpse)
analise_frequencia_dias <- data.frame(
  dia = factor(c("Segunda", "Terça", "Quarta", "Quinta", "Sexta", "Sábado", "Domingo"),
               levels = c("Segunda", "Terça", "Quarta", "Quinta", "Sexta", "Sábado", "Domingo")),
  n_desloc = c(3, 9, 8, 5, 5, 12, 44),
  pct_total = c(0.03488372, 0.10465116, 0.09302326, 0.05813953, 0.05813953, 0.13953488, 0.51162791),
  pct_inf = c(0, 0.039955523, 0.031632824, 0.008639614, 0.008639614, 0.068660649, 0.413297824),
  pct_sup = c(0.07366374, 0.16934680, 0.15441369, 0.10759744, 0.10759744, 0.21040912, 0.60995799)
)

# Gráfico
graf_dias <- ggplot(analise_frequencia_dias, aes(x = dia, y = pct_total)) +
  geom_bar(stat = "identity", fill = "gray40", width = 0.7) +
  geom_errorbar(aes(ymin = pct_inf, ymax = pct_sup), 
                width = 0.2, size = 0.7, color = "black") +
  scale_y_continuous(labels = percent_format(accuracy = 1), 
                     limits = c(0, max(analise_frequencia_dias$pct_sup) + 0.05)) +
  labs(x = "Dia da Semana", 
       y = "Proporção de Deslocamentos (%)",
       title = "Distribuição dos Deslocamentos por Motivação Religiosa por Dia da Semana",
       subtitle = "População acima de 60 anos residente em Belo Horizonte",
       caption = "Fonte: Elaboração Própria") +
  tema_abnt

print(graf_dias)

# ============================================================================
# 3. GRÁFICO: Companhia durante o deslocamento (ATUALIZADO)
# ============================================================================

# Dados atualizados
analise_frequencia_companhia <- data.frame(
  companhia = c("Sozinho", "Familiar corresidente", "Outro", "Familiar não corresidente"),
  n_desloc = c(47, 22, 11, 6),
  pct_total = c(0.54651163, 0.25581395, 0.12790698, 0.06976744),
  pct_inf = c(0.44129373, 0.16359722, 0.05731825, 0.01592447),
  pct_sup = c(0.6517295, 0.3480307, 0.1984957, 0.1236104)
)

# Ordenar por porcentagem (decrescente)
analise_frequencia_companhia$companhia <- reorder(analise_frequencia_companhia$companhia, 
                                                  -analise_frequencia_companhia$pct_total)

# Gráfico de barras com intervalos de confiança
graf_companhia <- ggplot(analise_frequencia_companhia, aes(x = companhia, y = pct_total)) +
  geom_bar(stat = "identity", fill = "gray40", width = 0.7) +
  geom_errorbar(aes(ymin = pct_inf, ymax = pct_sup), 
                width = 0.2, size = 0.7, color = "black") +
  scale_y_continuous(labels = percent_format(accuracy = 1), 
                     limits = c(0, max(analise_frequencia_companhia$pct_sup) + 0.05)) +
  labs(x = "Tipo de Companhia", 
       y = "Proporção de Deslocamentos (%)",
       title = "Distribuição dos Deslocamentos por Motivação Religiosa por Tipo de Companhia",
       subtitle = "População acima de 60 anos residente em Belo Horizonte",
       caption = "Fonte: Elaboração Própria") +
  tema_abnt +
  theme(axis.text.x = element_text(angle = 0, hjust = 0.5))

print(graf_companhia)

# ============================================================================
# 4. GRÁFICO: Frequência por Bairro
# ============================================================================

# Dados
analise_frequencia_bairro <- data.frame(
  f_d_bairro = c("Bairro de residência", "Fora do bairro de residência"),
  n_desloc = c(65, 21),
  pct_total = c(0.755814, 0.244186),
  pct_inf = c(0.6650163, 0.1533884),
  pct_sup = c(0.8466116, 0.3349837)
)

# Gráfico
graf_bairro <- ggplot(analise_frequencia_bairro, aes(x = f_d_bairro, y = pct_total)) +
  geom_bar(stat = "identity", fill = "gray40", width = 0.6) +
  geom_errorbar(aes(ymin = pct_inf, ymax = pct_sup), 
                width = 0.15, size = 0.7, color = "black") +
  scale_y_continuous(labels = percent_format(accuracy = 1), 
                     limits = c(0, max(analise_frequencia_bairro$pct_sup) + 0.05)) +
  labs(x = "Localização do Deslocamento", 
       y = "Proporção de Deslocamentos (%)",
       title = "Deslocamentos por Motivação Religiosa Dentro e Fora do Bairro de Residência",
       subtitle = "População acima de 60 anos residente em Belo Horizonte",
       caption = "Fonte: Elaboração Própria") +
  tema_abnt +
  theme(axis.text.x = element_text(angle = 0, hjust = 0.5))

print(graf_bairro)

# ============================================================================
# SALVAR PLOTS
# ============================================================================
resultados_dir <- paste0(base_path, '/resultados')

ggsave(paste0(resultados_dir, "/figura1_modos_transporte.png"), 
       graf_modos, width = 8, height = 6, dpi = 300)

ggsave(paste0(resultados_dir, "/figura2_dias_semana.png"), 
       graf_dias, width = 8, height = 6, dpi = 300)

ggsave(paste0(resultados_dir, "/figura3_companhia.png"), 
       graf_companhia, width = 8, height = 6, dpi = 300)

ggsave(paste0(resultados_dir, "/figura4_bairro.png"), 
       graf_bairro, width = 7, height = 6, dpi = 300)
