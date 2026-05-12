unit Core.Functions;

interface

Uses
   System.Json
  ,AnsiStrings
  ,System.Hash
  ,Vcl.ComCtrls
  ,Vcl.Graphics
  ,Winapi.UrlMon
  ,System.Classes
  ,Winapi.WinSock
  ,Winapi.Windows
  ,System.SysUtils
  ,Vcl.Imaging.JPEG
  ,System.NetEncoding
  ,Vcl.Imaging.PNGImage;

type
  TJsonObjectHelper = class Helper for TJSONObject
  public
    procedure ClearAndFreeItems;
  end;

  TJsonValueHelper = class Helper for TJSONValue
  public
    procedure ClearAndFreeItems;
  end;

function ConcederAcessoPastaRede(RemotePath, UserName, Password : PAnsiChar; vGeraRaise: Boolean = False): Boolean;
function RemoveDirBarra(pPath: String): String;
function ObterDescricaoErro(const pResult: HRESULT): String;
procedure ConverterPngParaJpg(const pArquivoEntrada, pArquivoSaida: string);
function ObterVersaoAplicacao(pPath: String): String;
function ObterUsuarioWindows: String;
function ObterNomeMaquina: String;
function GetIP: String;
function Split(pDelimiter: Char; pValue: String; pLeft: Boolean = True): String;

{Codificação e Decodificação}
function GetEncodeBase64(const pValue: String): String;
function GetDecodeBase64(const pValue: String): String;
function GetHashMD5String(const pValue: String): String;


const
    cKey = 'RuiGiovannaNatã201019821987';

implementation

function ConcederAcessoPastaRede(RemotePath, UserName, Password : PAnsiChar; vGeraRaise: Boolean = False): Boolean;
var
  vNRW : TNetResourceA;
  vErro: String;
  vRetorno: Integer;
begin
  Result := False;

  with vNRW do
  begin
    dwType := RESOURCETYPE_ANY;
    lpLocalName := nil;
    lpRemoteName := RemotePath;
    lpProvider := nil;
  end;

  vRetorno := WNetAddConnection2A(vNRW, Password, UserName, 0);

  vErro := '';
  case vRetorno of
    NO_ERROR :
    begin
      Result := True;
      Exit;
    end;
    ERROR_ACCESS_DENIED: vErro := 'Access to the network resource was denied.';
    ERROR_ALREADY_ASSIGNED: vErro := 'The local device specified by lpLocalName is already connected to a network resource.';
    ERROR_BAD_DEV_TYPE: vErro := 'The type of local device and the type of network resource do not match.';
    ERROR_BAD_DEVICE: vErro := 'The value specified by lpLocalName is invalid.';
    ERROR_BAD_NET_NAME: vErro := 'The value specified by lpRemoteName is not acceptable to any network resource provider. The resource name is invalid, or the named resource cannot be located.';
    ERROR_BAD_PROFILE: vErro := 'The user profile is in an incorrect format.';
    ERROR_BAD_PROVIDER: vErro := 'The value specified by lpProvider does not match any provider.';
    ERROR_BUSY: vErro := 'The router or provider is busy, possibly initializing. The caller should retry.';
    ERROR_CANCELLED: vErro := 'The attempt to make the connection was cancelled by the user through a dialog box from one of the network resource providers, or by a called resource.';
    ERROR_CANNOT_OPEN_PROFILE: vErro := 'The system is unable to open the user profile to process persistent connections.';
    ERROR_DEVICE_ALREADY_REMEMBERED: vErro := 'An entry for the device specified in lpLocalName is already in the user profile.';
    ERROR_EXTENDED_ERROR: vErro := 'A network-specific error occured. Call the WNetGetLastError function to get a description of the error.';
    ERROR_INVALID_PASSWORD: vErro := 'The specified password is invalid.';
    ERROR_NO_NET_OR_BAD_PATH: vErro := 'A network component has not started, or the specified name could not be handled.';
    ERROR_NO_NETWORK: vErro := 'A rede não está presente ou não foi iniciada.';
    ERROR_BAD_NETPATH: vErro := 'O caminho de rede não foi encontrado.';
    else vErro := 'Erro desconhecido - ' +  IntToStr(vRetorno) + ' - ' + SysErrorMessage(GetLastError);
  end;

  if (vGeraRaise) and (vErro <> '') then
  begin
    raise Exception.Create('Erro ao conectar na rede: ' + vErro);
  end;
