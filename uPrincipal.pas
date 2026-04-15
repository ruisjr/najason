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

    FMediaRegiaoNorte: Double;

    function CarregarMunicipios(const pMunicipioLista: TJSONArray): TDictionary<Integer, TMunicipio>;
    function ObterPopulacao(const pCodMunicipio: Integer): Integer;
    function ObterTotaisPorRegiao(const pRegiao: String): Integer;
    function ObterRegioes: TStringList;
    function RetornarJSONExportacao: TJSONObject;

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
  vWS: TWebService;
begin
  vWS := TWebService.Create;
  try
    vWS.Metodo := 'GET';
    vWS.URL := 'https://servicodados.ibge.gov.br/api/v1/localidades/municipios';
    vWS.Enviar;

    mmDados.Clear;

    lblStatus.Caption := 'Carregando dados IBGE...';

    FDictMunicipios := CarregarMunicipios(TJSONArray(vWS.Response));
    FTotalMunicipio := FDictMunicipios.Count;

    lblStatus.Caption := 'Apresentando dados IBGE...';

    ExibirDadosIBGE;

    lblStatus.Caption := 'Dados carregados com sucesso.';
  finally
    FreeAndNil(vWS);
  end;
end;

procedure TfrmPrincipal.btnExportarCSVClick(Sender: TObject);
var
  vWS: TWebService;
  vJson: TJSONObject;
  vTexto: TStringList;
begin
  vTexto := TStringList.Create;
  try
    vTexto.Text := mmDados.Text;
    vTexto.SaveToFile(ExtractFilePath(Application.ExeName) + '\resultado.csv');

    vWS := TWebService.Create;
    try
      vJson := RetornarJSONExportacao;
      try
        vWS.Metodo := 'POST';
        vWS.URL    := 'https://mynxlubykylncinttggu.functions.supabase.co/ibge-submit';
        vWS.Body   := vJson.ToJSON();
        vWS.Token  := TFuncoes.RetornarToken;
        vWS.Enviar;
      finally
        vJson.Free;
      end;
    finally
      FreeAndNil(vWS);
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
var
  vValue: TJSONValue;
  vJsonObjUF,
  vJsonObjReg,
  vJsonObjMesoR,
  vJsonObjMicroR: TJSONObject;
  vMunicipio: TMunicipio;
begin
  if Assigned(pMunicipioLista) then
  begin
    Result := TDictionary<Integer, TMunicipio>.Create;
    for vValue in pMunicipioLista do
    begin
      vMunicipio := TMunicipio.Create;
      try
        try
          vJsonObjMicroR := TJSONObject(TJsonObject.ParseJSONValue(vValue.GetValue<TJSONObject>('microrregiao').ToJSON()));
          vJsonObjMesoR  := TJSONObject(TJsonObject.ParseJSONValue(vJsonObjMicroR.GetValue<TJSONObject>('mesorregiao').ToJSON()));
          Inc(FTotalMunicipioOK);
        except
            try
              vJsonObjMicroR := TJSONObject(TJsonObject.ParseJSONValue(vValue.GetValue<TJSONObject>('regiao-imediata').ToJSON()));
              vJsonObjMesoR  := TJSONObject(TJsonObject.ParseJSONValue(vJsonObjMicroR.GetValue<TJSONObject>('regiao-intermediaria').ToJSON()));
            except
              vJsonObjMicroR := TJSONObject(TJsonObject.ParseJSONValue(vValue.GetValue<TJSONObject>('regiao-imediata').ToJSON()));
              vJsonObjMesoR  := TJSONObject(TJsonObject.ParseJSONValue(vJsonObjMicroR.GetValue<TJSONObject>('regiao-intermediaria').ToJSON()));
            end;
        end;

        vJsonObjUF     := TJSONObject(TJsonObject.ParseJSONValue(vJsonObjMesoR.GetValue<TJSONObject>('UF').ToJSON()));
        vJsonObjReg    := TJSONObject(TJsonObject.ParseJSONValue(vJsonObjUF.GetValue<TJSONObject>('regiao').ToJSON()));

        vMunicipio.NomeOficial := TFuncoes.RemoverAcentos(vJsonObjMicroR.GetValue<String>('nome')).ToUpper;
        vMunicipio.CodigoIBGE  := vValue.GetValue<Integer>('id');
        vMunicipio.UF          := vJsonObjUF.GetValue<String>('sigla').ToUpper;
        vMunicipio.Regiao      := vJsonObjReg.GetValue<String>('nome').ToUpper;

        try
          Application.ProcessMessages;
          vMunicipio.Populacao := ObterPopulacao(vMunicipio.CodigoIBGE);
          Inc(FTotalPopulacaoOK);
        except
          on E: EWebServiceError do
          begin
            vMunicipio.Populacao := 0;
            Inc(FTotalErroApi);
          end;
        end;
        Result.AddOrSetValue(vMunicipio.CodigoIBGE, vMunicipio);
      finally
        vJsonObjUF.Free;
        vJsonObjReg.Free;
        vJsonObjMesoR.Free;
        vJsonObjMicroR.Free;
      end;
    end;
  end;
