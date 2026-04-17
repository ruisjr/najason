object frmPrincipal: TfrmPrincipal
  Left = 0
  Top = 0
  BorderStyle = bsDialog
  Caption = 'Importar e Exportar Dados IBGE'
  ClientHeight = 571
  ClientWidth = 1035
  Color = clBtnFace
  Constraints.MaxHeight = 1051
  Constraints.MaxWidth = 1051
  Constraints.MinHeight = 600
  Constraints.MinWidth = 610
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -12
  Font.Name = 'Segoe UI'
  Font.Style = []
  OldCreateOrder = True
  OnDestroy = FormDestroy
  PixelsPerInch = 96
  TextHeight = 15
  object lblStatus: TLabel
    Left = 356
    Top = 9
    Width = 671
    Height = 28
    AutoSize = False
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -20
    Font.Name = 'Segoe UI'
    Font.Style = []
    ParentFont = False
  end
  object lblNumeroRegistros: TLabel
    Left = 8
    Top = 535
    Width = 393
    Height = 28
    AutoSize = False
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -20
    Font.Name = 'Segoe UI'
    Font.Style = []
    ParentFont = False
  end
  object btnCarregarIBGE: TButton
    Left = 8
    Top = 8
    Width = 160
    Height = 33
    Caption = '&Carregar Dados IBGE'
    TabOrder = 0
    OnClick = btnCarregarIBGEClick
  end
  object mmDados: TMemo
    Left = 8
    Top = 47
    Width = 1019
    Height = 482
    ReadOnly = True
    ScrollBars = ssBoth
    TabOrder = 2
  end
  object btnExportarCSV: TButton
    Left = 174
    Top = 8
    Width = 160
    Height = 33
    Caption = '&Exportar CSV'
    TabOrder = 1
    OnClick = btnExportarCSVClick
  end
  object btnFechar: TButton
    Left = 867
    Top = 535
    Width = 160
    Height = 33
    Caption = '&Fechar'
    TabOrder = 3
    OnClick = btnFecharClick
  end
end
