unit Core.Thread;

interface

Uses
  {Classes de Sistema}
   System.Classes
  ,System.SyncObjs
  ,System.SysUtils
  ,System.DateUtils
  {Classes de Negócio}
  ,Core.DataBase.Connection;

type
  TStatusService = (ssCreated, ssWaiting, ssInExecute, ssClosing, ssClosed);

  TThreadIntegracaoBase = class(TThread)
  strict private
    FStatus: TStatusService;
    FInterval: Integer;
    FLogTracking: Boolean;
    FDBConnection: TDataBaseConnection;
    FEventoControl : TEvent;
    FInterruptSending: Boolean;
    FLastSubmissionDate: TDateTime;

    procedure RecordLog(PMsg: String; pLogForce: Boolean = False);
  protected
    {Procedures}
    procedure Execute; override;
    procedure SetStatus(Value : TStatusService); virtual;
    procedure SetDataUltimoEnvio(Value : TDateTime); virtual;

    property DBConnection: TDataBaseConnection read FDBConnection write FDBConnection;
  public
    {Construtores e Destrutores}
    constructor Create; overload; virtual;
    destructor Destroy; override;

    {Procedures}
    procedure Finish; virtual;
    procedure ExecutarEnvio; virtual; abstract;

    {Properties}
    property Status:             TStatusService read FStatus            write SetStatus;
    property Interval:           Integer        read FInterval          write FInterval;
    property LogTracking:        Boolean        read FLogTracking       write FLogTracking;
    property InterruptSending:   Boolean        read FInterruptSending  write FInterruptSending;
    property LastSubmissionDate: TDateTime      read FLastSubmissionDate;
  end;


implementation


Uses
  {Classes de negócio}
   Core.Global
  ,Core.Environment;

{ TThreadIntegracaoPadrao }


constructor TThreadIntegracaoBase.Create;
begin
  inherited Create(True);

  FDBConnection := TDataBaseConnection.Create;

  FInterval := 120;

  SetStatus(ssCreated);

  FLogTracking    := True;
  FEventoControl  := TEvent.Create(nil, True, False, '');
  FreeOnTerminate := False;

  RecordLog('Start service with PID(' + IntToStr(Self.ThreadID) + ').', True);
end;

destructor TThreadIntegracaoBase.Destroy;
begin
  FDBConnection.Disconnect;

  Terminate;
  FEventoControl.SetEvent;

  FreeAndNil(FDBConnection);
  FreeAndNil(FEventoControl);

  RecordLog('Destroying service with PID(' + IntToStr(Self.ThreadID) + ').');

  inherited;
end;

procedure TThreadIntegracaoBase.Execute;
begin
  inherited;
  RecordLog('Thread started');
  while not Terminated do
  begin
    try
      if (FStatus = ssClosing) then
        break
      else
      begin
        if FEventoControl.WaitFor(1000) = wrSignaled then
        begin
          RecordLog('Stop requested.');
          Sleep(100);

          SetStatus(ssClosing);
          Break;
        end;

        SetStatus(ssWaiting);

        if (not InterruptSending) and (SecondsBetween(Now, FLastSubmissionDate) >= Interval) then
        begin
          SetStatus(ssInExecute);
          ExecutarEnvio;

          SetDataUltimoEnvio(Now);

          RecordLog('Process completed successfully.');
        end;
      end;
    except
      on E: Exception do
      begin
        RecordLog('An unhandled error occurred in the thread | Error: ' + E.Message, True);
        Sleep(1000 * 60 * 5);
      end;
    end;

    Sleep(1000);
  end;

  SetStatus(ssClosed);
  RecordLog('Thread completed.');
end;

procedure TThreadIntegracaoBase.Finish;
begin
  FEventoControl.SetEvent;
end;

procedure TThreadIntegracaoBase.RecordLog(PMsg: String; pLogForce: Boolean);
begin
  if Pos(Self.UnitName, PMsg) = 0 then
    PMsg := Self.UnitName + ' | ' + PMsg;

  if (not pLogForce) and (not FLogTracking) then
    Exit;

  Env.Log.Info(PMsg);
end;

procedure TThreadIntegracaoBase.SetDataUltimoEnvio(Value: TDateTime);
begin
  FLastSubmissionDate := Value;
end;

procedure TThreadIntegracaoBase.SetStatus(Value: TStatusService);
begin
  if FInterruptSending then
    FStatus := ssClosing
  else
    FStatus := Value;
end;

end.
