program PrinterStatusSnmp;

uses
  Forms,
  uMain in 'uMain.pas' {frmMain};

{$R *.res}

begin
  Application.Initialize;
  Application.Title := 'SNMP printer status';
  Application.CreateForm(TfrmMain, frmMain);
  Application.Run;
end.
