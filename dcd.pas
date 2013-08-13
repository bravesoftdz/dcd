{******************************************************************************
*  DCD 2.0a - Outono? de 1993.                                                *
*            Originalmente desenvolvido numa iniciativa louvavel para acabar  *
*            com a pirataria na velha e boa CompuSystems!                     *
**---------------------------------------------------------------------------**
*                                                                             *
*  Autor              : DELUAN PEREZ                                          *
*  desenvolvido em    : 08/01/1990                                            *
*  Ultima atualizacao : Outono? de 1993                                       *
*                                                                             *
**---------------------------------------------------------------------------**
*  Historico de Modificacoes:                                                 *
*                                                                             *
*    11/04/1993 - 2.0, por Deluan Perez                                       *
*               - Dada uma "geral" no codigo! Agora o algoritimo funciona     *
*                 quase que totalmente igual ao NCD.                          *
*                                                                             *
*    08/01/1990 - 1.0, por Deluan Cotts                                       *
*               - Versao inicial                                              *
******************************************************************************}

program DCD;

uses Crt, SysUtils;

const TREEFILE = '.treeinfo.dcd';

type FolhaPtr = ^Folha;
     PathStr = String;
     Folha = record
                   path : ^PathStr;
                   prx  : FolhaPtr;
             end;

var p      : FolhaPtr;
    c      : LongInt;
    s, par : String;
    first  : FolhaPtr;
    f      : Text;
    drive  : String[2];
    atual  : PathStr = '';
    rescan : Boolean;
    notmem : Boolean;

{-----------------------------------------------------------------------------}
procedure Apresentacao;
begin
     WriteLn(stderr, 'Deluan Change Directory 2.0 (c) 1990,2013 por Deluan');
end;

{-----------------------------------------------------------------------------}
function UpStr(s : String) : String;
begin
     //for i := 1 to l do s[i] := Upcase(s[i]);
     UpStr := s;
end;

{-----------------------------------------------------------------------------}
function Posr(s1, s2 : String) : Byte;
var i  : Byte;
    l1 : Byte absolute s1;
    l2 : Byte absolute s2;
begin
     if l1 > l2 then Posr := 0
     else begin
          i := l2 - l1 + 1;
          while (i > 0) and (Copy(s2, i, l1) <> s1) do Dec(i);
          Posr := i;
     end;
end;

{-----------------------------------------------------------------------------}
procedure Cadastra(nivel : String);
var pt : FolhaPtr;
begin
     pt := p;  GetMem(p, SizeOf(p^));
     if p <> NIL then begin
        GetMem(p^.path, Length(nivel)+1);
        if p^.path <> NIL then begin
           if pt <> NIL then pt^.prx := p
           else first := p;
           p^.prx   := NIL;
           p^.path^ := nivel;
           Inc(c);
           //WriteLn(nivel);
           Write(stderr, c:10, #8#8#8#8#8#8#8#8#8#8);
        end
        else notmem := TRUE;
     end
     else notmem := TRUE;
end;

{-----------------------------------------------------------------------------}
procedure PosStack(n : String);
begin
     p := first;
     while (p <> NIL) and (n <> p^.path^) do
           p := p^.prx;
end;

{-----------------------------------------------------------------------------}
procedure Next;
begin
     p := p^.prx;
     if p = NIL then p := first;
end;

{-----------------------------------------------------------------------------}
procedure Tree(nivel : PathStr);
var sr : TSearchRec;
begin
     if nivel <> '' then Cadastra(nivel)
     else Cadastra('/');
     if FindFirst(nivel + '/*', faDirectory, sr) = 0 then
         repeat
//               writeln(stderr, sr.name, ': ', sr.attr, '&', faDirectory, '=', sr.attr and faDirectory);
               with sr do begin
                    if ((attr and faDirectory) = faDirectory) and (name[1] <> '.') then begin
                       //writeln(stderr, nivel + ' ' + sr.name);
                       Tree(nivel + '/' + name);
                    end;
               end;
         until FindNext(sr) <> 0;
     FindClose(sr);
end;

{-----------------------------------------------------------------------------}
procedure Save;
begin
     p := first;
     Rewrite(f);
     while p <> NIL do begin
           WriteLn(f, p^.path^);
           p := p^.prx;
     end;
     p := first;
     Close(f);
end;

function GetHomePath: String;
begin
     GetHomePath := GetEnvironmentVariable('HOME');
end;

{-----------------------------------------------------------------------------}
procedure Load;
var s : String;
begin
     notmem := FALSE;
     p      := NIL;
     first  := NIL;
     c      := 0;   {$I-}
     Reset(f);      {$I+}
     if (IoResult > 0) then begin
        Write(stderr, 'Rescaning Tree ... ');
        Tree(GetHomePath);
        Save;
     end
     else begin
          Write(stderr, 'Loading Tree ... ');
          while not Eof(f) do begin
                ReadLn(f, s);
                Cadastra(s);
          end;
          Close(f);
     end;
     Write(stderr, #13); ClrEol;
end;

{-----------------------------------------------------------------------------}
function Match(n1, n2 : String; mode : Byte) : Boolean;
begin
     n2 := Copy(n2, Posr('/', n2) + 1, 80);
     case mode of
          0 : Match := (n1 = n2);
          1 : Match := (n1 = Copy(n2, 1, Length(n1)));
     end;
end;

{-----------------------------------------------------------------------------}
function Find(n : String; mode : Integer) : PathStr;
var pt     : FolhaPtr;
    s      : String;
begin
     if (n = '') then begin
        Exit('');
     end;
     if mode = 2 then begin
       repeat
             delete(n, length(n), 1);
             //Dec(n[0]);
             s := Find(n, 1);
       until (s <> '') or (length(n) = 0);
       Exit(s);
     end;

     PosStack(atual);
     if p = NIL then begin
        Erase(f);
        Load;
     end;
     if not Match(n, atual, mode) then p := first;
     pt := p;
     repeat
           Next;
     until Match(n, p^.path^, mode) or (pt = p);
     if n = '/' then n := '';
     if Match(n, p^.path^, mode) then begin
         Exit(p^.path^);
     end;
     Exit('');
end;

begin
     TextRec(Output).FlushFunc := TextRec(Output).InOutFunc;
     TextRec(StdErr).FlushFunc := TextRec(StdErr).InOutFunc;

     DirectVideo := FALSE;
     if ParamCount <> 1 then begin
        Apresentacao;
        Halt(1);
     end;

     Assign(f, GetHomePath + '/' + TREEFILE);
     par := UpStr(ParamStr(1));
     rescan := (par = '-R');
     if rescan then begin  {$I-}
        Erase(f);          {$I+}
        if IoResult = 0 then;
     end;

     Load;

     if notmem then begin
        WriteLn(stderr, 'Not enough memory!');
        Halt(1);
     end;

     if rescan then Halt;

     getDir(0, atual);
     if (atual[2] = ':') then begin
        drive := Copy(atual, 1, 2);
        Delete(atual, 1, 2);
     end;

     s := Find(par, 0);
     if s = '' then s := Find(par, 1);
     if s = '' then s := Find(par, 2);
     if s = '' then WriteLn(stderr, 'Directory not found!')
     else begin      {$I-}
          WriteLn(stderr, s);
          WriteLn(s);
          ChDir(s);  {$I+}
          if IoResult <> 0 then begin
             WriteLn(stderr, 'ERROR: Directory does not exist: ', drive, s);
             WriteLn(stderr, '       Execute ''dcd -r''.');
          end;
     end;
end.