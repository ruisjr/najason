unit Core.DataBase.Rtti;

interface

uses
  {Classes de sistema}
   Data.Db
//  ,AdvEdit
//  ,Advcombo
  ,Vcl.Forms
  ,System.Rtti
  ,System.JSON
  ,Vcl.ExtCtrls
  ,System.TypInfo
  ,System.Classes
  ,System.SysUtils
  ,System.Variants
//  ,AdvOfficeButtons
  ,System.Generics.Collections
  {Classes de negócio}
  ,Core.DataBase.Types
  ,Core.DataBase.RttiHelper
  ,Core.DataBase.Interfaces
  ,Core.Entidades.CustomAttributes;

type
  EDataBaseRtti = Exception;

  TDataBaseRtti<T : class, constructor> = class(TInterfacedObject, IDataBaseRtti<T>)
  strict private
    function ValueIsNil(const pValue: TValue): Boolean;
  private
    FInstance : T;
    FModeInsert: Boolean;

    {Functions}
    function _CreateObjectByName(const AClassName: string): T;
    function _FloatFormat(pValue: String): Currency;
    function _BindValueToComponent(pComponent: TComponent; pValue : Variant): IDataBaseRtti<T>;
    function _BindValueToProperty(pEntity: T; pProperty: TRttiProperty; pValue : TValue): IDataBaseRtti<T>;
    function _GetRttiPropertyValue(pEntity: T; pPropertyName: String): Variant;
    function _GetComponentToValue(pComponent: TComponent): TValue;

    {Procedures}
    procedure _ApplyValueToChildEntity(FieldName: string; pObjChild: TObject; pField: TField);
  public
    {Construtores e Destrutores}
    constructor Create(pInstance: T);
    destructor Destroy; override;

    { Funções de classes }
    class function New(pInstance: T): IDataBaseRtti<T>;

    {Funções}
    function GetRttiProperty(pEntity: T; pPropertyName: String): TRttiProperty;
    function GetParameterFromPK: TDictionary<string, TValue>;

    function TableName(var pTableName: String): IDataBaseRtti<T>;
    function Sequence(var pSequence: String): IDataBaseRtti<T>;
    function ClassName(var pClassName: String): IDataBaseRtti<T>;
    function Fields(var pFields: String): IDataBaseRtti<T>;
    function FieldsInsert(var pFields: String): IDataBaseRtti<T>;
    function Param(var pParam: String): IDataBaseRtti<T>;
    function Where(var pWhere: String): IDataBaseRtti<T>;
    function Update(var pUpdate: String): IDataBaseRtti<T>;
    function Values(pInstance: T; var pValues: String): IDataBaseRtti<T>;

    function DataSetToEntity(pDataSet: TDataSet; out pEntity: T): IDataBaseRtti<T>;
    function DataSetToEntityList(pDataSet: TDataSet; var pList: TObjectList<T>): IDataBaseRtti<T>;
    function ApplyEntityChildToParent(var pEntity: T; pEntityChild: T; pFieldName: String): IDataBaseRtti<T>;

    function DictionaryFields(var pDictionary: TDictionary<string, variant>): IDataBaseRtti<T>;
    function DictionaryTypeFields(const pParameters: TDictionary<string, TValue>; var pDictionary: TDictionary<string, TFieldType>): IDataBaseRtti<T>; overload;
    function DictionaryTypeFields(var pDictionary: TDictionary<string, TFieldType>): IDataBaseRtti<T>; overload;
    function BindFormToEntity(pForm : TForm; var pEntity: T): IDataBaseRtti<T>;
    function BindEntityToForm(pForm : TForm; const pEntity: T): IDataBaseRtti<T>;
    function BindValueToProperty(var pEntity: T; pPropertyName: string; pValue: TValue): IDataBaseRtti<T>;

    function LoadObjectForeignKey(pEntity: T): TDictionary<String, TObject>;
  end;


implementation

Uses
  {Classes de Sistema}
   Vcl.Graphics
  ,Vcl.StdCtrls
  ,System.UITypes;

{ TDataBaseRtti<T> }

function TDataBaseRtti<T>.BindEntityToForm(pForm: TForm; const pEntity: T): IDataBaseRtti<T>;
var
  LTypRtti: TRttiType;
  LPrpRtti: TRttiField;
  LCtxRtti: TRttiContext;
begin
  Result := Self;

  LCtxRtti := TRttiContext.Create;
  try
    LTypRtti := LCtxRtti.GetType(pForm.ClassInfo);
    for LPrpRtti in LTypRtti.GetFields do
    begin
      if LPrpRtti.Has<Bind> then
        _BindValueToComponent(pForm.FindComponent(LPrpRtti.Name), _GetRttiPropertyValue(pEntity, LPrpRtti.GetAttribute<Bind>.Field));
    end;
  finally
    LCtxRtti.Free;
  end;
end;

function TDataBaseRtti<T>.BindFormToEntity(pForm: TForm; var pEntity: T): IDataBaseRtti<T>;
var
  LTypRtti: TRttiType;
  LPrpRtti: TRttiField;
  LCtxRtti: TRttiContext;
begin
  Result := Self;
  LCtxRtti := TRttiContext.Create;
  try
    LTypRtti := LCtxRtti.GetType(pForm.ClassInfo);
    for LPrpRtti in LTypRtti.GetFields do
    begin
      if LPrpRtti.Has<Bind> then
      begin
        _BindValueToProperty(pEntity, GetRttiProperty(pEntity, LPrpRtti.GetAttribute<Bind>.Field), _GetComponentToValue(pForm.FindComponent(LPrpRtti.Name)));
      end;
    end;
  finally
    LCtxRtti.Free;
  end;
