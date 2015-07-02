object frmMain: TfrmMain
  Left = 450
  Top = 238
  Width = 493
  Height = 275
  Caption = 'SNMP printer status'
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  OldCreateOrder = False
  OnClose = FormClose
  OnCreate = FormCreate
  PixelsPerInch = 96
  TextHeight = 13
  object mmoMain: TMemo
    Left = 0
    Top = 0
    Width = 485
    Height = 244
    Align = alClient
    Color = clBtnFace
    Font.Charset = RUSSIAN_CHARSET
    Font.Color = clWindowText
    Font.Height = -11
    Font.Name = 'DejaVu Sans Mono'
    Font.Style = []
    ParentFont = False
    ReadOnly = True
    ScrollBars = ssVertical
    TabOrder = 0
  end
  object SNMP: TIdSNMP
    Host = '192.168.75.99'
    ReceiveTimeout = 200
    Community = 'public'
    Left = 12
    Top = 12
  end
  object tmrMain: TTimer
    OnTimer = tmrMainTimer
    Left = 56
    Top = 12
  end
  object trayIcon: TJvTrayIcon
    Active = True
    IconIndex = 0
    Visibility = [tvAutoHide, tvRestoreClick, tvMinimizeClick]
    Left = 108
    Top = 12
  end
end
