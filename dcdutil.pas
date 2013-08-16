unit DCDUtil;

{$MODE DELPHI}
{$H+}

interface

uses
  Crt, Classes, SysUtils;

const TREEFILE_NAME = '.treeinfo.dcd';

type

{ TTreeInfo }

 TTreeInfo = class
 private
   TreeFile: String;
   RootDir: String;
   CurrentDir: String;
   FolderList: TStringList;
   Index: LongInt;
   procedure RecurseTree(Path : AnsiString);
   function StartSearch(Path: String): Boolean;
   function Next: String;
   function Match(Name, Path : String; mode : Byte) : Boolean;
   function Find(Name : String; mode : Integer) : String;
 public
   constructor Create(ARootDir: String; ACurrentDir: String);
   procedure Add(path: String);
   procedure Save;
   function Load: Boolean;
   procedure Rescan;
   function Search(FolderToFind: String): String;
 end;


implementation


{ TTreeInfo }

constructor TTreeInfo.Create(ARootDir: String; ACurrentDir: String);
begin
     inherited Create;
     RootDir := ARootDir;
     ForceDirectories(GetAppConfigDir(false));
     TreeFile := GetAppConfigDir(false) + DirectorySeparator + TREEFILE_NAME;
     CurrentDir := ACurrentDir;

     Index := 0;
     FolderList := TStringList.Create;
     FolderList.OwnsObjects := True;
end;

procedure TTreeInfo.RecurseTree(Path : AnsiString);
var sr : TSearchRec;
begin
     if Path <> '' then begin
        Add(Path);
     end
     else begin
        Add(DirectorySeparator);
     end;
     if FindFirst(Path + DirectorySeparator + '*', faDirectory, sr) = 0 then
         repeat
              if ((sr.attr and faDirectory) = faDirectory) and (Copy(sr.name, 1, 1) <> '.') then begin
                 RecurseTree(Path + DirectorySeparator + sr.name);
              end;
         until FindNext(sr) <> 0;
     FindClose(sr);
end;

procedure TTreeInfo.Add(path: String);
begin
     FolderList.Add(Path);
     Write(stderr, FolderList.Count:10, #8#8#8#8#8#8#8#8#8#8);
end;

function TTreeInfo.Next: String;
begin
     Inc(Index);
     if (Index = FolderList.Count) then begin
       Index := 0;
     end;

     Result := FolderList[Index];
end;

procedure TTreeInfo.Save;
begin
     FolderList.SaveToFile(TreeFile);
end;

function TTreeInfo.Load: Boolean;
begin
     FolderList.Clear;
     Index := 0;

     if not FileExists(TreeFile) then begin
        Exit(False);
     end;

     FolderList.LoadFromFile(TreeFile);
     Exit(True);
end;

procedure TTreeInfo.Rescan;
begin
     Write(stderr, 'Rescaning Tree ... ');
     FolderList.Clear;
     Index := 0;
     RecurseTree(RootDir);
     FolderList.Sort;
     Save;
     Write(stderr, #13); ClrEol;
end;

function TTreeInfo.StartSearch(Path: String): Boolean;
var Pos: Integer;
begin
     if (FolderList.Find(Path, Pos)) then begin
       Index := Pos;
       Exit(True);
     end;
     Exit(False);
end;

function TTreeInfo.Search(FolderToFind: String): String;
var S: String;
begin
     S := Find(FolderToFind, 0);
     if S = '' then s := Find(FolderToFind, 1);
     if S = '' then s := Find(FolderToFind, 2);
     Exit(S);
end;

function TTreeInfo.Match(Name, Path: String; mode: Byte): Boolean;
begin
     Path := ExtractFileName(Path);
     case mode of
          0 : Match := (Name = Path);
          1 : Match := (Name = Copy(Path, 1, Length(Name)));
     end;
end;

function TTreeInfo.Find(Name: String; mode: Integer): String;
var s      : String;
    Start: Integer;
begin
     if (Name = '') then begin
        Exit('');
     end;
     if mode = 2 then begin
       repeat
             delete(Name, length(Name), 1);
             s := Find(Name, 1);
       until (s <> '') or (length(Name) = 0);
       Exit(s);
     end;

     if not StartSearch(CurrentDir) then begin
       Rescan;
     end;

     if not Match(Name, FolderList[Index], mode) then Index := 0;
     Start := Index;
     repeat
           Next;
     until Match(Name, FolderList[Index], mode) or (Start = Index);
     if Name = DirectorySeparator then Name := '';
     if Match(Name, FolderList[Index], mode) then begin
         Exit(FolderList[Index]);
     end;

     Exit('');
end;

end.
