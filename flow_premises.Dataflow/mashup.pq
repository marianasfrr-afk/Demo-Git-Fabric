[StagingDefinition = [Kind = "FastCopy"]]
section Section1;
[DataDestinations = {[Definition = [Kind = "Reference", QueryName = "transacoes_DataDestination", IsNewTarget = true], Settings = [Kind = "Automatic", TypeSettings = [Kind = "Table"]]]}]
shared transacoes = let
  Origem = Excel.Workbook(File.Contents("C:\Users\maria\OneDrive\transacoes.xlsx"), null, true),
  #"Navegação 1" = Origem{[Item = "transacoes", Kind = "Sheet"]}[Data],
  #"Cabeçalhos promovidos" = Table.PromoteHeaders(#"Navegação 1", [PromoteAllScalars = true]),
  #"Tipo de coluna alterado" = Table.TransformColumnTypes(#"Cabeçalhos promovidos", {{"ID", Int64.Type}, {"Data", type date}, {"Total", type number}, {"Moeda", type text}})
in
  #"Tipo de coluna alterado";
[DataDestinations = {[Definition = [Kind = "Reference", QueryName = "calendario_DataDestination", IsNewTarget = true], Settings = [Kind = "Automatic", TypeSettings = [Kind = "Table"]]]}]
shared calendario = let
    DataInicial = #date(2020,1,1),
    DataFinal = #date(2035,12,31),
    QuantidadeDias = Duration.Days(DataFinal - DataInicial) + 1,
    ListaDatas = List.Dates(DataInicial, QuantidadeDias, #duration(1,0,0,0)),
    Calendario = Table.FromList(ListaDatas, Splitter.SplitByNothing(), {"Data"}),
    TipoData = Table.TransformColumnTypes(Calendario,{{"Data", type date}})
in
    TipoData;
shared NavigationQuery = let
  Origem = Lakehouse.Contents([CreateNavigationProperties = false, EnableFolding = false, HierarchicalNavigation = true, EnableVorder = true, OutputMetadataRefresh = true])
in
  Origem;
shared calendario_DataDestination = let
  Pattern = Lakehouse.Contents([CreateNavigationProperties = false, EnableFolding = false, HierarchicalNavigation = true, EnableVorder = true, OutputMetadataRefresh = true]),
  Navigation_1 = Pattern{[workspaceId = "63f04e96-5789-47b2-a61c-38ce349e92d5"]}[Data],
  Navigation_2 = Navigation_1{[lakehouseId = "400a4495-6c9c-4450-a4a0-830fde25949f"]}[Data],
  Navigation_3 = Navigation_2{[Id = "dbo", ItemKind = "Schema"]}[Data],
  TableNavigation = Navigation_3{[Id = "calendario", ItemKind = "Table"]}?[Data]?
in
  TableNavigation;
shared transacoes_DataDestination = let
  Pattern = Lakehouse.Contents([CreateNavigationProperties = false, EnableFolding = false, HierarchicalNavigation = true, EnableVorder = true, OutputMetadataRefresh = true]),
  Navigation_1 = Pattern{[workspaceId = "63f04e96-5789-47b2-a61c-38ce349e92d5"]}[Data],
  Navigation_2 = Navigation_1{[lakehouseId = "400a4495-6c9c-4450-a4a0-830fde25949f"]}[Data],
  Navigation_3 = Navigation_2{[Id = "dbo", ItemKind = "Schema"]}[Data],
  TableNavigation = Navigation_3{[Id = "transacoes", ItemKind = "Table"]}?[Data]?
in
  TableNavigation;
