unit MeshMaker_FormCompile;


interface


uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs, SysTools,
  ComCtrls, StdCtrls, ExtCtrls, Localization, MeshMaker_FormMain;


(*****************************************************************************)
(*  TFormCompile
(*****************************************************************************)

type
  TFormCompile = class(TForm)
    LabelWait: TLabel;
    ButtonCancel: TButton;
    ProgressBarCompile: TProgressBar;
    PanelFocus: TPanel;
    MemoOutput: TMemo;
    TimerClose: TTimer;
    procedure FormActivate(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure TimerCloseTimer(Sender: TObject);
    procedure ButtonCancelClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);

  private
    FlagAborted: Boolean;
    PipedProcess: TPipedProcess;
    TextBufferData: string;
    TextErrorHistory: string;
    TextErrorMessage: string;
    TextErrorLine: string;
    TextFileError: string;
    TextFileLocked: string;
    TextFileMake: string;
    TextFilePackage: string;
    TextFilePackageOld: string;

    procedure PipedProcessOutput(Sender: TObject; const Data: string; Pipe: TPipedOutput);
    procedure PipedProcessTerminate(Sender: TObject);

  public
    FormMain: TFormMain;
    TextPackages: array of string;
    TextPackageCompile: string;

    function Compile: TModalResult;
  end;


var
  FormCompile: TFormCompile;


implementation


{$R *.DFM}


(*****************************************************************************)
(*  TFormCompile
(*****************************************************************************)

procedure TFormCompile.FormCreate(Sender: TObject);
begin
  Localize(Self);
end;


function TFormCompile.Compile: TModalResult;
var
  CountItems: Integer;
  FileMake: TextFile;
  IndexPackage: Integer;
  IndexPath: Integer;
  ResultFind: Integer;
  SearchRec: TSearchRec;
  TextFileMask: string;
begin
  Result := mrAbort;

  FlagAborted      := False;
  PipedProcess     := nil;
  TextBufferData   := '';
  TextErrorHistory := '';
  TextFileError    := '';
  TextFileLocked   := '';

  ButtonCancel.Enabled := True;

  TextFilePackage    := Format('%sSystem\%s.u',     [FormMain.TextDirectoryUnreal, TextPackageCompile]);
  TextFilePackageOld := Format('%sSystem\%s.u.old', [FormMain.TextDirectoryUnreal, TextPackageCompile]);

  DeleteFile(TextFilePackageOld);
  if FileExists(TextFilePackage) and not RenameFile(TextFilePackage, TextFilePackageOld) then
  begin
    Application.MessageBox(PChar(Format(Localized(Self, 'MessageErrorPackageDelete', 'Unable to delete existing old package file ''System\%s.u.''\nClose UnrealEd and Unreal Tournament before running MeshMaker.'), [TextPackageCompile])), 'MeshMaker', MB_ICONERROR);
    Exit;
  end;

  CountItems := Length(TextPackages);

  TextFileMask := FormMain.TextDirectoryUnreal + IncludeTrailingBackslash(TextPackageCompile) + 'Classes\*.uc';
  ResultFind := FindFirst(TextFileMask, faReadOnly + faHidden + faArchive, SearchRec);

  while ResultFind = 0 do
  begin
    Inc(CountItems, 2);
    ResultFind := FindNext(SearchRec);
  end;

  FindClose(SearchRec);

  ProgressBarCompile.Max := CountItems + 2;
  ProgressBarCompile.Position := 0;

  try
    TextFileMake := GetTempFile('msh');

    AssignFile(FileMake, TextFileMake);
    Rewrite(FileMake);

    try
      WriteLn(FileMake, '[Engine.Engine]');
      WriteLn(FileMake, 'EditorEngine=Editor.EditorEngine');
      WriteLn(FileMake);
      WriteLn(FileMake, '[Core.System]');

      for IndexPath := 0 to FormMain.CountPaths - 1 do
      begin
        WriteLn(FileMake, Format('Paths=%s', [StringReplace(FormMain.TextFilePaths[IndexPath], '\', '/', [rfReplaceAll])]));
      end;

      WriteLn(FileMake);
      WriteLn(FileMake, '[Editor.EditorEngine]');

      for IndexPackage := Low(TextPackages) to High(TextPackages) do
      begin
        WriteLn(FileMake, Format('EditPackages=%s', [TextPackages[IndexPackage]]));
      end;

      WriteLn(FileMake, Format('EditPackages=%s', [TextPackageCompile]));

    finally
      CloseFile(FileMake);
    end;

  except
    on Exception do
    begin
      Application.MessageBox(PChar(Format(Localized(Self, 'MessageErrorMakeCreate', 'Unable to create temporary make file ''%s''. Compilation aborted.'), [TextFileMake])), 'MeshMaker', MB_ICONERROR);
      Exit;
    end;
  end;

  PipedProcess := TPipedProcess.Create;
  PipedProcess.Command     := Format('"%sSystem\ucc.exe" make ini="%s"', [FormMain.TextDirectoryUnreal, TextFileMake]);
  PipedProcess.OnOutput    := PipedProcessOutput;
  PipedProcess.OnTerminate := PipedProcessTerminate;

  Result := ShowModal;
end;


procedure TFormCompile.FormActivate(Sender: TObject);
begin
  PanelFocus.SetFocus;
  PipedProcess.Execute;
end;


procedure TFormCompile.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  if Assigned(PipedProcess) then
  begin
    Action := caNone;
    Exit;
  end;

  DeleteFile(TextFileMake);

  if FileExists(TextFilePackageOld) and not FileExists(TextFilePackage) then
  begin
    RenameFile(TextFilePackageOld, TextFilePackage);
  end;
end;


procedure TFormCompile.PipedProcessOutput(Sender: TObject; const Data: string; Pipe: TPipedOutput);
var
  IndexCharError: Integer;
  IndexCharSeparator: Integer;
  TextLine: string;
begin
  MemoOutput.Text := MemoOutput.Text + Data;
  MemoOutput.Perform(WM_VSCROLL, SB_BOTTOM, 0);

  TextBufferData := TextBufferData + Data;

  while True do
  begin
    IndexCharSeparator := Pos(#13#10, TextBufferData);
    if IndexCharSeparator = 0 then Break;

    TextLine := Copy(TextBufferData, 1, IndexCharSeparator - 1);
    Delete(TextBufferData, 1, IndexCharSeparator + 1);

    if Length(TextLine) = 0 then Continue;

    if    ((TextLine[1] = '-') and (AnsiPos(Format('-%s-', [TextPackageCompile]), TextLine) = 0))
       or (AnsiSameText(Copy(TextLine, 1, 7), 'Parsing'))
       or (AnsiSameText(Copy(TextLine, 1, 9), 'Compiling')) then
    begin
      ProgressBarCompile.StepIt;
      Continue;
    end;

    if AnsiSameText(Copy(TextLine, 1, 7), 'Success') then
    begin
      ProgressBarCompile.Position := ProgressBarCompile.Max - 1;
      Continue;
    end;

    if AnsiSameText(Copy(TextLine, 1, 22), 'Failed loading package') then
    begin
      IndexCharSeparator := Pos(' ''', TextLine);
      TextFileLocked := TextFileLocked + #9 + ExtractFileName(Copy(TextLine, IndexCharSeparator + 2, Length(TextLine) - IndexCharSeparator - 2)) + #13#10;
      Continue;
    end;

    if AnsiSameText(Copy(TextLine, 1, 7), 'General') then
    begin
      TextErrorMessage := Trim(TextLine);
      Continue;
    end;

    if AnsiSameText(Copy(TextLine, 1, 7), 'History') then
    begin
      TextErrorHistory := Copy(TextLine, 10, Length(TextLine));
      Continue;
    end;

    IndexCharError := AnsiPos(': Error,', TextLine);
    if IndexCharError > 0 then
    begin
      TextFileError := TrimRight(Copy(TextLine, 1, IndexCharError - 1));

      for IndexCharSeparator := Length(TextFileError) downto 1 do
      begin
        if TextFileError[IndexCharSeparator] = '(' then Break;
      end;

      TextErrorLine := Copy(TextFileError, IndexCharSeparator + 1, Length(TextFileError) - IndexCharSeparator - 1);
      Delete(TextFileError, IndexCharSeparator, Length(TextFileError));

      TextErrorMessage := Copy(TextLine, IndexCharError + 9, Length(TextLine));
    end;
  end;
end;


procedure TFormCompile.PipedProcessTerminate(Sender: TObject);
begin
  TimerClose.Enabled := True;
end;


procedure TFormCompile.TimerCloseTimer(Sender: TObject);
begin
  if not PipedProcess.Executing then
  begin
    TimerClose.Enabled := False;

    if (Length(TextFileError) <> 0) and (Application.MessageBox(PChar(Format(Localized(Self, 'MessageErrorCompileClass', 'Error compiling class %s: %s in line %s.\n\nDo you want to skip this class and recompile the package?'), [ChangeFileExt(ExtractFileName(TextFileError), ''), TextErrorMessage, TextErrorLine])), 'MeshMaker', MB_ICONERROR + MB_YESNO) = IDYES) then
    begin
      DeleteFile(ChangeFileExt(TextFileError, '.uc.error'));
      RenameFile(TextFileError, ChangeFileExt(TextFileError, '.uc.error'));

      TextFileError := '';
      PipedProcess.Execute;
    end

    else if Length(TextFileLocked) > 0 then
    begin
      Application.MessageBox(PChar(Format(Localized(Self, 'MessageErrorPackageLoad', 'The compiler wasn''t able to load the following packages:\n\n%s\nClose all other applications that are currently using those packages and recompile.'), [TextFileLocked])), 'MeshMaker', MB_ICONERROR);
      ModalResult := mrAbort;

      PipedProcess.Free;
      PipedProcess := nil;
    end

    else begin
      if PipedProcess.ExitCode = 0 then
      begin
        ModalResult := mrOk;
      end
      else begin
        if not FlagAborted then
        begin
          Application.MessageBox(PChar(Format(Localized(Self, 'MessageErrorCompileGeneric', 'Compiler error: %s\n\nCheck MeshMaker.log for details.'), [TextErrorMessage])), 'MeshMaker', MB_ICONERROR);
          Log(Format('Compiler error: %s', [TextErrorMessage]));
          Log(Format('History: %s', [TextErrorHistory]));
        end;

        ModalResult := mrAbort;
      end;

      PipedProcess.Free;
      PipedProcess := nil;
    end;
  end;
end;


procedure TFormCompile.ButtonCancelClick(Sender: TObject);
begin
  ButtonCancel.Enabled := False;

  if Assigned(PipedProcess) then
  begin
    FlagAborted := True;
    PipedProcess.Abort;
  end;
end;

end.
