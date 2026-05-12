unit Entidade.Estado;

interface

uses
  {Classes de Negócio}
   Core.Entidades.ModelBase
  ,Core.Entidades.CustomAttributes;

type
  [Table('estado')]
  TEstado = class(TBaseModel)
  strict private
    FID: Integer;
    FSigla: string;
    FCodIBGE: Integer;
  public
    [DBField('id'), PK, NotNull, Seq('pais_seq')]
    property ID:      Integer read FID      write FID;
    [DBField('sigla'), NotNull]
    property Sigla:   string  read FSigla   write FSigla;
    [DBField('cod_ibge'), NotNull]
    property CodIBGE: Integer read FCodIBGE write FCodIBGE;
  end;

implementation

end.
