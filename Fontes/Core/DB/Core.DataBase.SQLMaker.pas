unit Core.DataBase.SQLMaker;

interface

uses
  {Classe de sistema}
   Data.DB
  ,System.Rtti
  ,System.Classes
  ,System.SysUtils
  ,System.Generics.Collections
  {Classes de negócio}
  ,Core.Exceptions
  ,Core.DataBase.Types
  ,Core.DataBase.Interfaces;

type
  TSQLMaker<T: class, constructor> = class(TInterfacedObject, ISQLMaker<T>)
  strict private
    FInstance : T;
    FFields   : String;
    FWhere    : String;
    FOrderBy  : String;
    FGroupBy  : String;
    FLimit    : String;
    FJoin     : String;
    FSQL      : String;
  public
    {Construtores e Destrutores}
    constructor Create(pInstance: T);
    destructor Destroy; override;

    {Funções de classes}
    class function New(pInstance: T): ISQLMaker<T>;

    function Insert(var pSQL: String): ISQLMaker<T>; overload;
    function Update(var pSQL: String): ISQLMaker<T>; overload;
    function Delete(var pSQL: String): ISQLMaker<T>;
    function Select(var pSQL: String): ISQLMaker<T>;

    function SelectById(var pSQL: String): ISQLMaker<T>;
    function Fields(pFields: String): ISQLMaker<T>;
    function TableName(var pTableName: String): ISQLMaker<T>;
    function GetNewID(var pSQL: String): ISQLMaker<T>;

    function Where(pWhere: String): ISQLMaker<T>; overload;
    function Where(pParameters: TDictionary<String, TValue>): ISQLMaker<T>; overload;
    function OrderBy(pOrder: String): ISQLMaker<T>;
    function GroupBy(pGroup: String): ISQLMaker<T>;
    function Limit(pLimit: String): ISQLMaker<T>;
    function Join(pJoin: String): ISQLMaker<T>;
    function SQL(pSQL: String): ISQLMaker<T>;

    function ParseCriteria(const pField: String; pValue: TValue; const pOperator: TOperatorType): String;
  end;

implementation

uses
  Core.DataBase.Rtti;

{ TSQLMaker<T> }

constructor TSQLMaker<T>.Create(pInstance: T);
begin
  FInstance := pInstance;
  FLimit := '';
end;

function TSQLMaker<T>.Delete(var pSQL: String): ISQLMaker<T>;
var
  LClassName: String;
begin
  Result := Self;

  TDataBaseRtti<T>.New(FInstance)
    .TableName(LClassName);

  pSQL := pSQL + 'DELETE FROM ' + LClassName;
  if not FWhere.IsEmpty then
    pSQL := pSQL + ' WHERE ' + FWhere;
end;

destructor TSQLMaker<T>.Destroy;
begin
  inherited;
end;

function TSQLMaker<T>.Fields(pFields: String): ISQLMaker<T>;
begin
  Result := Self;
  if not Trim(pFields).IsEmpty then
    FFields := pFields;
end;

function TSQLMaker<T>.GetNewID(var pSQL: String): ISQLMaker<T>;
begin
  Result := Self;
  pSQL := 'SELECT NEXTVAL(:PAR_SEQUENCE) AS ID';
end;

function TSQLMaker<T>.GroupBy(pGroup: String): ISQLMaker<T>;
begin
  Result := Self;

  if not Trim(pGroup).IsEmpty then
    FGroupBy := pGroup;
end;

function TSQLMaker<T>.Insert(var pSQL: String): ISQLMaker<T>;
var
  vClassName, vFields, vParam : String;
begin
  Result := Self;

  TDataBaseRtti<T>.New(FInstance)
    .TableName(vClassName)
    .FieldsInsert(vFields)
    .Param(vParam);

  pSQL := pSQL + 'INSERT INTO ' + vClassName;
  pSQL := pSQL + ' (' + vFields + ') ';
  pSQL := pSQL + ' VALUES (' + vParam + ')';
end;

function TSQLMaker<T>.Join(pJoin: String): ISQLMaker<T>;
begin
  Result := Self;
  FJoin  := pJoin;
end;

function TSQLMaker<T>.Limit(pLimit: String): ISQLMaker<T>;
begin
  Result := Self;

  if not Trim(pLimit).IsEmpty then
    FLimit := pLimit;
end;

class function TSQLMaker<T>.New(pInstance: T): ISQLMaker<T>;
begin
  Result := Self.Create(pInstance);
end;

function TSQLMaker<T>.OrderBy(pOrder: String): ISQLMaker<T>;
begin
  Result := Self;
  if not Trim(pOrder).IsEmpty then
    FOrderBy := pOrder;
end;

function TSQLMaker<T>.ParseCriteria(const pField: String; pValue: TValue; const pOperator: TOperatorType): String;
begin
  case pOperator of
    OtEqual, otDifferent,
    otBigger, otBiggerEqual,
    otMinor, otMinorEqual:
    begin
      Result := pField + ' ' + cOperator[pOperator] + ' :' + pField;
    end;
    otLikeFirst:
    begin
      Result := 'UPPER(' + pField + ') ' + cOperator[pOperator] + ' ' + QuotedStr('%' + pValue.ToString().ToUpper);
    end;
    otLikeLast:
    begin
      Result := 'UPPER(' + pField + ') ' + cOperator[pOperator] + ' ' + QuotedStr(pValue.ToString().ToUpper+ '%');
    end;
    otLikeBoth:
    begin
      Result := 'UPPER(' + pField + ') ' + cOperator[pOperator] +  ' ' + QuotedStr('%' + pValue.ToString().ToUpper+ '%');
    end;
  end;
