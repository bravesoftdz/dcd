program DCD;

{$MODE DELPHI}
{$H+}

uses Crt, SysUtils, Classes, DCDUtil;

var NewDir, Param : String;
    Rescan : Boolean;
    TreeInfo: TTreeInfo;

procedure Apresentacao;
begin
     WriteLn(stderr, 'Deluan Change Directory 3.0 (c) 1990,2013 por Deluan');
end;


function GetHomePath: String;
begin
     GetHomePath := ExcludeTrailingPathDelimiter(GetUserDir);
end;

begin
     TextRec(Output).FlushFunc := TextRec(Output).InOutFunc;
     TextRec(StdErr).FlushFunc := TextRec(StdErr).InOutFunc;

     TreeInfo := TTreeInfo.Create(GetHomePath, GetCurrentDir);

     if ParamCount <> 1 then begin
        Apresentacao;
        Halt(1);
     end;

     Param := ParamStr(1);
     Rescan := Param = '-r';
     if Rescan or not TreeInfo.Load then begin
        TreeInfo.Rescan;
     end;

     if Rescan then begin
        Halt(0);
     end;

     NewDir := TreeInfo.Search(Param);
     if NewDir <> '' then begin
        WriteLn(stdout, NewDir);
     end;
end.