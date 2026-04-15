unit uMunicipio;

interface

type
  TMunicipio = class
  strict private
    FRegiao: String;
    FNomeOficial: String;
    FUF: String;
    FCodigoIBGE: Integer;
    FPopulacao: Int64;

  public
    property NomeOficial: String  read FNomeOficial write FNomeOficial;
    property UF:          String  read FUF          write FUF;
    property Regiao:      String  read FRegiao      write FRegiao;
    property CodigoIBGE:  Integer read FCodigoIBGE  write FCodigoIBGE;
    property Populacao:   Int64   read FPopulacao   write FPopulacao;
  end;

implementation

end.