end;

function TDataBaseRtti<T>.BindValueToProperty(var pEntity: T; pPropertyName: string; pValue: TValue): IDataBaseRtti<T>;
var
  LPropRtti: TRttiProperty;
begin
  Result := Self;
  LPropRtti := GetRttiProperty(pEntity, pPropertyName);
  LPropRtti.SetValue(Pointer(pEntity), pValue);
end;

function TDataBaseRtti<T>.ClassName(var pClassName: String): IDataBaseRtti<T>;
var
  LTypRtti: TRttiType;
  LCtxRtti: TRttiContext;
begin
  Result := Self;
  LCtxRtti := TRttiContext.Create;
  try
    LTypRtti := LCtxRtti.GetType(FInstance.ClassInfo);
    pClassName := Copy(LTypRtti.Name, 2, Length(LTypRtti.Name));
  finally
    LCtxRtti.Free;
  end;
end;

constructor TDataBaseRtti<T>.Create(pInstance: T);
begin
  FInstance := pInstance;
  FModeInsert := False;
end;

function TDataBaseRtti<T>._CreateObjectByName(const AClassName: string): T;
var
  LContext: TRttiContext;
  LType: TRttiInstanceType;
  LConstructor: TRttiMethod;
  LFullClassName: string;
begin
  Result := nil;

  if Pos('.', AClassName) = 0 then
    LFullClassName := FInstance.UnitName + '.' +AClassName
  else
    LFullClassName := AClassName;

  LContext := TRttiContext.Create;
  try
    LType := LContext.FindType(LFullClassName) as TRttiInstanceType;

    if Assigned(LType) then
    begin
      LConstructor := LType.GetMethod('Create');
      if Assigned(LConstructor) then
      begin
        Result := LConstructor.Invoke(LType.MetaclassType, []).AsType<T>;
      end
      else
        raise Exception.Create('Construtor "Create" sem parâmetros não encontrado para ' + LFullClassName);
    end
    else
      raise Exception.Create('Classe não encontrada: ' + LFullClassName);

  finally
    LContext.Free;
  end;
end;

function TDataBaseRtti<T>.DataSetToEntity(pDataSet: TDataSet; out pEntity: T): IDataBaseRtti<T>;
var
  LValue: TValue;
  LField : TField;
  LCtxRtti: TRttiContext;
  LTypRtti: TRttiType;
  LprpRtti: TRttiProperty;
  LMemoryStream: TMemoryStream;
  LRttiInstance: TRttiInstanceType;
begin
  Result := Self;
  if not Assigned(pEntity) then
    pEntity := _CreateObjectByName(FInstance.ClassType.ClassName);

  pDataSet.First;
  while not pDataSet.Eof do
  begin
    LCtxRtti := TRttiContext.Create;
    try
      for LField in pDataSet.Fields do
      begin
        LTypRtti := LCtxRtti.GetType(FInstance.Classtype);
        for LprpRtti in LTypRtti.GetProperties do
        begin
          if LowerCase(LprpRtti.FieldName) = LowerCase(LField.DisplayName) then
          begin
            case LprpRtti.PropertyType.TypeKind of
              tkUnknown, tkString, tkWChar, tkLString, tkWString, tkUString:
                LValue := LField.AsString;
              tkInteger, tkInt64:
                LValue := LField.AsInteger;
              tkChar: ;
              tkEnumeration:
              begin
                if (LprpRtti.GetValue(Pointer(pEntity)).TypeInfo = TypeInfo(Boolean)) then
                  LValue := LField.AsBoolean
                else
                  LValue := LField.AsString;
              end;
              tkFloat:
              begin
                if ((LprpRtti.GetValue(Pointer(pEntity)).TypeInfo = TypeInfo(TDate)) or
                    (LprpRtti.GetValue(Pointer(pEntity)).TypeInfo = TypeInfo(TDateTime))) then
                  LValue := LField.AsDateTime
                else
                  LValue := LField.AsFloat;
              end;
              tkSet: ;
              tkClass:
              begin
                if LprpRtti.IsForeignKey then
                begin
                  if LprpRtti.PropertyType.IsInstance then
                  begin
                    LValue := LprpRtti.GetValue(Pointer(pEntity));

                    if (LValue.AsObject = nil) then
                    begin
                      LRttiInstance := LprpRtti.PropertyType.AsInstance;
                      LValue := LRttiInstance.MetaclassType.Create;
                    end;
                    //Campo(Obj), LprpRtti.FieldName, Valor
                    {Aplicar o valor da primary Key no campo respectivo para PK}
                    Self._ApplyValueToChildEntity(LprpRtti.FieldName, LValue.AsObject, LField);
                  end;
                end
                else
                begin
                  if LprpRtti.GetValue(Pointer(pEntity)).TypeInfo = TypeInfo(TJSONObject) then
                  begin
                    LValue := TJSONObject(TJSONObject.ParseJSONValue(LField.AsString));
                    LprpRtti.SetValue(Pointer(pEntity), LValue);
                  end
                  else if LprpRtti.GetValue(Pointer(pEntity)).TypeInfo = TypeInfo(TJSONArray) then
                  begin
                    LValue := TJSONArray(TJSONObject.ParseJSONValue(LField.AsString));
                    LprpRtti.SetValue(Pointer(pEntity), LValue);
                  end
                  else if (LprpRtti.GetValue(Pointer(pEntity)).TypeInfo = TypeInfo(TMemoryStream)) then
                  begin
                    TBlobField(LField).SaveToStream(LMemoryStream);
                    if LMemoryStream <> nil then
                    begin
                      LMemoryStream.Position := 0;
                      LprpRtti.SetValue(Pointer(pEntity), LMemoryStream);
                    end;
                  end;
                end;
              end;
              tkMethod: ;
              tkVariant: ;
              tkArray: ;
              tkRecord: ;
              tkInterface: ;
              tkDynArray: ;
              tkClassRef: ;
              tkPointer: ;
              tkProcedure: ;
            end;

            LprpRtti.SetValue(Pointer(pEntity), LValue);
          end;
        end;
      end;
    finally
      LCtxRtti.Free;
    end;
    pDataSet.Next;
  end;
  pDataSet.First;
