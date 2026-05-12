unit Core.Environment;

interface

uses
  {Classes de sistema}
   System.Classes
  ,System.SysUtils
  {Classes de negócio}
  ,Core.Logs,
  Core.DataBase.Interfaces;


type
  TEnvironment = class
  strict private
    FLog: ILog;
    FConnection: IDBConnection;
  private
    function GetConnection: IDBConnection;
    function GetLog: ILog;
  public
    {Construtores e destrutores}
    constructor Create; reintroduce;
    destructor Destroy; override;

    property Log:        ILog          read GetLog;
    property Connection: IDBConnection read GetConnection;
  end;

  {Função global para utilizar como singleton o objeto Environment}
  function Env: TEnvironment;

var
  gEnv: TEnvironment;

implementation

uses
  Core.DataBase.Connection;

{ TEnvironment }

constructor TEnvironment.Create;
begin
  inherited Create;
end;

destructor TEnvironment.Destroy;
begin
  inherited;
end;

function TEnvironment.GetConnection: IDBConnection;
begin
  if not Assigned(FConnection) then
    FConnection := TDataBaseConnection.Create;
  Result := FConnection;
end;

function TEnvironment.GetLog: ILog;
begin
  if not Assigned(FLog) then
    FLog := TLog.Create;
  Result := FLog;
end;

function Env: TEnvironment;
begin
  if not Assigned(gEnv) then
    gEnv := TEnvironment.Create;

  Result := gEnv;
end;

initialization
  gEnv := Env;

finalization
  FreeAndNil(gEnv);

end.
