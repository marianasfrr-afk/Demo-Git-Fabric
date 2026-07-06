[StagingDefinition = [Kind = "FastCopy"]]
section Section1;
shared transacoes = let
  Origem = Excel.Workbook(File.Contents("C:\Users\maria\OneDrive\transacoes.xlsx"), null, true),
  #"Navegação 1" = Origem{[Item = "transacoes", Kind = "Sheet"]}[Data],
  #"Cabeçalhos promovidos" = Table.PromoteHeaders(#"Navegação 1", [PromoteAllScalars = true]),
  #"Tipo de coluna alterado" = Table.TransformColumnTypes(#"Cabeçalhos promovidos", {{"ID", Int64.Type}, {"Data", type date}, {"Total", type number}, {"Moeda", type text}})
in
  #"Tipo de coluna alterado";
shared calendario = let
    DataInicial = #date(2020,1,1),
    DataFinal = #date(2035,12,31),
    QuantidadeDias = Duration.Days(DataFinal - DataInicial) + 1,
    ListaDatas = List.Dates(DataInicial, QuantidadeDias, #duration(1,0,0,0)),
    Calendario = Table.FromList(ListaDatas, Splitter.SplitByNothing(), {"Data"}),
    TipoData = Table.TransformColumnTypes(Calendario,{{"Data", type date}})
in
    TipoData;
