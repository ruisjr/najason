program PrjDesafio;

uses
  Vcl.Forms,
  uPrincipal in 'uPrincipal.pas' {frmPrincipal},
  uWebService in 'uWebService.pas',
  uMunicipio in 'uMunicipio.pas',
  uGlobal in 'uGlobal.pas',
  uTelaProgress in 'uTelaProgress.pas' {frmProgress};

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TfrmPrincipal, frmPrincipal);
  Application.CreateForm(TfrmProgress, frmProgress);
  Application.Run;
end.