end;

function TDataBaseRtti<T>.ApplyEntityChildToParent(var pEntity: T; pEntityChild: T; pFieldName: String): IDataBaseRtti<T>;
var
  LCtxRtti: TRttiContext;
  LTypRtti: TRttiType;
  LprpRtti: TRttiProperty;
begin
  Result := Self;

  LCtxRtti := TRttiContext.Create;
  try
    LTypRtti := LCtxRtti.GetType(pEntity.Classtype);
    for LprpRtti in LTypRtti.GetProperties do
    begin
      case LprpRtti.PropertyType.TypeKind of
        tkClass:
        begin
          if LprpRtti.IsForeignKey then
          begin
            if (LprpRtti.FieldName.Equals(pFieldName)) then
            begin
              if LprpRtti.PropertyType.IsInstance then
                LprpRtti.SetValue(Pointer(pEntity), TObject(pEntityChild));
            end;
          end;
        end;
        tkMethod: ;
        tkVariant: ;
        tkArray: ;
        tkRecord: ;
        tkInterface: ;
        tkDynArray: ;
        tkClassRef: ;
        tkPointer: ;
        tkProcedure: ;
      end;
    end;
  finally
    LCtxRtti.Free;
  end;
end;

function TDataBaseRtti<T>.DataSetToEntityList(pDataSet: TDataSet; var pList: TObjectList<T>): IDataBaseRtti<T>;
var
  vInfo: PTypeInfo;
  vValue: TValue;
  vField: TField;
  vCtxRtti: TRttiContext;
  VPrpRtti: TRttiProperty;
begin
  Result := Self;
  pList.Clear;
  while not pDataSet.Eof do
  begin
    vInfo := System.TypeInfo(T);
    pList.Add(T.Create);
    vCtxRtti := TRttiContext.Create;
    try
      for vField in pDataSet.Fields do
      begin
        for VPrpRtti in vCtxRtti.GetType(vInfo).GetProperties do
        begin
          if LowerCase(vPrpRtti.FieldName) = LowerCase(vField.FieldName) then
          begin
            vField.DisplayLabel := VPrpRtti.DisplayName;
            case VPrpRtti.PropertyType.TypeKind of
              tkUnknown, tkString, tkWChar, tkLString, tkWString, tkUString:
                vValue := vField.AsString;
              tkInteger, tkInt64:
                vValue := vField.AsInteger;
              tkChar: ;
              tkEnumeration:
              begin
                if (VPrpRtti.GetValue(vInfo).TypeInfo.Name = 'Boolean') then
                  vValue := vField.AsBoolean
                else
                  vValue := vField.AsString;
              end;
              tkFloat:
                vValue := vField.AsFloat;
              tkSet: ;
              tkClass: ;
              tkMethod: ;
              tkVariant: ;
              tkArray: ;
              tkRecord: ;
              tkInterface: ;
              tkDynArray: ;
              tkClassRef: ;
              tkPointer: ;
              tkProcedure: ;
            end;
            if VPrpRtti.PropertyType.TypeKind <> tkClass then
              VPrpRtti.SetValue(Pointer(pList[Pred(pList.Count)]), vValue);
          end;
        end;
      end;
    finally
      vCtxRtti.Free;
    end;
    pDataSet.Next;
  end;
  pDataSet.Close;
end;

destructor TDataBaseRtti<T>.Destroy;
begin

  inherited;
end;

function TDataBaseRtti<T>.DictionaryFields(var pDictionary: TDictionary<string, variant>): IDataBaseRtti<T>;
var
  Ptr: Pointer;
  LObj: TObject;
  LTypRtti: TRttiType;
  LCtxRtti: TRttiContext;
  LPrpRtti,
  LPrpFKType: TRttiProperty;
  LVariant: Variant;
  LMStream: TMemoryStream;
