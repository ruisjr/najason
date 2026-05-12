program PrjDesafio;

uses
  madExcept,
  madLinkDisAsm,
  madListHardware,
  madListProcesses,
  madListModules,
  Vcl.Forms,
  uPrincipal in 'uPrincipal.pas' {frmPrincipal},
  uWebService in 'uWebService.pas',
  uMunicipio in 'uMunicipio.pas',
  uGlobal in 'uGlobal.pas',
  uTelaProgress in 'uTelaProgress.pas' {frmProgress},
  Core.Api in 'Fontes\Core\Core.Api.pas',
  Core.Email in 'Fontes\Core\Core.Email.pas',
  Core.Environment in 'Fontes\Core\Core.Environment.pas',
  Core.Exceptions in 'Fontes\Core\Core.Exceptions.pas',
  Core.Functions in 'Fontes\Core\Core.Functions.pas',
  Core.Global in 'Fontes\Core\Core.Global.pas',
  Core.Logs in 'Fontes\Core\Core.Logs.pas',
  Core.Rest.JsonHelper in 'Fontes\Core\Core.Rest.JsonHelper.pas',
  Core.Servico in 'Fontes\Core\Core.Servico.pas',
  Core.Thread in 'Fontes\Core\Core.Thread.pas',
  Core.Entidades.CustomAttributes in 'Fontes\Core\Entidades\Core.Entidades.CustomAttributes.pas',
  Core.Entidades.ModelBase in 'Fontes\Core\Entidades\Core.Entidades.ModelBase.pas',
  Core.DataBase.Access in 'Fontes\Core\DB\Core.DataBase.Access.pas',
  Core.DataBase.Connection in 'Fontes\Core\DB\Core.DataBase.Connection.pas',
  Core.DataBase.QueryBuilder in 'Fontes\Core\DB\Core.DataBase.QueryBuilder.pas',
  Core.DataBase.Rtti in 'Fontes\Core\DB\Core.DataBase.Rtti.pas',
  Core.DataBase.RttiHelper in 'Fontes\Core\DB\Core.DataBase.RttiHelper.pas',
  Core.DataBase.SQLMaker in 'Fontes\Core\DB\Core.DataBase.SQLMaker.pas',
  Core.DataBase.Types in 'Fontes\Core\DB\Core.DataBase.Types.pas',
  Core.DataBase.Interfaces in 'Fontes\Core\DB\Interfaces\Core.DataBase.Interfaces.pas',
  Entidade.Pais in 'Fontes\Entidades\Entidade.Pais.pas',
  Entidade.Estado in 'Fontes\Entidades\Entidade.Estado.pas',
  Entidade.Municipio in 'Fontes\Entidades\Entidade.Municipio.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TfrmPrincipal, frmPrincipal);
  Application.CreateForm(TfrmProgress, frmProgress);
  Application.Run;
end.
