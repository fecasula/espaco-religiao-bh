# Ativação manual e controlada do ambiente renv.

activate_path <- file.path("renv", "activate.R")

if (!file.exists(activate_path)) {
  stop(
    "Arquivo renv/activate.R não encontrado. ",
    "Confirme que o diretório de trabalho é a raiz do projeto."
  )
}

source(activate_path)

message("renv ativado para: ", normalizePath(".", winslash = "/"))
message("Bibliotecas ativas:")
print(.libPaths())
