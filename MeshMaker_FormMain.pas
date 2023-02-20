unit MeshMaker_FormMain;


interface


uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  StdCtrls, Mesh, ComCtrls, ExtCtrls, Buttons, Grids, ImgList, Registry,
  Shellapi, Shlobj, UT_Packages, Math, Menus, GraphTools, SysTools,
  Localization;


(*****************************************************************************)
(*  TOptions
(*****************************************************************************)

type
  TOptions = record
    ExportCollision: Boolean;
    ExportType: string;
    ExportPackage: string;
  end;


(*****************************************************************************)
(*  TThreadFindSkins
(*****************************************************************************)

type
  TThreadFindSkins = class(TThread)
  private
    FOnProgress: TNotifyEvent;
    FOwner: TObject;
    FProgressCurrent: Integer;
    FProgressTotal: Integer;

    procedure DoProgress;

  protected
    procedure Execute; override;

  public
    property OnProgress:      TNotifyEvent read FOnProgress write FOnProgress;
    property Owner:           TObject      read FOwner      write FOwner;
    property ProgressCurrent: Integer      read FProgressCurrent;
    property ProgressTotal:   Integer      read FProgressTotal;
  end;


(*****************************************************************************)
(*  TFormMain
(*****************************************************************************)

type
  TSkinPackages = record
    BitmapThumbnails: array of TBitmap;
    CountPackages: Integer;
    IndexPackage: Integer;
    TextFilePackages: array of string;
    TextSkin: string;
  end;


  TFormMain = class(TForm)
    BevelFiles: TBevel;
    BevelMesh: TBevel;
    BevelPrefab: TBevel;
    BevelTextures: TBevel;
    ButtonBack: TButton;
    ButtonBrowsePrefab: TBitBtn;
    ButtonCancel: TButton;
    ButtonNext: TButton;
    CheckBoxExportCollision: TCheckBox;
    EditExportClass: TEdit;
    EditExportPackage: TEdit;
    EditFileCode: TEdit;
    EditFileModel1: TEdit;
    EditFileModel2: TEdit;
    EditFilePackage: TEdit;
    EditPrefab: TEdit;
    HeaderControlTextures: THeaderControl;
    ImageListPackage: TImageList;
    LabelCaptionExportClass: TLabel;
    LabelCaptionExportPackage: TLabel;
    LabelCaptionFileCode: TLabel;
    LabelCaptionFileModel: TLabel;
    LabelCaptionFilePackage: TLabel;
    LabelCopyright_NoLoc: TLabel;
    LabelDescriptionDecoration1: TLabel;
    LabelDescriptionDecoration2: TLabel;
    LabelDescriptionFiles1: TLabel;
    LabelDescriptionFiles2: TLabel;
    LabelDescriptionMesh1: TLabel;
    LabelDescriptionMesh2: TLabel;
    LabelDescriptionModel1: TLabel;
    LabelDescriptionModel2: TLabel;
    LabelDescriptionModel3: TLabel;
    LabelDescriptionPackage1: TLabel;
    LabelDescriptionPackage2: TLabel;
    LabelDescriptionPrefab: TLabel;
    LabelDescriptionTextures: TLabel;
    LabelDescriptionWelcome1: TLabel;
    LabelDescriptionWelcome2: TLabel;
    LabelDescriptionTextureProgress: TLabel;
    LabelDone: TLabel;
    LabelDoneDecoration1: TLabel;
    LabelDoneDecoration2: TLabel;
    LabelDoneDecoration3: TLabel;
    LabelDoneModel1: TLabel;
    LabelDoneModel2: TLabel;
    LabelDoneModel3: TLabel;
    LabelEmail_NoLoc: TLabel;
    LabelFiles: TLabel;
    LabelMesh: TLabel;
    LabelPrefab: TLabel;
    LabelStatusPrefab: TLabel;
    LabelStatusTextures: TLabel;
    LabelTextures: TLabel;
    LabelWelcome: TLabel;
    MenuItemTexturesBrowse: TMenuItem;
    MenuItemTexturesSeparator: TMenuItem;
    OpenDialogPrefab: TOpenDialog;
    OpenDialogTexture: TOpenDialog;
    PageControl: TPageControl;
    PanelDoneDecoration: TPanel;
    PanelDoneFocus: TPanel;
    PanelDoneModel: TPanel;
    PanelEnterPrefab: TPanel;
    PanelMesh: TPanel;
    PanelPrefab: TPanel;
    PanelTextures: TPanel;
    PanelTexturesProgress: TPanel;
    PanelTexturesTable: TPanel;
    PopupMenuTextures: TPopupMenu;
    ProgressBarTextures: TProgressBar;
    RadioButtonExportDecoration: TRadioButton;
    RadioButtonExportModel: TRadioButton;
    SpeedButtonEnterPrefab: TSpeedButton;
    StringGridTextures: TStringGrid;
    TabSheetMesh: TTabSheet;
    TabSheetPrefab: TTabSheet;
    TabSheetDone: TTabSheet;
    TimerEmail: TTimer;
    LabelPasteBrush: TLabel;
    MemoPasteBrush: TMemo;

    procedure ButtonBackClick(Sender: TObject);
    procedure ButtonBrowsePrefabClick(Sender: TObject);
    procedure ButtonCancelClick(Sender: TObject);
    procedure ButtonNextClick(Sender: TObject);
    procedure EditExportChange(Sender: TObject);
    procedure EditPrefabChange(Sender: TObject);
    procedure EditPrefabExit(Sender: TObject);
    procedure EditPrefabKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure EditPrefabKeyPress(Sender: TObject; var Key: Char);
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure LabelEmail_NoLocMouseMove(Sender: TObject; Shift: TShiftState; X, Y: Integer);
    procedure LabelEmail_NoLocMouseUp(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
    procedure MenuItemTexturesBrowseClick(Sender: TObject);
    procedure PageControlChange(Sender: TObject);
    procedure PopupMenuTexturesClick(Sender: TObject);
    procedure PopupMenuTexturesDrawItem(Sender: TObject; ACanvas: TCanvas; ARect: TRect; Selected: Boolean);
    procedure PopupMenuTexturesMeasureItem(Sender: TObject; ACanvas: TCanvas; var Width, Height: Integer);
    procedure SpeedButtonEnterPrefabClick(Sender: TObject);
    procedure StringGridTexturesDrawCell(Sender: TObject; ACol, ARow: Integer; Rect: TRect; State: TGridDrawState);
    procedure StringGridTexturesKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure StringGridTexturesMouseUp(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
    procedure StringGridTexturesMouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
    procedure StringGridTexturesResize(Sender: TObject);
    procedure StringGridTexturesSelectCell(Sender: TObject; ACol, ARow: Integer; var CanSelect: Boolean);
    procedure TabSheetPrefabShow(Sender: TObject);
    procedure TimerEmailTimer(Sender: TObject);
    procedure MemoPasteBrushChange(Sender: TObject);

  private
    BitmapCheck: TBitmap;
    BitmapNone: TBitmap;
    CountSkinPackages: Integer;
    Mesh: TMesh;
    Options: TOptions;
    SkinPackages: array of TSkinPackages;
    TextPrefabAck: string;
    ThreadFindSkins: TThreadFindSkins;
    WidthThumbnails: Integer;

    procedure FindPaths;
    procedure FindSkins;
    function  GetThumbnail(Texture: TUTObjectClassTexture): TBitmap;
    procedure Localization;
    procedure PopupMenuTexturesFill(SkinPackages: TSkinPackages);
    procedure PopupMenuTexturesShow;
    function  SetPackage(var SkinPackages: TSkinPackages; TextFilePackage: string): Boolean;
    procedure SetStatusTextures;
    procedure TextPrefabEditing;
    procedure TextPrefabEdited(TextPrefab: string);
    procedure ThreadFindSkinsProgress(Sender: TObject);
    procedure ThreadFindSkinsTerminate(Sender: TObject);

    procedure MessageDropFiles(var Msg: TWMDropFiles); message WM_DROPFILES;

  public
    CountPaths: Integer;
    TextDirectoryUnreal: string;
    TextFilePaths: TFileNames;
  end;


var
  FormMain: TFormMain;


implementation


uses MeshMaker_FormCompile;


{$R *.DFM}
{$R CursorHand.res}


(*****************************************************************************)
(*  Tools
(*****************************************************************************)

function GetPackageName(TextFilePackage: string): string;
begin
  Result := ChangeFileExt(ExtractFileName(TextFilePackage), '');
end;


function GetValidIdent(TextSource: string; TextPrefix: string = '_'): string;
var
  IndexChar: Integer;
begin
  Result := '';

  for IndexChar := 1 to Length(TextSource) do
  begin
    if TextSource[IndexChar] in ['0'..'9', 'A'..'Z', 'a'..'z', '_'] then
    begin
      Result := Result + TextSource[IndexChar];
    end;
  end;

  if (Length(Result) = 0) or (Result[1] in ['0'..'9']) then
  begin
    Result := TextPrefix + Result;
  end;
end;


function IsDirectoryUnreal(TextDirectory: string): Boolean;
begin
  Result := FileExists(IncludeTrailingBackslash(TextDirectory) + 'System\Core.dll');
end;


function IsDirectoryDeusEx(TextDirectory: string): Boolean;
begin
  Result := FileExists(IncludeTrailingBackslash(TextDirectory) + 'System\DeusEx.dll');
end;


(*****************************************************************************)
(*  TThreadFindSkins
(*****************************************************************************)

procedure TThreadFindSkins.Execute;
var
  CountPackages: Integer;
  IndexPackage: Integer;
  IndexPath: Integer;
  IndexSkin: Integer;
  IndexTexture: Integer;
  Package: TUTPackage;
  TextFilePackage: string;
  TextFilePackages: TFileNames;
  TextFilePath: string;
begin
  with Owner as TFormMain do
  begin
    CountPackages := 0;
    TextFilePackages := nil;

    for IndexPath := 0 to CountPaths - 1 do
    begin
      TextFilePath := TextFilePaths[IndexPath];

      if     ((Length(TextFilePath) < 5) or not AnsiSameText(Copy(TextFilePath, Length(TextFilePath) - 4, 5), '*.utx'))
         and ((Length(TextFilePath) < 3) or not AnsiSameText(Copy(TextFilePath, Length(TextFilePath) - 2, 3), '*.u')) then Continue;

      try
        ChDir(TextDirectoryUnreal + 'System');
        ReadFiles(ExtractFilePath(TextFilePath), ExtractFileName(TextFilePath), TextFilePackages, CountPackages);

      except
        on Exception do;
      end;
    end;

    FProgressCurrent := 0;
    FProgressTotal := CountPackages;
    Synchronize(DoProgress);

    Package := TUTPackage.Create;

    for IndexPackage := 0 to CountPackages - 1 do
    begin
      try
        TextFilePackage := TextFilePackages[IndexPackage];
        Package.Initialize(TextFilePackage);

        for IndexSkin := 0 to High(SkinPackages) do
        begin
          with SkinPackages[IndexSkin] do
          begin
            IndexTexture := FindTexture(Package, TextSkin);

            if IndexTexture >= 0 then
            begin
              Inc(CountPackages);
              SetLength(BitmapThumbnails, CountPackages);
              SetLength(TextFilePackages, CountPackages);
              TextFilePackages[CountPackages - 1] := TextFilePackage;

              with Package.Exported[IndexTexture] do
              begin
                if LowerCase(UTClassName) = 'texture' then
                begin
                  UTObject.ReadObject;
                  BitmapThumbnails[CountPackages - 1] := GetThumbnail(TUTObjectClassTexture(UTObject));
                  UTObject.ReleaseObject;
                end
                else begin
                  BitmapThumbnails[CountPackages - 1] := nil;
                end;
              end;
            end;
          end;
        end;

      except
        on Exception do;
      end;

      if Terminated then Break;

      FProgressCurrent := IndexPackage + 1;
      Synchronize(DoProgress);
    end;

    Package.Free;
  end;
end;


procedure TThreadFindSkins.DoProgress;
begin
  if Assigned(FOnProgress) then FOnProgress(Self);
end;


(*****************************************************************************)
(*  TFormMain
(*****************************************************************************)

procedure TFormMain.FormCreate(Sender: TObject);
var
  BrowseInfo: TBrowseInfo;
  BufferName: array [0..MAX_PATH] of Char;
  BufferPath: array [0..MAX_PATH] of Char;
  ItemIdList: PItemIdList;
  Registry: TRegistry;
begin
  Localization;

  TextDirectoryUnreal := ExcludeTrailingBackslash(ExtractFilePath(ParamStr(0)));
  if not IsDirectoryUnreal(TextDirectoryUnreal) then TextDirectoryUnreal := ExcludeTrailingBackslash(ExtractFilePath(TextDirectoryUnreal));
  if not IsDirectoryUnreal(TextDirectoryUnreal) then TextDirectoryUnreal := '';

  Registry := TRegistry.Create;

  if Length(TextDirectoryUnreal) = 0 then
  begin
    Registry.RootKey := HKEY_LOCAL_MACHINE;
    Registry.Access := KEY_READ;

    if Registry.OpenKey('Software\Unreal Technology\Installed Apps\UnrealTournament', False) then
    begin
      if Registry.ValueExists('Folder') then
      begin
        TextDirectoryUnreal := Registry.ReadString('Folder');
        if not IsDirectoryUnreal(TextDirectoryUnreal) then TextDirectoryUnreal := '';
      end;
      Registry.CloseKey;
    end;
  end;

  if Length(TextDirectoryUnreal) = 0 then
  begin
    while True do
    begin
      BrowseInfo.hwndOwner      := Handle;
      BrowseInfo.pidlRoot       := nil;
      BrowseInfo.pszDisplayName := BufferName;
      BrowseInfo.lpszTitle      := PChar(Localized(Self, 'LabelBrowseDirectoryUnreal', 'Unable to determine your Unreal Tournament directory.\nPlease specify your Unreal Tournament base directory.'));
      BrowseInfo.ulFlags        := BIF_RETURNONLYFSDIRS;
      BrowseInfo.lpfn           := nil;

      ItemIdList := ShBrowseForFolder(BrowseInfo);

      if Assigned(ItemIdList) and ShGetPathFromIdList(ItemIdList, BufferPath) then
      begin
        TextDirectoryUnreal := BufferPath;

        if not IsDirectoryUnreal(TextDirectoryUnreal) then
        begin
          Application.MessageBox(PChar(Localized(Self, 'MessageErrorDirectoryUnreal', 'The selected directory doesn''t appear to be your Unreal Tournament base directory.')), 'MeshMaker', MB_ICONERROR);
          Continue;
        end;
      end
      else begin
        Application.ShowMainForm := False;
        Application.Terminate;
      end;

      Break;
    end;

    if Length(TextDirectoryUnreal) > 0 then
    begin
      Registry.RootKey := HKEY_LOCAL_MACHINE;
      Registry.Access := KEY_WRITE;

      if Registry.OpenKey('Software\Unreal Technology\Installed Apps\UnrealTournament', True) then
      begin
        Registry.WriteString('Folder', ExcludeTrailingBackslash(TextDirectoryUnreal));
        Registry.CloseKey;
      end;
    end;
  end;

  Options.ExportCollision := True;
  Options.ExportType      := 'Decoration';
  Options.ExportPackage   := '';

  Registry.RootKey := HKEY_CURRENT_USER;
  Registry.Access := KEY_READ;

  if Registry.OpenKey('Software\Phase\MeshMaker', False) then
  begin
    if Registry.ValueExists('ExportCollision') then Options.ExportCollision := Registry.ReadBool  ('ExportCollision');
    if Registry.ValueExists('ExportType')      then Options.ExportType      := Registry.ReadString('ExportType');
    if Registry.ValueExists('ExportPackage')   then Options.ExportPackage   := Registry.ReadString('ExportPackage');
    Registry.CloseKey;
  end;

  Registry.Free;

  CheckBoxExportCollision.Checked := Options.ExportCollision;
  RadioButtonExportModel.Checked := AnsiSameText(Options.ExportType, 'Model');

  TextDirectoryUnreal := IncludeTrailingBackslash(TextDirectoryUnreal);
  OpenDialogPrefab.InitialDir  := TextDirectoryUnreal + 'Maps';
  OpenDialogTexture.InitialDir := TextDirectoryUnreal + 'Textures';
  FindPaths;

  Mesh := TMesh.Create;
  if IsDirectoryDeusEx(TextDirectoryUnreal) then
  begin
    Mesh.Compatibility := COMPATIBILITY_DeusEx;
  end;

  Register2DClasses;

  BitmapCheck := TBitmap.Create;
  BitmapCheck.Monochrome := True;
  BitmapCheck.Width  := GetSystemMetrics(SM_CXMENUCHECK);
  BitmapCheck.Height := GetSystemMetrics(SM_CYMENUCHECK);
  BitmapCheck.Transparent := True;
  DrawFrameControl(BitmapCheck.Canvas.Handle, Rect(0, 0, BitmapCheck.Width, BitmapCheck.Height), DFC_MENU, DFCS_MENUCHECK + DFCS_CHECKED);

  BitmapNone := TBitmap.Create;
  BitmapNone.Width  := 32;
  BitmapNone.Height := 32;

  with BitmapNone.Canvas do
  begin
    Brush.Color := clBlack;
    FillRect(Rect(0, 0, BitmapNone.Width, BitmapNone.Height));
    Pen.Color := $404040;
    Pen.Width := 2;
    MoveTo(1, 1);                     LineTo(BitmapNone.Width - 1, BitmapNone.Height - 2);
    MoveTo(1, BitmapNone.Height - 2); LineTo(BitmapNone.Width - 1, 0);
  end;

  PageControl.ActivePageIndex := 0;
  PageControlChange(Self);

  Screen.Cursors[crHandPoint] := LoadCursor(HInstance, 'HandCursor');
end;


procedure TFormMain.Localization;
var
  WidthSection: Integer;


  procedure AdjustBevel(LabelAdjust: TLabel; BevelAdjust: TBevel);
  var
    WidthDelta: Integer;
  begin
    WidthDelta := LabelAdjust.Left + LabelAdjust.Width - BevelAdjust.Left + 6;
    BevelAdjust.Left  := BevelAdjust.Left  + WidthDelta;
    BevelAdjust.Width := BevelAdjust.Width - WidthDelta;
  end;


begin
  Localize(Self);

  AdjustBevel(LabelPrefab,   BevelPrefab);
  AdjustBevel(LabelTextures, BevelTextures);
  AdjustBevel(LabelMesh,     BevelMesh);
  AdjustBevel(LabelFiles,    BevelFiles);

  with HeaderControlTextures.Sections do
  begin
    Items[0].Text := Localized(Self, 'HeaderControlTextures(Texture)', Items[0].Text);
    Items[1].Text := Localized(Self, 'HeaderControlTextures(Package)', Items[1].Text);
    Items[2].Text := Localized(Self, 'HeaderControlTextures(Status)',  Items[2].Text);

    WidthSection := Items[2].Width - GetSystemMetrics(SM_CXVSCROLL) - 12;

    WidthSection := Max(WidthSection, Canvas.TextWidth(Localized(Self, 'LabelStatusTexture(Found)')));
    WidthSection := Max(WidthSection, Canvas.TextWidth(Localized(Self, 'LabelStatusTexture(Missing)')));
    WidthSection := Max(WidthSection, Canvas.TextWidth(Localized(Self, 'LabelStatusTexture(Multiple)')));

    WidthSection := Min(HeaderControlTextures.Width div 3, WidthSection + GetSystemMetrics(SM_CXVSCROLL) + 12);

    Items[0].Width := (HeaderControlTextures.Width - WidthSection) div 2;
    Items[1].Width := (HeaderControlTextures.Width - WidthSection) div 2;
    Items[2].Width := HeaderControlTextures.Width - Items[0].Width - Items[1].Width;
  end;
end;


procedure TFormMain.StringGridTexturesResize(Sender: TObject);
var
  IndexColumn: Integer;
  WidthColumns: Integer;
begin
  WidthColumns := 0;

  for IndexColumn := 0 to StringGridTextures.ColCount - 2 do
  begin
    Inc(WidthColumns, HeaderControlTextures.Sections[IndexColumn].Width);
    StringGridTextures.ColWidths[IndexColumn] := HeaderControlTextures.Sections[IndexColumn].Width;
  end;

  StringGridTextures.ColWidths[StringGridTextures.ColCount - 1] := StringGridTextures.ClientWidth - WidthColumns;
end;


procedure TFormMain.FormShow(Sender: TObject);
begin
  StringGridTexturesResize(Self);
  StringGridTextures.Col := 1;

  if ParamStr(1) <> '' then
  begin
    try ChDir(TextDirectoryUnreal) except on Exception do end;
    TextPrefabEditing;
    TextPrefabEdited(GetRelativePath(ParamStr(1), TextDirectoryUnreal));
  end;
end;


procedure TFormMain.ButtonCancelClick(Sender: TObject);
begin
  Application.Terminate;
end;


procedure TFormMain.TabSheetPrefabShow(Sender: TObject);
begin
  EditPrefab.SetFocus;
end;


procedure TFormMain.StringGridTexturesSelectCell(Sender: TObject; ACol, ARow: Integer; var CanSelect: Boolean);
begin
  CanSelect := ACol = 1;
end;


procedure TFormMain.StringGridTexturesDrawCell(Sender: TObject; ACol, ARow: Integer; Rect: TRect; State: TGridDrawState);
var
  IndexIcon: Integer;
begin
  with Sender as TStringGrid do
  begin
    Canvas.Font := Font;

    if gdFocused in State then
    begin
      Canvas.Brush.Color := clHighlight;
      Canvas.Font.Color  := clHighlightText;
    end
    else begin
      Canvas.Brush.Color := clWindow;
      Canvas.Font.Color  := clWindowText;
    end;

    Canvas.FillRect(Rect);

    case ACol of
      0:
      begin
        IndexIcon := Min(2, SkinPackages[ARow].CountPackages);
        ImageListPackage.Draw(Canvas, Rect.Left + 1, Rect.Top + 1, IndexIcon);
        Inc(Rect.Left, 18);
      end;

      1:
      begin
        Inc(Rect.Left, 4);
      end;

      2:
      begin
        Canvas.Font.Color := clGrayText;
        Inc(Rect.Left, 4);
      end;
    end;

    Canvas.TextOut(Rect.Left + 2, Rect.Top + 2, Cells[ACol, ARow]);
  end;
end;


procedure TFormMain.StringGridTexturesKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
begin
  if (Key in [VK_RETURN, VK_APPS]) or ((ssShift in Shift) and (Key = VK_F10)) then
  begin
    PopupMenuTexturesShow;
    Key := 0;
  end;
end;


procedure TFormMain.StringGridTexturesMouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
var
  IndexCol: Integer;
  IndexRow: Integer;
begin
  if Button in [mbLeft, mbRight] then
  begin
    StringGridTextures.MouseToCell(X, Y, IndexCol, IndexRow);

    if IndexRow >= 0 then
    begin
      StringGridTextures.Row := IndexRow;
      StringGridTextures.SetFocus;
    end;
  end;
end;


procedure TFormMain.StringGridTexturesMouseUp(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
var
  IndexCol: Integer;
  IndexRow: Integer;
begin
  if Button in [mbLeft, mbRight] then
  begin
    StringGridTextures.MouseToCell(X, Y, IndexCol, IndexRow);
    if (IndexCol >= 0) and (IndexRow = StringGridTextures.Row) then PopupMenuTexturesShow;
  end;
end;


procedure TFormMain.TextPrefabEditing;
begin
  if Assigned(ThreadFindSkins) then
  begin
    ThreadFindSkins.Terminate;
  end;

  ButtonNext.Enabled := False;
  LabelStatusPrefab.Hide;
  PanelTextures.Hide;
end;


procedure TFormMain.TextPrefabEdited(TextPrefab: string);
begin
  Application.ProcessMessages;

  try
    ChDir(TextDirectoryUnreal);

    Mesh.Clear;
    Mesh.ClearEvents;
    Mesh.LoadPrefab(TextPrefab);

    FindSkins;

  except
    on EInOutError do
    begin
      LabelStatusPrefab.Caption := Localized(Self, 'LabelStatusPrefab(Open)', 'Unable to open file. Please specify an UnrealEd prefab file.');
      LabelStatusPrefab.Show;
    end;

    on EPrefab do
    begin
      LabelStatusPrefab.Caption := Localized(Self, 'LabelStatusPrefab(Invalid)', 'Invalid file format. Please specify an UnrealEd prefab file.');
      LabelStatusPrefab.Show;
    end;
  end;

  TextPrefabAck := TextPrefab;
  EditPrefab.Text := TextPrefab;
  EditPrefab.Perform(EM_SETMARGINS, EC_RIGHTMARGIN, 0);
  PanelEnterPrefab.Hide;
end;


procedure TFormMain.FindPaths;
var
  CountInis: Integer;
  FileIni: TextFile;
  FlagFoundPath: Boolean;
  IndexIni: Integer;
  IndexPath: Integer;
  TextFileIni: string;
  TextFileInis: TFileNames;
  TextFilePath: string;
  TextLine: string;
begin
  TextFilePaths := nil;

  CountPaths := 5;
  SetLength(TextFilePaths, 5);

  TextFilePaths[0] := '..\System\*.u';
  TextFilePaths[1] := '..\Maps\*.unr';
  TextFilePaths[2] := '..\Textures\*.utx';
  TextFilePaths[3] := '..\Sounds\*.uax';
  TextFilePaths[4] := '..\Music\*.umx';

  try
    TextFileInis := nil;
    CountInis := 0;

    try
      ReadFiles(Format('%sSystem', [TextDirectoryUnreal]), '*.ini', TextFileInis, CountInis);

    except
      on Exception do;
    end;

    for IndexIni := CountInis - 1 downto 0 do
    begin
      TextFileIni := LowerCase(ExtractFileName(TextFileInis[IndexIni]));

      if    (TextFileIni = 'default.ini')
         or (TextFileIni = 'defuser.ini')
         or (TextFileIni = 'detected.ini')
         or (TextFileIni = 'manifest.ini')
         or (TextFileIni = 'mplaynow.ini')
         or (TextFileIni = 'opengldrv.ini')
         or (TextFileIni = 'presets.ini')
         or (TextFileIni = 'unrealed.ini')
         or (TextFileIni = 'user.ini') then Continue;

      try
        AssignFile(FileIni, TextFileInis[IndexIni]);
        Reset(FileIni);

        try
          while not Eof(FileIni) do
          begin
            ReadLn(FileIni, TextLine);
            TextLine := Trim(TextLine);
            if AnsiSameText(TextLine, '[Core.System]') then Break;
          end;

          while not Eof(FileIni) do
          begin
            ReadLn(FileIni, TextLine);
            TextLine := Trim(TextLine);
            if (Length(TextLine) > 0) and (TextLine[1] = '[') then Break;

            if AnsiSameText(Copy(TextLine, 1, 6), 'Paths=') then
            begin
              FlagFoundPath := False;
              TextFilePath := StringReplace(TrimLeft(Copy(TextLine, 7, Length(TextLine))), '/', '\', [rfReplaceAll]);

              for IndexPath := CountPaths - 1 downto 0 do
              begin
                if AnsiSameText(TextFilePaths[IndexPath], TextFilePath) then
                begin
                  FlagFoundPath := True;
                  Break;
                end;
              end;

              if not FlagFoundPath then
              begin
                if CountPaths >= Length(TextFilePaths) then SetLength(TextFilePaths, Length(TextFilePaths) * 2);
                TextFilePaths[CountPaths] := TextFilePath;
                Inc(CountPaths);
              end;
            end;
          end;

        finally
          CloseFile(FileIni);
        end;

      except
        on Exception do;
      end;
    end;

  finally
    TextFileInis := nil;
  end;
end;



procedure TFormMain.FindSkins;
var
  IndexSkin: Integer;
  IndexThumbnail: Integer;
begin
  ProgressBarTextures.Position := 0;
  LabelStatusTextures.Hide;
  PanelTexturesTable.Hide;
  PanelTexturesProgress.Show;
  PanelTextures.Show;

  if Assigned(ThreadFindSkins) then
  begin
    ThreadFindSkins.Terminate;
    ThreadFindSkins.WaitFor;
  end;

  for IndexSkin := 0 to CountSkinPackages - 1 do
  begin
    with SkinPackages[IndexSkin] do
    begin
      for IndexThumbnail := 0 to CountPackages - 1 do
      begin
        BitmapThumbnails[IndexThumbnail].Free;
      end;
    end;
  end;

  CountSkinPackages := Mesh.CountSkins;
  SetLength(SkinPackages, CountSkinPackages);

  for IndexSkin := 0 to CountSkinPackages - 1 do
  begin
    with SkinPackages[IndexSkin] do
    begin
      CountPackages    := 0;
      IndexPackage     := 0;
      TextFilePackages := nil;

      TextSkin := Mesh.Skins[IndexSkin].TextSkin;
    end;
  end;

  ThreadFindSkins := TThreadFindSkins.Create(True);
  ThreadFindSkins.FreeOnTerminate := True;
  ThreadFindSkins.OnProgress  := ThreadFindSkinsProgress;
  ThreadFindSkins.OnTerminate := ThreadFindSkinsTerminate;
  ThreadFindSkins.Owner := Self;
  ThreadFindSkins.Priority := tpLower; 
  ThreadFindSkins.Resume;
end;


function TFormMain.GetThumbnail(Texture: TUTObjectClassTexture): TBitmap;
var
  BitmapSource: TBitmap;
  IndexMipMap: Integer;
begin
  Result := TBitmap.Create;

  for IndexMipMap := 0 to Texture.MipMapCount - 1 do
  begin
    if Max(Texture.MipMap[IndexMipMap].Width, Texture.MipMap[IndexMipMap].Height) <= 64 then
    begin
      Result.Assign(Texture.MipMap[IndexMipMap]);
      Exit;
    end;
  end;

  BitmapSource := TBitmap.Create;
  BitmapSource.PixelFormat := pf24bit;
  BitmapSource.Height := Texture.MipMap[0].Height;
  BitmapSource.Width  := Texture.MipMap[0].Width;
  BitmapSource.Canvas.Draw(0, 0, Texture.MipMap[0]);

  Result.Width  := Min(64, 64 * BitmapSource.Width  div BitmapSource.Height);
  Result.Height := Min(64, 64 * BitmapSource.Height div BitmapSource.Width);
  BitmapShrink(BitmapSource, Result, BitmapSource.Width div Result.Width);

  BitmapSource.Free;
end;


function TFormMain.SetPackage(var SkinPackages: TSkinPackages; TextFilePackage: string): Boolean;
var
  IndexPackage: Integer;
  IndexTexture: Integer;
  Package: TUTPackage;
begin
  Result := False;

  for IndexPackage := 0 to SkinPackages.CountPackages - 1 do
  begin
    if AnsiSameText(TextFilePackage, SkinPackages.TextFilePackages[IndexPackage]) then
    begin
      SkinPackages.IndexPackage := IndexPackage;
      Result := True;
      Exit;
    end;
  end;

  try
    Package := TUTPackage.Create(TextFilePackage);
    IndexTexture := FindTexture(Package, SkinPackages.TextSkin);

    if IndexTexture >= 0 then
    begin
      with SkinPackages do
      begin
        Inc(CountPackages);
        SetLength(TextFilePackages, CountPackages);
        SetLength(BitmapThumbnails, CountPackages);

        IndexPackage := CountPackages - 1;
        TextFilePackages[IndexPackage] := TextFilePackage;

        with Package.Exported[IndexTexture] do
        begin
          UTObject.ReadObject;
          BitmapThumbnails[IndexPackage] := GetThumbnail(TUTObjectClassTexture(UTObject));
          UTObject.ReleaseObject;
        end;
      end;

      Result := True;
    end;

    Package.Free;

  except
    on Exception do;
  end;
end;


procedure TFormMain.ThreadFindSkinsProgress(Sender: TObject);
begin
  with Sender as TThreadFindSkins do
  begin
    ProgressBarTextures.Position := (ProgressCurrent * ProgressBarTextures.Max) div ProgressTotal;
  end;
end;


procedure TFormMain.ThreadFindSkinsTerminate(Sender: TObject);
var
  IndexSkin: Integer;
begin
  ThreadFindSkins := nil;

  with Sender as TThreadFindSkins do
  begin
    if ProgressCurrent = ProgressTotal then
    begin
      StringGridTextures.RowCount := CountSkinPackages;

      for IndexSkin := 0 to CountSkinPackages - 1 do
      begin
        StringGridTextures.Cells[0, IndexSkin] := SkinPackages[IndexSkin].TextSkin;

        if SkinPackages[IndexSkin].CountPackages = 0 then
        begin
          StringGridTextures.Cells[1, IndexSkin] := '';
          StringGridTextures.Cells[2, IndexSkin] := Localized(Self, 'LabelStatusTexture(Missing)', 'missing');
        end
        else begin
          StringGridTextures.Cells[1, IndexSkin] := GetPackageName(SkinPackages[IndexSkin].TextFilePackages[SkinPackages[IndexSkin].IndexPackage]);

          if SkinPackages[IndexSkin].CountPackages = 1 then
          begin
            StringGridTextures.Cells[2, IndexSkin] := Localized(Self, 'LabelStatusTexture(Found)', 'found');
          end
          else begin
            StringGridTextures.Cells[2, IndexSkin] := Localized(Self, 'LabelStatusTexture(Multiple)', 'multiple');
          end;
        end;
      end;

      PanelTexturesProgress.Hide;
      PanelTexturesTable.Show;
      SetStatusTextures;
      StringGridTexturesResize(Self);
    end;
  end;
end;


procedure TFormMain.EditPrefabChange(Sender: TObject);
begin
  if not AnsiSameStr(EditPrefab.Text, TextPrefabAck) then
  begin
    EditPrefab.Perform(EM_SETMARGINS, EC_RIGHTMARGIN, PanelEnterPrefab.Width shl 16);
    PanelEnterPrefab.Show;

    TextPrefabEditing;
  end;
end;


procedure TFormMain.SpeedButtonEnterPrefabClick(Sender: TObject);
begin
  TextPrefabEdited(EditPrefab.Text);
end;


procedure TFormMain.EditPrefabExit(Sender: TObject);
begin
  if PanelEnterPrefab.Visible then TextPrefabEdited(EditPrefab.Text);
end;


procedure TFormMain.EditPrefabKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
begin
  case Key of
    VK_RETURN:
    begin
      if PanelEnterPrefab.Visible then TextPrefabEdited(EditPrefab.Text);
      Key := 0;
    end;
  end;
end;


procedure TFormMain.EditPrefabKeyPress(Sender: TObject; var Key: Char);
begin
  if Key in [#13] then Key := #0;
end;


procedure TFormMain.ButtonBrowsePrefabClick(Sender: TObject);
var Filename: String;
begin
  TextPrefabEditing;

  if OpenSaveFileDialog(Application.Handle, OpenDialogPrefab.DefaultExt,
  	OpenDialogPrefab.Filter, OpenDialogPrefab.InitialDir, OpenDialogPrefab.Title,
    FileName, True, False, False, True) then
  begin
    try ChDir(TextDirectoryUnreal) except on Exception do end;
    OpenDialogPrefab.FileName := FileName;
    TextPrefabEdited(GetRelativePath(FileName, TextDirectoryUnreal));
  end;

  EditPrefab.SetFocus;
end;


procedure TFormMain.MessageDropFiles(var Msg: TWMDropFiles);
var
  BufferName: array [0..MAX_PATH] of Char;
begin
  DragQueryFile(Msg.Drop, 0, BufferName, SizeOf(BufferName));
  DragFinish(Msg.Drop);

  if FileExists(BufferName) then
  begin
    try ChDir(TextDirectoryUnreal) except on Exception do end;
    TextPrefabEditing;
    TextPrefabEdited(GetRelativePath(BufferName, TextDirectoryUnreal));
  end;
end;


procedure TFormMain.FormDestroy(Sender: TObject);
var
  Registry: TRegistry;
begin
  Options.ExportCollision := CheckBoxExportCollision.Checked;

  if IsValidIdent(EditExportPackage.Text)
    then if AnsiSameText(EditExportClass.Text, EditExportPackage.Text)
      then Options.ExportPackage := ''
      else Options.ExportPackage := EditExportPackage.Text;

  if RadioButtonExportModel.Checked
    then Options.ExportType := 'Model'
    else Options.ExportType := 'Decoration';

  Registry := TRegistry.Create;

  if Registry.OpenKey('Software\Phase\MeshMaker', True) then
  begin
    Registry.WriteBool  ('ExportCollision', Options.ExportCollision);
    Registry.WriteString('ExportType',      Options.ExportType);
    Registry.WriteString('ExportPackage',   Options.ExportPackage);
    Registry.CloseKey;
  end;

  Registry.Free;

  BitmapCheck.Free;
  BitmapNone.Free;

  Mesh.Free;
end;


procedure TFormMain.PopupMenuTexturesFill(SkinPackages: TSkinPackages);
var
  IndexPackage: Integer;
  MenuItem: TMenuItem;
begin
  while (PopupMenuTextures.Items.Count > 0) and (PopupMenuTextures.Items[0].Tag >= 0) do
  begin
    PopupMenuTextures.Items.Delete(0);
  end;

  WidthThumbnails := 0;

  for IndexPackage := 0 to High(SkinPackages.TextFilePackages) do
  begin
    MenuItem := TMenuItem.Create(PopupMenuTextures);

    if Assigned(SkinPackages.BitmapThumbnails[IndexPackage])
      then MenuItem.Bitmap := SkinPackages.BitmapThumbnails[IndexPackage]
      else MenuItem.Bitmap := BitmapNone;

    MenuItem.Caption       := Format('%s.%s', [GetPackageName(SkinPackages.TextFilePackages[IndexPackage]), SkinPackages.TextSkin]);
    MenuItem.Checked       := IndexPackage = SkinPackages.IndexPackage;
    MenuItem.OnClick       := PopupMenuTexturesClick;
    MenuItem.OnDrawItem    := PopupMenuTexturesDrawItem;
    MenuItem.OnMeasureItem := PopupMenuTexturesMeasureItem;
    MenuItem.Tag           := IndexPackage;

    PopupMenuTextures.Items.Insert(IndexPackage, MenuItem);

    if Assigned(MenuItem.Bitmap) and (WidthThumbnails < MenuItem.Bitmap.Width) then WidthThumbnails := MenuItem.Bitmap.Width;
  end;
end;


procedure TFormMain.PopupMenuTexturesShow;
var
  IndexSkin: Integer;
  RectCell: TRect;
begin
  IndexSkin := StringGridTextures.Row;

  if not AnsiSameText(SkinPackages[IndexSkin].TextSkin, 'None') then
  begin
    PopupMenuTexturesFill(SkinPackages[IndexSkin]);
    RectCell := StringGridTextures.CellRect(1, IndexSkin);
    PopupMenuTextures.Popup(StringGridTextures.ClientOrigin.X + (RectCell.Left + RectCell.Right) div 2, StringGridTextures.ClientOrigin.Y + RectCell.Bottom);
  end;
end;


procedure TFormMain.PopupMenuTexturesMeasureItem(Sender: TObject; ACanvas: TCanvas; var Width, Height: Integer);
begin
  with Sender as TMenuItem do
  begin
    if Tag < 0 then
    begin
      Width := ACanvas.TextWidth(Caption) + BitmapCheck.Width;
    end
    else begin
      Width  := ACanvas.TextWidth(Caption) + WidthThumbnails + BitmapCheck.Width + 16;
      Height := Max(ACanvas.TextHeight(Caption) + 6, Bitmap.Height + 12);
    end;
  end;
end;


procedure TFormMain.PopupMenuTexturesDrawItem(Sender: TObject; ACanvas: TCanvas; ARect: TRect; Selected: Boolean);
var
  RectFrame: TRect;
begin
  with Sender as TMenuItem do
  begin
    if Tag < 0 then
    begin
      ACanvas.FillRect(ARect);
      ACanvas.TextOut(ARect.Left + BitmapCheck.Width + 4, (ARect.Top + ARect.Bottom - ACanvas.TextHeight(Caption)) div 2 - 1, Caption);
    end
    else begin
      ACanvas.FillRect(ARect);
      ACanvas.TextOut(ARect.Left + WidthThumbnails + BitmapCheck.Width + 14, (ARect.Top + ARect.Bottom - ACanvas.TextHeight(Caption)) div 2, Caption);

      RectFrame.Left   := ARect.Left + (WidthThumbnails - Bitmap.Width) div 2 + BitmapCheck.Width + 4;
      RectFrame.Top    := (ARect.Bottom + ARect.Top - Bitmap.Height) div 2 - 2;
      RectFrame.Right  := RectFrame.Left + Bitmap.Width  + 4;
      RectFrame.Bottom := RectFrame.Top  + Bitmap.Height + 4;

      DrawEdge(ACanvas.Handle, RectFrame, EDGE_SUNKEN, BF_ADJUST + BF_RECT);
      ACanvas.Brush.Color := clBlack;
      ACanvas.FillRect(RectFrame);
      ACanvas.Draw(RectFrame.Left, RectFrame.Top, Bitmap);
    end;

    if Checked then
    begin
      ACanvas.Draw(ARect.Left + 2, (ARect.Top + ARect.Bottom - BitmapCheck.Height) div 2, BitmapCheck);
    end;
  end;
end;


procedure TFormMain.PopupMenuTexturesClick(Sender: TObject);
var
  IndexSkin: Integer;
begin
  with Sender as TMenuItem do
  begin
    IndexSkin := StringGridTextures.Row;

    if SetPackage(SkinPackages[IndexSkin], SkinPackages[IndexSkin].TextFilePackages[Tag]) then
    begin
      StringGridTextures.Cells[1, IndexSkin] := GetPackageName(SkinPackages[IndexSkin].TextFilePackages[SkinPackages[IndexSkin].IndexPackage]);
    end;

    SetStatusTextures;
  end;
end;


procedure TFormMain.MenuItemTexturesBrowseClick(Sender: TObject);
var
  IndexSkin: Integer;
begin
  IndexSkin := StringGridTextures.Row;

  if SkinPackages[IndexSkin].CountPackages > 0 then
  begin
    OpenDialogTexture.FileName := SkinPackages[IndexSkin].TextFilePackages[SkinPackages[IndexSkin].IndexPackage];
  end
  else begin
    OpenDialogTexture.FileName := '';
  end;

  if OpenDialogTexture.Execute then
  begin
    Application.ProcessMessages;

    if SetPackage(SkinPackages[IndexSkin], OpenDialogTexture.FileName) then
    begin
      StringGridTextures.Cells[1, IndexSkin] := GetPackageName(SkinPackages[IndexSkin].TextFilePackages[SkinPackages[IndexSkin].IndexPackage]);
    end
    else begin
      Application.MessageBox(PChar(Localized(Self, 'MessageErrorTextureLoad(Browse)', 'The selected file doesn''t contain this texture.')), 'MeshMaker', MB_ICONERROR);
    end;

    SetStatusTextures;
  end;
end;


procedure TFormMain.SetStatusTextures;
var
  IndexSkin: Integer;
begin
  if Length(SkinPackages) > 8 then
  begin
    LabelStatusTextures.Caption := Localized(Self, 'LabelStatusTextures(Number)', 'Too many textures used. Only up to eight are supported.');
    LabelStatusTextures.Show;
    ButtonNext.Enabled := False;
    Exit;
  end;

  for IndexSkin := 0 to High(SkinPackages) do
  begin
    if SkinPackages[IndexSkin].CountPackages = 0 then
    begin
      LabelStatusTextures.Caption := Localized(Self, 'LabelStatusTextures(Unresolved)', 'Some texture/package mappings are still unresolved.');
      LabelStatusTextures.Show;
      ButtonNext.Enabled := False;
      Exit;
    end;
  end;

  ButtonNext.Enabled := True;
  LabelStatusTextures.Hide;
end;


procedure TFormMain.ButtonNextClick(Sender: TObject);
var
  CountClasses: Integer;
  FileClass: TextFile;
  FlagFoundPackage: Boolean;
  IndexChar: Integer;
  IndexCharPackage: Integer;
  IndexClass: Integer;
  IndexPackage: Integer;
  IndexSkin: Integer;
  TextFilePackage: string;
  TextFileClasses: TFileNames;
  TextLine: string;
  TextPackage: string;
begin
  case PageControl.ActivePageIndex of
    0:
    begin
      ButtonNext.Enabled := False;

      for IndexSkin := 0 to Mesh.CountSkins - 1 do
      begin
        TextFilePackage := SkinPackages[IndexSkin].TextFilePackages[SkinPackages[IndexSkin].IndexPackage];

        if not Mesh.LoadSkin(Mesh.Skins[IndexSkin], SKIN_Texture, TextFilePackage) then
        begin
          Application.MessageBox(PChar(Format(Localized(Self, 'MessageErrorTextureLoad(Proceed)', 'Unable to load skin %s from package file ''%s.'''), [SkinPackages[IndexSkin].TextSkin, TextFilePackage])), 'MeshMaker', MB_ICONERROR);
          Exit;
        end;
      end;

      try
        ChDir(TextDirectoryUnreal);

        Mesh.ClearMesh;
        Mesh.ClearEvents;
        Mesh.LoadPrefab(EditPrefab.Text);

      except
        on Exception do
        begin
          Application.MessageBox(PChar(Localized(Self, 'MessageErrorPrefabLoad', 'Unable to load prefab.')), 'MeshMaker', MB_ICONERROR);
          Exit;
        end;
      end;

      EditExportClass.Text := GetValidIdent(GetPackageName(EditPrefab.Text), 'Deco');

      if IsValidIdent(Options.ExportPackage)
        then EditExportPackage.Text := Options.ExportPackage
        else EditExportPackage.Text := EditExportClass.Text;
    end;

    1:
    begin
      try
        Mesh.SaveMesh(TextDirectoryUnreal + EditExportPackage.Text, EditExportClass.Text, 'Decoration', CheckBoxExportCollision.Checked, CENTER_Extent, 'Generated by MeshMaker (c) 2001 by Mychaeel <mychaeel@planetunreal.com>');

      except
        on Exception do
        begin
          Application.MessageBox(PChar(Localized(Self, 'MessageErrorMeshSave', 'Unable to save mesh files.')), 'MeshMaker', MB_ICONERROR);
          Exit;
        end;
      end;

      if RadioButtonExportDecoration.Checked then
      begin
        FormCompile.FormMain := Self;
        FormCompile.TextPackageCompile := EditExportPackage.Text;

        SetLength(FormCompile.TextPackages, 2);
        FormCompile.TextPackages[0] := 'Core';
        FormCompile.TextPackages[1] := 'Engine';

        CountClasses := 0;
        TextFileClasses := nil;
        ReadFiles(Format('%s%s\Classes\', [TextDirectoryUnreal, EditExportPackage.Text]), '*.uc', TextFileClasses, CountClasses);

        for IndexClass := 0 to CountClasses - 1 do
        begin
          try
            AssignFile(FileClass, TextFileClasses[IndexClass]);
            Reset(FileClass);

            while not Eof(FileClass) do
            begin
              ReadLn(FileClass, TextLine);
              TextLine := Trim(TextLine);
              if (Length(TextLine) > 0)
                 and not AnsiSameText(Copy(TextLine, 1, 5), 'class')
                 and not (TextLine[1] in ['#', '/']) then Break;

              IndexCharPackage := AnsiPos('EditPackages=', TextLine);
              if IndexCharPackage = 0 then Continue;
              TextPackage := Copy(TextLine, IndexCharPackage + 13, Length(TextLine));

              for IndexChar := 1 to Length(TextPackage) do
              begin
                if not (TextPackage[IndexChar] in ['0'..'9', 'A'..'Z', 'a'..'z', '_']) then
                begin
                  Delete(TextPackage, IndexChar, Length(TextPackage));
                  Break;
                end;
              end;

              FlagFoundPackage := False;
              for IndexPackage := 0 to High(FormCompile.TextPackages) do
              begin
                if AnsiSameText(FormCompile.TextPackages[IndexPackage], TextPackage) then
                begin
                  FlagFoundPackage := True;
                  Break;
                end;
              end;

              if not FlagFoundPackage then
              begin
                SetLength(FormCompile.TextPackages, Length(FormCompile.TextPackages) + 1);
                FormCompile.TextPackages[High(FormCompile.TextPackages)] := TextPackage;
              end;
            end;

            CloseFile(FileClass);

          except
            on Exception do;
          end;
        end;

        if FormCompile.Compile <> mrOk then Exit;
      end;

      PanelDoneModel.Visible           := RadioButtonExportModel.Checked;
      PanelDoneDecoration.Visible      := RadioButtonExportDecoration.Checked;
      LabelCaptionFilePackage.Visible  := RadioButtonExportDecoration.Checked;
      EditFilePackage.Visible          := RadioButtonExportDecoration.Checked;
      LabelDescriptionPackage1.Visible := RadioButtonExportDecoration.Checked;
      LabelDescriptionPackage2.Visible := RadioButtonExportDecoration.Checked;

      EditFileCode.Text    := Format('%s\Classes\%s.uc',  [EditExportPackage.Text, EditExportClass.Text]);
      EditFileModel1.Text  := Format('%s\Models\%s_a.3d', [EditExportPackage.Text, EditExportClass.Text]);
      EditFileModel2.Text  := Format('%s\Models\%s_d.3d', [EditExportPackage.Text, EditExportClass.Text]);
      EditFilePackage.Text := Format('System\%s.u',       [EditExportPackage.Text]);

      LabelDescriptionPackage1.Caption := Format(Localized(Self, 'LabelDescriptionPackage1', 'You only have to bundle %s.u with your map release; or check'), [EditExportPackage.Text]);
    end;
  end;

  PageControl.ActivePageIndex := PageControl.ActivePageIndex + 1;
  PageControlChange(Self);
end;


procedure TFormMain.ButtonBackClick(Sender: TObject);
begin
  PageControl.ActivePageIndex := PageControl.ActivePageIndex - 1;
  PageControlChange(Self);
end;


procedure TFormMain.PageControlChange(Sender: TObject);
var
  IndexPage: Integer;
begin
  for IndexPage := 0 to PageControl.PageCount - 1 do
  begin
    PageControl.Pages[IndexPage].TabVisible := IndexPage <= PageControl.ActivePageIndex;
  end;

  ButtonBack.Visible := PageControl.ActivePageIndex > 0;
  ButtonNext.Enabled := PageControl.ActivePageIndex < PageControl.PageCount - 1;

  if PageControl.ActivePageIndex = PageControl.PageCount - 1
    then ButtonCancel.Caption := Localized(Self, 'ButtonClose',  'Close')
    else ButtonCancel.Caption := Localized(Self, 'ButtonCancel', 'Cancel');

  case PageControl.ActivePageIndex of
    0:
    begin
      ButtonNext.Enabled := PanelTextures.Visible and not LabelStatusTextures.Visible;
      if Visible then EditPrefab.SetFocus;
    end;

    1:
    begin
      EditExportChange(Self);
      if Visible then EditExportClass.SetFocus;
    end;

    2:
    begin
      if Visible then PanelDoneFocus.SetFocus;
    end;
  end;

  DragAcceptFiles(Handle, PageControl.ActivePage = TabSheetPrefab);
end;


procedure TFormMain.EditExportChange(Sender: TObject);
var
  FlagValid: Boolean;
begin
  FlagValid := IsValidIdent(EditExportClass.Text) and IsValidIdent(EditExportPackage.Text);

  ButtonNext.Enabled := FlagValid;

  if FlagValid and (Sender = EditExportPackage) then
  begin
    LabelDescriptionModel2.Caption      := Format(Localized(Self, 'LabelDescriptionModel2', 'UnrealScript source files in a subdirectory named ''%s'''), [EditExportPackage.Text]);
    LabelDescriptionDecoration1.Caption := Format(Localized(Self, 'LabelDescriptionDecoration1', 'With this option, MeshMaker will automatically create %s.u'), [EditExportPackage.Text]);
  end;
end;


procedure TFormMain.LabelEmail_NoLocMouseMove(Sender: TObject; Shift: TShiftState; X, Y: Integer);
begin
  if     (X >= 0) and (X < LabelEmail_NoLoc.Width)
     and (Y >= 0) and (Y < LabelEmail_NoLoc.Height) then
  begin
    LabelEmail_NoLoc.Font.Color := clBlue;
    LabelEmail_NoLoc.Font.Style := LabelEmail_NoLoc.Font.Style + [fsUnderline];
    TimerEmail.Enabled := True;
  end
  else begin
    LabelEmail_NoLoc.Font.Color := clWindowText;
    LabelEmail_NoLoc.Font.Style := LabelEmail_NoLoc.Font.Style - [fsUnderline];
    TimerEmail.Enabled := False;
  end;
end;


procedure TFormMain.LabelEmail_NoLocMouseUp(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
  if     (X >= 0) and (X < LabelEmail_NoLoc.Width)
     and (Y >= 0) and (Y < LabelEmail_NoLoc.Height) then
  begin
    ShellExecute(Handle, nil, PChar(Format('mailto:%s', [LabelEmail_NoLoc.Caption])), nil, nil, SW_SHOWNORMAL);
  end;
end;


procedure TFormMain.TimerEmailTimer(Sender: TObject);
begin
  LabelEmail_NoLocMouseMove(Sender, [], Mouse.CursorPos.X - LabelEmail_NoLoc.ClientOrigin.X, Mouse.CursorPos.Y - LabelEmail_NoLoc.ClientOrigin.Y);
end;

procedure TFormMain.MemoPasteBrushChange(Sender: TObject);
var FileName: String;
begin
	FileName := ExtractFilePath(ParamStr(0)) + 'MeshMaker_paste.tmp';
	MemoPasteBrush.Lines.SaveToFile(FileName);
    EditPrefab.Text := FileName;
    TextPrefabEdited(EditPrefab.Text)
end;

end.
