{******************************************************************************
*  DCD 2.0a - Outono? de 1993.                                                *
*            Originalmente desenvolvido numa iniciativa louv vel para acabar  *
*            com a pirataria na velha e boa CompuSystems!                     *
**---------------------------------------------------------------------------**
*                                                                             *
*  Autor              : DELUAN PEREZ                                          *
*  desenvolvido em    : 08/01/1990                                            *
*  £ltima atualiza‡„o : Outono? de 1993                                       *
*                                                                             *
**---------------------------------------------------------------------------**
*  Hist¢rico de Modifica‡”es:                                                 *
*                                                                             *
*    11/04/1993 - 2.0, por Deluan Perez                                       *
*               - Dada uma "geral" no c¢digo! Agora o algoritimo funciona     *
*                 quase que totalmente igual ao NCD.                          *
*                                                                             *
*    08/01/1990 - 1.0, por Deluan Cotts                                       *
*               - Vers„o inicial                                              *
******************************************************************************}

program DCD;

{$M 4096,10000,655360}   { 8312 em 308 diret¢rios no meu disquinho de 320M }

uses Crt, Dos{, Memory};

const TREEFILE = '\TREEINFO.DCD';

type FolhaPtr = ^Folha;
     Folha = record
                   path : ^PathStr;
                   prx  : FolhaPtr;
             end;

var p      : FolhaPtr;
    c      : Word;
    s, par : String;
    first  : FolhaPtr;
    f      : Text;
    drive  : String[2];
    atual  : PathStr;
    rescan : Boolean;
    notmem : Boolean;

{-----------------------------------------------------------------------------}
procedure Apresentacao;
var oldAttr : Byte;
begin
     oldAttr := TextAttr;
     WriteLn;
     TextColor(White);
     Write('Deluan Change Directory 2.0');
     TextAttr := oldAttr;
     Write(', (c) 1990,93 por Deluan Perez');
     WriteLn;
end;

{-----------------------------------------------------------------------------}
function UpStr(s : String) : String;
var l : Byte Absolute s;
    i : Byte;
begin
     for i := 1 to l do s[i] := Upcase(s[i]);
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
           Write(c:3, #8#8#8);
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
var sr : SearchRec;
begin
     if nivel <> '' then Cadastra(nivel)
     else Cadastra('\');
     FindFirst(nivel + '\*.*', AnyFile, sr);
     while (DosError = 0) and not notmem do begin
           with sr do
                if ((attr and Directory) > 0) and (name[1] <> '.') then
                   Tree(nivel + '\' + name);
	   FindNext(sr);
     end;
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
        Write('Rescaning Tree ... ');
        Tree('');
        Save;
     end
     else begin
          Write('Loading Tree ... ');
          while not Eof(f) do begin
                ReadLn(f, s);
                Cadastra(s);
          end;
          Close(f);
     end;
     Write(#13); ClrEol;
end;

{-----------------------------------------------------------------------------}
function Match(n1, n2 : String; mode : Byte) : Boolean;
begin
     n2 := Copy(n2, Posr('\', n2) + 1, 80);
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
     if (n = '') then Find := ''
     else begin
          if mode = 2 then begin
             repeat
                   Dec(n[0]);
                   s := Find(n, 1);
             until (s <> '') or (n[0] = #0);
             Find := s;
          end
          else begin
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
               if n = '\' then n := '';
               if not Match(n, p^.path^, mode) then Find := ''
               else Find := p^.path^;
          end;
     end;
end;

{-----------------------------------------------------------------------------}
{$F+}  function HeapFunc(size : Word) : Word;  {$F-}
begin
     HeapFunc := 1;
end;

begin
     DirectVideo := FALSE;
     Apresentacao;
     if ParamCount <> 1 then Halt(1);
     HeapError := @HeapFunc;

     WriteLn;
     Assign(f, TREEFILE);
     par := UpStr(ParamStr(1));
     rescan := (par = '/R');
     if rescan then begin  {$I-}
        Erase(f);          {$I+}
        if IoResult = 0 then;
     end;

     Load;

     if notmem then begin
        WriteLn('N„o h  mem¢ria suficiente para a opera‡„o!');
        Halt(1);
     end;

     if rescan then Halt;

     getDir(0, atual);
     drive := Copy(atual, 1, 2);
     Delete(atual, 1, 2);

     s := Find(par, 0);
     if s = '' then s := Find(par, 1);
     if s = '' then s := Find(par, 2);
     if s = '' then WriteLn('Diret¢rio n„o encontrado!')
     else begin      {$I-}
          WriteLn('Navegando para: ', drive, s);
          ChDir(s);  {$I+}
          if IoResult <> 0 then begin
             WriteLn('ERRO: Diret¢rio n„o existe: ', drive, s);
             WriteLn('      Execute ''DCD /R''.');
          end;
     end;
end.
