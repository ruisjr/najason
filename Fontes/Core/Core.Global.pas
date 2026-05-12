unit Core.Global;

interface

Uses
  {Classes de Sistema}
   Vcl.Forms
  ,System.IniFiles
  ,System.SysUtils
  ,System.Generics.Collections
  {Classes de Negócio}
  ,Core.DataBase.Types
  ,Core.DataBase.Access
  ,Core.DataBase.Interfaces;


const
  cAppName = 'SrvPetShopApp';
  cDirectoryExec = 'Bin';

function GetPortService: Integer;


implementation


function GetPortService: Integer;
var
  LPath: String;
  LArqIni: TIniFile;
begin
  try
    LPath   := StringReplace(ExtractFilePath(Application.ExeName), cDirectoryExec+'\', '', [rfReplaceAll]) + 'Drivers\FDConnectionDefs.ini';
    LArqIni := TIniFile.Create(LPath);
    Result  := LArqIni.ReadInteger(cAppName, 'ServicePort', 9000)
  finally
    FreeAndNil(LArqIni);
  end;
end;


end.