end;

function RemoveDirBarra(pPath: String): String;
begin
  Result := '';
  if pPath <> '' then
  begin
    Result := pPath;
    if pPath[Length(pPath)] = '\' then
      Result := Copy(pPath,1,Length(pPath)-1);
  end
  else
    Result := '';
end;

function ObterDescricaoErro(const pResult: HRESULT): String;
begin
  case pResult of
    INET_E_INVALID_URL: Result := 'URL inválida';
    INET_E_NO_SESSION: Result := 'Nenhuma sessão de Internet foi estabelecida';
    INET_E_CANNOT_CONNECT: Result := 'Não foi possível conectar ao servidor, acione a suporte do serviço';
    INET_E_RESOURCE_NOT_FOUND: Result := 'Servidor fora do ar, acione o servidor do serviço';
    INET_E_OBJECT_NOT_FOUND: Result := 'Erro 404 - Imagem não encontrada, acione o suporte do serviço';
    INET_E_DATA_NOT_AVAILABLE: Result := 'Uma conexão com a Internet foi estabelecida, mas os dados não podem ser recuperados';
    INET_E_DOWNLOAD_FAILURE: Result := 'Download falhou (a conexão foi interrompida)';
    INET_E_AUTHENTICATION_REQUIRED: Result := ' A autenticação é necessária para acessar o objeto';
    INET_E_NO_VALID_MEDIA: Result := 'O objeto não está em um dos tipos MIME aceitáveis';
    INET_E_CONNECTION_TIMEOUT: Result := 'Tempo de espera limite atingido, acione a Simplus';
    INET_E_INVALID_REQUEST: Result := 'Requisição inválida';
    INET_E_UNKNOWN_PROTOCOL: Result := 'Protocolo incorreto';
    INET_E_SECURITY_PROBLEM: Result := 'Foi encontrado um problema de segurança relacionado a uma das seguintes mensagens de erro do Win32';
    INET_E_CANNOT_LOAD_DATA: Result := 'O objeto não pôde ser carregado';
    INET_E_CANNOT_INSTANTIATE_OBJECT: Result := 'Não foi possível instanciar o objeto';
    INET_E_INVALID_CERTIFICATE: Result := 'O certificado SSL é inválido, acione o suporte do serviço';
    INET_E_REDIRECT_FAILED: Result := 'Erro ao ser redirecionado, acione o suporte do serviço';
    INET_E_REDIRECT_TO_DIR: Result := 'A solicitação está sendo redirecionada para um diretório, acione o suporte do serviço';
    INET_E_CANNOT_LOCK_REQUEST: Result := 'O recurso solicitado não pôde ser bloqueado';
    INET_E_USE_EXTEND_BINDING: Result := 'Solicitação de reemissão com vinculação estendida';
    INET_E_TERMINATED_BIND: Result := 'Conexão encerrada';
    INET_E_BLOCKED_REDIRECT_XSECURITYID: Result := 'Internet Explorer 8. Uma solicitação de redirecionamento foi bloqueada porque os SIDs não correspondem e BINDF2_DISABLE_HTTP_REDIRECT_XSECURITYID está definido nas opções de ligação';
    INET_E_CODE_DOWNLOAD_DECLINED: Result := 'O download do componente foi recusado pelo usuário, acione o suporte do serviço';
    INET_E_RESULT_DISPATCHED: Result := 'Conexão já foi encerrada';
    INET_E_CANNOT_REPLACE_SFP_FILE: Result := 'Não é possível substituir um arquivo protegido por SFP';
    INET_E_CODE_INSTALL_SUPPRESSED: Result := 'Internet Explorer 6 para Windows XP SP2 e posterior. O prompt Authenticode para instalar um controle ActiveX não foi mostrado porque a página restringe a instalação dos controles ActiveX. A causa comum é que a Barra de '+'Informações é exibida em vez do prompt do Authenticode';
    INET_E_CODE_INSTALL_BLOCKED_BY_HASH_POLICY: Result := 'Internet Explorer 6 para Windows XP SP2 e posterior. A instalação do controle ActiveX (conforme identificado pelo hash do arquivo criptográfico) foi proibida pela política de chave do registro';
    INET_E_DOWNLOAD_BLOCKED_BY_INPRIVATE: Result := 'Internet Explorer 8 e posterior. O download não foi permitido devido a uma sessão de navegação privada. A Navegação InPrivate impede que o Internet Explorer armazene dados sobre a sessão de navegação, como cookies, '+'arquivos temporários e histórico.';
    E_ABORT: Result := 'Operação abortada';
  else
    Result := 'Indefinido'
  end;