begin
  Result  := Self;
  LCtxRtti := TRttiContext.Create;
  try
    LTypRtti := LCtxRtti.GetType(FInstance.classInfo);
    for LPrpRtti in LTypRtti.GetProperties do
    begin
      if not LPrpRtti.IsNotNull and LPrpRtti.IsIgnore then
        Continue;

      case LPrpRtti.PropertyType.TypeKind of
        tkInteger, tkInt64:
        begin
          if LPrpRtti.IsPrimaryKey or LPrpRtti.IsForeignKey then
          begin
            if LPrpRtti.IsSequence and FModeInsert and
               (LPrpRtti.GetValue(Pointer(FInstance)).AsVariant <> null) then
              continue
            else
              pDictionary.Add(LPrpRtti.FieldName, LPrpRtti.GetValue(Pointer(FInstance)).AsInteger);
          end
          else
            pDictionary.Add(LPrpRtti.FieldName, LPrpRtti.GetValue(Pointer(FInstance)).AsInteger);
          end;
        tkFloat:
        begin
          if (LPrpRtti.GetValue(Pointer(FInstance)).TypeInfo = TypeInfo(TDateTime)) or
             (LPrpRtti.GetValue(Pointer(FInstance)).TypeInfo = TypeInfo(TDate)) or
             (LPrpRtti.GetValue(Pointer(FInstance)).TypeInfo = TypeInfo(TTime)) then
          begin
            if LPrpRtti.GetValue(Pointer(FInstance)).AsExtended = 0 then
                pDictionary.Add(LPrpRtti.FieldName, Null)
            else
            begin
              if LPrpRtti.GetValue(Pointer(FInstance)).TypeInfo = TypeInfo(TDate) then
                pDictionary.Add(LPrpRtti.FieldName, StrToDate(LPrpRtti.GetValue(Pointer(FInstance)).ToString))
              else if LPrpRtti.GetValue(Pointer(FInstance)).TypeInfo = TypeInfo(TTime) then
                pDictionary.Add(LPrpRtti.FieldName, StrToTime(LPrpRtti.GetValue(Pointer(FInstance)).ToString))
              else
                pDictionary.Add(LPrpRtti.FieldName, StrToDateTime(LPrpRtti.GetValue(Pointer(FInstance)).ToString ));
            end;
          end
          else
              pDictionary.Add(LPrpRtti.FieldName, _FloatFormat(LPrpRtti.GetValue(Pointer(FInstance)).ToString));
        end;
        tkWChar, tkLString, tkWString, tkUString, tkString:
          pDictionary.Add(LPrpRtti.FieldName, LPrpRtti.GetValue(Pointer(FInstance)).AsString);
        tkVariant:
          pDictionary.Add(LPrpRtti.FieldName, LPrpRtti.GetValue(Pointer(FInstance)).AsVariant);
        tkClass:
        begin
          if LPrpRtti.IsForeignKey then
          begin
            if LPrpRtti.GetValue(Pointer(FInstance)).AsInteger = 0 then
              Continue;

            LObj := LPrpRtti.GetValue(Pointer(FInstance)).AsObject;
            LPrpFKType := LPrpRtti.GetFKField(LObj);

            if (LPrpFKType <> nil) and (LPrpFKType.getValue(LObj).asInteger = 0) then
              Continue;

            if (LPrpFKType <> nil) then
              pDictionary.Add(LPrpRtti.fieldname, LPrpFKType.getValue(LObj).asinteger)
          end
          else
          begin
            if LPrpRtti.PropertyType.Handle = TypeInfo(TJSONArray) then
              pDictionary.Add(LPrpRtti.FieldName, TJsonArray(LPrpRtti.GetValue(Pointer(FInstance)).AsObject).ToJSON)
            else if LPrpRtti.PropertyType.Handle = TypeInfo(TJSONObject) then
              pDictionary.Add(LPrpRtti.FieldName, TJSONObject(LPrpRtti.GetValue(Pointer(FInstance)).AsObject).ToJSON)
            else if LPrpRtti.PropertyType.Handle = TypeInfo(TMemoryStream) then
            begin
              LMStream := TMemoryStream(LPrpRtti.GetValue(Pointer(FInstance)).AsObject);
              LMStream.Position := 0;
              LVariant := VarArrayCreate([0, LMStream.Size - 1], varByte);
              Ptr := VarArrayLock(LVariant);
              try
                LMStream.Read(Ptr^, LMStream.Size);
              finally
                VarArrayUnlock(LVariant);
              end;

              pDictionary.Add(LPrpRtti.FieldName, LVariant);
            end;
          end;
        end;
        tkEnumeration:
        begin
          if (LPrpRtti.GetValue(Pointer(FInstance)).TypeInfo.Name = 'Boolean') then
            pDictionary.Add(LPrpRtti.fieldname, LPrpRtti.GetValue(Pointer(FInstance)).AsBoolean)
        end
      else
        pDictionary.Add(LPrpRtti.FieldName, LPrpRtti.GetValue(Pointer(FInstance)).AsString);
      end;
    end;
  finally
    LCtxRtti.Free;
  end;
end;

function TDataBaseRtti<T>.DictionaryTypeFields(const pParameters: TDictionary<string, TValue>; var pDictionary: TDictionary<string, TFieldType>): IDataBaseRtti<T>;
var
  LKey: String;
begin
  Result := Self;
  for LKey in pParameters.Keys do
  begin
    case pParameters.Items[LKey].Kind of
      tkInteger, tkInt64:
        pDictionary.Add(LKey, TFieldType.ftInteger);
      tkFloat:
      begin
        if ((pParameters.Items[LKey].TypeInfo = TypeInfo(TDateTime)) or pParameters.Items[LKey].IsType<TDateTime>) then
          pDictionary.Add(LKey, TFieldType.ftDateTime)
        else if ((pParameters.Items[LKey].TypeInfo = TypeInfo(TDate)) or pParameters.Items[LKey].IsType<TDate>) then
          pDictionary.Add(LKey, TFieldType.ftDate)
        else if ((pParameters.Items[LKey].TypeInfo = TypeInfo(TTime)) or pParameters.Items[LKey].IsType<TTime>) then
          pDictionary.Add(LKey, TFieldType.ftTime)
        else
          pDictionary.Add(LKey, TFieldType.ftFloat)
      end;
      tkWChar, tkLString, tkWString, tkUString:
        pDictionary.Add(LKey, TFieldType.ftString);
      tkEnumeration:
      begin
        if (pParameters.Items[LKey].TypeInfo.Name = 'Boolean') then
          pDictionary.Add(LKey, TFieldType.ftBoolean);
      end;
    end;
  end;
