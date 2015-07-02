unit uMain;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, IdBaseComponent, IdComponent, IdUDPBase, IdUDPClient, IdSNMP,
  StdCtrls, ExtCtrls, JvExControls, JvComCtrls,

  uConsts, uSupvis, uLinker, uBinSpecTask, uTOOThread, uTOOSpecTask,
  JvComponentBase, JvTrayIcon;

const
  STATUS_NOLINK = 0;

var
  TASKS_QUIT_MSG : LongWord = 0;

type
  TMySpecTask = class(TTOOSpecTask)
  private
    function getVarCount: integer;
    function GetVar(const aIndex: integer): TTOOVar;
  public
    property VarCount : integer read getVarCount;
    property Variable[const aIndex : integer] : TTOOVar read GetVar;
    property TaskName : string read m_name;
  end;

  TMyPrinter = record
    infoReceived : boolean;
    sysName : string;
    sysDescr : string;
    hrPrinterStatus : byte;
    varToo : TTOOVar;
  end;

  TfrmMain = class(TForm)
    SNMP: TIdSNMP;
    tmrMain: TTimer;
    mmoMain: TMemo;
    trayIcon: TJvTrayIcon;
    procedure FormCreate(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure tmrMainTimer(Sender: TObject);
  private
    { Private declarations }
    m_SpecTask : TMySpecTask;
    m_printers : array of TMyPrinter;
    m_halt : boolean;
    procedure RequestPrintersState;
    procedure Log(const aMsg : string);
    procedure OnMsg(var Msg: TMsg; var Handled: Boolean);
  public
    { Public declarations }
  end;

var
  frmMain: TfrmMain;

implementation

{$R *.dfm}

{ TMySpecTask }

function TMySpecTask.GetVar(const aIndex: integer): TTOOVar;
begin
  Result := m_vars[aIndex] as TTOOVar;
end;

function TMySpecTask.getVarCount: integer;
begin
  Result := m_vars.Count;
end;

{ TfrmMain }

procedure TfrmMain.FormCreate(Sender: TObject);
var
   i, msTimer : integer;
begin
  Application.OnMessage := OnMsg;
  try
    trayIcon.Icon.Assign(Application.Icon);
    trayIcon.Hint := Application.Title;
    Log('Begin work');
    if (ParamCount > 1) then
    begin
      msTimer := StrToIntDef(ParamStr(2), 0);
      if (msTimer > 0) then
        tmrMain.Interval := msTimer;
    end;
    Log('Polling interval: ' + IntToStr(tmrMain.Interval) + 'ms');
    m_SpecTask := TMySpecTask.create(ExtractFileName(ParamStr(0)), nil);
    Log('Task ''' + m_SpecTask.TaskName + '''');
    m_SpecTask.connect(false);
    Log('Connected TOO');
    SetLength(m_printers, m_SpecTask.VarCount);
    for i := low(m_printers) to high(m_printers) do
    begin
      m_printers[i].infoReceived := false;
      m_printers[i].varToo := m_SpecTask.Variable[i];
    end;
  except
    on e : Exception do
    begin
      Log('!!! Error: ' + e.Message);
      Application.MessageBox(PAnsiChar(e.Message), PAnsiChar(Application.Title), MB_ICONERROR or MB_OK or MB_TOPMOST or MB_APPLMODAL);
      m_halt := true;
    end;
  end;
end;

procedure TfrmMain.FormClose(Sender: TObject; var Action: TCloseAction);
var
  i : integer;
begin
  if (m_SpecTask.connected) then
  begin
    for i := low(m_printers) to high(m_printers) do
    begin
      m_printers[i].hrPrinterStatus := STATUS_NOLINK;
      m_SpecTask.writeVar(m_printers[i].varToo, @m_printers[i].hrPrinterStatus);
    end;
  end;
  FreeAndNil(m_SpecTask);
end;

procedure TfrmMain.RequestPrintersState;
var
  i : integer;
begin
  for i := low(m_printers) to high(m_printers) do
  begin
    SNMP.Query.Clear();
    SNMP.Query.Host := m_printers[i].varToo.param;
    SNMP.Query.Port := 161;
    SNMP.Query.Community := 'public';
    SNMP.Query.PDUType := PDUGetRequest;
    (*
        SNMP hrPrinterStatus '1.3.6.1.2.1.25.3.5.1.1.1' - 1(other) 2(unknown) 3(idle) 4(printing) 5(warmup)
    *)
    SNMP.Query.MIBAdd('1.3.6.1.2.1.25.3.5.1.1.1', '');
    if (not m_printers[i].infoReceived) then
    begin
      (*
          SNMP sysName  '1.3.6.1.2.1.1.5.0'
      *)
      SNMP.Query.MIBAdd('1.3.6.1.2.1.1.5.0', '');
      (*
          SNMP sysDescr '1.3.6.1.2.1.1.1.0'
      *)
      SNMP.Query.MIBAdd('1.3.6.1.2.1.1.1.0', '');
    end;
    if SNMP.SendQuery() then
    begin
      m_printers[i].hrPrinterStatus := StrToInt(SNMP.Reply.Value[0]);
      if (not m_printers[i].infoReceived) then
      begin
        m_printers[i].sysName := SNMP.Reply.Value[1];
        m_printers[i].sysDescr := SNMP.Reply.Value[2];
        m_printers[i].infoReceived := true;
        Log('New printer: ''' + m_printers[i].sysName + ''' (' + m_printers[i].sysDescr + ')');
      end;
    end
    else
      m_printers[i].hrPrinterStatus := STATUS_NOLINK;
    if (not m_SpecTask.writeVar(m_printers[i].varToo, @m_printers[i].hrPrinterStatus)) then
    begin
      Log('!!! ERROR write variable ''' + m_printers[i].varToo.name + '''');
    end;
    Application.ProcessMessages();
  end;
end;

procedure TfrmMain.Log(const aMsg: string);
begin
  mmoMain.Lines.Add(TimeToStr(Now()) + '  ' + aMsg);
end;

procedure TfrmMain.tmrMainTimer(Sender: TObject);
begin
  if (m_halt) then
    Close();
  RequestPrintersState();
end;

procedure TfrmMain.OnMsg(var Msg: TMsg; var Handled: Boolean);
begin
  if (Msg.message = TASKS_QUIT_MSG) then
  begin
    close();
    Handled := true;
  end;
end;

initialization
  TASKS_QUIT_MSG := RegisterWindowMessage('TASKS_QUIT');

end.