end;

procedure TfrmPrincipal.ExibirDadosIBGE;
var
  vKey: Integer;
  vMunicipio: TMunicipio;
begin
  mmDados.Lines.Add('municipio_input;populacao_input;municipio_ibge;uf;regiao;id_ibge');
  for vKey in FDictMunicipios.Keys do
    mmDados.Lines.Add(Format('%s,%d,%d,%s,%s,%d',[FDictMunicipios[vKey].NomeOficial, FDictMunicipios[vKey].Populacao, FDictMunicipios[vKey].CodigoIBGE, FDictMunicipios[vKey].UF, FDictMunicipios[vKey].Regiao, FDictMunicipios[vKey].CodigoIBGE]));
end;

procedure TfrmPrincipal.FormDestroy(Sender: TObject);
begin
  FDictMunicipios.Clear;
  FreeAndNil(FDictMunicipios);
end;

function TfrmPrincipal.ObterPopulacao(const pCodMunicipio: Integer): Integer;
var
  vWS: TWebService;
  vJsonObj: TJSONObject;
  vJsonResult,
  vJsonSeries: TJSONArray;
begin
  Result := 0;
  vWS := TWebService.create;
  try
    vWS.URL    := Format('https://servicodados.ibge.gov.br/api/v3/agregados/9514/periodos/2022/variaveis/93?localidades=N6[%d]', [pCodMunicipio]);
    vWS.Metodo := 'GET';
    vWS.Enviar;

    if Assigned(vWS.Response) then
    begin
      //TJSONarray(vWS.Response)[0].tojson
      vJsonResult := TJSONArray(TJSONObject.ParseJSONValue(TJSONarray(vWS.Response)[0].GetValue<TJSONArray>('resultados').ToJSON()));
      try
        if (vJsonResult.Count > 0) then
        begin
          vJsonSeries := TJSONArray(TJSONObject.ParseJSONValue(vJsonResult[0].GetValue<TJSONArray>('series').ToJSON()));
          try
            if (vJsonSeries.Count > 0) then
            begin
              vJsonObj := TJSONObject(TJSONObject.ParseJSONValue(vJsonSeries[0].GetValue<TJSONObject>('serie').ToJSON()));
              try
                Result := vJsonObj.getValue('2022').Value.ToInteger;
              finally
                vJsonObj.free;
              end;
            end;
          finally
            vJsonSeries.free;
          end;
        end;
      finally
        vJSONResult.free;
      end;
    end;
  finally
    FreeAndNil(vWS);
  end;
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
        Result.Add(vJsonArr[vIx].GetValue<String>('nome').ToUpper)
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