end;

function TDataBaseRtti<T>.DictionaryTypeFields(var pDictionary: TDictionary<string, TFieldType>): IDataBaseRtti<T>;
var
  LCtxRtti: TRttiContext;
  LTypRtti: TRttiType;
  LPrpRtti: TRttiProperty;
begin
  Result := Self;
  LCtxRtti := TRttiContext.Create;
  try
    LTypRtti := LCtxRtti.GetType(FInstance.ClassInfo);
    for LPrpRtti in LTypRtti.GetProperties do
    begin
      if not LPrpRtti.IsNotNull and LPrpRtti.IsIgnore then
        Continue;

      if ValueIsNil(LPrpRtti.GetValue(Pointer(FInstance))) then
      Continue;

      case LPrpRtti.PropertyType.TypeKind of
        tkInteger, tkInt64:
          pDictionary.Add(LPrpRtti.FieldName, TFieldType.ftInteger);
        tkFloat:
        begin
          if LPrpRtti.GetValue(Pointer(FInstance)).TypeInfo = TypeInfo(TDateTime) then
              pDictionary.Add(LPrpRtti.FieldName, TFieldType.ftDateTime)
          else if LPrpRtti.GetValue(Pointer(FInstance)).TypeInfo = TypeInfo(TDate) then
              pDictionary.Add(LPrpRtti.FieldName, TFieldType.ftDate)
          else if LPrpRtti.GetValue(Pointer(FInstance)).TypeInfo = TypeInfo(TTime) then
              pDictionary.Add(LPrpRtti.FieldName, TFieldType.ftTime)
          else
              pDictionary.Add(LPrpRtti.FieldName, TFieldType.ftFloat)
        end;
        tkWChar, tkLString, tkWString, tkUString:
          pDictionary.Add(LPrpRtti.FieldName, TFieldType.ftString);
        tkEnumeration:
        begin
          if (LPrpRtti.GetValue(Pointer(FInstance)).TypeInfo = TypeInfo(Boolean)) then
            pDictionary.Add(LPrpRtti.FieldName, TFieldType.ftBoolean);
        end;
        tkClass:
        begin
          if (LPrpRtti.PropertyType.Handle = TypeInfo(TJSONArray)) or (LPrpRtti.PropertyType.Handle = TypeInfo(TJSONObject)) then
            pDictionary.Add(LPrpRtti.FieldName, TFieldType.ftOraClob)
          else if (LPrpRtti.PropertyType.Handle = TypeInfo(TMemoryStream)) then
            pDictionary.Add(LPrpRtti.FieldName, TFieldType.ftBlob)
        end;
      end;
    end;
  finally
    LCtxRtti.Free;
  end;
end;

function TDataBaseRtti<T>.Fields(var pFields: String): IDataBaseRtti<T>;
var
  LCtxRtti : TRttiContext;
  LTypRtti : TRttiType;
  LPrpRtti : TRttiProperty;
begin
  Result   := Self;
  LCtxRtti := TRttiContext.Create;
  try
    LTypRtti := LCtxRtti.GetType(FInstance.ClassInfo);
    for LPrpRtti in LTypRtti.GetProperties do
    begin
      if not LPrpRtti.IsIgnore then
        pFields := pFields + LPrpRtti.FieldName + ', ';
    end;
  finally
    pFields := Copy(pFields, 0, Length(pFields) - 2) + ' ';
    LCtxRtti.Free;
  end;
end;

function TDataBaseRtti<T>.FieldsInsert(var pFields: String): IDataBaseRtti<T>;
var
  LObj: TObject;
  LCtxRtti: TRttiContext;
  LTypRtti: TRttiType;
  LPrpRtti,
  LPrpFKType: TRttiProperty;
begin
  Result   := Self;

  FModeInsert := True;
  LCtxRtti    := TRttiContext.Create;
  try
    LTypRtti := LCtxRtti.GetType(FInstance.ClassInfo);
    for LPrpRtti in LTypRtti.GetProperties do
    begin
//      if vPrpRtti.IsAutoInc then
//        Continue;

      if LPrpRtti.IsIgnore then
        Continue;

      if LPrpRtti.IsForeignKey then
      begin
        begin
          if LPrpRtti.GetValue(Pointer(FInstance)).IsObject then
          begin
            LObj := LPrpRtti.GetValue(Pointer(FInstance)).AsObject;
            LPrpFKType := LPrpRtti.GetFKField(LObj);
            if LPrpFKType.getValue(LObj).asinteger = 0 then
              Continue;
          end
          else
          begin
            if LPrpRtti.GetValue(Pointer(FInstance)).AsInteger = 0 then
              Continue;
          end;
        end;
      end;
      pFields := pFields + LPrpRtti.FieldName + ', ';
    end;
  finally
    pFields := Copy(pFields, 0, Length(pFields) - 2) + ' ';
    LCtxRtti.Free;
  end;
end;