end;

function TSQLMaker<T>.Select(var pSQL: String): ISQLMaker<T>;
var
  vFields,
  vClassName : String;
begin
  Result := Self;

  if FSQL.IsEmpty then
  begin
    TDataBaseRtti<T>.New(FInstance)
      .Fields(vFields)
      .TableName(vClassName);

    if not Trim(FFields).IsEmpty then
      pSQL := pSQL + ' SELECT ' + FFields
    else
      pSQL := pSQL + ' SELECT ' + vFields;

    pSQL := pSQL + '  FROM ' + vClassName;

    if not Trim(FJoin).IsEmpty then
      pSQL := pSQL + ' ' + FJoin + ' ';

    if not Trim(FWhere).IsEmpty then
      pSQL := pSQL + ' WHERE ' + FWhere;

    if not Trim(FGroupBy).IsEmpty then
      pSQL := pSQL + ' GROUP BY ' + FGroupBy;
    if not Trim(FOrderBy).IsEmpty then
      pSQL := pSQL + ' ORDER BY ' + FOrderBy;
    if not Trim(FLimit).IsEmpty then
      pSQL := pSQL + ' LIMIT ' + FLimit;
  end
  else
    pSQL := FSQL;
end;

function TSQLMaker<T>.SelectById(var pSQL: String): ISQLMaker<T>;
var
  vFields,
  vClassName : String;
begin
  Result := Self;

  TDataBaseRtti<T>.New(FInstance)
    .Fields(vFields)
    .TableName(vClassName)
    .Where(FWhere);

  if not Trim(FFields).IsEmpty then
    pSQL := pSQL + ' SELECT ' + FFields
  else
    pSQL := pSQL + ' SELECT ' + vFields;

  pSQL := pSQL + ' FROM ' + vClassName;

  if not Trim(FJoin).IsEmpty then
    pSQL := pSQL + ' ' + FJoin + ' ';
  if not Trim(FWhere).IsEmpty then
    pSQL := pSQL + ' WHERE ' + FWhere;
  if not Trim(FGroupBy).IsEmpty then
    pSQL := pSQL + ' GROUP BY ' + FGroupBy;
  if not Trim(FOrderBy).IsEmpty then
    pSQL := pSQL + ' ORDER BY ' + FOrderBy;
  if not Trim(FLimit).IsEmpty then
    pSQL := pSQL + ' LIMIT ' + FLimit;
end;

function TSQLMaker<T>.SQL(pSQL: String): ISQLMaker<T>;
begin
  if not pSQL.IsEmpty then
    FSQL := pSQL;
end;

function TSQLMaker<T>.TableName(var pTableName: String): ISQLMaker<T>;
begin
  Result := Self;

  TDataBaseRtti<T>.New(FInstance)
    .TableName(pTableName);

  if pTableName.IsEmpty then
    raise ESQLMakerError.Create(Format('O nome da tabela não foi definido na classe %s.', [FInstance.ClassName]));
end;

function TSQLMaker<T>.Update(var pSQL: String): ISQLMaker<T>;
var
  LClassName,
  LUpdate: String;
begin
  Result := Self;

  TDataBaseRtti<T>.New(FInstance)
    .TableName(LClassName)
    .Update(LUpdate);

  pSQL := pSQL + 'UPDATE ' + LClassName;
  pSQL := pSQL + ' SET '   + LUpdate;
  if not FWhere.IsEmpty then
    pSQL := pSQL + ' WHERE ' + FWhere;
end;

function TSQLMaker<T>.Where(pParameters: TDictionary<String, TValue>): ISQLMaker<T>;
var
  Key: String;
  Value: TValue;
begin
  Result := Self;
  for Key in pParameters.Keys do
  begin
    Value := pParameters[key];
    if FWhere.IsEmpty then
    begin
      if Value.ToString.ToLower = cOperator[TOperatorType.otIsNotNull].ToLower then
        FWhere := key + ' ' + cOperator[TOperatorType.otIsNotNull].ToUpper
      else if Value.ToString.ToLower = cOperator[TOperatorType.otIsNull].ToLower then
        FWhere := key + ' ' + cOperator[TOperatorType.otIsNull].ToUpper
      else
        FWhere := key + ' = :' + 'PAR_'+key
    end
    else
    begin
      if Value.ToString.ToLower = cOperator[TOperatorType.otIsNotNull].ToLower then
        FWhere := FWhere + ' AND ' + key + ' ' + cOperator[TOperatorType.otIsNotNull].ToUpper
      else if Value.ToString.ToLower = cOperator[TOperatorType.otIsNull].ToLower then
        FWhere := FWhere + ' AND ' + key + ' ' + cOperator[TOperatorType.otIsNull].ToUpper
      else
        FWhere := FWhere + ' AND ' + key + ' = :' + 'PAR_'+key
    end;
  end;
end;

function TSQLMaker<T>.Where(pWhere: String): ISQLMaker<T>;
begin
  Result := Self;
  FWhere := pWhere;
end;

end.
