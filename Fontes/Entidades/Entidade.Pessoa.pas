unit Entidade.Pessoa;

interface

uses
  {Classes de Negócio}
   Core.Entidades.ModelBase
  ,Core.Entidades.CustomAttributes;

type
  TTipoPessoa = (
    tpCliente     = 1,
    tpFornecedor  = 4,
    tpFuncionario = 6,
    tpCliFornec   = 5,
    tpCliFunc     = 7,
    tpFornFunc    = 10,
    tpCliFornFunc = 11
  );

  [Table('pessoa')]
  TPessoa = class(TBaseModel)
  private
    FID: Integer;
    FNome: String;
    FGenero: String;
    FCpfCnpj: String;
    FTipoPessoa: Integer;
    FEstadoCivil: String;
    FDataCadastro: TDate;
    FNomeReduzido: String;
    FDataNascimento: TDate;
  public
    [DBField('ID'), PK, NotNull, Seq('pessoa_seq')]
    property ID:             Integer      read FID             write FID;
    [DBField('nome'), NotNull]
    property Nome:           string       read FNome           write FNome;
    [DBField('nome_reduzido')]
    property NomeReduzido:   String       read FNomeReduzido   write FNomeReduzido;
    [DBField('cpf_cnpj'), NotNull]
    property CpfCnpj:        String       read FCpfCnpj        write FCpfCnpj;
    [DBField('data_nascimento')]
    property DataNascimento: TDate        read FDataNascimento write FDataNascimento;
    [DBField('data_cadastro'), NotNull]
    property DataCadastro:   TDate        read FDataCadastro   write FDataCadastro;
    [DBField('tipo_pessoa'), NotNull]
    property TipoPessoa:     Integer      read FTipoPessoa     write FTipoPessoa;
    [DBField('genero')]
    property Genero:         String       read FGenero         write FGenero;
    [DBField('estado_civil')]
    property EstadoCivil:    String       read FEstadoCivil    write FEstadoCivil;
  end;

implementation

end.
