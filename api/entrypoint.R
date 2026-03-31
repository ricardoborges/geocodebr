# api/entrypoint.R
library(plumber)

# Busca o arquivo de router do servidor
caminho <- "api/plumber.R"

# Permite ser invocado tanto da pasta raiz quanto da própria pasta /api/ (por ex dentro do container)
if(!file.exists(caminho) && file.exists("plumber.R")) {
  caminho <- "plumber.R"
}

pr <- plumb(caminho)

message("=========================================================")
message("Inicializando Servidor Plumber do R-Geocodebr em Batch...")
message("Acessível no host http://0.0.0.0:8000")
message("=========================================================")

# Sobe ativamente segurando o processo de STDOUT. Host 0.0.0.0 obriga a exposição fora do Docker
pr$run(host = "0.0.0.0", port = 8000)
