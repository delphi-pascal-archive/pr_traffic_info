{
  Программа для показа и накопления трафика сетевых соединений
  по статье http://delphimaster.ru/articles/netmon/index.html
  последняя версия  14.11.2005  http://programania.com/ti.zip
  вопросы mail@programania.com
  Руководство применения:
  Нажмите правую кнопку мыши на нужном соединении и выберите что надо
  еще можно смотреть и настраивать ti.txt, но только осторожно
}
unit Unit1;
{$S-,R-,B-}
interface

uses
  Windows, SysUtils, graphics, Forms, Dialogs, shellApi,
  ComCtrls,  Controls, ExtCtrls, Classes, StdCtrls, Menus ,messages;

type
  TForm1 = class(TForm)
    Timer1: TTimer;
    Image1: TImage;
    PopupMenu1: TPopupMenu;
    N1: TMenuItem;
    N2: TMenuItem;
    procedure Timer1Timer(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormCloseQuery(Sender: TObject; var CanClose: Boolean);
    procedure Image1MouseDown(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; Xm, Ym: Integer);
    procedure N1Click(Sender: TObject);
    procedure N2Click(Sender: TObject);
  private
    { Private declarations }
  procedure WMQueryEndSession(var Message:TWMEndSession);
  public
    { Public declarations }
  end;

var
  Form1: TForm1;
type
  TMibIfRow = packed record
    wszName		: array[0..255] of WideChar;
    dwIndex		: DWORD;
    dwType		: DWORD;
    dwMtu		: DWORD;
    dwSpeed		: DWORD;
    dwPhysAddrLen	: DWORD;
    bPhysAddr		: array[0..7] of Byte;
    dwAdminStatus	: DWORD;
    dwOperStatus	: DWORD;
    dwLastChange	: DWORD;
    dwInOctets		: DWORD;
    dwInUcastPkts	: DWORD;
    dwInNUCastPkts	: DWORD;
    dwInDiscards	: DWORD;
    dwInErrors		: DWORD;
    dwInUnknownProtos	: DWORD;
    dwOutOctets		: DWORD;
    dwOutUCastPkts	: DWORD;
    dwOutNUCastPkts	: DWORD;
    dwOutDiscards	: DWORD;
    dwOutErrors		: DWORD;
    dwOutQLen		: DWORD;
    dwDescrLen		: DWORD;
    bDescr		: array[0..255] of Char;
  end;
  TMibIfArray = array [0..512] of TMibIfRow;
  PMibIfRow = ^TMibIfRow;
  PmibIfArray = ^TmibIfArray;

const bc=$DFEFFF;//цвет фона

type
TMibIfTable = packed record
  dwNumEntries	: DWORD;
  Table    	: TMibIfArray;
end;
PMibIfTable = ^ TMibIfTable;

var
m:array of record
  tIn,tOut:integer;
  y,mon,d:word;
  seans,yn:integer;
  po:boolean;//признак обработки
  n:string;
end;
t:textFile;
x,yy:integer;
Year, Month, Day, Hour, Min, Sec, MSec:word;
GetIfTable:function(pIfTable: pMibIfTable; pdwSize:puLONG; bOrder:boolean):DWORD;stdcall;
s:string;
sm:string;//соединение на котором нажата мышь
j,rrr:integer;
seanss:integer=0; //сеанс за сегодня
qm:integer=0;     //число сведений
mbc:integer=20;   //цена мб в центах
kd:extended=29.00;//курс $
ns:string='';     //показываемый сеанс
ns1:string='';    //показанный первым сеанс
FLibHandle: tHandle;

implementation

{$R *.DFM}

PROCEDURE ost;
var i:integer;

Function sd(i:integer):string;
begin
result:=intToStr(i);
while length(result)<10 do result:=result+' ';
end;

begin
FreeLibrary(FLibHandle);
with form1 do begin
rewrite(t);
writeln(t,'Показывать='+ns);
writeln(t,'Цена мб в центах='+intToStr(mbc));
writeln(t,'Курс $='+formatFloat('00.00',kd));
writeln(t,'form1.width='+intToStr(width));
for i:=1 to qm do with m[i] do begin
  writeln(t,
  intToStr(d),'.',intToStr(mon),'.',intToStr(y),'-',intTostr(seans),#9,
  sd(tIn),#9,  sd(tOut),#9, n);
end;
closeFile(t);
end;
end;

procedure TForm1.WMQueryEndSession(var Message:TWMEndSession);
begin
//
if Message.EndSession = TRUE then begin
 ost;
 close;
end;
inherited;
end;

PROCEDURE uqm;
begin
inc(qm); if qm>=length(m) then setLength(m,length(m)+1000);
end;

FUNCTION kb(b:integer):string;
begin
if b<1000 then result:=intToStr(b) else
result:=formatfloat('0.0',b/1000)+' кб';
if b>=1000000 then insert(' мб ',result,length(result)-7);
if b>=10000000 then setLength(result,length(result)-9);
end;

FUNCTION rub(b:integer):string;
begin
rub:=formatfloat('0.00',(b/1000000*mbc/100*kd))+' руб.';
end;

PROCEDURE showInfo;
type TMAC = array [0..7] of Byte;
var
Table	  : tMibIfTable;
i,j       : integer;
Size      : integer;
sIn,sOut  : integer;
wIn,wOut  : integer;
dIn,dOut  : integer;
np        : integer;//номер последнего за сегодня в массиве
nh        : integer;

Procedure textO(ss:string; int,outt:integer);
var n,w:integer;
begin
with form1.image1.picture.bitmap.canvas do begin
inc(yy,18);
font.color:=$888888; textOut(10,yy,ss);   font.color:=$0;
textOut(20+x,yy,kb(int)); textOut(120+x,yy,kb(outt));
textOut(220+x,yy,kb(int+outt));
ss:=rub(int+outt);
n:=320+x;
w:=n+textWidth(ss)+20;
if w>form1.width then form1.width:=w;
textOut(n,yy,ss);
end;
end;

BEGIN
with form1.image1 do begin

Size := SizeOf(Table);
if GetIfTable(@Table, @Size, False ) = 0 then
for i:= 0 to Table.dwNumEntries-1 do begin
  s:=String(Table.Table[i].bDescr);
  s:=copy(s,1,Table.Table[i].dwDescrLen);
  sIn:=Table.Table[i].dwInOctets;
  sOut:=Table.Table[i].dwOutOctets;
  np:=0;
  for j:=1 to qm do if m[j].n=s then with m[j] do begin
    if (year=y)and(month=mon)and(day=d)and(seans=0) then begin
      if (sIn>=tIn) and (sOut>=tOut) then begin np:=j; tIn:=sIn; tOut:=sOut end else
      begin
//новый сеанс связи за сегодня
        inc(seanss);
        seans:=seanss;
        uqm;
        np:=qm;
        m[qm]:=m[j]; m[qm].seans:=0; m[qm].tIn:=sIn; m[qm].tOut:=sOut;
      end;
    end;
  end;
  if np=0 then begin
//первое соединение за сегодня
    uqm;
    with m[qm] do begin
      n:=s; y:=year; mon:=month; d:=day; tIn:=sIn; tOut:=sOut; seans:=0;
    end;
  end;
end;


x:=70;
with picture.bitmap.canvas do begin
picture.bitmap.height:=height;
picture.bitmap.width:=width;
brush.color:=bc;
font.size:=10;
yy:=4;
ns1:='';
for i:=1 to qm do begin m[i].po:=false; m[i].yn:=0 end;
for i:=1 to qm do with canvas,m[i] do if not po then begin
  s:=n;
  if ns1='' then ns1:=s;
  wIn:=0;wOut:=0;   sIn:=0;sOut:=0;  dIn:=0;dOut:=0;
//сбор сведений всего, за день, за сеанс
  for j:=1 to qm do with m[j] do if not po and(n=s) then begin
    inc(wIn,tIn); inc(wOut,tOut);
    if (d=day)and(mon=month)and(y=year) then begin
      inc(dIn,tIn);inc(dOut,tOut);
      if seans=0 then begin sIn:=tIn; sOut:=tOut end;
    end;
    m[j].po:=true;
  end;
  if (ns='')or(s=ns) then begin
    yn:=yy;
    nh:=yy+16*8;
    if nh>clientheight then begin
      form1.height:=nh;
      height:=nh;
      picture.bitmap.height:=form1.clientHeight;
      application.ProcessMessages;
    end;
    if length(s)>60 then s:=copy(s,1,60)+'...';
    font.color:=$004488;font.style:=[fsBold]; textOut(10,yy,s); font.color:=$888888;font.style:=[];
    inc(yy,18);
    textOut(20+x,yy,'Отправлено');
    textOut(120+x,yy,'Принято');
    textOut(220+x,yy,'Всего');
    textOut(320+x,yy,'Сумма');
    textO('Сеанс',sOut,sIn);
    textO('Сегодня',dOut,dIn);
    textO('Всего',wOut,wIn);
    inc(yy,24);
    if ns<>'' then application.title:=kb(dOut+dIn);
  end;
end;
end;
end;//form1
end;

procedure TForm1.FormCreate(Sender: TObject);
var
i,r:integer;
p,{=}z:string;
Function wel(c:char):integer;
var se:string;
begin
//выделение элемента до символа c из s
se:='';
i:=1;
while (i<=length(s))and(s[i]<>c) do begin
  if s[i] in['0'..'9'] then se:=se+s[i];
  inc(i);
end;
wel:=strToIntDef(se,0);
delete(s,1,i);

end;

BEGIN
FLibHandle := LoadLibrary('IPHLPAPI.DLL'); //Загружаем библиотеку
if FLibHandle = 0 then Exit;
@GetIfTable := GetProcAddress(FLibHandle, 'GetIfTable');

if not Assigned(GetIfTable) then begin
  FreeLibrary(FLibHandle);
  form1.Close;
end;

color:=bc;
image1.picture.bitmap.canvas.brush.color:=bc;

DecodeDate(Now, Year, Month, Day);
Decodetime(Now, Hour, Min, Sec, MSec);
if Hour<6 then dec(day);//завтра еще не наступило
if day<1 then
if Month in[4,6,9,11] then day:=30 else
if Month=2 then begin if Year mod 4=0 then day:=29 else day:=28 end
else day:=31;

assignFile(t,'ti.txt');
{$i-}reset(t);{$i+}
if ioresult=0 then begin
while not eof(t) do begin
  readln(t,s);
  if pos(#9,s)=0 then begin
    i:=pos('=',s);
    if (i>0) then begin
      p:=trim(copy(s,1,i-1));
      z:=trim(copy(s,i+1,$FFFF));
      if p='Показывать' then ns:=z;
      if p='Цена мб в центах' then mbc:=strToIntDef(z,20);
      if p='Курс $' then begin val(z,kd,r);if r<>0 then kd:=29 end;
      if p='form1.width' then width:=strToIntDef(z,500);
    end;
  end
  else begin
    uqm;
    with m[qm] do begin
      d:=wel('.'); mon:=wel('.'); y:=wel('-');  seans:=wel(#9);
      tIn:=wel(#9); tOut:=wel(#9); n:=s;
    end;
  end;
end;
closeFile(t);
end;
timer1.enabled:=true;
end;

procedure TForm1.FormCloseQuery(Sender: TObject; var CanClose: Boolean);
begin
ost;
end;

procedure TForm1.Timer1Timer(Sender: TObject);
begin
timer1.Enabled:=false;
showInfo;
timer1.Enabled:=true;
end;

procedure TForm1.Image1MouseDown(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; Xm, Ym: Integer);
var i,min:integer;
begin
if button=mbRight then begin
//на чем нажали?
min:=$FFFFFF;
sm:=ns1;
for i:=1 to qm do with m[i] do
  if (yn>0)and(ym>=yn)and(ym-yn<min) then begin sm:=n; min:=ym-yn end;

if ns='' then N1.caption:='1 соединение'
         else N1.caption:='Все';

PopupMenu1.popup(left+Xm,top+Ym+20);
end;
end;

procedure TForm1.N1Click(Sender: TObject);
begin
with image1.picture.bitmap do
canvas.fillRect(rect(0,0,width,height));
if ns='' then begin ns:=sm; height:=100 end else ns:='';
end;

procedure TForm1.N2Click(Sender: TObject);
var
t:textFile;
imf:string;
i,
sIn,sOut, //всего
dIn,dOut, //за день
dp,mp,yp:integer; // дата прошлой записи
Procedure writeS;
begin
// вывод строки таблицы
writeln(t,'<tr>',
'<td align=right>',intToStr(dp),'.',intToStr(mp),'.',intToStr(yp),'</td>',
'<td align=right>',rub(dIn+dOut),'</td>',
'<td align=right>',kb(dOut),'</td>',
'<td align=right>',kb(dIn),'</td>',
'<td align=right>',kb(dIn+dOut),'</td>',
'</tr>'#13#10);
end;

begin
//Показ истории растраты трафика
imf:=extractFilePath(application.exeName)+'ti.htm';
assignFile(t,imf);
rewrite(t);
writeln(t,
'<html><head>'#13#10,
'<meta http-equiv="Content-Type" content="text/html; charset=windows-1251">'#13#10,
'<style type="text/css">'#13#10,
'a {color:#884422; font-style: normal; font-family: arial;  font-size=14}'#13#10,
'table.tm td {background-color:#FFF2E8; font-family: arial; font-size=14}'#13#10,
'table.tm th {background-color:#E8D8CC; font-family: arial; color:#CC8868; font-size=14}'#13#10,
'</style></head>'#13#10,
'<body bgcolor=#FCF8F4>'#13#10,

'<font color=#AA6622>'#13#10,
'<center><font size=+2>Трафик</font><br>'#13#10,
'<b>',sm,'</b></font><br><br>'#13#10,

'<table class="tm" bgcolor=#CCAA88 cellspacing=1 cellpadding=4 border=0>'#13#10,
'<tr>'#13#10,
'<th>Дата</th><th>Сумма</th><th>Отправлено</th><th>Принято</th><th>Всего</th>'#13#10,
'</tr>'#13#10);

sIn:=0; sOut:=0; dp:=-1;
for i:=qm downTo 1 do with m[i] do if n=sm then begin
//  if i=qm then begin dp:=d; mp:=mon; yp:=y; dIn:=0; dOut:=0 end;
  if (d<>dp)or(mon<>mp)or(y<>yp) then begin
    if dp>0 then writeS; // 1-ую пропускаем чтоб было с чем сравнивать
    dIn:=0;
    dOut:=0;
  end;
  inc(dIn,tIn);   inc(dOut,tOut);
  inc(sIn,tIn);   inc(sOut,tOut);
  dp:=d; mp:=mon; yp:=y;
end;
writeS;

writeln(t,'<tr>',
'<th><b>Всего</b></td>',
'<th align=right><b>',rub(sIn+sOut),'</b></td>',
'<th align=right><b>',kb(sOut),'</b></td>',
'<th align=right><b>',kb(sIn),'</b></td>',
'<th align=right><b>',kb(sIn+sOut),'</b></td>',
'</tr>'#13#10,
'</table></center><body></html>');

closeFile(t);
ShellExecute(0,'open',pChar(imf),nil,nil,SW_NORMAL);
end;

end.
