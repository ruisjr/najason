unit Core.DataBase.Interfaces;

interface

uses
  {Classes de sistema}
   Data.DB
  ,Vcl.Forms
  ,System.Rtti
  ,System.Classes
  ,FireDac.Comp.Client
  ,System.Generics.Collections
  {Classes de negócio}
  ,Core.DataBase.Types;


type
  IDBConnection = interface
    ['{973F5068-D967-41C5-A8D0-BF8F63DECFCA}']
    {Functions}
    function GetConnection: TFDConnection;

    {Procedures}
    procedure FreeMemory;
    procedure BeginTransaction;
    procedure CommitTransaction;
    procedure RollBackTransaction;
  end;

  IDataBaseDAO<T: class> = interface
    ['{CF67169D-0326-4D51-BDD1-5596907843C6}']
    {Procedures}
    procedure ToDataSet;
    procedure FreeMemory;
    procedure Insert(pEntity: T); overload;
    procedure Update(pEntity: T); overload;
    procedure Delete(pEntity: T); overload;
    procedure Delete; overload;

    {Functions}
    function GetNewID: Integer;
    function DataSet: TDataSet;
    function DataSource(pDataSource: TDataSource): IDataBaseDAO<T>;

    function Where(const pConditional: String; const pOperatorType: TOperatorType; const pValue: TValue): IDataBaseDAO<T>;
    function WhereAnd(const pConditional: String; const pOperatorType: TOperatorType; const pValue: TValue): IDataBaseDAO<T>;

    function Fields(const pFields: String): IDataBaseDAO<T>;
    function SQL(const pSQL: String): IDataBaseDAO<T>;
    function OrderBy(const pField: String): IDataBaseDAO<T>;
    function GroupBy(const pField: String): IDataBaseDAO<T>;
    function Limit(const pLimit: Integer) :IDataBaseDAO<T>;

    function First: T;
    function ToList(const pRecMax: Integer = 0; const pRecSkip: Integer = 0): TObjectList<T>;
    function Bind(const pForm: TForm): IDataBaseDAO<T>;
  end;

  ISQLMaker<T> = interface
    ['{C098CF56-1DD5-43CF-9728-6543673D366E}']
    function ParseCriteria(const pField: String; pValue: TValue; const pOperator: TOperatorType): String;

    function Insert(var pSQL: String): ISQLMaker<T>; overload;
    function Update(var pSQL: String): ISQLMaker<T>; overload;
    function Delete(var pSQL: String): ISQLMaker<T>;
    function Select(var pSQL: String): ISQLMaker<T>;

    function SelectById(var pSQL: String): ISQLMaker<T>;
    function Fields(pFields: String): ISQLMaker<T>;
    function TableName(var pTableName: String): ISQLMaker<T>;
    function Where(pWhere: String): ISQLMaker<T>; overload;
    function Where(pParameters: TDictionary<String, TValue>): ISQLMaker<T>; overload;
    function OrderBy(pOrder: String): ISQLMaker<T>;
    function GroupBy(pGroup: String): ISQLMaker<T>;
    function Limit(pLimit: String): ISQLMaker<T>;
    function Join(pJoin: String): ISQLMaker<T>;
    function SQL(pSQL: String): ISQLMaker<T>;
    function GetNewID(var pSQL: String): ISQLMaker<T>;
  end;

  IDataBaseQuery<T> = interface
    ['{D1835E6C-8782-4ADE-A52A-A98FC40A05CF}']
    {Functions}
    function SQL: TStrings;
    function Params: TParams;
    function Fields: TFields;
    function ExecSQL: IDataBaseQuery<T>;
    function DataSet: TDataSet;
    function Open(pSQL: String): IDataBaseQuery<T>; overload;
    function Open: IDataBaseQuery<T>; overload;

    {Procedures}
    procedure FreeMemory;
    procedure Next;
    procedure First;
    procedure SetRecsMax(const pValue: Integer);
    procedure SetRecsSkip(const pValue: Integer);
    procedure FillParameter(pParameters: TDictionary<String, TValue>); overload;
    procedure FillParameter(pEntity: T; pInsert: Boolean = False); overload;
    procedure FillParameterSequence(pEntity: T);
  end;

  IDataBaseRtti<T: class> = interface
    ['{7E8CDFB6-A11D-44C7-A60E-012ABB2DB869}']
    function GetRttiProperty(pEntity: T; pPropertyName: String): TRttiProperty;
    function GetParameterFromPK: TDictionary<string, TValue>;

    function TableName(var pTableName: String): IDataBaseRtti<T>;
    function ClassName(var pClassName: String): IDataBaseRtti<T>;
    function Fields(var pFields: String): IDataBaseRtti<T>;
    function FieldsInsert (var pFields: String) : IDataBaseRtti<T>;
    function Param(var pParam: String): IDataBaseRtti<T>;
    function Where(var pWhere: String): IDataBaseRtti<T>;
    function Update(var pUpdate: String): IDataBaseRtti<T>;

    function DataSetToEntity (pDataSet : TDataSet; out pEntity : T) : IDataBaseRtti<T>;
    function DataSetToEntityList(vDataSet: TDataSet; var vList: TObjectList<T>): IDataBaseRtti<T>;
    function ApplyEntityChildToParent(var pEntity: T; pEntityChild: T; pFieldName: String): IDataBaseRtti<T>;

    function DictionaryFields(var pDictionary : TDictionary<string, variant>) : IDataBaseRtti<T>;
    function DictionaryTypeFields(var aDictionary: TDictionary<string, TFieldType>): IDataBaseRtti<T>; overload;
    function DictionaryTypeFields(const pParameters: TDictionary<string, TValue>; var aDictionary: TDictionary<string, TFieldType>): IDataBaseRtti<T>; overload;
    function BindFormToEntity(pForm : TForm; var pEntity: T): IDataBaseRtti<T>;
    function BindEntityToForm(pForm : TForm; const pEntity: T): IDataBaseRtti<T>;
    function BindValueToProperty(var pEntity: T;pPropertyName: string; pValue: TValue): IDataBaseRtti<T>;

    function LoadObjectForeignKey(pEntity: T): TDictionary<String, TObject>;
  end;

implementation

end.
