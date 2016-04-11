unit uMain;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, IdBaseComponent, IdComponent, IdUDPBase, IdUDPClient, IdSNMP,
  StdCtrls, ExtCtrls, JvExControls, JvComCtrls,

  uConsts, uSupvis, uLinker, uBinSpecTask, uGlobalCommon, uTOOThread, uTOOSpecTask,
  JvComponentBase, JvTrayIcon, Menus;

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
    memLog: TMemo;
    trayMain: TJvTrayIcon;
    mnuMain: TMainMenu;
    N1: TMenuItem;
    N2: TMenuItem;
    procedure FormCreate(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure tmrMainTimer(Sender: TObject);
    procedure N2Click(Sender: TObject);
  private
    { Private declarations }
    m_SpecTask : TMySpecTask;
    m_printers : array of TMyPrinter;
    procedure RequestPrintersState;
    procedure logMsg(const aMsg : string);
    procedure OnMsg(var Msg: TMsg; var Handled: Boolean);
  public
    { Public declarations }
  end;

var
  frmMain: TfrmMain;

implementation

{$R *.dfm}

procedure SetWindowCloseFlag(const aWin : THandle; const aEnable : Boolean);
var
  mnu : HMENU;
begin
  mnu := GetSystemMenu(aWin, false);
  if (mnu <> 0) then
    if aEnable then
      EnableMenuItem(mnu, 6, MF_BYPOSITION or MF_ENABLED)
    else
      EnableMenuItem(mnu, 6, MF_BYPOSITION or MF_DISABLED);
end;

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
  SetWindowCloseFlag(Handle, False);
  Application.OnMessage := OnMsg;
  trayMain.Icon.Assign(Application.Icon);
  trayMain.HideApplication();
  trayMain.Hint := Application.Title;
  Caption := Application.Title;
  try
    logMsg('Запуск');
    case ParamCount of
      1 : msTimer := StrToIntDef(ParamStr(1), 1000);
      2 : msTimer := StrToIntDef(ParamStr(2), 1000);
      else
        msTimer := 1000;
    end;
    tmrMain.Interval := msTimer;

    logMsg('Период обновления данных: ' + IntToStr(tmrMain.Interval) + ' мс');

    if (ParamCount > 1) then
      m_specTask := TMySpecTask.createFromCmd(nil)
    else
      m_specTask := TMySpecTask.create(ExtractFileName(ParamStr(0)), nil);

    logMsg('Регистрация задачи "' + m_SpecTask.TaskName + '"');
    SetLength(m_printers, m_SpecTask.VarCount);
    for i := low(m_printers) to high(m_printers) do
    begin
      m_printers[i].infoReceived := false;
      m_printers[i].varToo := m_SpecTask.Variable[i];
    end;
    m_SpecTask.connect(false);
    tmrMain.Enabled := True;
    logMsg('Ок');
  except
    on e : Exception do
    begin
      logMsg('ОШИБКА! ' + e.Message);
      raise;
    end;
  end;
end;

procedure TfrmMain.FormClose(Sender: TObject; var Action: TCloseAction);
var
  i : integer;
begin
  tmrMain.Enabled := false;
  if (m_SpecTask.connected) then
  begin
    for i := low(m_printers) to high(m_printers) do
    begin
      m_printers[i].hrPrinterStatus := STATUS_NOLINK;
      m_SpecTask.writeVar(m_printers[i].varToo, @m_printers[i].hrPrinterStatus);
      m_SpecTask.writeVar(m_printers[i].varToo, nil);
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
        logMsg('Информация об устройстве: ' + m_printers[i].varToo.param);
        logMsg('Имя: ' + m_printers[i].sysName);
        logMsg('Описание: ' + m_printers[i].sysDescr);
      end;
    end
    else
      m_printers[i].hrPrinterStatus := STATUS_NOLINK;
    if (not m_SpecTask.writeVar(m_printers[i].varToo, @m_printers[i].hrPrinterStatus)) then
    begin
      logMsg('ОШИБКА! записи переменной "' + m_printers[i].varToo.name + '"');
    end;
  end;
end;

procedure TfrmMain.logMsg(const aMsg: string);
begin
  memLog.Lines.Add(TimeToStr(Now()) + ': ' + aMsg);
  memLog.SelStart := Length(memLog.Text);
end;

procedure TfrmMain.tmrMainTimer(Sender: TObject);
begin
  RequestPrintersState();
end;

var
  TASKS_QUIT_MSG_received : Boolean = false;

procedure TfrmMain.OnMsg(var Msg: TMsg; var Handled: Boolean);
begin
  if (Msg.message = TASKS_QUIT_MSG) then
  begin
    if (not TASKS_QUIT_MSG_received) then
    begin
      TASKS_QUIT_MSG_received := True;
      Close();
    end;
    Handled := true;
  end;
end;

procedure TfrmMain.N2Click(Sender: TObject);
begin
  Close();
end;

initialization
  TASKS_QUIT_MSG := RegisterWindowMessage('TASKS_QUIT');

end.
