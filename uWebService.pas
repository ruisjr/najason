unit uWebService;

interface

Uses
    System.SysUtils
  , System.Classes
  , Rest.Types
  , Rest.Client
  , IPPeerClient
  , IPPeerCommon
  , System.JSON
  , System.Generics.Collections;

type
  EWebServiceError = class(Exception);

  TStatusRequest = (srOK            = 200, srCreated      = 201, srAccept = 202,  srNoContent = 204,
                    srBadRequest    = 400, srUnauthorized = 401, srForbidden = 403, srNotFound = 404, srTimeOut = 408, srUnsupportedMediaType = 415,
                    srInternalError = 500, srBadGateway = 502, srServiceUnavailable = 503);

  TWebService = class
  strict private
    FErro: String;
    FMetodo: String;
    FURL: String;
    FBody: String;
    FResponse: TJSONObject;
    FToken: String;
    FStatusCode: TStatusRequest;
    FHeaders: TDictionary<String, String>;

    function GetMethod: TRESTRequestMethod;
  public
    constructor Create; reintroduce;
    destructor Destroy; override;

    procedure Enviar;

    property Erro:       string                      read FErro       write FErro;
    property Metodo:     String                      read FMetodo     write FMetodo;
    property URL:        String                      read FURL        write FURL;
    property Body:       String                      read FBody       write FBody;
    property Token:      String                      read FToken      write FToken;
    property Headers:    TDictionary<String, String> read FHeaders    write FHeaders;
    property Response:   TJSONObject                 read FResponse   write FResponse;
    property StatusCode: TStatusRequest              read FStatusCode write FStatusCode;
  end;

implementation

uses
   uGlobal;

{ TWebService }

constructor TWebService.Create;
begin
  FHeaders := TDictionary<String, String>.Create;
end;

destructor TWebService.Destroy;
begin
  FResponse.Free;

  FHeaders.Clear;
  FHeaders.Free;
  inherited;
end;

procedure TWebService.Enviar;
var
  vIx: Integer;
  vErro: String;
  vClient: TRESTClient;
  vRequest: TRESTRequest;
  vResponse: TRESTResponse;
  vJSON: TJSONObject;
  vJSONAr: TJSONArray;

  vPar: TPair<String, String>;
  vBodyStream: TStringStream;
begin
  vClient := TRESTClient.Create(nil);
  try
    vRequest := TRESTRequest.Create(nil);
    try
      vResponse := TRESTResponse.Create(nil);
      try
        try
          vClient.ResetToDefaults;
          vRequest.ResetToDefaults;

          vClient.Accept          := 'application/json, text/plain; q=0.9, text/html;q=0.8,';
          vClient.AcceptCharset   := 'UTF-8, *;q=0.8';
          vClient.BaseURL         := Self.Url;
          vClient.HandleRedirects := True;

          vRequest.Params.Clear;
          vRequest.Body.ClearBody;

          vRequest.Client   := vClient;
          vRequest.Method   := Self.GetMethod;
          vRequest.Response := vResponse;
          vRequest.SynchronizedEvents := False;

          {Adicionando o token se o PToken estiver preenchido, conforme a necessidade}
          if not Self.FToken.IsEmpty then
            vRequest.AddParameter('Authorization', 'Bearer ' + Self.FToken, TRESTRequestParameterKind.pkHTTPHEADER, [poDoNotEncode]);

          {Inclusão de headers se existir}
          for vPar in Self.FHeaders.ToArray do
            vRequest.AddParameter(vPar.Key, vPar.Value, pkHTTPHEADER, [poDoNotEncode]);

          if not Self.FBody.IsEmpty then
          begin
            vBodyStream := TStringStream.Create(TFuncoes.LimparStringJSON(Self.FBody), TEncoding.UTF8, False);
            vRequest.AddBody(vBodyStream, TRESTContentType.ctAPPLICATION_JSON);
          end;

          vRequest.Response := vResponse;
          vRequest.SynchronizedEvents := False;

          vResponse.ContentType := CONTENTTYPE_APPLICATION_JSON;

          try
            vRequest.Execute;
          finally
            Self.FStatusCode := TStatusRequest(vResponse.StatusCode);
          end;

          {Tratamento para validar se o retorno é um erro}
          case Self.FStatusCode of
            srBadRequest, srUnauthorized, srForbidden, srNotFound, srInternalError,
            srTimeOut, srUnsupportedMediaType, srServiceUnavailable:
            begin
              vJSON := TJSONObject(TJSONObject.ParseJSONValue(vResponse.Content));
              try
                if Assigned(vJSON) then
                begin
                  if vJSON.ClassType = TJSONArray then
                  begin
                    vJSONAr := TJSONArray(TJSONObject.ParseJSONValue(vJSON.ToJSON));
                    for vIx := vJSONAr.Count -1 downto 0 do
                    begin
                      vJSON := TJSONObject(TJSONObject.ParseJSONValue(TJSONObject(vJSONAr.Items[vIx]).ToJSON));
                      Self.Erro := Self.Erro + vJSON.Values['Mensagem'].Value;
                    end;
                  end
                  else
                  begin
                    if vJSON.GetValue('message') <> nil then
                      Self.Erro := vJSON.GetValue<String>('message');
                  end;

                  if vJSON.GetValue('messageError') <> nil then
                  begin
                    vJSON := TJSONObject(TJSONObject.ParseJSONValue(vJSON.values['messageError'].ToJson));
                    if vJSON.GetValue('message') <> nil then
                      Self.Erro := Trim(vJSON.GetValue<String>('message'));
                  end;
                end;
              finally
//                vJSON.ClearAndFreeItems;
                FreeAndNil(vJSON);
              end;

              vErro := Self.Erro;
              if vErro.IsEmpty then
              begin
                vErro := vResponse.Content;
                if vErro.IsEmpty then
                  vErro := Format('Retorno: %s. Erro ao se comunicar com webservie.', [vResponse.StatusCode.ToString]);
              end;

              Self.Erro := vErro;
            end;
          else
            begin
              Self.FResponse := TJSONObject(TJSONObject.ParseJSONValue(vResponse.Content));
            end;
          end;
        except
          on E: Exception do
          begin
            raise E;
          end;
        end;
      finally
        FreeAndNil(vResponse);
      end;
    finally
      FreeAndNil(vRequest);
    end;
  finally
    if Assigned(vClient) then
      vClient.Disconnect;
    FreeAndNil(vClient);
  end;
end;

function TWebService.GetMethod: TRESTRequestMethod;
begin
  if Self.FMetodo.Equals('POST') then
    Result := rmPOST
  else if Self.FMetodo.Equals('GET') then
    Result := rmGET
  else if Self.FMetodo.Equals('PUT') then
    Result := rmPUT
  else if Self.FMetodo.Equals('DELETE') then
    Result := rmDELETE
  else if Self.FMetodo.Equals('PATCH') then
    Result := rmPATCH
  else
    Result := rmGET;
end;

end.
