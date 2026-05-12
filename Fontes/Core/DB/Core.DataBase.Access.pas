unit Core.DataBase.Access;

interface

uses
  {Classes de Sistema}
   Data.DB
  ,Vcl.Forms
  ,System.SysUtils
  ,System.TypInfo
  ,System.Rtti
  ,System.Generics.Collections
  {Classes de negócio}
  ,Core.Exceptions
  ,Core.Environment
  ,Core.DataBase.Types
  ,Core.DataBase.Connection
  ,Core.DataBase.Interfaces
  ,Core.DataBase.QueryBuilder
  ,Core.Entidades.CustomAttributes;

type
  TDataBaseDAO<T: class, constructor> = class(TInterfacedObject, IDataBaseDAO<T>)
  strict private
    FEntity: T;
    FForm: TForm;
    FSQL: String;
    FOrder: String;
    FGroup: String;
    FLimit: String;
    FWhere: String;
    FFields: String;
    FList: TObjectList<T>;
    FParameters: TDictionary<String, TValue>;
    FDataSource: TDataSource;

    FQuery: IDataBaseQuery<T>;
    {Procedures}
    procedure Clear;
    procedure OnDataChange(Sender: TObject; Field: TField);
    procedure LoadChildObjects(pEntity: T);

    function GetParameterChild(const pObjChild: T): TDictionary<String, TValue>;
  public
    {Construtores e Destrutores}
    constructor Create; overload;
    constructor Create(const pEntity: T); overload;
    destructor Destroy; override;

    {Procedures}
    procedure FreeMemory;

    procedure ToDataSet;

    procedure Insert(pEntity: T); overload;
    procedure Update(pEntity: T); overload;
    procedure Delete(pEntity: T); overload;
    procedure Delete; overload;

    {Functions}
    function DataSet: TDataSet;
    function DataSource(pDataSource: TDataSource): IDataBaseDAO<T>;

    function SQL(const pSQL: String): IDataBaseDAO<T>;
    function GroupBy(const pField: String): IDataBaseDAO<T>;
    function OrderBy(const pField: String): IDataBaseDAO<T>;
    function Limit(const pLimit: Integer): IDataBaseDAO<T>;
    function Fields(const pFields: String): IDataBaseDAO<T>;
    function Where(const pField: String; const pOperatorType: TOperatorType; const pValue: TValue): IDataBaseDAO<T>;
    function WhereAnd(const pField: String; const pOperatorType: TOperatorType; const pValue: TValue): IDataBaseDAO<T>;

    function ToList(const pRecMax: Integer = 0; const pRecSkip: Integer = 0): TObjectList<T>;
    function First: T;
    function Bind(const pForm: TForm): IDataBaseDAO<T>;

    function GetNewID: Integer;
  end;

implementation

uses
   Core.DataBase.Rtti
  ,Core.DataBase.SQLMaker;


{ TDataBaseAccess }

constructor TDataBaseDAO<T>.Create;
begin
  inherited Create;
  FList := TObjectList<T>.Create;
  FQuery := TQueryBuilder<T>.Create;
  FParameters := TDictionary<String, TValue>.Create;

  if FEntity = nil then
    FEntity := T.Create;
end;

procedure TDataBaseDAO<T>.Clear;
begin
  FOrder := '';
  FGroup := '';
  FLimit := '';
  FWhere := '';
  FFields := '';
  FParameters.Clear;
end;

constructor TDataBaseDAO<T>.Create(const pEntity: T);
begin
  FEntity := pEntity;
  Self.Create;
end;

function TDataBaseDAO<T>.DataSet: TDataSet;
begin
  Result := TDataSet(FQuery);
end;

