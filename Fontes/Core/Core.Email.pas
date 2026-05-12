unit Core.Email;

interface

Uses
  {Classes de Sistema}
   IdSMTP
  ,IdMessage
  ,IdSSLOpenSSL
  ,System.Classes
  ,System.SysUtils
  ,IdExplicitTLSClientServerBase,
  {Classes de Negócio}
  Core.Exceptions;

type
  TEmail = class
  private
    FPort: Integer;
    FHost: String;
    FBody: TStrings;
    FSubject: String;
    FFromName: String;
    FPassword: String;
    FUserName: String;
    FToAddress: String;
    FFromAddress: String;

    procedure ValidarDadosEmail;
  public
    {Construtores e Destrutores}
    constructor Create; reintroduce;
    destructor Destroy; override;
    {Procedures}
    procedure Enviar;

    {Properties}
    property PHost:             String   read FHost         write FHost;
    property PPort:             Integer  read FPort         write FPort;
    property PBody:             TStrings read FBody         write FBody;
    property PSubject:          String   read FSubject      write FSubject;
    property PUserName:         String   read FUserName     write FUserName;
    property PPassword:         String   read FPassword     write FPassword;
    property PFromName:         String   read FFromName     write FFromName;
    property PEmailToAddress:   String   read FToAddress    write FToAddress;
    property PEmailFromAddress: String   read FFromAddress  write FFromAddress;
  end;

implementation

{ TEmail }


constructor TEmail.Create;
begin
  inherited Create;
  FBody := TStringList.Create;
end;

destructor TEmail.Destroy;
begin
  FreeAndNil(FBody);
  inherited;
end;

procedure TEmail.Enviar;
var
  vIdSMTP: TIdSMTP;
  vIdMessage: TIdMessage;
  vIdSSLSocket: TIdSSLIOHandlerSocketOpenSSL;
begin
  vIdSSLSocket := TIdSSLIOHandlerSocketOpenSSL.Create(nil);
  try
    vIdSSLSocket.SSLOptions.Mode := sslmClient;
    vIdSSLSocket.SSLOptions.Method := sslvTLSv1;

    vIdSMTP := TIdSMTP.Create(nil);
    try
      //Dados de Acesso
      vIdSMTP.Host := PHost;
      vIdSMTP.Port := PPort;
      vIdSMTP.UseTLS := utNoTLSSupport;
      vIdSMTP.IOHandler := vIdSSLSocket;

      //Dados de Autenticação
      vIdSMTP.AuthType := satDefault;
      vIdSMTP.Username := PUserName;
      vIdSMTP.Password := PPassword;

      vIdMessage := TIdMessage.Create(nil);
      try
        vIdMessage.Subject := PSubject;
        vIdMessage.From.Name := PFromName;
        vIdMessage.From.Address := PEmailFromAddress;
        vIdMessage.Recipients.EMailAddresses := PEmailToAddress;

        Self.ValidarDadosEmail;

        vIdMessage.Body.Assign(PBody);

        try
          vIdSMTP.Connect;
          vIdSMTP.Send(vIdMessage);
          vIdSMTP.Disconnect;
        except
          on E: Exception do
          begin

          end;
        end;
      finally
        vIdMessage.Free;
      end;
    finally
      vIdSMTP.Free;
    end;
  finally
    vIdSSLSocket.Free;
  end;
end;

procedure TEmail.ValidarDadosEmail;
begin
  if PUserName.IsEmpty or  PPassword.IsEmpty then
    EEmailAuthError.Create('Usuário ou Senha não informado, revise suas configurações.');
  if PEmailFromAddress.IsEmpty then
    EEmailFromAddresError.Create('Email de origem não foi informado.');
  if PEmailToAddress.IsEmpty then
    EEmailToAddresError.Create('Email do destinatário não foi informado.');
end;

end.
