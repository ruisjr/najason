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
    procedure btnCarregarIBGEClick(Sender: TObject);
    procedure btnFecharClick(Sender: TObject);
    procedure btnExportarCSVClick(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
  private
    { Private declarations }
    FDictMunicipios: TDictionary<Integer, TMunicipio>;
    FTotalMunicipio: Integer;
    FTotalMunicipioOK: Integer;
    FTotalErroApi: Integer;
    FTotalNaoEncontrado: Integer;
    FTotalPopulacaoOK: Integer;

    function GetUF(pJsMunicipio: TJSONObject): String;
    function GetRegiao(pJsMunicipio: TJSONObject): String;
    function CarregarMunicipios(const pMunicipioLista: TJSONArray): TDictionary<Integer, TMunicipio>;
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
   uWebService
  ,uTelaProgress;

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
      vJsAux := Self.ProcessarEnvioWS('https://mynxlubykylncinttggu.functions.supabase.co/ibge-submit', 'POST', vJson.ToJSON(), TFuncoes.RetornarToken);
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

function TfrmPrincipal.CarregarMunicipios(const pMunicipioLista: TJSONArray): TDictionary<Integer, TMunicipio>;
const
  cUrl = 'https://servicodados.ibge.gov.br/api/v1/localidades/municipios/%d';

var
  vValue: TJSONValue;
  vJsSidra: TJSONArray;
  vMunicipio: TMunicipio;
  vJsMunicipio: TJSONObject;
begin
  Result := TDictionary<Integer, TMunicipio>.Create;

  if Assigned(pMunicipioLista) then
  begin
    vJsSidra := pMunicipioLista.Items[0].GetValue<TJSONArray>('resultados').Items[0].GetValue<TJSONArray>('series');
    try
      for vValue in vJsSidra do
      begin
        vMunicipio := TMunicipio.Create;
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
                 .GetValue<String>('nome')
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
