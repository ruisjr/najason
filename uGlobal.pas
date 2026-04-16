unit uGlobal;

interface

uses
  system.SysUtils;

type
  TFuncoes = class
  public
    class function RemoverAcentos(const pValue: String): String;
    class function RetornarToken: String;
    class function LimparStringJSON(const AValue: string): string;
  end;

implementation

uses
  uWebService;

{ TFuncoes }

class function TFuncoes.LimparStringJSON(const AValue: string): string;
var
  I: Integer;
  C: Char;
begin
  Result := '';
  for I := 1 to Length(AValue) do
  begin
    C := AValue[I];

    { Mantém apenas caracteres >= espaço (32). Isso remove quebras de linha, tabs e caracteres de controle (0-31)}
    if Ord(C) >= 32 then
    begin
      {Opcional: Você pode adicionar filtros extras aqui}
      Result := Result + C;
    end;
  end;

  {Remove espaços em branco nas extremidades e possíveis caracteres de controle}
  Result := Trim(Result);
end;

class function TFuncoes.RemoverAcentos(const pValue: String): String;
const
  cComAcento = 'àâêôûãõáéíóúçüÀÂÊÔÛÃÕÁÉÍÓÚÇÜ';
  cSemAcento = 'aaeouaoaeioucuAAEOUAOAEIOUCU';
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
