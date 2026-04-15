unit uWebService;

interface

Uses
    System.SysUtils
  , System.Classes
  , IdHTTP
  , IdStack
  , IdSSLOpenSSL
  , IdSSLOpenSSLHeaders
  , System.JSON
  , System.Generics.Collections;

type
  EWebServiceError = class(Exception);

  TWebService = class
  strict private
    FMetodo: String;
    FURL: String;
    FBody: String;
    FResponse: TJSONObject;
    FToken: String;
    FHeaders: TDictionary<String, String>;
  public
    constructor Create; reintroduce;
    destructor Destroy; override;

    procedure Enviar;

    property Metodo:   String                      read FMetodo   write FMetodo;
    property URL:      String                      read FURL      write FURL;
    property Body:     String                      read FBody     write FBody;
    property Token:    String                      read FToken    write FToken;
    property Headers:  TDictionary<String, String> read FHeaders write FHeaders;
    property Response: TJSONObject                 read FResponse write FResponse;
  end;

implementation

{ TWebService }

constructor TWebService.Create;
begin
  IdOpenSSLSetLibPath('C:\NasajonDesafio');
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
  vHTTP: TIdHTTP;
  vHandler: TIdSSLIOHandlerSocketOpenSSL;
  vResponse: string;
  vJSONArray: TJSONArray;
  vKey: String;

  vStream: TStringStream;
  vJsonParse: TJsonValue;
begin
  vHTTP := TIdHTTP.Create(nil);
  try
    vHandler := TIdSSLIOHandlerSocketOpenSSL.Create(vHTTP);
    try
      // Configuração para HTTPS
      vHTTP.IOHandler := vHandler;
      vHandler.SSLOptions.Method := sslvTLSv1_2; // Define versão do TLS
      vHTTP.ConnectTimeout := 5000; // 5 segundos para conectar
      vHTTP.ReadTimeout := 5000;    // 30 segundos para ler (o JSON de municípios é pesado)
      vHTTP.Request.ContentType := 'application/json';

      if not Ftoken.Equals(EmptyStr) then
        vHTTP.Request.CustomHeaders.Values['Authorization'] := Format('Bearer %s', [FToken]);

      if Assigned(FHeaders) and (FHeaders.Count > 0) then
      begin
        for vKey in FHeaders.Keys do
          vHTTP.Request.CustomHeaders.Values[vKey] := FHeaders[vKey];
      end;

      // Executa a requisição
      try
        if Self.FMetodo.ToUpper.Equals('GET') then
          vResponse := vHTTP.Get(FURL)
        else if Self.FMetodo.ToUpper.Equals('POST') then
        begin
          vStream := TStringStream.Create(FBody, TEncoding.UTF8);
          try
            vResponse := vHTTP.Post(FURL, vStream);
          finally
            vStream.Free;
          end;
        end;
      except
        on E: EIdSocketError do
          raise EWebServiceError.Create('Erro de timeout.');
        on Exception do
          raise Exception.Create(WhichFailedToLoad());
      end;
      // Parse do JSON
      vJsonParse := TJSONObject.ParseJSONValue(vResponse);
      if vJsonParse is TJSONArray then
      begin
        vJSONArray := TJSONObject.ParseJSONValue(vResponse) as TJSONArray;
        Response := TJSONObject(vJSONArray);
      end
      else
        FResponse := TJSONObject.ParseJSONValue(vResponse) as TJSONObject;

    finally
      FreeAndNil(vHandler);
    end;
  finally
    vHTTP.Free;
  end;
end;

end.