end;

procedure ConverterPngParaJpg(const pArquivoEntrada, pArquivoSaida: string);
var
  vPng: TPngImage;
  vJpg: TJPEGImage;
  vBmp: Vcl.Graphics.TBitmap;
begin
  vBmp := Vcl.Graphics.TBitmap.Create;
  try
   vPng := TPngImage.Create;
    try
      // 1. Carrega a imagem PNG
      vPng.LoadFromFile(pArquivoEntrada);

      // 2. Prepara o Bitmap intermediário
      vBmp.SetSize(vPng.Width, vPng.Height);

      // 3. Pinta o fundo do Bitmap de Branco (O passo crucial)
      vBmp.Canvas.Brush.Color := clWhite;
      vBmp.Canvas.FillRect(Rect(0, 0, vBmp.Width, vBmp.Height));

      // 4. Desenha o PNG sobre o fundo branco
      vBmp.Canvas.Draw(0, 0, vPng);
    finally
      FreeAndNil(vPng);
    end;

    vJpg := TJPEGImage.Create;
    try
      // 5. Atribui a imagem "achatada" ao objeto JPEG
      vJpg.Assign(vBmp);

      // (Opcional) Configura a qualidade/compressão (0 a 100)
      vJpg.CompressionQuality := 90;
      vJpg.Compress;

      // 6. Salva o arquivo final
      vJpg.SaveToFile(pArquivoSaida);
    finally
      FreeAndNil(vJpg);
    end;

    // 7. Remove o arquivo PNG original
    DeleteFile(pArquivoEntrada);
  finally
    FreeAndNil(vBmp);
  end;
end;

function ObterVersaoAplicacao(pPath: String): String;
var
  VerInfoSize, VerValueSize, Dummy : DWORD;
  VerInfo: Pointer;
  VerValue: PVSFixedFileInfo;
  V1, V2, V3, V4: Word;
