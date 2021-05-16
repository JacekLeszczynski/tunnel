unit main;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, StdCtrls, Spin,
  ExtCtrls, Buttons, XMLPropStorage, NetSocket, PointerTab, LiveTimer,
  uETilePanel, ueled, lNet, DCPrijndael;

type

  { TFMain }

  TFMain = class(TForm)
    Bevel2: TBevel;
    BitBtn1: TBitBtn;
    BitBtn2: TBitBtn;
    BitBtn3: TBitBtn;
    CheckBox1: TCheckBox;
    cCrypt: TCheckBox;
    cUDP: TCheckBox;
    cMaster: TRadioButton;
    cWejscie: TRadioButton;
    cSlave: TRadioButton;
    cWyjscie: TRadioButton;
    aes: TDCP_rijndael;
    host: TEdit;
    Label10: TLabel;
    Label11: TLabel;
    Label12: TLabel;
    Label13: TLabel;
    Label14: TLabel;
    Label15: TLabel;
    Label6: TLabel;
    Label8: TLabel;
    Label9: TLabel;
    mem: TPointerTab;
    io2: TNetSocket;
    wewn2: TNetSocket;
    tC1: TTimer;
    tC0: TTimer;
    whost: TEdit;
    Label1: TLabel;
    Label2: TLabel;
    io: TNetSocket;
    Label3: TLabel;
    Label4: TLabel;
    Label5: TLabel;
    Label7: TLabel;
    test: TTimer;
    test2: TTimer;
    uELED1: TuELED;
    uELED2: TuELED;
    uETilePanel2: TuETilePanel;
    uETilePanel3: TuETilePanel;
    wewn: TNetSocket;
    WorkPort: TSpinEdit;
    IOPort: TSpinEdit;
    uETilePanel1: TuETilePanel;
    propstorage: TXMLPropStorage;
    procedure BitBtn1Click(Sender: TObject);
    procedure BitBtn2Click(Sender: TObject);
    procedure BitBtn3Click(Sender: TObject);
    procedure CheckBox1Change(Sender: TObject);
    procedure FormClose(Sender: TObject; var CloseAction: TCloseAction);
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure io2ReceiveBinary(const outdata; size: longword; aSocket: TLSocket
      );
    procedure ioReceiveBinary(const outdata; size: longword; aSocket: TLSocket);
    procedure ioStatus(aActive, aCrypt: boolean);
    procedure memCreateElement(Sender: TObject; var AWskaznik: Pointer);
    procedure memDestroyElement(Sender: TObject; var AWskaznik: Pointer);
    procedure memReadElement(Sender: TObject; var AWskaznik: Pointer);
    procedure memWriteElement(Sender: TObject; var AWskaznik: Pointer);
    procedure tC0Timer(Sender: TObject);
    procedure tC1Timer(Sender: TObject);
    procedure test2Timer(Sender: TObject);
    procedure testTimer(Sender: TObject);
    procedure wewn2ReceiveBinary(const outdata; size: longword;
      aSocket: TLSocket);
    procedure wewnCryptBinary(const indata; var outdata; var size: longword);
    procedure wewnDecryptBinary(const indata; var outdata; var size: longword);
    procedure wewnReceiveBinary(const outdata; size: longword; aSocket: TLSocket
      );
    procedure wewnReceiveString(aMsg: string; aSocket: TLSocket;
      aBinSize: integer; var aReadBin: boolean);
    procedure wewnStatus(aActive, aCrypt: boolean);
    procedure wewnTimeVector(aTimeVector: integer);
    procedure _PS;
  private
    run_monitor: boolean;
    ccc: boolean;
    ile_in,ile_out: integer;
    ile2_in,ile2_out: integer;
    procedure AllOff;
    procedure wyslij_kolejke;
    procedure suma(aIn: integer = 0; aOut: integer = 0; aIn2: integer = 0; aOut2: integer = 0);
  public
  end;

var
  FMain: TFMain;

implementation

uses
  ecode, monitor;

type
  TTBuf = array [0..65535] of char;
  PPBuf = ^TTBuf;
  TMe = record
    size: integer;
    mem: TTBuf;
  end;
  PMe = ^TMe;

var
  recmem: TMe;

{$R *.lfm}

{ TFMain }

procedure log(s: string);
begin
  {$IFDEF UNIX}
  writeln(s);
  {$ENDIF}
end;

procedure log(tekst: string; const buf; size: integer; tekst2: string);
var
  i: integer;
  p: PPBuf;
begin
  {$IFDEF UNIX}
  p:=@buf;
  write(tekst);
  for i:=0 to size-1 do write(ord(p^[i]),' ');
  writeln(tekst2);
  {$ENDIF}
end;

procedure TFMain.BitBtn3Click(Sender: TObject);
begin
  close;
end;

