unit Core.DataBase.Connection;

interface

uses
  {Classes de sistema}
   Data.DB
  ,Vcl.Forms
  ,FireDAC.DatS
  ,FireDAC.DApt
  ,FireDAC.Phys
  ,System.IniFiles
  ,System.SyncObjs
  ,System.SysUtils
  ,FireDAC.UI.Intf
  ,FireDAC.Phys.PG
  ,FireDAC.Stan.Def
  ,FireDAC.DApt.Intf
  ,FireDAC.Stan.Intf
  ,FireDAC.Phys.Intf
  ,FireDAC.Stan.Pool
  ,FireDAC.VCLUI.Wait
  ,FireDAC.Stan.Param
  ,FireDAC.Stan.Async
  ,FireDAC.Stan.Error
  ,FireDAC.Phys.PGDef
  ,FireDAC.Stan.Option
  ,Firedac.Comp.Client
  ,FireDAC.Comp.DataSet
  {Classes de Negócio}
  ,Core.DataBase.Interfaces;

type
  TDataBaseConnection = class(TInterfacedObject, IDBConnection)
  private
    FLink: TFDPhysPGDriverLink;
    FAppName: String;
    FConnection: TFDConnection;

    class var FInstance: IDBConnection;
    class var FConnectionLock: TCriticalSection;
  public
    {Construtores e Destrutores}
    constructor Create;
    destructor Destroy; override;

    {Class Functions}
    class function GetInstance: IDBConnection;
    class procedure FreeInstance; reintroduce;

    {procedures}
    procedure Connect;
    procedure Disconnect;
    procedure LoadConfig;
  protected
    {Functions}
    function GetConnection: TFDConnection;

    {Procedures}
    procedure FreeMemory;
    procedure BeginTransaction;
    procedure CommitTransaction;
    procedure RollBackTransaction;
  end;

implementation

uses
  {Classes de Negócio}
   Core.Global
  ,Core.Environment;

{ TDataBaseConnection }

procedure TDataBaseConnection.BeginTransaction;
begin
  if (not FConnection.InTransaction) then
    FConnection.StartTransaction;
end;

procedure TDataBaseConnection.CommitTransaction;
begin
  if FConnection.InTransaction then
    FConnection.Commit;
end;

procedure TDataBaseConnection.Connect;
begin
  try
    FConnection.Connected := True;
  except
    on E: Exception do
    begin
      Env.Log.Error(Format('%s | %s', [Self.ClassName, E.Message]));
      raise Exception.Create('The connection to the database could not be opened.'+#13#10 + E.Message);
    end;
  end;
end;

constructor TDataBaseConnection.Create;
begin
  FAppName := cAppName;
  LoadConfig;
  Self.FConnectionLock := TCriticalSection.Create;
end;

destructor TDataBaseConnection.Destroy;
begin
  Self.FreeMemory;
  inherited;
end;

procedure TDataBaseConnection.Disconnect;
begin
  if (FConnection.Connected) then
  begin
    try
      FConnection.Connected := False;
    except
      on E : Exception do
      begin
        Env.Log.Error(Format('%s | %s', [Self.ClassName, E.Message]));
        raise Exception.Create('The connection to the database could not be closed.' + #13#10 + E.Message);
      end;
    end;
  end;
end;

class procedure TDataBaseConnection.FreeInstance;
begin
  FConnectionLock.Enter;
  try
    FInstance := nil;
  finally
    FConnectionLock.Leave;
  end;
end;

procedure TDataBaseConnection.FreeMemory;
begin
  FreeInstance;
  if FConnection.Connected then
    FConnection.Close;

  FreeAndNil(Self.FConnectionLock);
  FreeAndNil(FConnection);
end;

function TDataBaseConnection.GetConnection: TFDConnection;
begin
  Result := FConnection;
end;

class function TDataBaseConnection.GetInstance: IDBConnection;
begin
  FConnectionLock.Enter;
  try
    if FInstance = nil then
      FInstance := TDataBaseConnection.Create;

    Result := FInstance;
  finally
    FConnectionLock.Leave;
  end;
end;

procedure TDataBaseConnection.LoadConfig;
var
  LPath: String;
  LArqIni: TIniFile;
  LMessage: String;
begin
  try
    LPath := StringReplace(ExtractFilePath(Application.ExeName), cDirectoryExec+'\', '', [rfReplaceAll]) + 'Drivers\FDConnectionDefs.ini';
    LArqIni := TIniFile.Create(LPath);
    try
      FLink := TFDPhysPGDriverLink.Create(nil);
      FLink.Release;
      FLink.VendorLib := StringReplace(ExtractFilePath(Application.ExeName), cDirectoryExec+'\', '', [rfReplaceAll]) + 'Lib\libpq.dll';

      FConnection := TFDConnection.Create(nil);

      FConnection.DriverName        := LArqIni.ReadString(FAppName, 'DriverID', 'PG');
      FConnection.ConnectionName    := FAppName;
      FConnection.LoginPrompt       := True;
      FConnection.Name              := 'Conn' + FAppName;

      with (TFDPhysPGConnectionDefParams(FConnection.Params)) do
      begin
        Port            := LArqIni.ReadInteger(FAppName, 'Port',      5432);
        Server          := LArqIni.ReadString(FAppName,  'Server',    'localhost');
        DriverID        := LArqIni.ReadString(FAppName,  'DriverID',  '');
        Database        := LArqIni.ReadString(FAppName,  'Database',  '');
        Password        := LArqIni.ReadString(FAppName,  'Password',  'postgres');
        UserName        := LArqIni.ReadString(FAppName,  'User_Name', 'postgres');
        LoginTimeout    := LArqIni.ReadInteger(FAppName, 'Timeout',   30);
        ApplicationName := FAppName;
        CharacterSet    := csUTF8;
      end;

      FConnection.Params.UserName := LArqIni.ReadString(FAppName, 'User_Name', 'postgres');
      FConnection.Params.Password := LArqIni.ReadString(FAppName, 'Password',  'postgres');

      Self.Connect;

      Env.Log.Info(Format('%s | Connected to the database %s.', [Self.ClassName, FConnection.ConnectionName]));
    finally
      FreeAndNil(LArqIni);
    end;
  except
    on E: Exception do
    begin
      LMessage := Format('%s | %s #13#10. The application will be finalized.', [Self.ClassName, E.Message]);
      Env.Log.Error(LMessage);
      Env.Log.Error(E.StackTrace);
      raise Exception.Create('The database connection data could not be loaded.' + #13#10 + E.Message);
    end;
  end;
end;

procedure TDataBaseConnection.RollBackTransaction;
begin
  if FConnection.InTransaction then
    FConnection.Rollback;
end;

end.
