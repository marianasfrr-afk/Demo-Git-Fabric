# Fabric notebook source

# METADATA ********************

# META {
# META   "kernel_info": {
# META     "name": "synapse_pyspark"
# META   },
# META   "dependencies": {
# META     "lakehouse": {
# META       "default_lakehouse": "400a4495-6c9c-4450-a4a0-830fde25949f",
# META       "default_lakehouse_name": "lake",
# META       "default_lakehouse_workspace_id": "63f04e96-5789-47b2-a61c-38ce349e92d5",
# META       "known_lakehouses": [
# META         {
# META           "id": "400a4495-6c9c-4450-a4a0-830fde25949f"
# META         }
# META       ]
# META     },
# META     "warehouse": {
# META       "default_warehouse": "1f36f268-9f67-4c2f-b472-df2d7ff82ea0",
# META       "known_warehouses": [
# META         {
# META           "id": "1f36f268-9f67-4c2f-b472-df2d7ff82ea0",
# META           "type": "Lakewarehouse"
# META         }
# META       ]
# META     }
# META   }
# META }

# CELL ********************

# Importações de bibliotecas
import requests
import json
from datetime import datetime, timedelta
from pyspark.sql import SparkSession
from pyspark.sql.types import StructType, StructField, StringType, FloatType, DateType
from pyspark.sql.functions import to_date, col, to_timestamp

# Parâmetros
data_inicial = datetime(2024, 11, 1)
data_final = datetime.today() # data atual
# data_final = datetime.today() - timedelta(days=1) # d-1

# Get da api
def get_cotacoes(data_inicial, data_final, moeda, pagina):
    url = f"https://olinda.bcb.gov.br/olinda/servico/PTAX/versao/v1/odata/CotacaoMoedaPeriodo(moeda=@moeda,dataInicial=@dataInicial,dataFinalCotacao=@dataFinalCotacao)?@moeda='{moeda}'&@dataInicial='{data_inicial}'&@dataFinalCotacao='{data_final}'&$skip={(pagina-1)*100}&$top=100&$format=json"
    response = requests.get(url)
    if response.status_code == 200:
        data = response.json().get("value", [])
        if not data:  # Verifique se a resposta está vazia
            return None
        return data
    return None

# Paginação
def get_cotacoes_paginacao(data_inicial, data_final, moeda):
    pagina = 1
    todas_cotacoes = []
    while True:
        cotacoes = get_cotacoes(data_inicial, data_final, moeda, pagina)
        if cotacoes is None:  # Interrompe o loop se a resposta estiver vazia
            break
        for cotacao in cotacoes:
            cotacao["Moeda"] = moeda  # Adiciona a moeda à resposta
        todas_cotacoes.extend(cotacoes)
        pagina += 1
    return todas_cotacoes

# Iteração sobre as moedas
def processar_cotacoes(data_inicial, data_final):
    data_inicial_str = datetime.strftime(data_inicial, "%m-%d-%Y")
    data_final_str = datetime.strftime(data_final, "%m-%d-%Y")

    # Lista das moedas excluindo 'BRL'
    df_moedas = spark.read.table("moedas").filter("Moeda != 'BRL'")
    moedas = df_moedas.select("Moeda").collect()
    all_cotacoes = []

    # Iteração das cotações para cada moeda
    for row in moedas:
        moeda = row["Moeda"]
        cotacoes = get_cotacoes_paginacao(data_inicial_str, data_final_str, moeda)
        all_cotacoes.extend(cotacoes)  # Adiciona as cotações da moeda à lista geral

    return all_cotacoes  # Retorna o JSON com todas as moedas

# Response
cotacoes_json = processar_cotacoes(data_inicial, data_final)
print(cotacoes_json)


# METADATA ********************

# META {
# META   "language": "python",
# META   "language_group": "synapse_pyspark"
# META }

# CELL ********************

# Esquema do dataframe
schema = StructType([
    StructField("paridadeCompra", FloatType(), True),
    StructField("paridadeVenda", FloatType(), True),
    StructField("cotacaoCompra", FloatType(), True),
    StructField("cotacaoVenda", FloatType(), True),
    StructField("dataHoraCotacao", StringType(), True),  # Temporariamente como String para conversão posterior
    StructField("tipoBoletim", StringType(), True),
    StructField("Moeda", StringType(), True)
])

# json -> dataframe
df = spark.createDataFrame(cotacoes_json, schema=schema)

# Trasformações
df = df.select(
    col("Moeda").alias("Moeda"),
    to_timestamp(col("dataHoraCotacao")).alias("DataHoraCotacao"),
    to_date(col("dataHoraCotacao")).alias("DataCotacao"),
    col("cotacaoCompra").alias("Cotacao"),
    col("tipoBoletim").alias("TipoBoletim")
)

df.show()



# METADATA ********************

# META {
# META   "language": "python",
# META   "language_group": "synapse_pyspark"
# META }

# CELL ********************

# Escreve o dataframe na tabela no lake
df.write.format("delta").mode("overwrite").saveAsTable("cotacoes")  

# Exibindo o dataframe do lakehouse
df_lake = spark.sql("SELECT * FROM lake.cotacoes")
display(df_lake)


# METADATA ********************

# META {
# META   "language": "python",
# META   "language_group": "synapse_pyspark"
# META }
