#=======================================================
# PLOTAGEM EVOLUÇÃO DA COMPOSIÇÃO RELIGIOSA 
#=======================================================
# OBJETIVO:

#-------------------------------------------------------
rm(list = ls(all = TRUE))

# Bibliotecas 
library(tidyverse)
library(tidyr)
library(xlsx)
library(scales)

#-------------------------------------------------------
# Load data 

base_path <- "D:/deslocamentos_religiao"
relig_pop <- read_xlsx(paste0(base_path, '/dados/tratados/perfil_religioso_pop_bh.xlsx'))

df_relig <- relig_pop%>%
  mutate(
    ano = factor(ano, levels = c('2000', '2010', '2022')))

# Definir o diretório base e resultados
resultados_dir <- paste0(base_path, '/resultados')

# Criar diretório se não existir
if(!dir.exists(resultados_dir)) {
  dir.create(resultados_dir, recursive = TRUE)
}

# Filtrar dados para Brasil e Belo Horizonte
df_longo <- df_relig %>%
  pivot_longer(
    cols = c(catolico, evangelico, espirita, outras),
    names_to = "religiao",
    values_to = "proporcao"
  )

df_apresentacao <- df_longo %>%
  # 1. Filtra pelas regiões de interesse (ajuste os termos exatos se necessário)
  filter(regiao %in% c("Brasil", "Belo Horizonte")) %>%
  
  # 2. Modifica os nomes das religiões para o formato apresentável
  mutate(
    religiao = case_when(
      religiao == "catolico"   ~ "Católico",
      religiao == "evangelico" ~ "Evangélico",
      religiao == "espirita"   ~ "Espírita",
      religiao == "outras"     ~ "Outra/Sem Religião",
      TRUE                     ~ religiao # Mantém o original caso haja outro valor
    )
  ) %>%
  
  # 3. Organiza o data frame por grupo etário para facilitar a leitura
  arrange(grupo_idade, regiao, religiao)
#---------------------------------------------------------

# Definir tema ABNT
tema_abnt <- theme_minimal() +
  theme(
    # Textos
    text = element_text(family = "serif", size = 11),
    plot.title = element_text(size = 12, face = "bold", hjust = 0.5),
    plot.subtitle = element_text(size = 10, hjust = 0.5),
    axis.title = element_text(size = 11),
    axis.text = element_text(size = 9),
    legend.title = element_text(size = 10),
    legend.text = element_text(size = 9),
    # Legendas
    legend.position = "bottom",
    legend.key.width = unit(1.5, "cm"),
    # Grade
    panel.grid.major = element_line(color = "gray80", linewidth = 0.3),
    panel.grid.minor = element_blank(),
    # Bordas
    panel.border = element_rect(fill = NA, color = "black", linewidth = 0.5),
    plot.margin = margin(0.5, 0.5, 0.5, 0.5, "cm"),
    # Eixos
    axis.line = element_line(color = "black", linewidth = 0.3),
    axis.ticks = element_line(color = "black", linewidth = 0.3)
  )

# Definir paleta de cores
paleta_cores <- c("Católico" = "#2C3E50",
                  "Evangélico" = "#E67E22",
                  "Espírita" = "#27AE60",
                  "Outra/Sem Religião" = "#8E44AD")

#---------------------------------------------------------

grafico_facetado <- df_apresentacao %>%
  ggplot(aes(x = ano, y = proporcao, color = religiao, group = religiao)) +
  geom_line(linewidth = 1.2) +
  geom_point(size = 2.5) +
  # Facetas: Linhas por Região, Colunas por Grupo Etário
  facet_grid(regiao ~ grupo_idade) + 
  scale_x_discrete(breaks = c("2000", "2010", "2022")) +
  scale_y_continuous(
    labels = percent_format(accuracy = 1),
    limits = c(0, 0.85),
    breaks = seq(0, 0.8, 0.2)
  ) +
  scale_color_manual(values = paleta_cores) +
  labs(
    title = "Evolução da Composição Religiosa da População Idosa",
    subtitle = "Comparativo entre Brasil e Belo Horizonte (2000-2022)",
    x = "Ano",
    y = "Proporção da População (%)",
    color = "Religião/Confissão",
    caption = "Fonte: Amostra dos Censos Demográficos 2000, 2010 e 2022 | Elaboração Própria"
  ) +
  tema_abnt +
  theme(
    # Customização extra para as etiquetas das facetas (ABNT)
    strip.text = element_text(family = "serif", size = 14, face = "bold"),
    strip.background = element_rect(fill = "gray95", color = "black", linewidth = 0.5),
    plot.caption = element_text(size = 8, hjust = 0.5, margin = margin(t = 15), color = "gray30")
  )

print(grafico_facetado)

# Salvar o gráfico combinado
output_path <- paste0(base_path, '/resultados/evolucao_reli.png')
ggsave(
  filename = output_path,
  plot = grafico_facetado,    
  width = 12,                 
  height = 7,                 
  dpi = 300,                  
  bg = "white"                
)