procedure TFMain.CheckBox1Change(Sender: TObject);
begin
  if CheckBox1.Checked then
  begin
    if run_monitor then exit;
    FMonitor:=TFMonitor.Create(self);
    FMonitor.Show;
    run_monitor:=true;
  end else begin
    if not run_monitor then exit;
    FMonitor.Free;
    run_monitor:=false;
  end;
end;

procedure TFMain.FormClose(Sender: TObject; var CloseAction: TCloseAction);
begin
  AllOff;
end;

procedure TFMain.FormCreate(Sender: TObject);
begin
  SetConfDir('studio-jahu-tunel');
  propstorage.FileName:=MyConfDir('config.xml');
  propstorage.Active:=true;
  ccc:=false;
  run_monitor:=false;
end;

procedure TFMain.FormDestroy(Sender: TObject);
begin
  if run_monitor then FMonitor.Free;
end;

procedure TFMain.io2ReceiveBinary(const outdata; size: longword;
  aSocket: TLSocket);
var
  l: integer;
begin
  if size>0 then
  begin
    l:=wewn2.SendBinary(outdata,size);
    suma(0,0,l,0);
  end;
end;

procedure TFMain.ioReceiveBinary(const outdata; size: longword;
  aSocket: TLSocket);
var
  l: integer;
begin
  if size>0 then
  begin
    l:=wewn.SendString('BIN',@outdata,size);
    suma(l,0);
    if run_monitor then FMonitor.log('[O>W] Ramka '+IntToStr(size)+' bajtów:',outdata,size,' (Udało się wysłać '+IntToStr(l)+' bajtów)');
  end;
end;

procedure TFMain.ioStatus(aActive, aCrypt: boolean);
begin
  if io.Mode=smServer then uELED2.Color:=clYellow else uELED2.Color:=clRed;
  uELED2.Active:=aActive;
  test2.Enabled:=aActive;
  if aActive and (mem.Count>0) then wyslij_kolejke;
end;

procedure TFMain.memCreateElement(Sender: TObject; var AWskaznik: Pointer);
var
  p: PMe;
begin
  new(p);
  AWskaznik:=p;
end;

procedure TFMain.memDestroyElement(Sender: TObject; var AWskaznik: Pointer);
var
  p: PMe;
begin
  p:=AWskaznik;
  dispose(p);
end;

procedure TFMain.memReadElement(Sender: TObject; var AWskaznik: Pointer);
var
  p: PMe;
begin
  p:=AWskaznik;
  recmem:=p^;
end;

procedure TFMain.memWriteElement(Sender: TObject; var AWskaznik: Pointer);
var
  p: PMe;
begin
  p:=AWskaznik;
  p^:=recmem;
end;

procedure TFMain.tC0Timer(Sender: TObject);
begin
  tC0.Enabled:=false;
  if io.Active then io.Disconnect;
  if io2.Active then io2.Disconnect;
end;

procedure TFMain.tC1Timer(Sender: TObject);
begin
  tC1.Enabled:=false;
  if not io.Active then io.Connect;
  if (not io2.Active) and cUDP.Checked then io2.Connect;
end;

procedure TFMain.test2Timer(Sender: TObject);
begin
  if io.Mode=smServer then
  begin
    if io.Count=0 then uELED2.Color:=clYellow else uELED2.Color:=clRed;
    if io.Count=0 then
    begin
      if ccc then
      begin
        wewn.SendString('DISCONNECT');
        ccc:=false;
      end;
    end else begin
      if not ccc then
      begin
        wewn.SendString('CONNECT');
        ccc:=true;
      end;
    end;
  end;
end;

procedure TFMain.testTimer(Sender: TObject);
begin
  if wewn.Mode=smServer then if wewn.Count=0 then uELED1.Color:=clYellow else uELED1.Color:=clBlue;
end;

procedure TFMain.wewn2ReceiveBinary(const outdata; size: longword;
  aSocket: TLSocket);
var
  l: integer;
begin
  if size>0 then
  begin
    l:=io2.SendBinary(outdata,size);
    suma(0,0,0,l);
  end;
end;

procedure TFMain.wewnCryptBinary(const indata; var outdata; var size: longword);
var
  vec,klucz: string;
begin
  size:=CalcBuffer(size,16);
  klucz:='1hs53hd74hdt37sh';
  vec:='hf74hd73j3gdd64g';
  aes.Init(klucz[1],128,@vec[1]);
  aes.Encrypt(indata,outdata,size);
  aes.Burn;
end;

procedure TFMain.wewnDecryptBinary(const indata; var outdata; var size: longword
  );
var
  vec,klucz: string;
begin
  klucz:='1hs53hd74hdt37sh';
  vec:='hf74hd73j3gdd64g';
  aes.Init(klucz[1],128,@vec[1]);
  aes.Decrypt(indata,outdata,size);
  aes.Burn;
