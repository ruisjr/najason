unit Entidade.Raca;

interface

uses
  {Classes de Negócio}
   Entidade.Especie
  ,Core.Entidades.ModelBase
  ,Core.Entidades.CustomAttributes;

type
  [Table('raca')]
  TRaca = class(TBaseModel)
  strict private
    FID: Integer;
    FNome: String;
    FPorte: String;
    FPelagem: String;
    FIdEspecie: TEspecie;
  public
    [DBField('id'), PK, NotNull, Seq('raca_seq')]
    property ID:        Integer read FID        write FID;
    [DBField('nome'), NotNull]
    property Nome:      String  read FNome write FNome;
    [DBField('porte'), NotNull]
    property Porte:     String  read FPorte     write FPorte;
    [DBField('pelagem'), NotNull]
    property Pelagem:   String  read FPelagem   write FPelagem;
    [DBField('id_especie'), FK, NotNull]
    property IdEspecie: TEspecie read FIdEspecie write FIdEspecie;
  end;


implementation

end.
