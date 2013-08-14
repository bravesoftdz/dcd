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

{$MODE DELPHI}

uses Crt, SysUtils, Classes, DCDUtil;

var NewDir, Param : String;
    Rescan : Boolean;
    TreeInfo: TTreeInfo;
    CurrentDir, Drive: String;

procedure Apresentacao;
begin
     WriteLn(stderr, 'Deluan Change Directory 2.0 (c) 1990,2013 por Deluan');
end;


function GetHomePath: String;
begin
     GetHomePath := GetEnvironmentVariable('HOME');
end;

begin
     TextRec(Output).FlushFunc := TextRec(Output).InOutFunc;
     TextRec(StdErr).FlushFunc := TextRec(StdErr).InOutFunc;

     GetDir(0, CurrentDir);
     if (CurrentDir[2] = ':') then begin
        drive := Copy(CurrentDir, 1, 2);
        Delete(CurrentDir, 1, 2);
     end;

     TreeInfo := TTreeInfo.Create(GetHomePath, CurrentDir);

     if ParamCount <> 1 then begin
        Apresentacao;
        Halt(1);
     end;

     Param := ParamStr(1);
     Rescan := (upcase(Param) = '-R');
     if Rescan or not TreeInfo.Load then begin
        TreeInfo.Rescan;
     end;

     if Rescan then begin
        Halt(0);
     end;

     NewDir := TreeInfo.Search(Param);
     if NewDir = '' then WriteLn(stderr, 'Directory not found!')
     else begin
          WriteLn(stderr, NewDir);
          WriteLn(NewDir); {$I-}
          ChDir(NewDir);   {$I+}
          if IoResult <> 0 then begin
             WriteLn(stderr, 'ERROR: Directory does not exist: ', drive, NewDir);
             WriteLn(stderr, '       Execute ''dcd -r''.');
          end;
     end;
end.