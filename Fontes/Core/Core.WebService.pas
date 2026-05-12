unit Core.WebService;

interface

Uses
  {Classe de Sistema}
   System.JSON
  ,System.Classes
  ,System.SysUtils
  ,System.DateUtils
  ,System.Generics.Collections
  {Classes de Negócio}
  ,Core.Api
  ,Core.Global
  ,Core.Functions
  ,Core.DataBase.Access
  ,Core.DataBase.Interfaces;

type
  TIntegracaoWS = class
  private
    FApiIntegracao: TApiIntegracao;

    procedure LoadApiData;
  public
    {Construtres e Destrutores}
    constructor Create; reintroduce;
    destructor Destroy; override;

    {Functions}
    function ObterLogin: String;
    function ObterProdutos(const pData: TDateTime): TJSONArray;
    function ObterInfoProduto(const pGtin: String): TJSONObject;
    function ObterImagem(pUrl, pDir, pFileName, pTipoAtivo: String): Boolean;
  end;


implementation

Uses
  Winapi.UrlMon;

{ TIntegracaoWS<T> }

constructor TIntegracaoWS.Create;
begin
  FApiIntegracao := TApiIntegracao.Create;
end;

destructor TIntegracaoWS.Destroy;
begin
  FreeAndNil(FApiIntegracao);
  inherited;
end;

procedure TIntegracaoWS.LoadApiData;
begin
//  FApiIntegracao.UserName := vgIntegParam.PAuthUser;
//  FApiIntegracao.Password := vgIntegParam.PAuthPass;
end;

function TIntegracaoWS.ObterImagem(pUrl, pDir, pFileName, pTipoAtivo: String): Boolean;
var
  vErro: String;
  vHResult : HRESULT;
begin
  vHResult := URLDownloadToFile(nil, PChar(pUrl), PChar(IncludeTrailingPathDelimiter(pDir) + pFileName), 0, nil);

  if vHResult <> S_OK then
  begin
    vErro := ObterDescricaoErro(vHResult);
    raise Exception.Create(pUrl + #13#10'Ocorrência: ' + IntToStr(vHResult) + ' (' + IntToHex(vHResult, 8) + ') ' + Trim(vErro));
  end;

  Result := True;
end;

function TIntegracaoWS.ObterInfoProduto(const pGtin: String): TJSONObject;
begin
  Self.ObterLogin;

  FApiIntegracao.Url := Format(vgIntegParam.PUrlBuscaInfoProduto, [pGtin]);
  FApiIntegracao.Method := mtGet;
  FApiIntegracao.EnviarRequisicao;

  Result := TJSONObject(TJsonObject.ParseJSONValue(FApiIntegracao.ApiResponse.Content));
end;

function TIntegracaoWS.ObterLogin: String;
var
  vJson : TJSONObject;
  vSplited: TArray<String>;
begin
  Self.LoadApiData;

  if (Self.FApiIntegracao.ApiAuthorization = nil) or
     (FApiIntegracao.ApiAuthorization.ExpirationTime < now) then
  begin
    FApiIntegracao.Url := vgIntegParam.PUrlLogin;
    FApiIntegracao.Method := mtPost;
    FApiIntegracao.EnviarRequisicao(True);

    vJson := TJSONObject(TJSONObject.ParseJSONValue(FApiIntegracao.ApiResponse.Content));
    try
      FApiIntegracao.ApiAuthorization.Token := vJson.Values['token'].Value;

      vSplited := vJson.Values['expirationTime'].Value.Split([' ']);
      FApiIntegracao.ApiAuthorization.ExpirationTime := StrToDateTime(DateTimeToStr(ISO8601ToDate(vSplited[0])) + ' ' + vSplited[1]);
    finally
      FreeAndNil(vJson);
    end;
    Exit(FApiIntegracao.ApiResponse.Content);
  end;
end;

function TIntegracaoWS.ObterProdutos(const pData: TDateTime): TJSONArray;
var
  vData: String;
begin
  Self.ObterLogin;

  try
    vData := DateToISO8601(IncDay(pData) -1);

    FApiIntegracao.Url := Format(vgIntegParam.PUrlListarProdutos, [vData]);
    FApiIntegracao.Method := mtGet;
    FApiIntegracao.EnviarRequisicao;

    Result := TJSONArray(TJSONObject.ParseJSONValue(FApiIntegracao.ApiResponse.Content));
  except
    on E: Exception do
    begin
      FreeAndNil(Result);
      raise E;
    end;
  end;
end;

end.
