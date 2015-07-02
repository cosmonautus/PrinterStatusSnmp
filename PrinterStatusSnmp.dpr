program PrinterStatusSnmp;

uses
  Windows,
  Messages,
  Forms,
  SysUtils,
  uMain in 'uMain.pas' {frmMain};

{$R *.res}

const
  sMainTitle : PAnsiChar = 'SNMP printer status';

var
  hWindow : HWND;

begin
  Application.Initialize();
  hWindow := FindWindow('TApplication', PAnsiChar(sMainTitle));
  if (hWindow <> 0) then
  begin
    Application.MessageBox('Приложение уже запущено.', PAnsiChar(sMainTitle), MB_ICONWARNING or MB_OK or MB_TOPMOST or MB_APPLMODAL);
    exit;
  end;
  Application.Title := 'SNMP printer status';
  Application.CreateForm(TfrmMain, frmMain);
  Application.Run();
end.