begin
  try
    VerInfo := nil;
    VerInfoSize := 0;
    try
      VerInfoSize := GetFileVersionInfoSize(PChar(pPath), Dummy);
      GetMem(VerInfo, VerInfoSize);
      GetFileVersionInfo(PChar(pPath), 0, VerInfoSize, VerInfo);
      VerQueryValue(VerInfo, '\', Pointer(VerValue), VerValueSize);
      with VerValue^ do
      begin
        V1 := dwFileVersionMS shr 16;
        V2 := dwFileVersionMS and $FFFF;
        V3 := dwFileVersionLS shr 16;
        V4 := dwFileVersionLS and $FFFF;
      end;
      Result := IntToStr(V1)+'.'+IntToStr(V2)+'.'+FormatFloat('00', V3)+'.'+FormatFloat('00', V4);
    finally
      FreeMem(VerInfo, VerInfoSize);
    end;
  except
    Result := '';
  end;
end;

function ObterUsuarioWindows: String;
var
 lpBuffer: Array[0..20] of Char;
 nSize,
 vErro: DWord;
 vAchou: Boolean;
begin
  nSize := 120;
  vAchou := GetUserName(lpBuffer,nSize);
  if (vAchou) then
  begin
    Result := lpBuffer;
  end
  else
  begin
    vErro := GetLastError();
    Result := IntToStr(vErro);
  end;
end;

function ObterNomeMaquina: String;
var
  lpBuffer: Array[0..20] of Char;
  nSize,
  vErro: DWord;
  vAchou: Boolean;
begin
  nSize := 120;
  vAchou := GetComputerName(lpBuffer,nSize);
  if (vAchou) then
  begin
    Result := lpBuffer;
  end
  else
  begin
    vErro := GetLastError();
    Result := IntToStr(vErro);
  end;
end;

function GetIP: String;
var
 Name: AnsiString;
 WSAData: TWSAData;
 HostEnt: PHostEnt;
begin
  WSAStartup(2, WSAData);
  SetLength(Name, 255);
  Gethostname(PAnsiChar(Name), 255);
  SetLength(Name, AnsiStrings.StrLen(PAnsiChar(Name)));
  HostEnt := gethostbyname(PAnsiChar(Name));
  with HostEnt^  do
  begin
    Result := Format('%d.%d.%d.%d', [Byte(h_addr^[0]), Byte(h_addr^[1]), Byte(h_addr^[2]), Byte(h_addr^[3])]);
  end;
  WSACleanup;
end;

function Split(pDelimiter: Char; pValue: String; pLeft: Boolean = True): String;
var
  vListString: TStringList;
begin
  if pValue.IsEmpty then
    Exit('');

  vListString := TStringList.Create;
  try
    vListString.Clear;
    vListString.Delimiter       := pDelimiter;
    vListString.StrictDelimiter := True; // Requires D2006 or newer.
    vListString.DelimitedText   := pValue;

    if pLeft then
      Result := vListString[0].Trim
    else if vListString.Count > 1 then
      Result := vListString[1].Trim
    else
      Result := vListString[0].Trim;
  finally
    FreeAndNil(vListString);
  end;
end;

function GetEncodeBase64(const pValue: String): String;
var
  vBase64: TBase64Encoding;
begin
  vBase64 := TBase64Encoding.Create(0);
  try
    Result := vBase64.Encode(pValue + ' || ' + cKey);
  finally
    FreeAndNil(vBase64);
  end;
end;

function GetDecodeBase64(const pValue: String): String;
var
  vBase64: TNetEncoding;
  vDecode: String;
begin
  vBase64 := TNetEncoding.Create;
  try
    vDecode := vBase64.Base64.Decode(pvalue);
    Result := Split('|', vDecode);
  finally
    FreeAndNil(vBase64);
  end;
end;

function GetHashMD5String(const pValue: String): String;
begin
  Result := THashMD5.GetHashString(pValue);
end;

{ TJsonObjectHelper }

procedure TJsonObjectHelper.ClearAndFreeItems;
var
  vIx: Integer;
  vPar: TJSONPair;
begin
  if not Assigned(Self) then
    Exit;

  for vIx := Self.Count - 1 downto 0 do
  begin
    vPar := Self.Pairs[vIx];
    if (vPar.JsonValue is TJSONObject) then
      TJSONObject(vPar.JsonValue).ClearAndFreeItems;

    Self.RemovePair(vPar.JsonString.Value);
    vPar.Free;
  end;
end;

{ TJsonValueHelper }

procedure TJsonValueHelper.ClearAndFreeItems;
var
  vIx: Integer;
  vPar: TJSONPair;
  vObj: TJSONObject;
  procedure RemovePair(vObj: TJSONObject);
  var
    I: Integer;
  begin
    for I := vObj.Count - 1 downto 0 do
    begin
      vPar := vObj.Pairs[I];
      vObj.RemovePair(vPar.JsonString.value);
      vPar.Free;
    end;
  end;
begin
  if Self.ClassType = TJSONArray then
  begin
    for vIx := TJSONArray(Self).Count -1 downto 0 do
    begin
      vObj := TJSONArray(Self).Remove(vIx) as TJSONObject;
      RemovePair(vObj);
      if Assigned(vObj) then
        vObj.Free;
    end;
  end
  else
    RemovePair(TJSONObject(Self));
end;

end.
