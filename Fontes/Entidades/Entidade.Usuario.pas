unit Entidade.Usuario;

interface

uses
   {Classes de Negócio}
   Core.Entidades.ModelBase
  ,Core.Entidades.CustomAttributes;

type
  [Table('usuario')]
  TUsuario = class(TBaseModel)
  private
    FID   : Integer;
    FNome : String;
    FSenha: String;
    FEmail: String;
    FAtivo: Boolean;
    FBloqueado: Boolean;
    FDataCadastro: TDateTime;
    FUltimoAcesso: TDateTime;
    FPrimeiroAcesso: Boolean;
    FLogin: String;
    function GetSenha: String;
    procedure SetSenha(const Value: String);

  public
    [DBField('ID'), PK, NotNull, Seq('usuario_seq'), Display('Código')]
    property ID:    Integer          read FID             write FID;
    [DBField('nome'), NotNull, Display('Nome')]
    property Nome:  String           read FNome           write FNome;
    [DBField('login'), NotNull, Display('Login')]
    property Login: String           read FLogin          write FLogin;
    [DBField('senha'), NotNull, Display('Senha')]
    property Senha: String           read GetSenha        write SetSenha;
    [DBField('email'), NotNull, Display('E-Mail')]
    property Email: String           read FEmail          write FEmail;
    [DBField('ativo')]
    property Ativo: Boolean          read FAtivo          write FAtivo;
    [DBField('bloqueado')]
    property Bloqueado: Boolean      read FBloqueado      write FBloqueado;
    [DBField('data_cadastro')]
    property DataCadastro: TDateTime read FDataCadastro   write FDataCadastro;
    [DBField('data_ultimo_acesso')]
    property UltimoAcesso: TDateTime read FUltimoAcesso   write FUltimoAcesso;
    [DBField('primeiro_acesso')]
    property PrimeiroAcesso: Boolean read FPrimeiroAcesso write FPrimeiroAcesso;
  end;

implementation

uses
  Core.Functions;

{ TUsuario }

function TUsuario.GetSenha: String;
begin
  Result := GetDecodeBase64(FSenha);
end;

procedure TUsuario.SetSenha(const Value: String);
begin
  FSenha := GetEncodeBase64(Value);
end;

end.

