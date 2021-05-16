unit monitor;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, StdCtrls;

type

  { TFMonitor }

  TFMonitor = class(TForm)
    Memo1: TMemo;
    procedure FormClose(Sender: TObject; var CloseAction: TCloseAction);
    procedure FormCreate(Sender: TObject);
  private
  public
    procedure log(aText: string);
    procedure log(aCaption: string; const buf; size: integer; aText: string = '');
  end;

var
  FMonitor: TFMonitor;
  wektorczasu: integer = 0;

implementation

uses
  ecode;

type
  TTBuf = array [0..65535] of char;
  PPBuf = ^TTBuf;

{$R *.lfm}

{ TFMonitor }

procedure TFMonitor.FormClose(Sender: TObject; var CloseAction: TCloseAction);
begin
  CloseAction:=caNone;
end;

procedure TFMonitor.FormCreate(Sender: TObject);
begin
  Memo1.Clear;
end;

procedure TFMonitor.log(aText: string);
begin
  Memo1.Append(aText+' CZAS='+IntToStr(TimeToInteger+wektorczasu));
  Memo1.SelStart:=length(Memo1.Text);
end;

procedure TFMonitor.log(aCaption: string; const buf; size: integer;
  aText: string);
var
  l,i: integer;
  p: PPBuf;
  c: char;
  b: byte;
  s: string;
begin
  l:=0;
  s:='';
  p:=@buf;
  Memo1.Append(aCaption+' CZAS='+IntToStr(TimeToInteger+wektorczasu)+aText);
  for i:=0 to size-1 do
  begin
    c:=p^[i];
    b:=ord(c);
    inc(l);
    if s='' then s:='    '+IntToHex(b,2) else s:=s+' '+IntToHex(b,2);
    if l>=39 then
    begin
      Memo1.Append(s);
      l:=0;
      s:='';
    end;
  end;
  if s<>'' then Memo1.Append(s);
  Memo1.SelStart:=length(Memo1.Text);
end;

end.

