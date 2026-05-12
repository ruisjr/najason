unit Entidade.Especie;

interface

uses
  {Classes de Negócio}
   Core.Entidades.ModelBase
  ,Core.Entidades.CustomAttributes;

type
  [Table('especie')]
  TEspecie = class(TBaseModel)
  private
    FID: Integer;
    FDescricao: String;
  public
    [DBField('id'), PK, NotNull, Seq('especie_seq')]
    property ID:   Integer read FID        write FID;
    [DBField('descricao'), NotNull]
    property Descricao: String  read FDescricao write FDescricao;
  end;

implementation

end.
