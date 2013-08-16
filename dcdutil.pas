unit DCDUtil;

{$MODE DELPHI}
{$H+}

interface

uses
  Crt, Classes, SysUtils;

const TREEFILE_NAME = 'treeinfo.dcd';

type

{ TTreeInfo }

 TTreeInfo = class
 private
   TreeFile: String;
   RootDir: String;
   CurrentDir: String;
   FolderList: TStringList;
   procedure RecurseTree(Path : AnsiString);
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

const
  MODE_EXACT = 0;
  MODE_PARTIAL = 1;
  MODE_BRUTE_FORCE = 2;

{ TTreeInfo }

constructor TTreeInfo.Create(ARootDir: String; ACurrentDir: String);
begin
     inherited Create;
     RootDir := ARootDir;
     ForceDirectories(GetAppConfigDir(false));
     TreeFile := ExcludeTrailingPathDelimiter(GetAppConfigDir(false)) + DirectorySeparator + TREEFILE_NAME;
     CurrentDir := ACurrentDir;

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

procedure TTreeInfo.Save;
begin
     WriteLn(stderr, 'Saving db to ' + TreeFile);
     FolderList.SaveToFile(TreeFile);
end;

function TTreeInfo.Load: Boolean;
begin
     FolderList.Clear;

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
     RecurseTree(RootDir);
     FolderList.Sort;
     Write(stderr, #13); ClrEol;
     Save;
end;

function TTreeInfo.Search(FolderToFind: String): String;
var S: String;
begin
     if (FolderToFind = '') then begin
        Exit('');
     end;
     S := Find(FolderToFind, MODE_EXACT);
     if S = '' then S := Find(FolderToFind, MODE_PARTIAL);
     if S = '' then S := Find(FolderToFind, MODE_BRUTE_FORCE);
     Exit(S);
end;

function TTreeInfo.Match(Name, Path: String; mode: Byte): Boolean;
begin
     Path := ExtractFileName(Path);
     case mode of
          MODE_EXACT:
            Match := (Name = Path);
          MODE_PARTIAL:
            Match := (Name = Copy(Path, 1, Length(Name)));
     end;
end;

function TTreeInfo.Find(Name: String; mode: Integer): String;
var S: String;
    Start: Integer;
    Index: Integer;
begin
     if mode = MODE_BRUTE_FORCE then begin
       repeat
             SetLength(Name, Length(Name)-1);
             S := Find(Name, MODE_PARTIAL);
       until (S <> '') or (Length(Name) = 0);
       Exit(S);
     end;

     if not FolderList.Find(CurrentDir, Start) then begin
       Start := 0;
     end;

     Index := Start;
     repeat
           Inc(Index);
           if (Index = FolderList.Count) then begin
               Index := 0;
           end;
     until Match(Name, FolderList[Index], mode) or (Start = Index);

     if Match(Name, FolderList[Index], mode) then begin
         Exit(FolderList[Index]);
     end;

     Exit('');
end;

end.
