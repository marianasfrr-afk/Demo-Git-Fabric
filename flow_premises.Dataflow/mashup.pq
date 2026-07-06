[StagingDefinition = [Kind = "FastCopy"]]
section Section1;
shared transacoes = let
  Origem = Excel.Workbook(File.Contents("C:\Users\maria\OneDrive\transacoes.xlsx"), null, true),
  #"Navegação 1" = Origem{[Item = "transacoes", Kind = "Sheet"]}[Data],
  #"Cabeçalhos promovidos" = Table.PromoteHeaders(#"Navegação 1", [PromoteAllScalars = true]),
  #"Tipo de coluna alterado" = Table.TransformColumnTypes(#"Cabeçalhos promovidos", {{"ID", Int64.Type}, {"Data", type date}, {"Total", type number}, {"Moeda", type text}})
in
  #"Tipo de coluna alterado";