function TDataBaseRtti<T>.ValueIsNil(const pValue: TValue): Boolean;
begin
  Result := False;
  case pValue.Kind of
    tkString, tkChar, tkWChar,
    tkLString, tkWString, tkUString:
      Result := Pointer(pValue.AsString) = nil;
    tkInteger, tkInt64:
      Result := Pointer(pValue.AsInteger) = nil;
    tkFloat:
    begin
      if pValue.TypeInfo = TypeInfo(TDateTime) then
        Result := Pointer(Trunc(pValue.asExtended)) = nil;
    end;
    tkClass:
      Result := Pointer(pValue.AsObject) = nil
  else
    Result := True;
  end;
end;

class function TDataBaseRtti<T>.New(pInstance: T): IDataBaseRtti<T>;
begin
  Result := Self.Create(pInstance);
end;

function TDataBaseRtti<T>.Param(var pParam: String): IDataBaseRtti<T>;
var
  LObj      : TObject;
  LCtxRtti  : TRttiContext;
  LTypRtti  : TRttiType;
  LPrpRtti,
  LPrpFKType: TRttiProperty;
begin
  Result := Self;

  LCtxRtti := TRttiContext.Create;
  try
    LTypRtti := LCtxRtti.GetType(FInstance.ClassInfo);
    for LPrpRtti in LTypRtti.GetProperties do
    begin
      if LPrpRtti.IsIgnore then
        Continue;

//      if vPrpRtti.IsAutoInc then
//        Continue;

      if FModeInsert         and
         LPrpRtti.IsSequence then
      begin
        if (LPrpRtti.GetValue(Pointer(FInstance)).AsVariant <> null) then
          pParam := pParam + Format(':%s,', [LPrpRtti.FieldName])
        else
          pParam := pParam + Format('nextval(%s), ', [QuotedStr(LPrpRtti.Sequence)]);
        Continue;
      end;

      if LPrpRtti.IsEnum then
      begin
        pParam := pParam + ':' + LPrpRtti.FieldName + '::' + LPrpRtti.EnumName + ', ';
        Continue;
      end;

      if LPrpRtti.IsForeignKey then
      begin
        begin
          if LPrpRtti.GetValue(Pointer(FInstance)).isobject then
          begin
            LObj := LPrpRtti.GetValue(Pointer(FInstance)).AsObject;
            LPrpFKType := LPrpRtti.GetFKField(LObj);
            if LPrpFKType.getValue(LObj).asinteger = 0 then
                Continue;
          end
          else
          begin
            if LPrpRtti.GetValue(Pointer(FInstance)).AsInteger = 0 then
              Continue;
          end;
        end;
      end;
      pParam  := pParam + ':' + LPrpRtti.FieldName + ', ';
    end;
  finally
    pParam := Copy(pParam, 0, Length(pParam) - 2) + ' ';
    LCtxRtti.Free;
  end;
end;

function TDataBaseRtti<T>.Sequence(var pSequence: String): IDataBaseRtti<T>;
var
  LTypRtti: TRttiType;
  LCtxRtti: TRttiContext;
begin
  Result := Self;
  LCtxRtti := TRttiContext.Create;
  try
    LTypRtti := LCtxRtti.GetType(FInstance.ClassInfo);
    if LTypRtti.Has<Seq> then
      pSequence := LTypRtti.GetAttribute<Seq>.Name;
  finally
    LCtxRtti.Free;
  end;
end;

function TDataBaseRtti<T>.TableName(var pTableName: String): IDataBaseRtti<T>;
var
  LTypRtti: TRttiType;
  LCtxRtti: TRttiContext;
begin
  Result   := Self;
  LCtxRtti := TRttiContext.Create;
  try
    LTypRtti := LCtxRtti.GetType(FInstance.ClassInfo);
    if LTypRtti.Has<Table> then
      pTableName := LTypRtti.GetAttribute<Table>.Name;
  finally
    LCtxRtti.Free;
  end;
end;

function TDataBaseRtti<T>.Update(var pUpdate: String): IDataBaseRtti<T>;
var
  LValue : TValue;
  LTypRtti : TRttiType;
  LCtxRtti : TRttiContext;
  LPrpRtti : TRttiProperty;
begin
  Result   := Self;
  LCtxRtti := TRttiContext.Create;
  try
    LTypRtti := LCtxRtti.GetType(FInstance.ClassInfo);

    for LPrpRtti in LTypRtti.GetProperties do
    begin
      LValue := LPrpRtti.GetValue(Pointer(FInstance));

      if LPrpRtti.IsIgnore then
        Continue;

      if LPrpRtti.IsAutoInc then
        Continue;

      if (not ValueIsNil(LValue)) then
      begin
        if LPrpRtti.IsEnum then
        begin
          pUpdate := pUpdate + LPrpRtti.FieldName + ' = :' + LPrpRtti.FieldName + '::' + LPrpRtti.EnumName + ', ';
          Continue;
        end;
        pUpdate := pUpdate + LPrpRtti.FieldName + ' = :' + LPrpRtti.FieldName + ', ';
      end;
    end;
  finally
    pUpdate := Copy(pUpdate, 0, Length(pUpdate) - 2) + ' ';
    LCtxRtti.Free;
  end;
end;

function TDataBaseRtti<T>.Values(pInstance: T; var pValues: String): IDataBaseRtti<T>;
var
  LCtxRtti: TRttiContext;
  LTypRtti: TRttiType;
  LPrpRtti: TRttiProperty;
begin
  Result   := Self;
  LCtxRtti := TRttiContext.Create;
  try
    LTypRtti := LCtxRtti.GetType(FInstance.ClassInfo);
    for LPrpRtti in LTypRtti.GetProperties do
    begin
      if LPrpRtti.IsIgnore then
        Continue;

