options(
  repos = c(CRAN = "https://cloud.r-project.org"),
  encoding = "UTF-8",
  scipen = 999,
  dplyr.summarise.inform = FALSE
)

# No Windows, priorize pacotes binários quando disponíveis.
if (identical(.Platform$OS.type, "windows")) {
  options(pkgType = "binary")
}

# O renv não é ativado automaticamente nesta versão de recuperação.
# Depois que o projeto abrir normalmente, execute no Console:
# source("scripts/00_ativar_renv_seguro.R")
