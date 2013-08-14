unit DCDUtil;

{$MODE DELPHI}
{$H-}

interface

uses
  Crt, Classes, StrUtils, SysUtils;

const TREEFILE_NAME = '.treeinfo.dcd';

type FolhaPtr = ^Folha;
     Folha = record
                   path : String;
                   prx  : FolhaPtr;
             end;
type

{ TTreeInfo }

 TTreeInfo = class
 private
   TreeFile: String;
   RootDIr: String;
   CurrentDir: String;
   First: FolhaPtr;
   Current: FolhaPtr;
   Count: LongInt;
   procedure RecurseTree(nivel : AnsiString);
   function StartSearch(Path: String): Boolean;
   function Next: String;
   function Match(n1, n2 : String; mode : Byte) : Boolean;
   function Find(n : String; mode : Integer) : String;
 public
   constructor Create(ARootDir: String; ACurrentDir: String);
   procedure Add(path: String);
   procedure Save;
   function Load: Boolean;
   procedure Rescan;
   function Search(Folder: String): String;
 end;


implementation

{ TTreeInfo }

constructor TTreeInfo.Create(ARootDir: String; ACurrentDir: String);
begin
     inherited Create;
     RootDir := ARootDir;
     TreeFile := RootDir + DirectorySeparator + TREEFILE_NAME;
     CurrentDir := ACurrentDir;
     Current := NIL;
     First := NIL;
     Count := 0;
end;

procedure TTreeInfo.RecurseTree(nivel : AnsiString);
var sr : TSearchRec;
begin
     if nivel <> '' then begin
        Add(nivel);
     end
     else begin
        Add(DirectorySeparator);
     end;
     if FindFirst(nivel + DirectorySeparator + '*', faDirectory, sr) = 0 then
         repeat
               //writeln(sr.name, ': ', sr.attr, '&', faDirectory, '=', sr.attr and faDirectory);
               with sr do begin
                    if ((attr and faDirectory) = faDirectory) and (Copy(name, 1, 1) <> '.') then begin
                       //writeln(nivel + ' ' + sr.name);
                       try
                          RecurseTree(nivel + DirectorySeparator + name);
                       except
                         on E: Exception do
                         WriteLn(E.Message, ' ------------', nivel + DirectorySeparator + name);
                       end;
                    end;
               end;
         until FindNext(sr) <> 0;
     FindClose(sr);
end;

procedure TTreeInfo.Add(path: String);
var pt : FolhaPtr;
begin
    pt := Current;
    Current := GetMem(SizeOf(Current^));
    if Current <> NIL then begin
      if pt <> NIL then pt^.prx := Current
      else First := Current;
      Current^.prx := NIL;
      Current^.path := path;
      Inc(Count);
      Write(stderr, Count:10, #8#8#8#8#8#8#8#8#8#8);
    end
    else WriteLn(stderr, '***********FUUUUUUUUUUUUUUUUUUUUU************');
end;

function TTreeInfo.Next: String;
begin
     Current := Current^.prx;
     if Current = NIL then Current := First;
     Result := Current^.path;
end;

procedure TTreeInfo.Save;
var F: Text;
    P: FolhaPtr;
begin
     P := First;
     Assign(F, TreeFile);
     Rewrite(F);
     while P <> NIL do begin
           WriteLn(F, P^.path);
           P := P^.prx;
     end;
     P := First;
     Close(F);
end;

function TTreeInfo.Load: Boolean;
var F: Text;
    S: String;
begin
     Current := NIL;
     First := NIL;
     Count := 0;
     if not FileExists(TreeFile) then begin
        Exit(False);
     end;
     Assign(F, TreeFile);
     Reset(F);
     Write(stderr, 'Loading Tree ... ');
     while not Eof(F) do begin
           ReadLn(F, S);
           Add(S);
     end;
     Close(F);
     Write(stderr, #13); ClrEol;
     Exit(True);
end;

procedure TTreeInfo.Rescan;
begin
     Write(stderr, 'Rescaning Tree ... ');
     RecurseTree(RootDir);
     Save;
end;

function TTreeInfo.StartSearch(Path: String): Boolean;
begin
     Current := First;
     while (Current <> NIL) and (Path <> Current^.path) do
           Current := Current^.prx;
     Result := Current <> NIL;
end;

function TTreeInfo.Search(Folder: String): String;
var S: String;
begin
     S := Find(Folder, 0);
     if S = '' then s := Find(Folder, 1);
     if S = '' then s := Find(Folder, 2);
     Exit(S);
end;

function TTreeInfo.Match(n1, n2: String; mode: Byte): Boolean;
begin
     n2 := Copy(n2, RPos(DirectorySeparator, n2) + 1, 255);
     case mode of
          0 : Match := (n1 = n2);
          1 : Match := (n1 = Copy(n2, 1, Length(n1)));
     end;
end;

function TTreeInfo.Find(n: String; mode: Integer): String;
var pt     : FolhaPtr;
    s      : String;
begin
     if (n = '') then begin
        Exit('');
     end;
     if mode = 2 then begin
       repeat
             delete(n, length(n), 1);
             s := Find(n, 1);
       until (s <> '') or (length(n) = 0);
       Exit(s);
     end;

     if not StartSearch(CurrentDir) then begin
       Rescan;
     end;

     if not Match(n, Current^.path, mode) then Current := First;
     pt := Current;
     repeat
           Next;
     until Match(n, Current^.path, mode) or (pt = Current);
     if n = DirectorySeparator then n := '';
     if Match(n, Current^.path, mode) then begin
         Exit(Current^.path);
     end;
     Exit('');
end;

end.
