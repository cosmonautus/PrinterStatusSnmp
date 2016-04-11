object frmMain: TfrmMain
  Left = 450
  Top = 238
  Width = 677
  Height = 275
  Caption = 'SNMP printer status'
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  Menu = mnuMain
  OldCreateOrder = False
  OnClose = FormClose
  OnCreate = FormCreate
  PixelsPerInch = 96
  TextHeight = 13
  object memLog: TMemo
    Left = 0
    Top = 0
    Width = 661
    Height = 217
    Align = alClient
    Color = clBtnFace
    Font.Charset = RUSSIAN_CHARSET
    Font.Color = clWindowText
    Font.Height = -13
    Font.Name = 'Courier New'
    Font.Style = []
    ParentFont = False
    ReadOnly = True
    ScrollBars = ssVertical
    TabOrder = 0
  end
  object SNMP: TIdSNMP
    Host = '192.168.75.99'
    ReceiveTimeout = 100
    Community = 'public'
    Left = 12
    Top = 12
  end
  object tmrMain: TTimer
    Enabled = False
    OnTimer = tmrMainTimer
    Left = 56
    Top = 12
  end
  object trayMain: TJvTrayIcon
    Active = True
    IconIndex = 0
    Visibility = [tvAutoHide, tvRestoreClick, tvMinimizeClick]
    Left = 108
    Top = 12
  end
  object mnuMain: TMainMenu
    Left = 164
    Top = 12
    object N1: TMenuItem
      Caption = #1047#1072#1076#1072#1095#1072
      object N2: TMenuItem
        Caption = #1042#1099#1093#1086#1076
        ShortCut = 57425
        OnClick = N2Click
      end
    end
  end
end
