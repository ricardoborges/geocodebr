# plumber.R

# Carregar o pacote geocodebr e utilitários
library(geocodebr)
library(jsonlite)

#* Check status simplificado da API
#* @get /health
function() {
  list(status = "API geocodebr respondendo", message = "OK")
}

#* Geocodifica um lote de endereços 
#* @post /api/v1/geocode
#* @param req objeto do request contendo o body completo do Plumber
#* @param res objeto da resposta
function(req, res) {
  # Proteção primária de request nulo
  if (is.null(req$body)) {
    res$status <- 400
    return(list(error = "Request body vazio. Envie 'enderecos' no formato JSON."))
  }
  
  body_json <- req$body
  
  # Se o framework receber string bruta e não decodificar
  if (is.character(body_json)) {
    tryCatch({
      body_json <- jsonlite::fromJSON(body_json, simplifyDataFrame = TRUE)
    }, error = function(e) {
      res$status <- 400
      return(list(error = "Falha ao decodificar payload como JSON. Verifique a formatação."))
    })
  }

  if (is.null(body_json$enderecos) || nrow(body_json$enderecos) == 0) {
    res$status <- 400
    return(list(error = "Vetor 'enderecos' obrigatório não localizado no payload principal ou está vazio."))
  }
  
  # Isolar dataframe fornecido pra validação
  input_df <- body_json$enderecos
  
  # O pacote `geocodebr` exige explicitamente a definição das colunas de entrada
  # Através de de/para para podermos mandar o df base limpo
  campos_fornecidos <- list()
  
  colunas <- colnames(input_df)
  if ("logradouro" %in% colunas) campos_fornecidos$logradouro <- "logradouro"
  if ("numero" %in% colunas) campos_fornecidos$numero <- "numero"
  if ("cep" %in% colunas) campos_fornecidos$cep <- "cep"
  if ("localidade" %in% colunas) campos_fornecidos$localidade <- "localidade" # bairro e vizinhanças
  if ("municipio" %in% colunas) campos_fornecidos$municipio <- "municipio"
  if ("estado" %in% colunas) campos_fornecidos$estado <- "estado"
  
  if (length(campos_fornecidos) == 0) {
    res$status <- 400
    return(list(error = "Você não enviou nomes de chaves reconhecidas (logradouro, numero, cep, localidade, municipio, estado) nos endereços enviados."))
  }
  
  # Validando mapeamento de campos a rigor para os tipos da lib
  campos <- do.call(geocodebr::definir_campos, campos_fornecidos)
  
  # Chamada intensiva - Tratamento via TRY para manter API ligada se falhas no CNEFE DuckDB ocorram.
  result_df <- tryCatch({
    geocodebr::geocode(
      enderecos = input_df,
      campos_endereco = campos,
      resultado_sf = FALSE,       # Usado restrito pra serializador JSON não estourar lendo pontos OGS da stdlib
      resultado_completo = TRUE,  # Trás informações analíticas 
      resolver_empates = TRUE,    # Mantém a maior verossimilhança possivel
      verboso = FALSE             # Impede que encha os logs do stdout do contêiner Docker
    )
  }, error = function(e) {
    res$status <- 500
    return(list(error = paste("Erro no processamento da lib:", e$message)))
  })
  
  # Ao invés de returnar a array, returnamos a lista contendo ela, por padrão de payload REST moderno
  return(list(
    results = result_df,
    count = nrow(result_df)
  ))
}
