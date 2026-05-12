unit Entidade.Municipio;

interface

uses
  {Classes de Negócio}
   Core.Entidades.ModelBase
  ,Core.Entidades.CustomAttributes;

type
  [Table('municipio')]
  TMunicipio = class(TBaseModel)
  strict private
    FID: Integer;
    FUF: String;
    FNome: string;
    FCodIBGE: Integer;
    FCodPais: Integer;
    FMacroRegiao: Integer;
  public
    [DBField('id'), PK, NotNull, Seq('municipio_seq')]
    property ID:          Integer read FID          write FID;
    [DBField('nome'), NotNull]
    property Nome:        string  read FNome        write FNome;
    [DBField('cod_ibge'), NotNull]
    property CodIBGE:     Integer read FCodIBGE     write FCodIBGE;
    [DBField('macro_regiao')]
    property MacroRegiao: Integer read FMacroRegiao write FMacroRegiao;
    [DBField('cod_pais')]
    property CodPais:     Integer read FCodPais     write FCodPais;
    [DBField('uf'), NotNull]
    property UF:          String  read FUF          write FUF;
  end;

implementation

end.
