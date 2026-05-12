unit Core.DataBase.RttiHelper;

interface

uses
  {Classes de Sistema}
  System.Rtti,
  System.SysUtils,
  {Classes de Negócio}
  Core.Entidades.CustomAttributes;


type
  TRttiPropertyHelper = class Helper for TRttiProperty
  public
    function Has<T: TCustomAttribute>: Boolean;
    function GetAttribute<T: TCustomAttribute>: T;
    function IsEnum: Boolean;
    function IsIgnore: Boolean;
    function IsDBField: Boolean;
    function FieldName: string; overload;
    function FieldName<T: TCustomAttribute>: String; overload;
    function DisplayName: string;
    function Sequence: String;
    function DBDateTime: String;
    function EnumName: string;
    function IsAutoInc: Boolean;
    function IsNotNull: Boolean;
    function IsSequence: Boolean;
    function IsDBDateTime: Boolean;
    function IsPrimaryKey: Boolean;
    function IsForeignKey: Boolean;
    function FormatMsg(const pMsg: String): String;
    function GetFKField(aInstance: TObject): TRttiProperty;
  end;

  TRttiTypeHelper = class Helper for TRttiType
  public
    function Has<T: TCustomAttribute>: Boolean;
    function IsTable: Boolean;
    function GetAttribute<T: TCustomAttribute>: T;
    function GetPropertyFromAttribute<T: DBField>(const pFieldName: string): TRttiProperty; overload;
  end;

  TRttiFieldHelper = class Helper for TRttiField
  public
    function Has<T: TCustomAttribute>: Boolean;
    function GetAttribute<T: TCustomAttribute>: T;
    function DisplayName: string;
    function FormatMsg(const pMsg: String): String;
  end;

implementation

{ TRttiPropertyHelper }

function TRttiPropertyHelper.DBDateTime: String;
begin
  Result := Name;

  if IsDBDateTime then
    Result := GetAttribute<Core.Entidades.CustomAttributes.DBDateTime>.Name;
end;

function TRttiPropertyHelper.DisplayName: string;
begin
  Result := Name;
  if Has<Display> then
    Result := GetAttribute<Display>.Name
end;

function TRttiPropertyHelper.EnumName: string;
begin
  Result := Name;

  if IsEnum then
    Result := GetAttribute<Enumerator>.Tipo;
end;

function TRttiPropertyHelper.FieldName: string;
begin
  Result := Name;
  if IsDBField then
    Result := GetAttribute<DBField>.Name;
end;

function TRttiPropertyHelper.FieldName<T>: String;
var
  vAtributo: TCustomAttribute;
begin
  Result := '';
  for vAtributo in GetAttributes do
  begin
    if vAtributo is T then
      Exit(Self.FieldName);
  end;
end;

function TRttiPropertyHelper.FormatMsg(const pMsg: String): String;
begin
  Result := Format(pMsg, [Self.DisplayName]);
end;

function TRttiPropertyHelper.GetAttribute<T>: T;
var
  vAtributo: TCustomAttribute;
begin
  Result := nil;
  for vAtributo in GetAttributes do
  begin
    if vAtributo is T then
      Exit((vAtributo as T));
  end;
end;

function TRttiPropertyHelper.GetFKField(aInstance: TObject): TRttiProperty;
var
  vCtx: TRttiContext;
  vTypRtti: TRttiType;
  vPrpRtti: TRttiProperty;
begin
  Result := nil;
  vCtx := TRttiContext.Create;
  try
    vTypRtti := vCtx.GetType(aInstance.ClassInfo);
    for vPrpRtti in vTypRtti.GetProperties do
    begin
      if vPrpRtti.IsPrimaryKey then
        Exit(vPrpRtti);
    end;
  finally
      vCtx.Free;
  end;
end;

function TRttiPropertyHelper.Has<T>: Boolean;
begin
  Result := GetAttribute<T> <> nil;
end;

function TRttiPropertyHelper.IsAutoInc: Boolean;
begin
  Result := Has<AutoInc>;
end;

function TRttiPropertyHelper.IsDBDateTime: Boolean;
begin
  Result := Has<Core.Entidades.CustomAttributes.DBDateTime>;
end;

function TRttiPropertyHelper.IsDBField: Boolean;
begin
  Result := Has<DBField>
end;

function TRttiPropertyHelper.IsEnum: Boolean;
begin
  Result := Has<Enumerator>;
end;

function TRttiPropertyHelper.IsForeignKey: Boolean;
begin
  Result := Has<FK>;
end;

function TRttiPropertyHelper.IsIgnore: Boolean;
begin
  Result := Has<Ignore>;
end;

function TRttiPropertyHelper.IsNotNull: Boolean;
begin
  Result := Has<NotNull>;
end;

function TRttiPropertyHelper.IsPrimaryKey: Boolean;
begin
  Result := Has<PK>;
end;

function TRttiPropertyHelper.Sequence: String;
begin
  Result := Name;

  if IsSequence then
    Result := GetAttribute<Seq>.Name;
end;

function TRttiPropertyHelper.IsSequence: Boolean;
begin
  Result := Has<Seq> ;
end;

{ TRttiTypeHelper }

function TRttiTypeHelper.GetAttribute<T>: T;
var
  vAtributo: TCustomAttribute;
begin
  Result := nil;
  for vAtributo in GetAttributes do
  begin
    if vAtributo is T then
      Exit((vAtributo as T));
  end;
end;

function TRttiTypeHelper.GetPropertyFromAttribute<T>(const pFieldName: string): TRttiProperty;
var
  RttiProp: TRttiProperty;
begin
  Result := nil;
  for RttiProp in GetProperties do
  begin
    if RttiProp.GetAttribute<T> = nil then
      Continue;

    if RttiProp.GetAttribute<DBField>.Name = pFieldName then
      Exit(RttiProp);
  end;
end;

function TRttiTypeHelper.Has<T>: Boolean;
begin
  Result := GetAttribute<T> <> nil;
end;

function TRttiTypeHelper.IsTable: Boolean;
begin
  Result := Has<Table>;
end;

{ TRttiFieldHelper }

function TRttiFieldHelper.DisplayName: string;
begin
  Result := Name;
  if Has<Display> then
    Result := GetAttribute<Display>.Name
end;

function TRttiFieldHelper.FormatMsg(const pMsg: String): String;
begin
  Result := Format(pMsg, [Self.DisplayName]);
end;

function TRttiFieldHelper.GetAttribute<T>: T;
var
  vAtributo: TCustomAttribute;
begin
  Result := nil;
  for vAtributo in GetAttributes do
  begin
    if vAtributo is T then
      Exit((vAtributo as T));
  end;
end;

function TRttiFieldHelper.Has<T>: Boolean;
begin
  Result := GetAttribute<T> <> nil;
end;

end.

