unit Mesh;


interface


uses
  FileCtrl, SysUtils, Math, UT_Packages, SysTools;


(***************************************************************************)
(*  Tools
(***************************************************************************)

function FindTexture(Package: TUTPackage; TextTexture: string): Integer;


(***************************************************************************)
(*  TMesh
(***************************************************************************)

type
  EPrefab = class(Exception);
  EPrefabInvalidFile   = class(EPrefab);
  EPrefabInvalidNumber = class(EPrefab);
  EPrefabInvalidVector = class(EPrefab);

  EModel = class(Exception);
  EModelInvalidFile = class(EModel);

  EMesh = class(Exception);
  EMeshTooManySkins = class(EMesh);


  TOnError   = procedure (Sender: TObject; CodeError:   Integer; TextError:   string) of object;
  TOnWarning = procedure (Sender: TObject; CodeWarning: Integer; TextWarning: string) of object;


  TFlagCompatibilityMesh = (
    COMPATIBILITY_Unreal,
    COMPATIBILITY_DeusEx);


  TFlagCenter = (
    CENTER_Original,
    CENTER_Extent);


  TFlagSkin = (
    SKIN_None,
    SKIN_Texture,
    SKIN_File);


  TFlagSurface = (
    SURFACE_Masked,
    SURFACE_Translucent,
    SURFACE_Modulated,
    SURFACE_Twosided,
    SURFACE_Unlit,
    SURFACE_Environment,
    SURFACE_Unsmoothed);
  TFlagsSurface = set of TFlagSurface;


  TVector = record
    X: Double;
    Y: Double;
    Z: Double;
  end;


  TTexel = record
    U: Integer;
    V: Integer;
  end;


  TSkin = record
    FlagSkin:     TFlagSkin;
    FlagsSurface: TFlagsSurface;
    TexelSize:    TTexel;
    TextSkin:     string;
    IndexPackage: Integer;  // SKIN_Texture
    TextGroup:    string;   // SKIN_Texture
    TextFile:     string;   // SKIN_File
  end;


  TPackage = record
    Package:     TUTPackage;
    FlagUsed:    Boolean;
    TextPackage: string;
  end;


  TFace = record
    IndexSkin:     Integer;
    IndexVertices: array [0..2] of Integer;
    Texels:        array [0..2] of TTexel;
    Flags:         TFlagsSurface;
  end;


  THeaderAnimation = record
    CountFrames: Word;
    SizeFrame:   Word;
  end;


  THeaderMesh = record
    CountFaces:    Word;
    CountVertices: Word;
    Other: array [0..43] of Char;
  end;


  TPolygon = record
    IndexVertices:  array [0..2] of Word;
    FlagsType:      Byte;
    Color:          Byte;
    Texels:         array [0..2] of array [0..1] of Byte;
    IndexSkin:      Byte;
    FlagsPolygon:   Byte;
  end;


  TMesh = class
  private
    FOnError:   TOnError;
    FOnWarning: TOnWarning;

    FCountFaces:    Integer;
    FCountPackages: Integer;
    FCountPolygons: Integer;
    FCountSkins:    Integer;
    FCountVertices: Integer;

    FCompatibility: TFlagCompatibilityMesh;

    procedure RaiseError  (CodeError:   Integer; TextError:   string);
    procedure RaiseWarning(CodeWarning: Integer; TextWarning: string);

  public
    Faces:    array of TFace;
    Packages: array of TPackage;
    Skins:    array of TSkin;
    Vertices: array of TVector;

    constructor Create;
    destructor Destroy; override;

    procedure Clear;
    procedure ClearEvents;
    procedure ClearMesh;

    procedure LoadPrefab(TextFilePrefab: string);
    procedure LoadModel(TextFileModel: string);
    function  LoadSkin(var Skin: TSkin; FlagSkin: TFlagSkin; TextFile: string): Boolean;
    procedure SaveMesh(TextPath: string; TextClass: string; TextClassBase: string; FlagCollision: Boolean = False; FlagCenter: TFlagCenter = CENTER_Extent; TextComment: string = '');

    function AddFace(AIndexVertices: array of Integer; ATexels: array of TTexel; AIndexSkin: Integer; AFlags: TFlagsSurface): Integer;
    function AddPackage(TextFilePackage: string): Integer; overload;
    function AddPackage(Package: TUTPackage): Integer; overload;
    function AddSkin(TextSkin: string): Integer;
    function AddVertex(VectorVertex: TVector): Integer;

    property OnError:   TOnError   read FOnError   write FOnError;
    property OnWarning: TOnWarning read FOnWarning write FOnWarning;

    property CountFaces:    Integer read FCountFaces;
    property CountPackages: Integer read FCountPackages;
    property CountPolygons: Integer read FCountPolygons;
    property CountSkins:    Integer read FCountSkins;
    property CountVertices: Integer read FCountVertices;

    property Compatibility: TFlagCompatibilityMesh read FCompatibility write FCompatibility;
  end;


const
  WARNING_PREFAB_SKINMISSING   = 1000;
  WARNING_PREFAB_SKINALIGNMENT = 1001;
  WARNING_PREFAB_SKINSCALING   = 1002;
  WARNING_MESH_TOOMANYENVMAP   = 1100;

  ERROR_PREFAB_INVALIDFILE     = 2000;
  ERROR_PREFAB_INVALIDNUMBER   = 2001;
  ERROR_PREFAB_INVALIDVECTOR   = 2002;
  ERROR_MODEL_INVALIDFILE      = 2100;
  ERROR_MESH_TOOMANYSKINS      = 2200;

  VectorNull: TVector = (X: 0.0; Y: 0.0; Z: 0.0);
  TexelNull:  TTexel  = (U: 0; V: 0);


implementation


(***************************************************************************)
(*  Tools
(***************************************************************************)

function ModP(Divident: Integer; Divisor: Integer): Integer;
begin
  Result := Divident mod Divisor;
  if Result < 0 then Inc(Result, Divisor);
end;


function FindTexture(Package: TUTPackage; TextTexture: string): Integer;
var
  TextClass: string;
begin
  Result := 0;

  while True do
  begin
    Result := Package.FindObject(utolExports, [utfwName], '', TextTexture, '', Result);
    if Result < 0 then Exit;

    TextClass := LowerCase(Package.Exported[Result].UTClassName);

    if AnsiPos('texture', TextClass) = 0 then
    begin
      Inc(Result);
      Continue;
    end;

    if    (TextClass = 'texture')
       or (TextClass = 'firetexture')
       or (TextClass = 'icetexture')
       or (TextClass = 'watertexture')
       or (TextClass = 'wavetexture')
       or (TextClass = 'wettexture')
       or (TextClass = 'scriptedtexture') then Exit;

    Inc(Result);
  end;
end;


(***************************************************************************)
(*  TMesh
(***************************************************************************)

constructor TMesh.Create;
begin
  FCompatibility := COMPATIBILITY_Unreal;
end;


procedure TMesh.Clear;
var
  IndexPackage: Integer;
begin
  for IndexPackage := 0 to FCountPackages - 1 do
  begin
    Packages[IndexPackage].Package.Free;
  end;

  FCountFaces    := 0;
  FCountPackages := 0;
  FCountPolygons := 0;
  FCountSkins    := 0;
  FCountVertices := 0;

  Faces    := nil;
  Packages := nil;
  Skins    := nil;
  Vertices := nil;
end;


procedure TMesh.ClearEvents;
begin
  FOnError   := nil;
  FOnWarning := nil;
end;


procedure TMesh.ClearMesh;
begin
  FCountFaces    := 0;
  FCountPolygons := 0;
  FCountVertices := 0;

  Faces    := nil;
  Vertices := nil;
end;


destructor TMesh.Destroy;
begin
  Clear;
  inherited;
end;


function TMesh.AddFace(AIndexVertices: array of Integer; ATexels: array of TTexel; AIndexSkin: Integer; AFlags: TFlagsSurface): Integer;
begin
  Result := -1;

  if    (AIndexVertices[0] = AIndexVertices[1])
     or (AIndexVertices[1] = AIndexVertices[2])
     or (AIndexVertices[0] = AIndexVertices[2]) then Exit;

  Result := FCountFaces;
  Inc(FCountFaces);

       if Length(Faces) = 0           then SetLength(Faces, 12)
  else if Length(Faces) < FCountFaces then SetLength(Faces, Length(Faces) * 2);

  with Faces[Result] do
  begin
    IndexSkin := AIndexSkin;
    Flags     := AFlags;

    IndexVertices[0] := AIndexVertices[0];
    IndexVertices[1] := AIndexVertices[1];
    IndexVertices[2] := AIndexVertices[2];

    Texels[0] := ATexels[0];
    Texels[1] := ATexels[1];
    Texels[2] := ATexels[2];
  end;
end;


function TMesh.AddPackage(TextFilePackage: string): Integer;
begin
  for Result := 0 to FCountPackages - 1 do
  begin
    if AnsiSameText(TextFilePackage, Packages[Result].Package.Package) then Exit;
  end;

  Result := AddPackage(TUTPackage.Create(TextFilePackage));
end;


function TMesh.AddPackage(Package: TUTPackage): Integer;
begin
  for Result := 0 to FCountPackages - 1 do
  begin
    if Package = Packages[Result].Package then Exit;
  end;

  Result := FCountPackages;
  Inc(FCountPackages);

       if Length(Packages) = 0              then SetLength(Packages, 1)
  else if Length(Packages) < FCountPackages then SetLength(Packages, Length(Packages) * 2);

  Packages[Result].Package     := Package;
  Packages[Result].FlagUsed    := False;
  Packages[Result].TextPackage := ChangeFileExt(ExtractFileName(Package.Package), '');
end;


function TMesh.LoadSkin(var Skin: TSkin; FlagSkin: TFlagSkin; TextFile: string): Boolean;
var
  IndexPackage: Integer;
  IndexSkin: Integer;
  IndexTexture: Integer;
  Package: TUTPackage;
begin
  Result := False;

  case FlagSkin of
    SKIN_Texture:
    begin
      Package := nil;

      try
        for IndexPackage := 0 to FCountPackages - 1 do
        begin
          if AnsiSameText(TextFile, Packages[IndexPackage].Package.Package) then
          begin
            Package := Packages[IndexPackage].Package;
            Break;
          end;
        end;

        if not Assigned(Package) then
        begin
          Package := TUTPackage.Create(TextFile);
        end;

        IndexTexture := FindTexture(Package, Skin.TextSkin);

        if IndexTexture >= 0 then
        begin
          Skin.FlagSkin     := SKIN_Texture;
          Skin.IndexPackage := AddPackage(Package);
          Skin.TextSkin     := Package.Exported[IndexTexture].UTObjectName;
          Skin.TextGroup    := Package.Exported[IndexTexture].UTPackageName;

          with Package.Exported[IndexTexture].UTObject do
          begin
            ReadObject;

            Skin.TexelSize.U := Properties.PropertyByNameValue['USize'];
            Skin.TexelSize.V := Properties.PropertyByNameValue['VSize'];

            Skin.FlagsSurface := [];
            if Properties.PropertyByNameValue['bMasked']      then Skin.FlagsSurface := Skin.FlagsSurface + [SURFACE_Masked];
            if Properties.PropertyByNameValue['bTransparent'] then Skin.FlagsSurface := Skin.FlagsSurface + [SURFACE_Translucent];
            if Properties.PropertyByNameValue['bEnvironment'] then Skin.FlagsSurface := Skin.FlagsSurface + [SURFACE_Environment];
            if Properties.PropertyByNameValue['bModulate']    then Skin.FlagsSurface := Skin.FlagsSurface + [SURFACE_Modulated];
            if Properties.PropertyByNameValue['bTwoSided']    then Skin.FlagsSurface := Skin.FlagsSurface + [SURFACE_Twosided];
            if Properties.PropertyByNameValue['bNoSmooth']    then Skin.FlagsSurface := Skin.FlagsSurface + [SURFACE_Unsmoothed];
            if Properties.PropertyByNameValue['bUnlit']       then Skin.FlagsSurface := Skin.FlagsSurface + [SURFACE_Unlit];

            ReleaseObject;
          end;

          for IndexPackage := FCountPackages - 1 downto 0 do
          begin
            Packages[IndexPackage].FlagUsed := False;
          end;

          for IndexSkin := FCountSkins - 1 downto 0 do
          begin
            if Skins[IndexSkin].FlagSkin = SKIN_Texture then
            begin
              Packages[Skins[IndexSkin].IndexPackage].FlagUsed := True;
            end;
          end;

          Result := True;
        end;

      except
        on Exception do;
      end;
    end;

    SKIN_File:
    begin
      // ...
    end;
  end;
end;


function TMesh.AddSkin(TextSkin: string): Integer;
var
  IndexPackage: Integer;
  IndexTexture: Integer;
begin
  for Result := 0 to FCountSkins - 1 do
  begin
    if AnsiSameText(Skins[Result].TextSkin, TextSkin) then Exit;
  end;

  Result := FCountSkins;
  Inc(FCountSkins);

       if Length(Skins) = 0           then SetLength(Skins, 1)
  else if Length(Skins) < FCountSkins then SetLength(Skins, Length(Skins) * 2);

  for IndexPackage := 0 to FCountPackages - 1 do
  begin
    with Packages[IndexPackage] do
    begin
      IndexTexture := FindTexture(Package, TextSkin);

      if IndexTexture >= 0 then
      begin
        Skins[Result].TextSkin := Package.Exported[IndexTexture].UTObjectName;
        LoadSkin(Skins[Result], SKIN_Texture, Package.Package);

        Exit;
      end;
    end;
  end;

  Skins[Result].FlagSkin     := SKIN_None;
  Skins[Result].FlagsSurface := [];
  Skins[Result].IndexPackage := -1;
  Skins[Result].TexelSize.U  := 256;
  Skins[Result].TexelSize.V  := 256;
  Skins[Result].TextSkin     := TextSkin;
  Skins[Result].TextGroup    := '';
  Skins[Result].TextFile     := '';
end;


function TMesh.AddVertex(VectorVertex: TVector): Integer;
begin
  for Result := 0 to FCountVertices - 1 do
  begin
    if     (Vertices[Result].X = VectorVertex.X)
       and (Vertices[Result].Y = VectorVertex.Y)
       and (Vertices[Result].Z = VectorVertex.Z) then Exit;
  end;

  Inc(FCountVertices);

       if Length(Vertices) = 0              then SetLength(Vertices, 8)
  else if Length(Vertices) < FCountVertices then SetLength(Vertices, Length(Vertices) * 2);

  Result := FCountVertices - 1;
  Vertices[Result] := VectorVertex;
end;


procedure TMesh.RaiseError(CodeError: Integer; TextError: string);
begin
  if Assigned(FOnError) then
  begin
    FOnError(Self, CodeError, TextError);
    raise EAbort.Create(Format('[%d] %s', [CodeError, TextError]));
  end
  else begin
    case CodeError of
      ERROR_PREFAB_INVALIDFILE:   raise EPrefabInvalidFile  .Create(TextError);
      ERROR_PREFAB_INVALIDNUMBER: raise EPrefabInvalidNumber.Create(TextError);
      ERROR_PREFAB_INVALIDVECTOR: raise EPrefabInvalidVector.Create(TextError);
      ERROR_MODEL_INVALIDFILE:    raise EModelInvalidFile   .Create(TextError);
      ERROR_MESH_TOOMANYSKINS:    raise EMeshTooManySkins   .Create(TextError);
    end;
  end;
end;


procedure TMesh.RaiseWarning(CodeWarning: Integer; TextWarning: string);
begin
  if Assigned(FOnWarning) then
  begin
    FOnWarning(Self, CodeWarning, TextWarning);
  end;
end;


procedure TMesh.LoadPrefab(TextFilePrefab: string);
var
  DecimalSeparatorOld: Char;
  FilePrefab: TextFile;
  TextLine: string;
  VectorVertex: array of TVector;


  function GetLine: string;
  begin
    ReadLn(FilePrefab, Result);
    Result := Trim(Result);
  end;


  function ParseLine(TextLine: string; var TextParameters: string): string;
  var
    IndexChar: Integer;
  begin
    TextParameters := Trim(TextLine);

    IndexChar := Pos(' ', TextParameters) - 1;
    if IndexChar < 0 then IndexChar := Length(TextParameters);

    Result := AnsiLowerCase(Copy(TextParameters, 1, IndexChar));
    TextParameters := TrimLeft(Copy(TextParameters, IndexChar + 2, Length(TextParameters)));

    if AnsiSameText(Result, 'begin') or AnsiSameText(Result, 'end') then
    begin
      IndexChar := Pos(' ', TextParameters) - 1;
      if IndexChar < 0 then IndexChar := Length(TextParameters);

      Result := Result + ' ' + AnsiLowerCase(Copy(TextParameters, 1, IndexChar));
      TextParameters := TrimLeft(Copy(TextParameters, IndexChar + 2, Length(TextParameters)));
    end;
  end;


  function ParseParameter(TextParameters: string; TextName: string): string;
  var
    IndexChar: Integer;
  begin
    if AnsiSameText(TextName + '=', Copy(TextParameters, 1, Length(TextName) + 1)) then
    begin
      IndexChar := 1;
    end
    else begin
      IndexChar := AnsiPos(AnsiLowerCase(' ' + TextName + '='), AnsiLowerCase(TextParameters));
      if IndexChar = 0 then Exit;
      Inc(IndexChar);
    end;

    Delete(TextParameters, 1, IndexChar + Length(TextName));
    IndexChar := Pos(' ', TextParameters) - 1;
    if IndexChar < 0 then IndexChar := Length(TextParameters);

    Result := Copy(TextParameters, 1, IndexChar);
  end;


  function ParseNumber(TextNumber: string): Double;
  begin
    Result := 0.0;
    if Length(TextNumber) = 0 then Exit;

    try
      Result := StrToFloat(TextNumber);

    except
      on EConvertError do
      begin
        RaiseError(ERROR_PREFAB_INVALIDNUMBER, TextNumber);
      end;
    end;
  end;


  function ParseVector(TextVector: string): TVector;
  var
    IndexChar: Integer;
  begin
    Result := VectorNull;

    try
      IndexChar := Pos(',', TextVector);
      if IndexChar = 0 then raise EConvertError.Create('No vector components specified');
      Result.X := StrToFloat(Copy(TextVector, 1, IndexChar - 1));

      TextVector := TrimLeft(Copy(TextVector, IndexChar + 1, Length(TextVector)));
      IndexChar := Pos(',', TextVector);
      if IndexChar = 0 then IndexChar := Length(TextVector) + 1;
      Result.Y := StrToFloat(Copy(TextVector, 1, IndexChar - 1));

      TextVector := TrimLeft(Copy(TextVector, IndexChar + 1, Length(TextVector)));
      Result.Z := StrToFloat(TextVector);

    except
      on EConvertError do
      begin
        RaiseError(ERROR_PREFAB_INVALIDVECTOR, TextVector);
      end;
    end;
  end;


  function ReadPolygon: Boolean;
  var
	I: Integer;
    CountVertices: Integer;
    FlagsSurface: TFlagsSurface;
    FlagsSurfaceNative: Integer;
    IndexSkin: Integer;
    IndexVertex: Integer;
    ScaleU: double;
    ScaleV: double;
    TexelCurrent: TTexel;
    TexelDelta: TTexel;
    TexelMin: TTexel;
    TexelMax: TTexel;
    TexelPan: TTexel;
    TextCommand: string;
    TextParameters: string;
    TextSkin: string;
    VectorOrigin: TVector;
    VectorTextureU: TVector;
    VectorTextureV: TVector;


    function GetTexel(VectorVertex: TVector): TTexel;
    begin
      VectorVertex.X := VectorVertex.X - VectorOrigin.X;
      VectorVertex.Y := VectorVertex.Y - VectorOrigin.Y;
      VectorVertex.Z := VectorVertex.Z - VectorOrigin.Z;

      Result.U := Trunc(VectorTextureU.X * VectorVertex.X + VectorTextureU.Y * VectorVertex.Y + VectorTextureU.Z * VectorVertex.Z);
      Result.V := Trunc(VectorTextureV.X * VectorVertex.X + VectorTextureV.Y * VectorVertex.Y + VectorTextureV.Z * VectorVertex.Z);

      if IndexSkin >= 0 then
      begin
        Result.U := (Result.U * 256) div Skins[IndexSkin].TexelSize.U;
        Result.V := (Result.V * 256) div Skins[IndexSkin].TexelSize.V;
      end;

      Result.U := Trunc((TexelPan.U + Result.U) * ScaleU);
      Result.V := Trunc((TexelPan.V + Result.V) * ScaleV);
    end;


    function GetTexelAdjusted(OffsetPan: Integer; OffsetMin: Integer; OffsetMax: Integer): Integer;
    begin
      if OffsetMax - OffsetMin >= 256 then
      begin
        Result := -OffsetMin;
        Exit;
      end;

      Result := ModP(OffsetPan + OffsetMin, 256) - OffsetMin;

      if (Result + OffsetMin) and not $ff =
         (Result + OffsetMax) and not $ff then Exit;

      if ModP(255 - (Result + OffsetMin), 255) < ModP(Result + OffsetMax, 256)
        then Result :=                       -OffsetMin
        else Result := Result - ModP(Result + OffsetMax, 256) - 1;
    end;


  begin
    if ParseLine(TextLine, TextParameters) <> 'begin polygon' then
    begin
      Result := False;
      Exit;
    end;

    CountVertices  := 0;
    TexelPan       := TexelNull;
    VectorOrigin   := VectorNull;
    VectorTextureU := VectorNull;
    VectorTextureV := VectorNull;

    TextSkin := ParseParameter(TextParameters, 'texture');
    I := Pos(TextSkin, '.') + 1;
    if I > 1 then TextSkin := Copy(TextSkin, I, Length(TextSkin) - I);
    if Length(TextSkin) = 0 then TextSkin := 'None';

    FlagsSurfaceNative := Trunc(ParseNumber(ParseParameter(TextParameters, 'flags')));

    while not Eof(FilePrefab) do
    begin
      TextLine := GetLine;
      TextCommand := ParseLine(TextLine, TextParameters);

           if TextCommand = 'end polygon' then Break
      else if TextCommand = 'origin'   then VectorOrigin   := ParseVector(TextParameters)
      else if TextCommand = 'textureu' then VectorTextureU := ParseVector(TextParameters)
      else if TextCommand = 'texturev' then VectorTextureV := ParseVector(TextParameters)
      else if TextCommand = 'pan' then
      begin
        TexelPan.U := Trunc(ParseNumber(ParseParameter(TextParameters, 'u')));
        TexelPan.V := Trunc(ParseNumber(ParseParameter(TextParameters, 'v')));
      end
      else if TextCommand = 'vertex' then
      begin
        Inc(CountVertices);
        if Length(VectorVertex) < CountVertices then SetLength(VectorVertex, CountVertices);
        VectorVertex[CountVertices - 1] := ParseVector(TextParameters);
      end;
    end;

    if FlagsSurfaceNative and 1 = 0 then
    begin
      IndexSkin := AddSkin(TextSkin);

      FlagsSurface := Skins[IndexSkin].FlagsSurface;
      if FlagsSurfaceNative and $00000002 <> 0 then FlagsSurface := FlagsSurface + [SURFACE_Masked];
      if FlagsSurfaceNative and $00000004 <> 0 then FlagsSurface := FlagsSurface + [SURFACE_Translucent];
      if FlagsSurfaceNative and $00000040 <> 0 then FlagsSurface := FlagsSurface + [SURFACE_Modulated];
      if FlagsSurfaceNative and $00000100 <> 0 then FlagsSurface := FlagsSurface + [SURFACE_Twosided];
      if FlagsSurfaceNative and $00000800 <> 0 then FlagsSurface := FlagsSurface + [SURFACE_Unsmoothed];
      if FlagsSurfaceNative and $00400000 <> 0 then FlagsSurface := FlagsSurface + [SURFACE_Unlit];
      if FlagsSurfaceNative and $08000000 <> 0 then FlagsSurface := FlagsSurface + [SURFACE_Environment];

      if Skins[IndexSkin].FlagSkin = SKIN_None then
      begin
        RaiseWarning(WARNING_PREFAB_SKINMISSING, TextSkin);
      end;

      ScaleU := 1.0;
      ScaleV := 1.0;

      if IndexSkin >= 0 then
      begin
        TexelPan.U := (TexelPan.U * 256) div Skins[IndexSkin].TexelSize.U;
        TexelPan.V := (TexelPan.V * 256) div Skins[IndexSkin].TexelSize.V;
      end;

      TexelMin := GetTexel(VectorVertex[0]);
      TexelMax := TexelMin;

      for IndexVertex := 1 to CountVertices - 1 do
      begin
        TexelCurrent := GetTexel(VectorVertex[IndexVertex]);

        if TexelMin.U > TexelCurrent.U then TexelMin.U := TexelCurrent.U;
        if TexelMin.V > TexelCurrent.V then TexelMin.V := TexelCurrent.V;
        if TexelMax.U < TexelCurrent.U then TexelMax.U := TexelCurrent.U;
        if TexelMax.V < TexelCurrent.V then TexelMax.V := TexelCurrent.V;
      end;

      Dec(TexelMin.U, TexelPan.U);
      Dec(TexelMin.V, TexelPan.V);
      Dec(TexelMax.U, TexelPan.U);
      Dec(TexelMax.V, TexelPan.V);

      TexelPan.U := GetTexelAdjusted(TexelPan.U, TexelMin.U, TexelMax.U);
      TexelPan.V := GetTexelAdjusted(TexelPan.V, TexelMin.V, TexelMax.V);

      TexelDelta.U := TexelMax.U - TexelMin.U;
      TexelDelta.V := TexelMax.V - TexelMin.V;

      if TexelDelta.U < 256 then ScaleU := 1.0 else ScaleU := 255.0 / TexelDelta.U;
      if TexelDelta.V < 256 then ScaleV := 1.0 else ScaleV := 255.0 / TexelDelta.V;

      if (ScaleU < 1.0) or (ScaleV < 1.0) then
      begin
        RaiseWarning(WARNING_PREFAB_SKINSCALING, TextSkin);
      end;

      Inc(FCountPolygons);

//      TexelPan       := TexelNull;
//      ScaleU := 1;
//      ScaleV := 1;

      for IndexVertex := 1 to CountVertices - 2 do
      begin
        AddFace([AddVertex(VectorVertex[0]), AddVertex(VectorVertex[IndexVertex]), AddVertex(VectorVertex[IndexVertex + 1])],
                [GetTexel (VectorVertex[0]), GetTexel (VectorVertex[IndexVertex]), GetTexel (VectorVertex[IndexVertex + 1])],
                IndexSkin, FlagsSurface);
      end;
    end;

    Result := True;
  end;


  function ReadPolyList: Boolean;
  var
    TextParameters: string;
  begin
    if ParseLine(TextLine, TextParameters) <> 'begin polylist' then
    begin
      Result := False;
      Exit;
    end;

    while not Eof(FilePrefab) do
    begin
      TextLine := GetLine;
      if ParseLine(TextLine, TextParameters) = 'end polylist' then Break;

      ReadPolygon;
    end;

    Result := True;
  end;


begin
  VectorVertex := nil;

  DecimalSeparatorOld := DecimalSeparator;
  DecimalSeparator := '.';

  AssignFile(FilePrefab, TextFilePrefab);
  Reset(FilePrefab);

  try
    while not Eof(FilePrefab) do
    begin
      TextLine := GetLine;
      if ReadPolyList then Break;
    end;

    if FCountPolygons = 0 then
    begin
      RaiseError(ERROR_PREFAB_INVALIDFILE, TextFilePrefab);
    end;

  finally
    CloseFile(FilePrefab);
    VectorVertex := nil;

    DecimalSeparator := DecimalSeparatorOld;
  end;
end;


procedure TMesh.LoadModel(TextFileModel: string);
type
  TChunkHeader = record
    Id:     Word;
    Length: Longword;
  end;

var
  FileModel: file of Byte;


var
  ChunkHeaderMain: TChunkHeader;
begin
  AssignFile(FileModel, TextFileModel);
  Reset(FileModel);

  try
    BlockRead(FileModel, ChunkHeaderMain, SizeOf(ChunkHeaderMain));

  finally
    CloseFile(FileModel);
  end;
end;


procedure TMesh.SaveMesh(TextPath: string; TextClass: string; TextClassBase: string; FlagCollision: Boolean; FlagCenter: TFlagCenter; TextComment: string);
var
  DecimalSeparatorOld: Char;
  FileAnimation: file;
  FileCode: TextFile;
  FileMesh: file;
  IndexFace: Integer;
  IndexPackage: Integer;
  IndexSkin: Integer;
  IndexSkinEnvironment: Integer;
  IndexVertex: Integer;
  HeaderAnimation: THeaderAnimation;
  HeaderMesh: THeaderMesh;
  Polygon: TPolygon;
  Scale: Double;
  TextFilePackage: string;
  TextSkinQualified: string;
  VectorExtent: TVector;
  VectorMin: TVector;
  VectorMax: TVector;
  VectorScale: TVector;
  VectorOrigin: TVector;
  VertexUnreal: Longword;
  VertexDeusEx: array [0..3] of Smallint;


  function GetIndexSkin(IndexSkin: Integer): Integer;
  begin
         if IndexSkinEnvironment < 0         then Result := IndexSkin
    else if IndexSkinEnvironment > IndexSkin then Result := IndexSkin
    else if IndexSkinEnvironment = IndexSkin then Result := FCountSkins - 1
    else                                          Result := IndexSkin   - 1;
  end;


begin
  if FCountFaces = 0 then Exit;
  if FCountSkins > 8 then RaiseError(ERROR_MESH_TOOMANYSKINS, IntToStr(FCountSkins));

  IndexSkinEnvironment := -1;
  for IndexFace := 0 to FCountFaces - 1 do
  begin
    with Faces[IndexFace] do
    begin
      if SURFACE_Environment in Flags then
      begin
             if IndexSkinEnvironment = IndexSkin then Continue
        else if IndexSkinEnvironment >= 0 then RaiseWarning(WARNING_MESH_TOOMANYENVMAP, Skins[IndexSkin].TextSkin)
        else    IndexSkinEnvironment := IndexSkin;
      end;
    end;
  end;

  VectorMin := Vertices[0];
  VectorMax := Vertices[0];

  for IndexVertex := 1 to FCountVertices - 1 do
  begin
    with Vertices[IndexVertex] do
    begin
      if VectorMin.X > X then VectorMin.X := X;
      if VectorMin.Y > Y then VectorMin.Y := Y;
      if VectorMin.Z > Z then VectorMin.Z := Z;

      if VectorMax.X < X then VectorMax.X := X;
      if VectorMax.Y < Y then VectorMax.Y := Y;
      if VectorMax.Z < Z then VectorMax.Z := Z;
    end;
  end;

  case FlagCenter of
    CENTER_Original:
    begin
      VectorOrigin := VectorNull;

      VectorExtent.X := Max(Abs(VectorMin.X), Abs(VectorMax.X));
      VectorExtent.Y := Max(Abs(VectorMin.Y), Abs(VectorMax.Y));
      VectorExtent.Z := Max(Abs(VectorMin.Z), Abs(VectorMax.Z));
    end;

    CENTER_Extent:
    begin
      VectorOrigin.X := (VectorMax.X + VectorMin.X) / 2;
      VectorOrigin.Y := (VectorMax.Y + VectorMin.Y) / 2;
      VectorOrigin.Z := (VectorMax.Z + VectorMin.Z) / 2;

      VectorExtent.X := (VectorMax.X - VectorMin.X) / 2;
      VectorExtent.Y := (VectorMax.Y - VectorMin.Y) / 2;
      VectorExtent.Z := (VectorMax.Z - VectorMin.Z) / 2;
    end;
  end;

  case FCompatibility of
    COMPATIBILITY_Unreal:
    begin
      Scale := Max(Max(VectorExtent.X, VectorExtent.Y) / 1023.0, VectorExtent.Z / 511.0);
      VectorScale.X := Scale;
      VectorScale.Y := Scale;
      VectorScale.Z := Scale * 2.0;
    end;

    COMPATIBILITY_DeusEx:
    begin
      Scale := Max(Max(VectorExtent.X, VectorExtent.Y), VectorExtent.Z) / 32767.0;
      VectorScale.X := Scale;
      VectorScale.Y := Scale;
      VectorScale.Z := Scale;
    end;
  end;

  if not DirectoryExists(TextPath)              then MkDir(TextPath);
  if not DirectoryExists(TextPath + '\Models')  then MkDir(TextPath + '\Models');
  if not DirectoryExists(TextPath + '\Classes') then MkDir(TextPath + '\Classes');

  AssignFile(FileMesh, TextPath + '\Models\' + TextClass + '_d.3d');
  Rewrite(FileMesh, 1);

  try
    FillChar(HeaderMesh, SizeOf(HeaderMesh), 0);
    HeaderMesh.CountFaces    := FCountFaces;
    HeaderMesh.CountVertices := FCountVertices;
    BlockWrite(FileMesh, HeaderMesh, SizeOf(HeaderMesh));

    FillChar(Polygon, SizeOf(Polygon), 0);

    for IndexFace := 0 to FCountFaces - 1 do
    begin
      with Faces[IndexFace] do
      begin
        Polygon.IndexSkin := GetIndexSkin(Max(0, IndexSkin));

        Polygon.IndexVertices[0] := IndexVertices[0];
        Polygon.IndexVertices[1] := IndexVertices[1];
        Polygon.IndexVertices[2] := IndexVertices[2];

        Polygon.Texels[0][0] := Texels[0].U;
        Polygon.Texels[0][1] := Texels[0].V;
        Polygon.Texels[1][0] := Texels[1].U;
        Polygon.Texels[1][1] := Texels[1].V;
        Polygon.Texels[2][0] := Texels[2].U;
        Polygon.Texels[2][1] := Texels[2].V;

        Polygon.FlagsType := $00;

        if SURFACE_Unlit       in Flags then Polygon.FlagsType := Polygon.FlagsType or $10;
        if SURFACE_Environment in Flags then Polygon.FlagsType := Polygon.FlagsType or $40;
        if SURFACE_Unsmoothed  in Flags then Polygon.FlagsType := Polygon.FlagsType or $80;

             if SURFACE_Translucent in Flags then Polygon.FlagsType := Polygon.FlagsType or $02
        else if SURFACE_Masked      in Flags then Polygon.FlagsType := Polygon.FlagsType or $03
        else if SURFACE_Modulated   in Flags then Polygon.FlagsType := Polygon.FlagsType or $04
        else if SURFACE_Twosided    in Flags then Polygon.FlagsType := Polygon.FlagsType or $01;
      end;

      BlockWrite(FileMesh, Polygon, SizeOf(Polygon));
    end;

  finally
    CloseFile(FileMesh);
  end;

  AssignFile(FileAnimation, TextPath + '\Models\' + TextClass + '_a.3d');
  Rewrite(FileAnimation, 1);

  try
    case FCompatibility of
      COMPATIBILITY_Unreal:
      begin
        HeaderAnimation.CountFrames := 1;
        HeaderAnimation.SizeFrame := SizeOf(VertexUnreal) * FCountVertices;
        BlockWrite(FileAnimation, HeaderAnimation, SizeOf(HeaderAnimation));

        for IndexVertex := 0 to FCountVertices - 1 do
        begin
          VertexUnreal :=     (Trunc((Vertices[IndexVertex].X - VectorOrigin.X) / VectorScale.X) and $7ff)
                          or ((Trunc((Vertices[IndexVertex].Y - VectorOrigin.Y) / VectorScale.Y) and $7ff) shl 11)
                          or ((Trunc((Vertices[IndexVertex].Z - VectorOrigin.Z) / VectorScale.Z) and $3ff) shl 22);

          BlockWrite(FileAnimation, VertexUnreal, SizeOf(VertexUnreal));
        end;
      end;

      COMPATIBILITY_DeusEx:
      begin
        HeaderAnimation.CountFrames := 1;
        HeaderAnimation.SizeFrame := SizeOf(VertexDeusEx) * FCountVertices;
        BlockWrite(FileAnimation, HeaderAnimation, SizeOf(HeaderAnimation));

        for IndexVertex := 0 to FCountVertices - 1 do
        begin
          VertexDeusEx[0] := Trunc((Vertices[IndexVertex].X - VectorOrigin.X) / VectorScale.X);
          VertexDeusEx[1] := Trunc((Vertices[IndexVertex].Y - VectorOrigin.Y) / VectorScale.Y);
          VertexDeusEx[2] := Trunc((Vertices[IndexVertex].Z - VectorOrigin.Z) / VectorScale.Z);
          VertexDeusEx[3] := 0;

          BlockWrite(FileAnimation, VertexDeusEx, SizeOf(VertexDeusEx));
        end;
      end;
    end;

  finally
    CloseFile(FileAnimation);
  end;

  DecimalSeparatorOld := DecimalSeparator;
  DecimalSeparator := '.';

  AssignFile(FileCode, TextPath + '\Classes\' + TextClass + '.uc');
  Rewrite(FileCode);

  try
    if Length(TextComment) > 0 then
    begin
      WriteLn(FileCode, Format('// %s', [TextComment]));
      WriteLn(FileCode);
    end;

    WriteLn(FileCode, Format('class %s extends %s;', [TextClass, TextClassBase]));
    WriteLn(FileCode);

    for IndexPackage := 0 to FCountPackages - 1 do
    begin
      if Packages[IndexPackage].FlagUsed then
      begin
        TextFilePackage := GetRelativePath(Packages[IndexPackage].Package.Package, IncludeTrailingBackslash(TextPath));
        if Pos(' ', TextFilePackage) > 0 then TextFilePackage := '"' + TextFilePackage + '"';

        if AnsiSameText(ExtractFileExt(TextFilePackage), '.u')
          then WriteLn(FileCode, Format('// Include EditPackages=%s in UnrealTournament.ini', [Packages[IndexPackage].TextPackage]))
          else WriteLn(FileCode, Format('#exec obj load file=%s package=%s', [TextFilePackage, Packages[IndexPackage].TextPackage]));
      end;
    end;

    WriteLn(FileCode);
    WriteLn(FileCode, Format('#exec mesh import mesh=%s anivfile=Models\%s_a.3d datafile=Models\%s_d.3d x=0 y=0 z=0 mlod=0', [TextClass, TextClass, TextClass]));
    WriteLn(FileCode, Format('#exec mesh origin mesh=%s x=0 y=0 z=0', [TextClass]));
    WriteLn(FileCode, Format('#exec mesh sequence mesh=%s seq=All startframe=0 numframes=1', [TextClass]));
    WriteLn(FileCode);
    WriteLn(FileCode, Format('#exec meshmap new meshmap=%s mesh=%s', [TextClass, TextClass]));
    WriteLn(FileCode, Format('#exec meshmap scale meshmap=%s x=%.5f y=%.5f z=%.5f', [TextClass, VectorScale.X, VectorScale.Y, VectorScale.Z]));
    WriteLn(FileCode);
    WriteLn(FileCode, 'defaultproperties');
    WriteLn(FileCode, '{');
    WriteLn(FileCode, '  DrawType=DT_Mesh');
    WriteLn(FileCode, Format('  Mesh=Mesh''%s''', [TextClass]));
    WriteLn(FileCode, '  ScaleGlow=3.00000');

    if FlagCollision then
    begin
      WriteLn(FileCode, '  bCollideWhenPlacing=True');
      WriteLn(FileCode, '  bCollideActors=True');
      WriteLn(FileCode, '  bCollideWorld=True');
      WriteLn(FileCode, '  bBlockActors=True');
      WriteLn(FileCode, '  bBlockPlayers=True');
    end;

    WriteLn(FileCode, Format('  CollisionRadius=%.5f', [Max(VectorExtent.X, VectorExtent.Y)]));
    WriteLn(FileCode, Format('  CollisionHeight=%.5f', [VectorExtent.Z]));

    for IndexSkin := 0 to FCountSkins - 1 do
    begin
      case Skins[IndexSkin].FlagSkin of
        SKIN_None:
        begin
          Continue;
        end;

        SKIN_Texture:
        begin
          TextSkinQualified := ChangeFileExt(ExtractFileName(Packages[Skins[IndexSkin].IndexPackage].Package.Package), '.');
          if Length(Skins[IndexSkin].TextGroup) > 0
            then TextSkinQualified := TextSkinQualified + Skins[IndexSkin].TextGroup + '.';
          TextSkinQualified := TextSkinQualified + Skins[IndexSkin].TextSkin;
        end;

        SKIN_File:
        begin
          TextSkinQualified := Skins[IndexSkin].TextSkin;
        end;
      end;

      WriteLn(FileCode, Format('  MultiSkins(%d)=Texture''%s''', [GetIndexSkin(IndexSkin), TextSkinQualified]));
    end;

    WriteLn(FileCode, '}');

  finally
    CloseFile(FileCode);
    DecimalSeparator := DecimalSeparatorOld;
  end;
end;

end.

