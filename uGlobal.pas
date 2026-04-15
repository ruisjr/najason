unit uGlobal;

interface

uses
  system.SysUtils;

type
  TFuncoes = class
  public
    class function RemoverAcentos(const pValue: String): String;
    class function RetornarToken: String;
  end;

implementation

uses
  uWebService;

{ TFuncoes }

class function TFuncoes.RemoverAcentos(const pValue: String): String;
const
  cComAcento = 'àâêôûãõáéíóúçüÀÂÊÔÛÃÕÁÉÍÓÚÇÜ';
  cSemAcento = 'aaeeouaoaeioucuAAEEOUAOAEIOUCU';
var
  vIx,
  vPos: Integer;
begin
  Result := pValue;
  for vIx := 1 to Length(Result) do
  begin
    vPos := Pos(Result[vIx], cComAcento);
    if vPos > 0 then
      Result[vIx] := cSemAcento[vPos];
  end;
end;

class function TFuncoes.RetornarToken: String;
const
  cBody = '{"email": "ruisjr2005@gmail.com", "password": "Gio2010!(*@p"}';
  cApiKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im15bnhsdWJ5a3lsbmNpbnR0Z2d1Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjUxODg2NzAsImV4cCI6MjA4MDc2NDY3MH0.Z-zqiD6_tjnF2WLU167z7jT5NzZaG72dWH0dpQW1N-Y';
var
  vWs: TWebService;
begin
  vWS := TWebService.Create;
  try
    vWS.Metodo := 'POST';
    vWs.URL    := 'https://mynxlubykylncinttggu.supabase.co/auth/v1/token?grant_type=password';
    vWs.Body   := cBody;
    vWs.Headers.AddOrSetValue('Content-Type', 'application/json');
    vWs.Headers.AddOrSetValue('apikey', cApiKey);
    vWs.Enviar;

    if Assigned(vWS.Response) then
      Result := vWS.Response.GetValue<String>('access_token');
  finally
    FreeAndNil(vWS);
  end;
end;

end.
