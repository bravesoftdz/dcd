program DCD;

{$MODE DELPHI}
{$H+}

uses Crt, SysUtils, Classes, GetOpts, DCDUtil;

const OPTIONS = 'r';
      RESULT_CHDIR = 0;
      RESULT_NOOP = 1;
      RESULT_NOT_FOUND = 2;

var NewDir: String;
    TreeInfo: TTreeInfo;
    OptionRescan: Boolean;

procedure ShowUsage;
begin
     WriteLn(stderr, 'Deluan Change Directory 3.0 (c) 1990,2013 by Deluan');
end;


function GetHomePath: String;
begin
     GetHomePath := ExcludeTrailingPathDelimiter(GetUserDir);
end;

procedure ParseOptions;
var C: Char;
begin
     OptErr := False;
     repeat
       C := GetOpt(OPTIONS);
       case C of
         'r' : OptionRescan := True;
         '?',':' : begin
           writeln(stderr, 'Invalid option -', OptOpt);
           Halt(RESULT_NOOP);
         end;
      end; { case }
    until C = EndOfOptions;
end;

begin
     TextRec(Output).FlushFunc := TextRec(Output).InOutFunc;
     TextRec(StdErr).FlushFunc := TextRec(StdErr).InOutFunc;

     ParseOptions;

     if ParamCount <> 1 then begin
        ShowUsage;
        Halt(RESULT_NOOP);
     end;

     TreeInfo := TTreeInfo.Create(GetHomePath, GetCurrentDir);

     if OptionRescan or not TreeInfo.Load then begin
        TreeInfo.Rescan;
     end;

     if OptionRescan then begin
        Halt(RESULT_NOOP);
     end;

     NewDir := TreeInfo.Search(ParamStr(1));
     if NewDir <> '' then begin
        WriteLn(stdout, NewDir);
        Halt(RESULT_CHDIR);
     end;
     Halt(RESULT_NOT_FOUND);
end.