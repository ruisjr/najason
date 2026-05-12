unit uPrincipal;

interface

uses
   Winapi.Windows
  ,Winapi.Messages
  ,System.SysUtils
  ,System.Variants
  ,System.Classes
  ,Vcl.Graphics
  ,Vcl.Controls
  ,Vcl.Forms
  ,Vcl.Dialogs
  ,Vcl.StdCtrls
  ,System.JSON
  ,System.Generics.Collections
  ,System.Threading
  {Classes de negocio}
  ,uMunicipio
  ,uGlobal;

type
  TfrmPrincipal = class(TForm)
    btnCarregarIBGE: TButton;
    mmDados: TMemo;
    btnExportarCSV: TButton;
    btnFechar: TButton;
    lblStatus: TLabel;
    lblNumeroRegistros: TLabel;
    btnPaisDB: TButton;
    btnEstadosDB: TButton;
    BtnMunicipioDB: TButton;
    procedure btnCarregarIBGEClick(Sender: TObject);
    procedure btnFecharClick(Sender: TObject);
    procedure btnExportarCSVClick(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure btnPaisDBClick(Sender: TObject);
    procedure btnEstadosDBClick(Sender: TObject);
    procedure BtnMunicipioDBClick(Sender: TObject);
  private
    { Private declarations }
    FDictMunicipios: TDictionary<Integer, TMunicipioDTO>;
    FTotalMunicipio: Integer;
    FTotalMunicipioOK: Integer;
    FTotalErroApi: Integer;
    FTotalNaoEncontrado: Integer;
    FTotalPopulacaoOK: Integer;

    function GetUF(pJsMunicipio: TJSONObject): String;
    function GetRegiao(pJsMunicipio: TJSONObject): String;
    function CarregarMunicipios(const pMunicipioLista: TJSONArray): TDictionary<Integer, TMunicipioDTO>;
    function ObterTotaisPorRegiao(const pRegiao: String): Integer;
    function ObterRegioes: TStringList;
    function RetornarJSONExportacao: TJSONObject;
    function ProcessarEnvioWS(const pURL, pMetodo: String; pBody: string = ''; pToken: string = ''): TJSONObject;

    procedure ExibirDadosIBGE;

  public
    { Public declarations }
  end;

var
  frmPrincipal: TfrmPrincipal;

implementation

uses
   REST.Json
  ,uWebService
  ,uTelaProgress
  ,Core.DataBase.Interfaces
  ,Core.DataBase.Access
  ,Entidade.Pais
  ,Entidade.Estado
  ,Entidade.Municipio
  ,Core.Environment
  ;

{$R *.dfm}

procedure TfrmPrincipal.btnCarregarIBGEClick(Sender: TObject);
var
  vResponse: TJSONObject;
begin
  lblStatus.Caption := 'Carregando dados IBGE...';

  vResponse := Self.ProcessarEnvioWS('https://servicodados.ibge.gov.br/api/v3/agregados/6579/variaveis/all?localidades=N6[all]', 'GET');
  try
    mmDados.Clear;

    FDictMunicipios := Self.CarregarMunicipios(TJSONArray(TJSONObject.ParseJSONValue(vResponse.ToJSON)));

    FTotalMunicipio := 0;
    if Assigned(FDictMunicipios) then
      FTotalMunicipio := FDictMunicipios.Count;

    lblStatus.Caption := 'Apresentando dados IBGE...';

    if not Assigned(FDictMunicipios) then
    begin
      lblStatus.Caption := 'Dados não encontrados para apresentar.';
      Exit;
    end;

    ExibirDadosIBGE;

    lblStatus.Caption := 'Dados carregados com sucesso.';
  finally
    if Assigned(vResponse) then
      FreeAndNil(vResponse);
  end;
end;

procedure TfrmPrincipal.btnEstadosDBClick(Sender: TObject);
var
  LIx: Integer;
  DAO: IDataBaseDAO<TEstado>;
  LUF: TEstado;
  LResponse: TJSONObject;
  LObj: TJSONObject;
  LArray: TJSONArray;
begin
  LResponse := Self.ProcessarEnvioWS('https://servicodados.ibge.gov.br/api/v1/localidades/estados', 'GET');
  try
    if not Assigned(LResponse) then
      Exit;

    DAO := TDataBaseDAO<TEstado>.Create;
    try
      Env.Connection.BeginTransaction;
      try
        LArray := TJSONArray(TJSONObject.ParseJSONValue(LResponse.ToJSON));
        try
          for LIx := LArray.Count-1 downto 0 do
          begin
            LUF := TEstado.Create;
            LObj := TJSONObject(TJSONObject.ParseJSONValue(LArray.Items[LIx].ToJSON));
            try
              LUF.Sigla := LObj.GetValue<String>('sigla');
              LUF.CodIBGE := LObj.GetValue<Integer>('id');

              DAO.Insert(LUF);
            finally
              LObj.Free;
              LUF.Free;
            end;
          end;
        finally
          LArray.Free;
        end;
        Env.Connection.CommitTransaction;
      except
        on E: Exception do
        begin
          Env.Connection.RollBackTransaction;
        end;
      end;
    finally
      DAO.FreeMemory;
    end;
  finally
    LResponse.Free;
  end;
end;

procedure TfrmPrincipal.btnExportarCSVClick(Sender: TObject);
var
  vJson,
  vJsAux: TJSONObject;
  vTexto: TStringList;
begin
  vTexto := TStringList.Create;
  try
    vTexto.Text := mmDados.Text;
    vTexto.SaveToFile(ExtractFilePath(Application.ExeName) + '\resultado.csv');

    vJson := Self.RetornarJSONExportacao;
    try
//      vJsAux := Self.ProcessarEnvioWS('https://mynxlubykylncinttggu.functions.supabase.co/ibge-submit', 'POST', vJson.ToJSON(), TFuncoes.RetornarToken);
    finally
      if Assigned(vJsAux) then
        FreeAndNil(vJsAux);
      vJson.Free;
    end;
  finally
    FreeAndNil(vTexto);
  end;
end;

procedure TfrmPrincipal.btnFecharClick(Sender: TObject);
begin
  Application.Terminate;
end;

procedure TfrmPrincipal.btnPaisDBClick(Sender: TObject);
var
  LIx: Integer;
  DAO: IDataBaseDAO<TPais>;
  LPais: TPais;
  LResponse: TJSONObject;
  LObj: TJSONObject;
  LArray: TJSONArray;
begin
  LResponse := Self.ProcessarEnvioWS('https://servicodados.ibge.gov.br/api/v1/localidades/paises', 'GET');
  try
    if not Assigned(LResponse) then
      Exit;

    DAO := TDataBaseDAO<TPais>.Create;
    try
      Env.Connection.BeginTransaction;
      try
        LArray := TJSONArray(TJSONObject.ParseJSONValue(LResponse.ToJSON));
        try
          for LIx := LArray.Count-1 downto 0 do
          begin
            LPais := TPais.Create;
            LObj := TJSONObject(TJSONObject.ParseJSONValue(LArray.Items[LIx].ToJSON));
            try
              LPais.Nome := LObj.GetValue<String>('nome');
              LPais.CodIBGE := LObj.GetValue<TJSONObject>('id').GetValue<Integer>('M49');

              DAO.Insert(LPais);
            finally
              LObj.Free;
              LPais.Free;
            end;
          end;
        finally
          LArray.Free;
        end;
        Env.Connection.CommitTransaction;
      except
        on E: Exception do
        begin
          Env.Connection.RollBackTransaction;
        end;
      end;
    finally
      DAO.FreeMemory;
    end;
  finally
    LResponse.Free;
  end;
end;

procedure TfrmPrincipal.BtnMunicipioDBClick(Sender: TObject);
var
  LIx: Integer;
  DAO: IDataBaseDAO<TMunicipio>;
  LMunicipio: TMunicipio;
  LResponse: TJSONObject;
  LObj: TJSONObject;
  LArray: TJSONArray;
begin
  LResponse := Self.ProcessarEnvioWS('https://servicodados.ibge.gov.br/api/v1/localidades/municipios', 'GET');
  try
    if not Assigned(LResponse) then
      Exit;

    DAO := TDataBaseDAO<TMunicipio>.Create;
    try
      Env.Connection.BeginTransaction;
      try
        LArray := TJSONArray(TJSONObject.ParseJSONValue(LResponse.ToJSON));
        try
          for LIx := LArray.Count-1 downto 0 do
          begin
            LMunicipio := TMunicipio.Create;
            LObj := TJSONObject(TJSONObject.ParseJSONValue(LArray.Items[LIx].ToJSON));
            try
              LMunicipio.Nome := LObj.GetValue<String>('nome').ToUpper;
              LMunicipio.CodIBGE := LObj.GetValue<Integer>('id');
              LMunicipio.CodPais := 76;
              LMunicipio.UF := GetUF(LObj).ToUpper;

              Env.Log.Info('id: '+LMunicipio.CodIBGE.ToString+' | Nome: '+LMunicipio.Nome+' UF: '+LMunicipio.UF+' | Pais: '+LMunicipio.CodPais.ToString);

              DAO.Insert(LMunicipio);
            finally
              LObj.Free;
              LMunicipio.Free;
            end;
          end;
        finally
          LArray.Free;
        end;
        Env.Connection.CommitTransaction;
        Env.Log.Info('Importação de Municipios realizada com sucesso!');
      except
        on E: Exception do
        begin
          Env.Log.Error(E.Message);
          Env.Connection.RollBackTransaction;
        end;
      end;
    finally
      DAO.FreeMemory;
    end;
  finally
    LResponse.Free;
  end;
end;

function TfrmPrincipal.CarregarMunicipios(const pMunicipioLista: TJSONArray): TDictionary<Integer, TMunicipioDTO>;
const
  cUrl = 'https://servicodados.ibge.gov.br/api/v1/localidades/municipios/%d';

var
  vValue: TJSONValue;
  vJsSidra: TJSONArray;
  vMunicipio: TMunicipioDTO;
  vJsMunicipio: TJSONObject;
begin
  Result := TDictionary<Integer, TMunicipioDTO>.Create;

  if Assigned(pMunicipioLista) then
  begin
    vJsSidra := pMunicipioLista.Items[0].GetValue<TJSONArray>('resultados').Items[0].GetValue<TJSONArray>('series');
    try
      for vValue in vJsSidra do
      begin
        vMunicipio := TMunicipioDTO.Create;
        try
          Application.ProcessMessages;
          if (FTotalPopulacaoOK = 5199) then
            vMunicipio.CodigoIBGE  := vValue.GetValue<TJSONObject>('localidade').GetValue<Integer>('id');
          vMunicipio.CodigoIBGE  := vValue.GetValue<TJSONObject>('localidade').GetValue<Integer>('id');

          vJsMunicipio := ProcessarEnvioWS(Format(cUrl, [vMunicipio.CodigoIBGE]), 'GET');
          try
            vMunicipio.NomeOficial := TFuncoes.RemoverAcentos(vJsMunicipio.GetValue<String>('nome')).ToUpper;
            vMunicipio.UF          := GetUF(vJsMunicipio);
            vMunicipio.Regiao      := GetRegiao(vJsMunicipio);
            vMunicipio.Populacao   := vValue.GetValue<TJSONObject>('serie').GetValue<Integer>('2025');

            Inc(FTotalPopulacaoOK);

            lblNumeroRegistros.Caption := 'Registros incluídos: ' + IntToStr(FTotalPopulacaoOK);
          finally
            FreeAndNil(vJsMunicipio);
          end;
        except
          on E: EWebServiceError do
          begin
            vMunicipio.Populacao := 0;
            Inc(FTotalErroApi);
          end;
        end;
        Result.AddOrSetValue(vMunicipio.CodigoIBGE, vMunicipio);
      end;
    finally
      vJsSidra.Free;
    end;
  end;
end;

procedure TfrmPrincipal.ExibirDadosIBGE;
var
  vKey: Integer;
begin
  mmDados.Lines.Add('Cod IBGE;Nome Oficial;UF;Regiao;Populacao;');
  for vKey in FDictMunicipios.Keys do
    mmDados.Lines.Add(Format('%d;%s;%s;%s;%d;', [FDictMunicipios[vKey].CodigoIBGE, FDictMunicipios[vKey].NomeOficial, FDictMunicipios[vKey].UF, FDictMunicipios[vKey].Regiao, FDictMunicipios[vKey].Populacao]));
end;

procedure TfrmPrincipal.FormDestroy(Sender: TObject);
var
  vKey: Integer;
begin
  if Assigned(FDictMunicipios) then
  begin
    for vKey in FDictMunicipios.Keys do
      FDictMunicipios[vKey].Free;

    FDictMunicipios.Clear;
    FreeAndNil(FDictMunicipios);
  end;
end;

function TfrmPrincipal.GetRegiao(pJsMunicipio: TJSONObject): String;
var
  vRegiao: TJSONObject;
begin
  if pJsMunicipio.TryGetValue('microrregiao', vRegiao) then
    Result := vRegiao
                .GetValue<TJSONObject>('mesorregiao')
                .GetValue<TJSONObject>('UF')
                .GetValue<TJSONObject>('regiao')
                .GetValue<String>('nome')
  else
    Result :=  pJsMunicipio.GetValue<TJSONObject>('regiao-imediata')
                 .GetValue<TJSONObject>('regiao-intermediaria')
                 .GetValue<TJSONObject>('UF')
                 .GetValue<TJSONObject>('regiao')
                 .GetValue<String>('nome')
end;

function TfrmPrincipal.GetUF(pJsMunicipio: TJSONObject): String;
var
  vRegiao: TJSONObject;
begin
  if pJsMunicipio.TryGetValue('microrregiao', vRegiao) then
    Result :=  vRegiao
                 .GetValue<TJSONObject>('mesorregiao')
                 .GetValue<TJSONObject>('UF')
                 .GetValue<String>('sigla')
  else
    Result :=  pJsMunicipio.GetValue<TJSONObject>('regiao-imediata')
                 .GetValue<TJSONObject>('regiao-intermediaria')
                 .GetValue<TJSONObject>('UF')
                 .GetValue<String>('sigla')
end;

function TfrmPrincipal.ObterRegioes: TStringList;
var
  vIx: Integer;
  vWS: TWebService;
  vJsonArr: TJSONArray;
begin
  vWS := TWebService.Create;
  try
    vWS.Metodo := 'GET';
    vWS.URL    := 'https://servicodados.ibge.gov.br/api/v1/localidades/regioes';
    vWs.Enviar;

    vJsonArr := TJSONArray(TJSONObject.ParseJSONValue(vWS.Response.ToJSON()));
    try
      Result := TStringList.Create;

      for vIx := 0 to vJsonArr.Count -1 do
      begin
        Result.Add(vJsonArr.Items[vIx].GetValue<String>('nome').ToUpper)
      end;
    finally
      vJsonArr.free;
    end;
  finally
    FreeAndNil(vWS);
  end;
end;

function TfrmPrincipal.ObterTotaisPorRegiao(const pRegiao: String): Integer;
var
  vKey: Integer;
begin
  Result := 0;
  for vKey in FDictMunicipios.Keys do
  begin
    if pRegiao.ToUpper.Equals(FDictMunicipios[vKey].Regiao.ToUpper) then
      Result := Result + FDictMunicipios[vKey].Populacao;
  end;
end;

function TfrmPrincipal.ProcessarEnvioWS(const pURL, pMetodo: string; pBody: string = ''; pToken: string = ''): TJSONObject;
var
  vWS: TWebService;
begin
  vWS := TWebService.Create;
  try
    vWS.Metodo := pMetodo;
    vWS.URL    := pURL;
    vWS.Body   := pBody;
    vWS.Token  := pToken;
    vWS.Enviar;

    Result := TJSONObject(TJSONObject.ParseJSONValue(vWS.Response.ToJSON));
  finally
    FreeAndNil(vWS);
  end;
end;

function TfrmPrincipal.RetornarJSONExportacao: TJSONObject;
var
  vIx: Integer;
  vJsonPair: TJSONObject;
  vJsonMedia: TJsonObject;
  vRegioes: TStringList;
begin
  vJsonPair := TJSONObject.Create;
  vJsonPair.AddPair('total_municipios', TJSONNumber.Create(FTotalMunicipio));
  vJsonPair.AddPair('total_ok', TJSONNumber.Create(FTotalMunicipioOK));
  vJsonPair.AddPair('total_nao_encontrado', TJSONNumber.Create(FTotalNaoEncontrado));
  vJsonPair.AddPair('total_erro_api', TJSONNumber.Create(FTotalErroApi));
  vJsonPair.AddPair('pop_total_ok', TJSONNumber.Create(FTotalPopulacaoOK));

  vJsonMedia := TJSONObject.Create;

  vRegioes := ObterRegioes;
  for vIx := 0 to vRegioes.count -1 do
    vJsonMedia.AddPair(vRegioes[vIx], TJSONNumber.Create(ObterTotaisPorRegiao(vRegioes[vIx])));

  vJsonPair.AddPair('medias_por_regiao', vJsonMedia);

  Result := TJSONObject.Create;
  Result.AddPair('stats', vJsonPair);
end;

end.
