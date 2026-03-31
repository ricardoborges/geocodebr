FROM rocker/r-ver:4.4.0

# Evitar prompts obstrutivos no apt-get
ENV DEBIAN_FRONTEND=noninteractive

# Instalar dependências complexas (Gdal, Geos, Sqlite3) requeridas pelo pacote "sf" "arrow" e "duckdb"
RUN apt-get update -qq && apt-get install -y --no-install-recommends \
    libgdal-dev \
    libgeos-dev \
    libproj-dev \
    libsqlite3-dev \
    libsodium-dev \
    libxml2-dev \
    libcurl4-openssl-dev \
    libssl-dev \
    git \
 && rm -rf /var/lib/apt/lists/*

# Instalar pacotes de infra e serviço de base web
RUN R -e "install.packages(c('plumber', 'jsonlite', 'dplyr', 'remotes'))"

# Instalar pacote de geolocalização do CNEFE oficial pelo CRAN/Github
# rocker/r-ver usará espelhos do Posit Public Package Manager baixando binários
RUN R -e "install.packages('geocodebr')"

# Copiar a aplicação
WORKDIR /app
COPY api/ /app/api/

EXPOSE 8000

# Executar a API ativamente
ENTRYPOINT ["Rscript", "api/entrypoint.R"]
