unit Core.Logs;

interface

uses
  {Classes de Sistema}
   Vcl.Forms
  ,Quick.Logger
  ,System.SysUtils
  ,Quick.Logger.Provider.Files
  ,Quick.Logger.Provider.Console;

Type
  iLog = interface
    ['{EBF2E3E8-9699-41AE-AC7C-0A06C4757E7D}']
    function Info(vMessage: String): iLog;
    function Debug(vMessage: String): iLog;
    function Error(vMessage: String): iLog;
    function Warning(vMessage: String): iLog;
  end;

  TLog = class(TInterfacedObject, iLog)
  strict private

  public
    class function New: iLog;

    function Info(vMessage: String): iLog;
    function Debug(vMessage: String): iLog;
    function Error(vMessage: String): iLog;
    function Warning(vMessage: String): iLog;
  end;

implementation

uses
  {Classes de Sistema}
   System.IOUtils
  {Classes de Negócio}
  ,Core.Global;

{ TLog }

function TLog.Debug(vMessage: String): iLog;
begin
  Log(vMessage, etDebug);
end;

function TLog.Error(vMessage: String): iLog;
begin
  Log(vMessage, etError);
end;

function TLog.Info(vMessage: String): iLog;
begin
  Log(vMessage, etInfo);
end;

class function TLog.New: iLog;
begin
  Result := Self.create;
end;

function TLog.Warning(vMessage: String): iLog;
begin
  Log(vMessage, etWarning);
end;

initialization
begin
  {Add Log File and console providers}
  Logger.Providers.Add(GlobalLogFileProvider);
  Logger.Providers.Add(GlobalLogConsoleProvider);
  {Configure provider options}
  GlobalLogFileProvider.FileName := StringReplace(ExtractFilePath(Application.ExeName), cDirectoryExec+'\', 'Log\', [rfReplaceAll])
                                  + StringReplace(ExtractFileName(Application.ExeName), 'exe', 'log', [rfReplaceAll]);

  {Se o diretório não existe, cria.}
  if not TDirectory.Exists(StringReplace(ExtractFilePath(Application.ExeName), cDirectoryExec+'\', 'Log\', [rfReplaceAll])) then
    TDirectory.CreateDirectory(StringReplace(ExtractFilePath(Application.ExeName), cDirectoryExec+'\', 'Log\', [rfReplaceAll]));

  {Se houver o parâmetro -debug na inicilização, altera o logLEvel para Debug}
  if FindCmdLineSwitch('debug') then
  begin
    GlobalLogFileProvider.LogLevel    := LOG_DEBUG;
    GlobalLogConsoleProvider.LogLevel := LOG_DEBUG;
  end
  else
  begin
    GlobalLogFileProvider.LogLevel    := LOG_BASIC;
    GlobalLogConsoleProvider.LogLevel := LOG_BASIC;
  end;

  {LogFileProvider}
  GlobalLogFileProvider.Enabled         := True;
  GlobalLogFileProvider.DailyRotate     := True;
  GlobalLogFileProvider.MaxFileSizeInMB := 20;

  {LogConsoleProvider}
  GlobalLogConsoleProvider.Enabled         := True;
  GlobalLogConsoleProvider.ShowEventColors := True;
end;

end.