end;

procedure TFMain.wewnReceiveBinary(const outdata; size: longword;
  aSocket: TLSocket);
var
  l,i: integer;
  p: PPBuf;
begin
  if io.Active then
  begin
    l:=io.SendBinary(outdata,size);
    suma(0,l);
    if run_monitor then FMonitor.log('[W>I] SENDING '+IntToStr(size)+' bajtów:',outdata,size,' (Udało się wysłać '+IntToStr(l)+' bajtów)');
  end else begin
    p:=@outdata;
    recmem.size:=size;
    for i:=0 to size-1 do recmem.mem[i]:=p^[i];
    mem.Add;
  end;
end;

procedure TFMain.wewnReceiveString(aMsg: string; aSocket: TLSocket;
  aBinSize: integer; var aReadBin: boolean);
begin
  if aMsg='BIN' then
  begin
    if not io.Active then tC1.Enabled:=true;
    aReadBin:=true;
  end else
  if aMsg='CONNECT' then
  begin
    tC1.Enabled:=true;
  end else
  if aMsg='DISCONNECT' then
  begin
    tC0.Enabled:=true;
  end else FMonitor.log('[WW] Odebrana niezdefiniowana ramka "'+aMsg+'" zawierająca wielkość binarną: '+IntToStr(aBinSize)+' bajtów!');
end;

procedure TFMain.wewnStatus(aActive, aCrypt: boolean);
begin
  if wewn.Mode=smServer then uELED1.Color:=clYellow else
  begin
    if not aActive then if io.Active then io.Disconnect;
    uELED1.Color:=clBlue;
  end;
  uELED1.Active:=aActive;
  test.Enabled:=aActive;
  if not aActive then wektorczasu:=0;
end;

procedure TFMain.wewnTimeVector(aTimeVector: integer);
begin
  wektorczasu:=aTimeVector;
end;

procedure TFMain.BitBtn1Click(Sender: TObject);
begin
  wewn.Port:=WorkPort.Value;
  wewn2.Port:=WorkPort.Value;
  if cCrypt.Checked then wewn.Security:=ssCrypt else wewn.Security:=ssNone;
  if cMaster.Checked then
  begin
    wewn.Mode:=smServer;
    wewn.Host:='localhost';
    wewn.Connect;
    wewn2.Mode:=smServer;
    wewn2.Host:='localhost';
    if cUDP.Checked then wewn2.Connect;
  end else begin
    wewn.Mode:=smClient;
    wewn.Host:=whost.Text;
    wewn.Connect;
    wewn2.Mode:=smClient;
    wewn2.Host:=whost.Text;
    if cUDP.Checked then wewn2.Connect;
    wewn.GetTimeVector;
  end;
  if not wewn.Active then exit;
  ile_in:=0;
  ile_out:=0;
  ile2_in:=0;
  ile2_out:=0;
  suma;
  io.Port:=IOPort.Value;
  if cWejscie.Checked then
  begin
    io.Mode:=smServer;
    io.Host:='localhost';
    io.Connect;
    io2.Mode:=smServer;
    io2.Host:='localhost';
    if cUDP.Checked then io2.Connect;
  end else begin
    io.Mode:=smClient;
    io.Host:=host.Text;
    io2.Mode:=smClient;
    io2.Host:=host.Text;
  end;
end;

procedure TFMain.BitBtn2Click(Sender: TObject);
begin
  if io.Active then io.Disconnect;
  if wewn.Active then wewn.Disconnect;
  if io2.Active then io2.Disconnect;
  if wewn2.Active then wewn2.Disconnect;
end;

procedure TFMain._PS;
begin
  application.ProcessMessages;
end;

procedure TFMain.AllOff;
begin
  if io.Active then io.Disconnect;
  if wewn.Active then wewn.Disconnect;
  if io2.Active then io2.Disconnect;
  if wewn2.Active then wewn2.Disconnect;
end;

procedure TFMain.wyslij_kolejke;
var
  l: integer;
begin
  while mem.Read do
  begin
    l:=io.SendBinary(&recmem.mem[0],recmem.size);
    suma(0,l);
    if run_monitor then FMonitor.log('[M>I] SENDING '+IntToStr(recmem.size)+' bajtów:',&recmem.mem[0],recmem.size,' (Udało się wysłać '+IntToStr(l)+' bajtów)');
  end;
end;

procedure TFMain.suma(aIn: integer; aOut: integer; aIn2: integer; aOut2: integer
  );
begin
  ile_in+=aIn;
  ile_out+=aOut;
  ile2_in+=aIn2;
  ile2_out+=aOut2;
  Label10.Caption:=IntToStr(ile_in);
  Label11.Caption:=IntToStr(ile_out);
  Label14.Caption:=IntToStr(ile2_in);
  Label15.Caption:=IntToStr(ile2_out);
end;

end.

