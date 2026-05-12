unit Core.Servico;

interface

Uses
  {Classes de sistema}
   Vcl.Forms
  ,System.Classes
  ,Winapi.Windows
  ,System.SysUtils
  {Classes de Negócio}
  ,Core.Thread
  ,Core.Environment
  ,Core.DataBase.Types;


type
  TServicoBase = class(TPersistent)
  private
    FThread: TThreadIntegracaoBase;
  public
    destructor Destroy; override;

    {Procedures}
    procedure StartThread; virtual;
    procedure StopThread; virtual;
    procedure ExecutarEnvio; virtual;

    {Functions}
    function GetStatus: TStatusService; virtual;

    property PThread: TThreadIntegracaoBase read FThread write FThread;
  end;

implementation

{ TServicoProdutos }

destructor TServicoBase.Destroy;
begin
  Env.Log.Info(Self.UnitName + ' | Destroying Thread.');
  FreeAndNil(FThread);
  inherited;
end;

procedure TServicoBase.ExecutarEnvio;
begin
  PThread.ExecutarEnvio;
end;

procedure TServicoBase.StopThread;
var
  vInicioTick: Cardinal;
begin
  if Assigned(FThread) then
  begin
    vInicioTick := GetTickCount;
    if FThread.Finished then
      Exit;

    {Aguarda terminar com timeout}
    while (GetTickCount - vInicioTick) < 10000 do
    begin
      if FThread.Finished then
        Break;

      Application.ProcessMessages;
      Sleep(100);
    end;

    if not FThread.Finished then
    begin
      Env.Log.Info(Self.UnitName + ' | Ending Thread.');
      FThread.OnTerminate := nil;
      FThread.Terminate;
      FThread.WaitFor;
    end
  end;
end;

function TServicoBase.GetStatus: TStatusService;
begin
  Result := ssCreated;
  if Assigned(PThread) then
    Result := PThread.Status;
end;

procedure TServicoBase.StartThread;
begin
  FThread.Start;
end;

end.
