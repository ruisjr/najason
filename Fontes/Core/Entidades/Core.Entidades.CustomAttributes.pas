unit Core.Entidades.CustomAttributes;

interface

type
  Table = class(TCustomAttribute)
  private
    FName: String;
  public
    constructor Create(pName: String);
    property Name: String read FName;
  end;

  DBField = class(TCustomAttribute)
  private
    FName: String;
  public
    constructor Create(pName: String);
    property Name: String read FName;
  end;

  PK = class(TCustomAttribute)
  end;

  FK = class(TCustomAttribute)
  end;

  Seq = class(TCustomAttribute)
  private
    FName: String;
  public
    constructor Create(pName: String);
    property Name: String read FName;
  end;

  DBDateTime = class(TCustomAttribute)
  private
    FName: String;
  public
    constructor Create(pName: String);
    property Name: String read FName;
  end;

  Display = class(TCustomAttribute)
  private
    FName: string;
  public
    constructor Create(const pName: string);
    property Name: string read FName write FName;
  end;

  Ignore = class(TCustomAttribute)
  end;

  NotNull = class(TCustomAttribute)
  end;

  AutoInc = class(TCustomAttribute)
  end;

  NumberOnly = class(TCustomAttribute)
  end;

  Bind = class(TCustomAttribute)
  private
    FField: String;
  public
    constructor Create(pField : String);
    property Field: String read FField;
  end;

  Enumerator = class(TCustomAttribute)
  private
    FTipo: string;
  public
    Constructor Create(pTipo: string);
    property Tipo: string read FTipo;
  end;


implementation

{ Bind }

constructor Bind.Create(pField: String);
begin
  FField := pField;
end;

{ Enumerator }

constructor Enumerator.Create(pTipo: string);
begin
  FTipo := pTipo;
end;

{ DBField }

constructor DBField.Create(pName: String);
begin
  FName := pName;
end;

{ Table }

constructor Table.Create(pName: String);
begin
  FName := pName;
end;

{ SEQ }

constructor Seq.Create(pName: String);
begin
  FName := pName;
end;

{ Display }

constructor Display.Create(const pName: string);
begin
  FName := pName;
end;

{ DBDateTime }

constructor DBDateTime.Create(pName: String);
begin
  FName := pName;
end;

end.
