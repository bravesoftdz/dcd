uses Dos;

const TREEFILE = '\TREEINFO.DEL';

type FolhaPtr = ^Folha;
     Folha = record
                   nome : String[14];
                   path : PathStr;
                   prx  : FolhaPtr;
                   ant  : FolhaPtr;
             end;

var p      : FolhaPtr;
    c      : Word;
    s, par : String;
    topo   : FolhaPtr;
    first  : FolhaPtr;
    f      : Text;
    mk     : Pointer;


function UpStr(s : String) : String;
var l : Byte Absolute s;
    i : Byte;
begin
     for i := 1 to l do s[i] := Upcase(s[i]);
     UpStr := s;
end;

function Posr(s1, s2 : String) : Byte;
var i  : Byte;
    l1 : Byte absolute s1;
    l2 : Byte absolute s2;
    s  : String;
begin
     if l1 > l2 then Posr := 0
     else begin
          s := s2;
          i := l2 - l1 + 1;
          while (i > 0) and (Copy(s, i, l1) <> s1) do Dec(i, l1);
          Posr := i;
     end;
end;


procedure Cadastra(nivel : String);
var pt : FolhaPtr;
    i  : Byte;
begin
     pt := p;  New(p);
     if pt <> NIL then pt^.prx := p
     else first := p;
     p^.ant := pt;
     p^.prx := NIL;
     p^.path := nivel;
     i := Posr('\', nivel);
     Delete(nivel, 1, Posr('\', nivel));
     p^.nome := nivel;
     Inc(c);
     Write(c:3, #8#8#8);
     topo := p;
end;


procedure PosStack(n : String);
begin
     p := topo;
     while (p <> NIL) and (n <> p^.path) do
           p := p^.ant;
end;

procedure Next;
begin
     p := p^.prx;
     if p = NIL then p := first;
end;

procedure Tree(nivel : PathStr);
var sr : SearchRec;
begin
     if nivel <> '' then Cadastra(nivel)
     else Cadastra('\');
     FindFirst(nivel + '\*.*', Directory, sr);
     while DosError = 0 do begin
           with sr do
                if (attr = Directory) and (name[1] <> '.') then
                   Tree(nivel + '\' + name);
	   FindNext(sr);
     end;
end;

procedure Save;
begin
     p := first;
     Rewrite(f);
     while p <> NIL do begin
           WriteLn(f, p^.path);
           p := p^.prx;
     end;
     p := topo;
     Close(f);
end;

procedure Load;
var s : String;
begin
     p := NIL;
     topo := NIL;
     first := NIL;
     c := 0;        {$I-}
     Reset(f);      {$I+}
     if IoResult > 0 then begin
        Write('Rescaning Tree ... ');
        Tree('');
        Save;
     end
     else begin
          while not Eof(f) do begin
                ReadLn(f, s);
                Cadastra(s);
          end;
     end;
     Write(#13, '':79, #13);
end;

function Find(n : String; modo : Byte) : PathStr;
var pt    : FolhaPtr;
    atual : String;
    size  : Byte;
    fim   : Boolean;
begin
     if (p = NIL) then Find := ''
     else begin
          if modo = 0 then size := 80
          else size := Length(n);
          GetDir(0, atual);
          Delete(atual, 1, 2);
          pt := p;
          PosStack(atual);
          if p = NIL then begin
             Erase(f);
             Load;
          end;
          if n <> Copy(atual, Posr('\', atual) + 1, size) then p := first;
          pt := p; fim := FALSE;
          while (n <> Copy(p^.nome, 1, size)) and not fim do begin
                Next;
                fim := (p = pt);
          end;
          if n = '\' then n := '';
          if n <> Copy(p^.nome, 1, size) then Find := ''
          else Find := p^.path
     end;
end;



begin
     if ParamCount <> 1 then Halt;
     WriteLn;
     Mark(mk);
     Assign(f, TREEFILE);
     par := UpStr(ParamStr(1));
     if par = '/R' then begin  {$I-}
        Erase(f);              {$I+}
        if IoResult = 0 then;
        Load;  Halt;
     end;
     Load;
     s := Find(par, 0);
     if s = '' then s := Find(par, 1);
     if s = '' then WriteLn('Not Found!')
     else begin      {$I-}
          ChDir(s);  {$I+}
          if IoResult <> 0 then begin
             WriteLn('ERRO: Diretorio nao existe mais!');
             WriteLn('      Execute ''DCD /R''.');
          end;
     end;

end.