function TDataBaseDAO<T>.DataSource(pDataSource: TDataSource): IDataBaseDAO<T>;
begin
  try
    Result := Self;
    FDataSource := pDataSource;
    FDataSource.DataSet := TDataSet(FQuery.DataSet);
    FDataSource.OnDataChange := OnDataChange;
  except
    on E: Exception do
    begin
      Env.Log.Error('An error occurred while retrieving data from the database.'+ #13#10 + 'Details: ' + E.Message);
    end;
  end;
end;

procedure TDataBaseDAO<T>.Delete(pEntity: T);
var
  LSQL: String;
begin
  try
    TSQLMaker<T>.New(pEntity).Delete(LSQL);

    FQuery.SQL.Clear;
    FQuery.SQL.Add(LSQL);
    FQuery.FillParameter(pEntity);
    FQuery.ExecSQL;
  except
    on E: Exception do
      Env.Log.Error('An error occurred while deleting the record.' + #13#10 + 'Details: ' + E.Message)
  end;
end;

procedure TDataBaseDAO<T>.Delete;
var
  LSQL: String;
begin
  try
    TSQLMaker<T>.New(FEntity).Where(FParameters).Delete(LSQL);

    FQuery.SQL.Clear;
    FQuery.SQL.Add(LSQL);
    FQuery.FillParameter(FParameters);
    FQuery.ExecSQL;
  except
    on E: Exception do
      Env.Log.Error('An error occurred while deleting the record.' + #13#10 + 'Details: ' + E.Message)
  end;
end;

destructor TDataBaseDAO<T>.Destroy;
begin
  FreeAndNil(FParameters);
  inherited;
end;

function TDataBaseDAO<T>.Limit(const pLimit: Integer): IDataBaseDAO<T>;
begin
  Result := Self;
  FLimit := pLimit.ToString();
end;

procedure TDataBaseDAO<T>.LoadChildObjects(pEntity: T);
var
  LKey,
  LSQL: String;
  LObj: TObject;
  LDict: TDictionary<String, TObject>;
begin
  LDict := TDataBaseRtti<T>.New(FEntity).LoadObjectForeignKey(pEntity);

  if not Assigned(LDict) then
    Exit;

  for LKey in LDict.Keys do
  begin
    LObj := TObject(LDict[LKey]);
    FParameters := Self.GetParameterChild(LObj);

    FQuery.DataSet.DisableControls;
    try
      TSQLMaker<T>.New(LObj)
        .Fields(FFields)
        .Where(FParameters)
        .GroupBy(FGroup)
        .OrderBy(FOrder)
        .Limit('1')
      .Select(LSQL);

      FQuery.SQL.Clear;
      FQuery.SQL.Add(LSQL);
      FQuery.FillParameter(FParameters);
      FQuery.Open;

      TDataBaseRtti<T>.New(LObj).DataSetToEntity(FQuery.DataSet, LObj);

      TDataBaseRtti<T>.New(LObj).ApplyEntityChildToParent(pEntity, LObj, LKey);
    finally
      Self.Clear;

      FQuery.DataSet.EnableControls;
      FQuery.DataSet.Close;
    end;
  end;
end;

procedure TDataBaseDAO<T>.OnDataChange(Sender: TObject; Field: TField);
begin
  if (FList.Count > 0) and (FDataSource.DataSet.RecNo - 1 <= FList.Count) then
  begin
    if Assigned(FForm) then
      TDataBaseRtti<T>.New(nil).BindEntityToForm(FForm, FList[FDataSource.DataSet.RecNo - 1]);
  end;
end;

function TDataBaseDAO<T>.SQL(const pSQL: String): IDataBaseDAO<T>;
begin
  Result := Self;
  FSQL := pSQL;
end;

function TDataBaseDAO<T>.OrderBy(const pField: String): IDataBaseDAO<T>;
begin
  Result := Self;
  FOrder := pField;
end;

procedure TDataBaseDAO<T>.ToDataSet;
var
  LSQL: String;
begin
  TSQLMaker<T>.New(FEntity).Select(LSQL);

  FQuery.DataSet.DisableControls;
  try
    FQuery.SQL.Clear;
    FQuery.Open(LSQL);
  finally
    Self.Clear;
    FQuery.DataSet.EnableControls;
  end;
end;

function TDataBaseDAO<T>.Fields(const pFields: String): IDataBaseDAO<T>;
begin
  Result := Self;
  FFields := pFields;
end;

function TDataBaseDAO<T>.First: T;
var
  LSQL: String;
begin
  if FSQL.IsEmpty then
  begin
    TSQLMaker<T>.New(FEntity)
      .Fields(FFields)
      .Where(FParameters)
      .GroupBy(FGroup)
      .OrderBy(FOrder)
      .Limit('1')
    .Select(LSQL);
  end
  else
    LSQL := FSQL;

  FQuery.DataSet.DisableControls;
  try
    FQuery.SQL.Clear;
    FQuery.SQL.Add(LSQL);
    FQuery.FillParameter(FParameters);
    FQuery.Open;

    TDataBaseRtti<T>.New(FEntity).DataSetToEntity(FQuery.DataSet, Result);

    {Validar se os próximos objetos são do tipo Class e preenche}
    Self.LoadChildObjects(Result);
  finally
    Self.Clear;

    FQuery.DataSet.EnableControls;
    FQuery.DataSet.Close;
  end;
end;

procedure TDataBaseDAO<T>.FreeMemory;
begin
  if Assigned(FQuery) then
  begin
    FQuery.FreeMemory;
    FQuery := Nil;
  end;

  if Assigned(FList) then
    FreeAndNil(FList);
  if Assigned(FDataSource) then
    FreeAndNil(FDataSource);
  if Assigned(FEntity) then
    FreeAndNil(FEntity);
end;

function TDataBaseDAO<T>.Bind(const pForm: TForm): IDataBaseDAO<T>;
begin
  Result := Self;
  FForm := pForm;
end;

function TDataBaseDAO<T>.GetNewID: Integer;
var
  LSQL: String;
begin
  TSQLMaker<T>
    .New(FEntity)
    .GetNewID(LSQL);

  FQuery.SQL.Clear;
  FQuery.SQL.Add(LSQL);
  FQuery.FillParameterSequence(FEntity);
  FQuery.Open;

  Result := FQuery.Fields[0].AsInteger;
end;

function TDataBaseDAO<T>.GetParameterChild(const pObjChild: T): TDictionary<String, TValue>;
begin
  Result := TDataBaseRtti<T>.New(pObjChild).GetParameterFromPK;
end;

function TDataBaseDAO<T>.GroupBy(const pField: String): IDataBaseDAO<T>;
begin
  Result := Self;
  if Trim(FGroup).IsEmpty then
    FGroup := pField
  else
    FGroup := FGroup + ', ' + pField;
end;

procedure TDataBaseDAO<T>.Insert(pEntity: T);
var
  vSQL: String;
begin
  try
    {Atribuir ao pEntity o id obtido}
    TDataBaseRtti<T>.New(Self).BindValueToProperty(pEntity, 'Id', Self.GetNewID);

    TSQLMaker<T>.New(pEntity).Insert(vSQL);

    FQuery.SQL.Clear;
    FQuery.SQL.Add(vSQL);
    FQuery.FillParameter(pEntity, True);
    FQuery.ExecSQL;
  except
    on E: Exception do
    begin
      Env.Log.Error('An error occurred while inserting the record.' + #13#10 + 'Details: ' + E.Message);
      raise EDataBaseDAOError.Create(format('An error occurred while inserting the record into the database.'+#13+'Class %s.', [pEntity.ClassName]));
    end;
  end;
end;

function TDataBaseDAO<T>.ToList(const pRecMax: Integer; const pRecSkip: Integer): TObjectList<T>;
var
  vSQL: String;
begin
  TSQLMaker<T>.New(FEntity)
    .Fields(FFields)
    .Where(FParameters)
    .GroupBy(FGroup)
    .OrderBy(FOrder)
    .Limit(FLimit)
  .Select(vSQL);

  FQuery.DataSet.DisableControls;
  try
    FQuery.SQL.Clear;
    FQuery.SQL.Add(vSQL);
    FQuery.FillParameter(FParameters);

    if (pRecMax > 0) then
      FQuery.SetRecsMax(pRecMax);
    if (pRecSkip > 0) and  (pRecMax > 0) then
      FQuery.SetRecsSkip(pRecSkip);

    FQuery.Open;

    Result := TObjectList<T>.Create;

    TDataBaseRtti<T>.New(Self).DataSetToEntityList(FQuery.DataSet, Result);
  finally
    FQuery.DataSet.EnableControls;
    FQuery.DataSet.Close;
  end;
end;

procedure TDataBaseDAO<T>.Update(pEntity: T);
var
  vSQL: String;
begin
  try
    TSQLMaker<T>.New(pEntity).Where(FParameters).Update(vSQL);

    FQuery.SQL.Clear;
    FQuery.SQL.Add(vSQL);
    FQuery.FillParameter(pEntity);
    FQuery.FillParameter(FParameters);
    FQuery.ExecSQL;
  except
    on E: Exception do
    begin
      Env.Log.Error('An error occurred while updating the record.' + #13#10 + 'Details: ' + E.Message);
      raise EDataBaseDAOError.Create(format('An error occurred while updating the record in the database.'+#13+'Class %s.', [pEntity.ClassName]));
    end;
  end;
end;

function TDataBaseDAO<T>.Where(const pField: String; const pOperatorType: TOperatorType; const pValue: TValue): IDataBaseDAO<T>;
begin
  Result := Self;
  if pOperatorType = TOperatorType.otIsNotNull then
    FParameters.Add(pField, cOperator[pOperatorType])
  else
    FParameters.Add(pField, pValue);
end;

function TDataBaseDAO<T>.WhereAnd(const pField: String; const pOperatorType: TOperatorType; const pValue: TValue): IDataBaseDAO<T>;
begin
  Result := Self;
  if pOperatorType = TOperatorType.otIsNotNull then
    FParameters.Add(pField, cOperator[pOperatorType])
  else
    FParameters.Add(pField, pValue);
end;

end.