//      if vPrpRtti.IsAutoInc then
//        Continue;
      if LPrpRtti.IsSequence then
      begin
        pValues := pValues + Format('nextval(%s), ', [QuotedStr(LPrpRtti.Sequence)]);
        Continue;
      end;

      pValues  := pValues + LPrpRtti.FieldName + '=' + LPrpRtti.GetValue(Pointer(pInstance)).AsString + ', ';
    end;
  finally
    pValues := Copy(pValues, 0, Length(pValues) - 2) + ' ';
    LCtxRtti.Free;
  end;
end;

function TDataBaseRtti<T>.Where(var pWhere: String): IDataBaseRtti<T>;
var
  LValue: TValue;
  LTypRtti: TRttiType;
  LCtxRtti: TRttiContext;
  LPrpRtti: TRttiProperty;
begin
  Result   := Self;
  LCtxRtti := TRttiContext.Create;
  try
    LTypRtti := LCtxRtti.GetType(FInstance.ClassInfo);
    for LPrpRtti in LTypRtti.GetProperties do
    begin
      LValue := LPrpRtti.GetValue(Pointer(FInstance));
      if LPrpRtti.IsPrimaryKey then
      begin
        if (LPrpRtti.IsEnum) then
          pWhere := pWhere + LPrpRtti.FieldName + ' = :' + LPrpRtti.FieldName + '::' + LPrpRtti.EnumName + ' AND '
        else
          if (not ValueIsNil(LValue)) then
            pWhere := pWhere + LPrpRtti.FieldName + ' = :' + LPrpRtti.FieldName + ' AND ';
      end
      else
      begin
        if (not ValueIsNil(LValue)) then
        begin
          if (LPrpRtti.IsEnum) then
            pWhere := pWhere + LPrpRtti.FieldName + ' = :' + LPrpRtti.FieldName + '::' + LPrpRtti.EnumName + ' AND '
          else
            pWhere := pWhere + LPrpRtti.FieldName + ' = :' + LPrpRtti.FieldName + ' AND ';
        end;
      end;
    end;
  finally
    pWhere := Copy(pWhere, 0, Length(pWhere) - 4) + ' ';
    LCtxRtti.Free;
  end;
end;

procedure TDataBaseRtti<T>._ApplyValueToChildEntity(FieldName: string; pObjChild: TObject; pField: TField);
var
  LTypRtti: TRttiType;
  LPrpRtti: TRttiProperty;
  LCtxRtti: TRttiContext;
begin
  LCtxRtti := TRttiContext.Create;
  try
    LTypRtti := LCtxRtti.GetType(pObjChild.Classtype);
    for LPrpRtti in LTypRtti.GetProperties do
    begin
      if LPrpRtti.IsPrimaryKey then
      begin
        case LPrpRtti.PropertyType.TypeKind of
         tkUnknown, tkString, tkWChar, tkLString, tkWString, tkUString:
          LPrpRtti.SetValue(Pointer(pObjChild), pField.AsString);
         tkInteger, tkInt64:
           LPrpRtti.SetValue(Pointer(pObjChild), pField.AsInteger);
         tkFloat:
          LPrpRtti.SetValue(Pointer(pObjChild), pField.AsFloat);
        end;
      end;
    end;
  finally
    LCtxRtti.Free;
  end;
end;

function TDataBaseRtti<T>._BindValueToComponent(pComponent: TComponent; pValue: Variant): IDataBaseRtti<T>;
begin
  if VarIsNull(pValue) then
      exit;
   {
  if pComponent is TAdvEdit then
      (pComponent as TAdvEdit).Text := pValue;

  if pComponent is TAdvComboBox then
      (pComponent as TAdvComboBox).ItemIndex := (pComponent as TAdvComboBox).Items.IndexOf(pValue);

  if pComponent is TRadioGroup then
      (pComponent as TRadioGroup).ItemIndex := (pComponent as TRadioGroup).Items.IndexOf(aValue);

  if pComponent is TShape then
      (pComponent as TShape).Brush.Color := aValue;

  //DateControls
  if pComponent is TAdvDateTimePicker then
      (pComponent as TAdvDateTimePicker).Date := aValue;

  if pComponent is TDateEdit then
      (pComponent as TDateEdit).Date := aValue;

  if pComponent is TAdvOfficeCheckBox then
      (pComponent as TAdvOfficeCheckBox).Checked := aValue;
      (pComponent as TAdvOfficeCheckBox).IsChecked := aValue;

  if pComponent is TTrackBar then
      (pComponent as TTrackBar).Position := aValue;
      }
end;

function TDataBaseRtti<T>._BindValueToProperty(pEntity: T; pProperty: TRttiProperty; pValue: TValue): IDataBaseRtti<T>;
begin
  case pProperty.PropertyType.TypeKind of
    tkUnknown: ;
    tkInteger:
      pProperty.SetValue(Pointer(pEntity), StrToInt(pValue.ToString));
    tkChar: ;
    tkEnumeration: ;
    tkFloat:
    begin
      if (pValue.TypeInfo    = TypeInfo(TDate))
         or (pValue.TypeInfo = TypeInfo(TTime))
         or (pValue.TypeInfo = TypeInfo(TDateTime)) then
      begin
        pProperty.SetValue(Pointer(pEntity), StrToDateTime(pValue.ToString))
      end
      else
        pProperty.SetValue(Pointer(pEntity), StrToFloat(pValue.ToString));
    end;
    tkSet: ;
    tkClass: ;
    tkMethod: ;
    tkString, tkWChar, tkLString, tkWString, tkVariant, tkUString:
      pProperty.SetValue(Pointer(pEntity), pValue);
    tkArray: ;
    tkRecord: ;
    tkInterface: ;
    tkInt64:
      pProperty.SetValue(Pointer(pEntity), pValue.Cast<Int64>);
    tkDynArray: ;
    tkClassRef: ;
    tkPointer: ;
    tkProcedure: ;
  else
    pProperty.SetValue(Pointer(pEntity), pValue);
  end;
