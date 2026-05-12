unit Entidade.Pais;

interface

uses
  {Classes de Negócio}
   Core.Entidades.ModelBase
  ,Core.Entidades.CustomAttributes;

type
  [Table('pais')]
  TPais = class(TBaseModel)
  strict private
    FID: Integer;
    FNome: string;
    FCodIBGE: Integer;
  public
    [DBField('id'), PK, NotNull, Seq('pais_seq')]
    property ID:      Integer read FID      write FID;
    [DBField('nome'), NotNull]
    property Nome:    string  read FNome    write FNome;
    [DBField('cod_ibge'), NotNull]
    property CodIBGE: Integer read FCodIBGE write FCodIBGE;
  end;


implementation

end.
