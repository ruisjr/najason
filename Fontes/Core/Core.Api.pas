unit Core.Api;

interface

Uses
  {Classes de Sistema}
   Rest.Types
  ,Rest.Client
  ,System.JSON
  ,IPPeerClient
  ,IPPeerCommon
  ,System.SysUtils
  ,System.DateUtils
  {Classes de Negócio}
  ,Core.Environment;

type
  EApiIntegracaoError = Exception;

  TMethodType = (mtGet, mtPost, mtPut, mtDelete, mtPatch);

  TApiAuthorization = class
  private
    FToken: String;
    FExpirationTime: TDateTime;
  public
    property Token:          String    read FToken          write FToken;
    property ExpirationTime: TDateTime read FExpirationTime write FExpirationTime;
  end;

  TApiResponse = class
  private
    FStatusCode: Integer;
    FContent: String;
  public
    property StatusCode: Integer  read FStatusCode write FStatusCode;
    property Content:    String   read FContent    write FContent;
  end;

  TApiIntegracao = class
  private
    FUrl: String;
    FBody: String;
    FMethod: TMethodType;
    FUserName: String;
    FPassword: String;
    FApiResponse: TApiResponse;
    FContentType: String;
    FApiAuthorization: TApiAuthorization;

    {Functions}
    function GetMethod(const pMethod: TMethodType): TRESTRequestMethod;
    function GetUrl: String;

    {Procedures}
    procedure SetAuthorization;
    procedure ValidarDadosObrigatorios;
  public
    {Construtores e Destrutores}
    constructor Create; reintroduce;
    destructor Destroy; override;

    {Procedures}
    procedure EnviarRequisicao(const pAuthorization: Boolean = False);

    {Properties}
    property Url:              String             read GetUrl             write FUrl;
    property Body:             String             read FBody              write FBody;
    property Method:           TMethodType        read FMethod            write FMethod;
    property UserName:         String             read FUserName          write FUserName;
    property Password:         String             read FPassword          write FPassword;
    property ContentType:      String             read FContentType       write FContentType;
    property ApiResponse:      TApiResponse       read FApiResponse       write FApiResponse;
    property ApiAuthorization: TApiAuthorization  read FApiAuthorization  write FApiAuthorization;
  end;

implementation

{ TApiIntegracao }

constructor TApiIntegracao.Create;
begin
  inherited Create;
  FApiResponse := TApiResponse.Create;
  FApiAuthorization := TApiAuthorization.Create;
end;

destructor TApiIntegracao.Destroy;
begin
  FreeAndNil(FApiResponse);
  FreeAndNil(FApiAuthorization);
  inherited;
end;

procedure TApiIntegracao.EnviarRequisicao(const pAuthorization: Boolean);
var
  vClient: TRESTClient;
  vRequest: TRESTRequest;
  vResponse: TRESTResponse;

  vParamBody: TRestRequestParameter;
  vParamHeader: TRestRequestParameter;
begin
  Self.ValidarDadosObrigatorios;

  vClient := TRESTClient.Create(nil);
  try
    vRequest := TRESTRequest.Create(nil);
    try
      vResponse := TRESTResponse.Create(nil);
      try
        try
          Self.ApiResponse.StatusCode := vResponse.StatusCode;

          vClient.Accept          := 'application/json, text/plain; q=0.9, text/html;q=0.8,';
          vClient.AcceptCharset   := 'UTF-8, *;q=0.8';
          vClient.BaseURL         := Self.Url;
          vClient.HandleRedirects := True;

          vRequest.Client := vClient;
          vRequest.Method := GetMethod(Self.Method);
          vRequest.Params.Clear;

          if pAuthorization then
            Self.SetAuthorization
          else
          begin
            vParamHeader             := vRequest.Params.AddItem;
            vParamHeader.name        := 'Authorization';
            vParamHeader.Value       := Self.ApiAuthorization.Token;
            vParamHeader.Options     := [poDoNotEncode];
            vParamHeader.ContentType := ctAPPLICATION_JSON;
            vParamHeader.Kind        := pkHTTPHEADER;
          end;

          vParamBody := vRequest.Params.AddItem;
          vParamBody.name := 'body';
          vParamBody.Value := Self.Body;
          vParamBody.ContentType := ctAPPLICATION_JSON;
          vParamBody.Kind := pkREQUESTBODY;

          vRequest.Response := vResponse;
          vRequest.SynchronizedEvents := False;

          vResponse.ContentType := CONTENTTYPE_APPLICATION_JSON;
          vRequest.Execute;

          Self.ApiResponse.Content := vResponse.Content;
          Self.ApiResponse.StatusCode := vResponse.StatusCode;
        except
          on E: Exception do
          begin
            Env.Log.Error(Self.UnitName + ' | Erro ao realizar a comunicação com o webservice.' + #13#10 + E.Message);
            raise E;
          end;
        end;

        if Self.ApiResponse.StatusCode > 300 then
        begin
          Env.Log.Error(Self.UnitName + ' | StatusCode: ' + IntToStr(Self.ApiResponse.StatusCode) + ' - ' + Self.ApiResponse.Content);
          raise Exception.Create('StatusCode: ' + IntToStr(Self.ApiResponse.StatusCode) + ' - ' + Self.ApiResponse.Content);
        end;
      finally
        FreeAndNil(vResponse);
      end;
    finally
      FreeAndNil(vRequest);
    end;
  finally
    FreeAndNil(vClient);
  end;
end;

function TApiIntegracao.GetMethod(const pMethod: TMethodType): TRESTRequestMethod;
begin
  case pMethod of
    mtGet   : Result := rmGET;
    mtPost  : Result := rmPOST;
    mtPut   : Result := rmPUT;
    mtDelete: Result := rmDELETE;
    mtPatch : Result := rmPATCH;
    else Result := rmGET;
  end
end;

function TApiIntegracao.GetUrl: String;
begin
  Result := FUrl;
end;

procedure TApiIntegracao.SetAuthorization;
var
  vBody: String;
  vJson: TJSONObject;
begin
  if FUserName.IsEmpty or FPassword.IsEmpty then
    raise Exception.Create('Credenciais não informadas');

  vJson := TJSONObject.Create;
  try
    vJson.AddPair('email', FUserName);
    vJson.AddPair('password', FPassword);

    vBody := vJson.ToString;
  finally
    FreeAndNil(vJson);
  end;

  Self.Body := vBody;
end;

procedure TApiIntegracao.ValidarDadosObrigatorios;
begin
  if Self.FUrl.IsEmpty then
    raise EApiIntegracaoError.Create('A propriedade URL não foi preenchida.')
  else if Self.FUserName.IsEmpty then
    raise EApiIntegracaoError.Create('A propriedade UserName não foi preenchida.')
  else if Self.FPassword.IsEmpty then
    raise EApiIntegracaoError.Create('A propriedade Password não foi preenchida.')
end;

end.