end;

function TDataBaseRtti<T>._FloatFormat(pValue: String): Currency;
begin
  while Pos('.', pValue) > 0 do
    delete(pValue,Pos('.', pValue),1);

  Result := StrToCurr(pValue);
end;

function TDataBaseRtti<T>._GetComponentToValue(pComponent: TComponent): TValue;
begin
  if pComponent is TEdit then
    Result := TValue.FromVariant((pComponent as TEdit).Text);

//  if pComponent is TAdvEdit then
//    Result := TValue.FromVariant((pComponent as TAdvEdit).Text);

//  if pComponent is TAdvComboBox then
//    Result := TValue.FromVariant((pComponent as TAdvComboBox).Items[(pComponent as TAdvComboBox).ItemIndex]);

  if pComponent is TRadioGroup then
    Result := TValue.FromVariant((pComponent as TRadioGroup).Items[(pComponent as TRadioGroup).ItemIndex]);

  if pComponent is TShape then
    Result := TValue.FromVariant((pComponent as TShape).Brush.Color);

//  if pComponent is TAdvOfficeCheckBox then
//    Result := TValue.FromVariant((pComponent as TAdvOfficeCheckBox).Checked);

//  if pComponent is TTrackBar then
//    Result := TValue.FromVariant((pComponent as TTrackBar).Position);

//  if pComponent is TAdvDateTimePicker then
//    Result := TValue.FromVariant((pComponent as TAdvDateTimePicker).DateTime);

//  if pComponent is TDateEdit then
//    Result := TValue.FromVariant((pComponent as TDateEdit).DateTime);
end;

function TDataBaseRtti<T>.GetParameterFromPK: TDictionary<string, TValue>;
var
  LValue: TValue;
  LCtxRtti: TRttiContext;
  LTypRtti: TRttiType;
  LPrpRtti: TRttiProperty;
  LRttiInstance: TRttiInstanceType;
begin
  Result := TDictionary<string, TValue>.Create;

  LCtxRtti := TRttiContext.Create;
  try
    LTypRtti := LCtxRtti.GetType(FInstance.ClassInfo);
    for LPrpRtti in LTypRtti.GetProperties do
    begin
      if LPrpRtti.IsPrimaryKey then
      begin
        Result.AddOrSetValue(LPrpRtti.FieldName, LPrpRtti.GetValue(TObject(FInstance)));
        Exit(Result);
      end;
    end;
  finally
    LCtxRtti.Free;
  end;
end;

function TDataBaseRtti<T>.GetRttiProperty(pEntity: T; pPropertyName: String): TRttiProperty;
var
  LTypRttiEntity: TRttiType;
  LCtxRttiEntity: TRttiContext;
begin
  LCtxRttiEntity := TRttiContext.Create;
  try
    LTypRttiEntity := LCtxRttiEntity.GetType(pEntity.ClassInfo);
    Result := LTypRttiEntity.GetProperty(pPropertyName);

    if not Assigned(Result) then
      Result := LTypRttiEntity.GetPropertyFromAttribute<DBField>(pPropertyName);

    if not Assigned(Result) then
      raise EDataBaseRtti.Create('Property ' + pPropertyName + ' not found!');
  finally
    LCtxRttiEntity.Free;
  end;
end;

function TDataBaseRtti<T>.LoadObjectForeignKey(pEntity: T): TDictionary<String, TObject>;
var
  LValue: TValue;
  LCtxRtti: TRttiContext;
  LTypRtti: TRttiType;
  LprpRtti: TRttiProperty;
  LRttiInstance: TRttiInstanceType;
begin
  Result := TDictionary<String, TObject>.Create;
  LCtxRtti := TRttiContext.Create;
  try
    LTypRtti := LCtxRtti.GetType(FInstance.Classtype);
    for LprpRtti in LTypRtti.GetProperties do
    begin
      case LprpRtti.PropertyType.TypeKind of
        tkClass:
        begin
          if LprpRtti.IsForeignKey then
          begin
            if LprpRtti.PropertyType.IsInstance then
            begin
              LValue := LprpRtti.GetValue(Pointer(pEntity));

              if (LValue.AsObject = nil) then
              begin
                LRttiInstance := LprpRtti.PropertyType.AsInstance;
                LValue := LRttiInstance.MetaclassType.Create;
              end
              else
                Result.AddOrSetValue(LprpRtti.FieldName, LValue.AsObject)
            end;
          end;
        end;
      end;
    end;

    if (Result.Count = 0) then
      FreeAndNil(Result);
  finally
    LCtxRtti.Free;
  end;
end;

function TDataBaseRtti<T>._GetRttiPropertyValue(pEntity: T; pPropertyName: String): Variant;
begin
  Result := GetRttiProperty(pEntity, pPropertyName).GetValue(Pointer(pEntity)).AsVariant;
end;

end.
