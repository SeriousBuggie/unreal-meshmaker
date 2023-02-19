unit ut_packages;
{
   UT Packages Delphi unit v1.7
   (C) 2001 Antonio Cordero Balcazar

   This unit allows you to read Unreal engine package files and their
   internal objects and extract information from them.

   Thanks to Epic Games and to everyone who helped.

   Legal: this source code is released as freeware. You can freely use and
          modify this source code, but you cannot distribute modified copies
          of it. Any changes and ideas are welcome.

// TODO : Package.OnStatus
// TODO : Add Property/Object/Package creation (another class)
// TODO : Complete support for other serialized property types.
// TODO : Complete support for compressed mipmaps in TUTObjectClassTexture
// TODO : search properties also in ancestors if don't exist in current object

   History:
   1.7 - Added end-quote characters to some object references in properties.
         Added classes LevelBase, Level, Model, Brush & Mover.
         Fixed some small bugs in some InitializeObject and DoReleaseObject functions.
         Enum cache for faster property search.         
   1.6 - Added TUTObjectClassClass.GetSource and SaveToFile methods.
         Added TUTObject.Owner property.
         Calls OnPackageNeeded if new package file does not exists.
         Support for reading array properties (GetPropertyByName* accepts array index).
   1.5 - Fixed some introduced bugs in property reading.
         Fixed ancestor of TUTObjectClassPolys.
         Removed class TUTObject_NoHeader since it is actually included in
           TUTObject (the difference is just a matter of flag RF_HasStack).
         Fixed a bug in the class equivalence function when a class had TUTObject
           as its interpreter.
         Removed some unneeded class mappings.
         Fixed bug when using the OnPackageNeeded event.
         If the objects are class instances the Enum properties are searched
           in their class objects.
         If the Enum is not found it will be searched in the current package
           (should not happen).
   1.4 - Added default properties to class decompilation.
         Changed TUTProperty.GetValue function to get a descriptive value instead
           of a description. Also with a value of -1 gets the information for the
           main property value (a complete description, even if it is an struct).
         Changed TUTProperty.ValueCount. A 0 value means not an struct. Any other
           value means an struct with that many fields.
         TUTProperty searchs for an struct or enum in the package or imported ones
           to find its fields/values.
         Fixed bug: removed unused jump labels in decompilation.
         Fixed bug: reading plane and sphere struct properties.
         Added TUTPackage.AllowReadingOtherPackages property. Set to True to
           allow reading other packages when needed (at property reading).
           Default is True. And added OnPackageNeeded event.
         Generalized method for getting known Enum values for properties.
         Added reference to owner object in TUTProperty.
         Fixed Enum property type in TUTObjectClassByteProperty.
         Added special faces (weapon) export from LodMesh objects.
   1.3 - Removed renaming of names.
         Pass more information to load exceptions.
         Fixed Sound class if package version >= 63.
         Added TUTPackage.ReleaseAllObjects method and Initialized property.
         Added TUTObject.HasBeenRead, HasBeenInterpreted, ExportedIndex and Position properties.
         Added TUTObject.RawSaveToFile and RawSaveToStream methods.
         Reinitializing a package will release all previously read objects.
         Fixed bug in some SaveToFile functions.
         Added Register2DClasses Register3DClasses, RegisterSoundClasses,
               RegisterCodeClasses RegisterAllClasses procedures to allow
               reduction in exe size if some classes are not used. You now have
               to use any of them or register manually each required class. To
               work as before call RegisterAllClasses in your code.
         Added SetNativeFunctionArray procedure.
         Fixed some memory leaks.
         Removed unneeded decompilation call from TUTObjectClassFunction.InterpretObject
                 Faster loading.
         Added TUTExportTableObjectData.CreateObject and FreeObject to make better memory use.
               Now objects are created at the first reference.
               They can be freed manually after use or when the package is freed.
         Removed messagebox at unknown opcode error, now raises an exception.
         Fixed function reading in version 61 packages (Klingon Honor Guard Demo).
         Added treatment for three unknown opcodes (0x15, 0x2B and a variant of 0x14).
         Added TUTPropertyList.GetPropertyByNameValueDefault and GetPropertyValueDefault.
         Fixed texture reading when the non-compressed mipmaps *are* compressed.
         Changed object release method to allow for consecutive reads.
   1.2 - Fixed renaming of names.
         Added Native Function array generator utility.
         Added Animation class.
         Renamed AnimSeqs field "functions" to "notifys".
         Moved read of structs to helper functions.
         Removed unnecessary "packed" keyword in records.
         Renamed some records to follow name convention.
   1.1 - Fixed UV mapping in 3DStudio exporter.
         Added MirrorX effect in 3DStudio exporter.
         Changed PrepareExporter function to support multiple frames.
         Added Unreal3D exporter class.
         Implemented Unreal3D exporter for SkeletalMeshes.
         Renames screwed object names.
         Renamed some properties of TUTExportTableObjectData and
           TUTImportTableObjectData to avoid name clashes.
         Added support for user-definable Native Functions array.
   1.0 - First public version.
         Support for following classes:
         Class (null class name),Field,Const,Enum,Struct,Function,State,
         Property,ByteProperty,IntProperty,BoolProperty,FloatProperty,
         ObjectProperty,ClassProperty,NameProperty,StructProperty,StrProperty,
         StringProperty,ArrayProperty,FixedArrayProperty,MapProperty,
         Palette,Sound,Music,TextBuffer,Font,Polys,
         Texture,WaterTexture,WaveTexture,WetTexture,IceTexture,FireTexture,
         ScriptedTexture,
         Primitive,Mesh,LodMesh,SkeletalMesh
}

interface

uses windows, sysutils, classes, graphics;

procedure Register2DClasses;
procedure Register3DClasses;
procedure RegisterSoundClasses;
procedure RegisterCodeClasses;
procedure RegisterOtherClasses;
procedure RegisterAllClasses;

const
  // Package flags
  PKG_AllowDownload = $0001;            // Allow downloading package.
  PKG_ClientOptional = $0002;           // Purely optional for clients.
  PKG_ServerSideOnly = $0004;           // Only needed on the server side.
  PKG_BrokenLinks = $0008;              // Loaded from linker with broken import links.
  PKG_Unsecure = $0010;                 // Not trusted.
  PKG_Need = $8000;                     // Client needs to download this package.

  // Object flags
  RF_Transactional = $00000001;         // Object is transactional.
  RF_Unreachable = $00000002;           // Object is not reachable on the object graph.
  RF_Public = $00000004;                // Object is visible outside its package.
  RF_TagImp = $00000008;                // Temporary import tag in load/save.
  RF_TagExp = $00000010;                // Temporary export tag in load/save.
  RF_SourceModified = $00000020;        // Modified relative to source files.
  RF_TagGarbage = $00000040;            // Check during garbage collection.
  RF_Unk_00000080 = $00000080;
  RF_Unk_00000100 = $00000100;
  RF_NeedLoad = $00000200;              // During load, indicates object needs loading.
  RF_HighlightedName = $00000400;       // A hardcoded name which should be syntax-highlighted.
  RF_InSingularFunc = $00000800;        // In a singular function.
  RF_Suppress = $00001000;              // Suppressed log name.
  RF_InEndState = $00002000;            // Within an EndState call.
  RF_Transient = $00004000;             // Don't save object.
  RF_PreLoading = $00008000;            // Data is being preloaded from file.
  RF_LoadForClient = $00010000;         // In-file load for client.
  RF_LoadForServer = $00020000;         // In-file load for client.
  RF_LoadForEdit = $00040000;           // In-file load for client.
  RF_Standalone = $00080000;            // Keep object around for editing even if unreferenced.
  RF_NotForClient = $00100000;          // Don't load this object for the game client.
  RF_NotForServer = $00200000;          // Don't load this object for the game server.
  RF_NotForEdit = $00400000;            // Don't load this object for the editor.
  RF_Destroyed = $00800000;             // Object Destroy has already been called.
  RF_NeedPostLoad = $01000000;          // Object needs to be postloaded.
  RF_HasStack = $02000000;              // Has execution stack.
  RF_Native = $04000000;                // Native (UClass only).
  RF_Marked = $08000000;                // Marked (for debugging).
  RF_ErrorShutdown = $10000000;         // ShutdownAfterError called.
  RF_DebugPostLoad = $20000000;         // For debugging Serialize calls.
  RF_DebugSerialize = $40000000;        // For debugging Serialize calls.
  RF_DebugDestroy = $80000000;          // For debugging Destroy calls.
  // The following flags have duplicated values but they seem to be used only
  // at execution time and so they will not appear in packages.
  //RF_EliminateObject  = 0x00000400,   // NULL out references to this during garbage collecion.
  //RF_RemappedName     = 0x00000800,   // Name is remapped.
  //RF_StateChanged     = 0x00001000,   // Object did a state change.

  // Property types
  otNone = 0;
  otByte = 1;
  otInt = 2;
  otBool = 3;
  otFloat = 4;
  otObject = 5;
  otName = 6;
  otString = 7;                         // old type
  otClass = 8;                          // not implemented
  otArray = 9;                          // not implemented
  otStruct = 10;
  otVector = 11;                        // not implemented => only seen as struct...
  otRotator = 12;                       // not implemented => only seen as struct...
  otStr = 13;
  otMap = 14;                           // not implemented
  otFixedArray = 15;                    // not implemented
  // Extended value types
  otExtendedValue = $00000100;
  otBuffer = otExtendedValue or 0;
  otWord = otExtendedValue or 1;

type
  TUTPackage = class;
  TUTObject = class;
  TUTPropertyType = cardinal;

  // TUTProperty
  TUTProperty = class
  private
    FIsInitialized: boolean;
    FOwner: TUTPackage;
    FOwnerObject: TUTObject;
    FName: string;
    FArrayIndex: integer;
    FPropertyType: TUTPropertyType;
    FValue: array of byte;
    FTypeName: string;
    function GetValueCount: integer;
    function GetFirstValue: variant;
    function GetTypeName: string;
    function GetDescription: string;
    function GetDescriptiveValue: string;
  public
    procedure SetOwnerObject(ownerobject: TUTObject);
    procedure SetProperty(Owner: TUTPackage; n: string; i: integer; t: TUTPropertyType; var value; valuesize: integer; typename: string = '');
    property Name: string read FName;
    property ArrayIndex: integer read FArrayIndex;
    property Value: variant read GetFirstValue;
    property DescriptiveValue: string read GetDescriptiveValue;
    property PropertyType: TUTPropertyType read FPropertyType;
    property Description: string read GetDescription;
    property TypeName: string read FTypeName;
    property SpecificTypeName: string read GetTypeName;
    property ValueCount: integer read GetValueCount;
    procedure GetValue(i: integer; var valuename: string; var value: variant; var descriptivevalue: string; var valuetype: TUTPropertyType);
    function GetValueTypeName(t: TUTPropertyType): string;
  end;

  TUTPropertyClass = class of TUTProperty;

  // TUTPropertyList
  TUTPropertyList = class
  private
    FProperties: tlist;
    function GetProperty(i: integer): TUTProperty;
    function GetPropertyCount: integer;
    function NewProperty: TUTProperty;
    function GetPropertyByName(name: string): TUTProperty;
    function GetPropertyListDescriptions: string;
    function GetPropertyByNameValue(name: string): variant;
    function GetPropertyValue(i: integer): variant;
    function GetPropertyByNameValueDefault(name: string;
      adefault: variant): variant;
    function GetPropertyValueDefault(i: integer;
      adefault: variant): variant;
  public
    constructor Create;
    destructor Destroy; override;
    property New: TUTProperty read NewProperty;
    property Count: integer read GetPropertyCount;
    property PropertyByPosition[i: integer]: TUTProperty read GetProperty;
    property PropertyByName[name: string]: TUTProperty read GetPropertyByName;
    property PropertyByNameValue[name: string]: variant read GetPropertyByNameValue; default;
    property PropertyByNameValueDefault[name: string;
    adefault: variant]: variant read GetPropertyByNameValueDefault;
    property PropertyByPositionValue[i: integer]: variant read GetPropertyValue;
    property PropertyByPositionValueDefault[i: integer;
    adefault: variant]: variant read GetPropertyValueDefault;
    procedure Clear;
    property Descriptions: string read GetPropertyListDescriptions;
    procedure FixArrayIndices;
  end;

  // TUTObject : generic class for UT exported objects
  // Status: completed
  TUTObject = class
  private
    FStartInPackage: integer;
    Fowner: TUTPackage;
    Fexportedindex: integer;
    FHasBeenRead: boolean;
    FHasBeenInterpreted: boolean;
    FReadCount: integer;
    function GetClassName: string;
    function GetObjectname: string;
    function GetPackageName: string;
    function GetSuperName: string;
    function GetClassIndex: integer;
    function GetObjectIndex: integer;
    function GetPackageIndex: integer;
    function GetSuperIndex: integer;
    function GetSerialOffset: integer;
    function GetSerialSize: integer;
    function GetFlags: longword;
    function GetProperties: TUTPropertyList;
    procedure check_initialized;
    function GetFullName: string;
    function GetPosition: integer;
    procedure SetPosition(const Value: integer);
    function GetOwner: TUTPackage;
  protected
    FProperties: TUTPropertyList;
    Buffer: TMemoryStream;
    procedure InitializeObject; virtual;
    procedure InterpretObject; virtual;
    procedure DoReleaseObject; virtual;
    procedure ReadProperties; virtual;
  public
    constructor create(owner: TUTPackage; exportedindex: integer); virtual;
    destructor destroy; override;
    procedure ReadObject(interpret: boolean = true);
    procedure ReleaseObject;
    procedure RawSaveToFile(filename: string);
    procedure RawSaveToStream(stream: TStream);
    property Owner: TUTPackage read GetOwner;
    property Position: integer read GetPosition write SetPosition;
    property HasBeenRead: boolean read FHasBeenRead;
    property HasBeenInterpreted: boolean read FHasBeenInterpreted;
    property ExportedIndex: integer read FExportedIndex;
    property Properties: TUTPropertyList read GetProperties;
    property UTObjectIndex: integer read GetObjectIndex;
    property UTClassIndex: integer read GetClassIndex;
    property UTPackageIndex: integer read GetPackageIndex;
    property UTSuperIndex: integer read GetSuperIndex;
    property UTSerialOffset: integer read GetSerialOffset;
    property UTSerialSize: integer read GetSerialSize;
    property UTFlags: longword read GetFlags;
    property UTObjectName: string read GetObjectname;
    property UTClassName: string read GetClassName;
    property UTPackageName: string read GetPackageName;
    property UTSuperName: string read GetSuperName;
    property UTFullName: string read GetFullName;
  end;

  TUTObjectClass = class of TUTObject;

  // TUTObjectClassField
  // Status: completed
  TUTObjectClassField = class(TUTObject)
  private
    FSuperField, FNext: integer;
    function GetNext: integer;
    function GetSuperField: integer;
  protected
    procedure InitializeObject; override;
    procedure InterpretObject; override;
    procedure DoReleaseObject; override;
  public
    property SuperField: integer read GetSuperField;
    property Next: integer read GetNext;
  end;

  // TUTObjectClassEnum
  // Status: completed
  TUTObjectClassEnum = class(TUTObjectClassField)
  private
    FValues: array of integer;
    function GetCount: integer;
    function GetValue(i: integer): integer;
    function GetValueName(i: integer): string;
  protected
    procedure InitializeObject; override;
    procedure InterpretObject; override;
    procedure DoReleaseObject; override;
  public
    property Count: integer read GetCount;
    property EnumValue[i: integer]: integer read GetValue;
    property EnumName[i: integer]: string read GetValueName;
    function GetDeclaration: string;
  end;

  // TUTObjectClassConst
  // Status: completed
  TUTObjectClassConst = class(TUTObjectClassField)
  private
    FValue: string;
    function GetValue: string;
  protected
    procedure InitializeObject; override;
    procedure InterpretObject; override;
    procedure DoReleaseObject; override;
  public
    property Value: string read GetValue;
    function GetDeclaration: string;
  end;

  // TUTObjectClassProperty
  // Status: completed
  TUTObjectClassProperty = class(TUTObjectClassField)
  private
    FArrayDimension: integer;
    FElementSize: integer;
    FPropertyFlags: longword;
    FCategory: string;
    FRepOffset: word;
    function GetArrayDimension: integer;
    function GetCategory: string;
    function GetElementSize: integer;
    function GetPropertyFlags: longword;
    function GetRepOffset: word;
  protected
    procedure InitializeObject; override;
    procedure InterpretObject; override;
    procedure DoReleaseObject; override;
  public
    property ArrayDimension: integer read GetArrayDimension;
    property ElementSize: integer read GetElementSize;
    property PropertyFlags: longword read GetPropertyFlags;
    property Category: string read GetCategory;
    property ReplicationOffset: word read GetRepOffset;
    function TypeName: string; virtual;
    function GetFlags(cn: string): string;
    function GetDeclaration(context, cn: string): string;
  end;

  // TUTObjectClassByteProperty
  // Status: completed
  TUTObjectClassByteProperty = class(TUTObjectClassProperty)
  private
    FEnum: integer;
    function GetEnum: integer;
  protected
    procedure InitializeObject; override;
    procedure InterpretObject; override;
    procedure DoReleaseObject; override;
  public
    property Enum: integer read GetEnum;
    function TypeName: string; override;
  end;

  // TUTObjectClassIntProperty
  // Status: completed
  TUTObjectClassIntProperty = class(TUTObjectClassProperty)
  private
  protected
  public
    function TypeName: string; override;
  end;

  // TUTObjectClassBoolProperty
  // Status: completed
  TUTObjectClassBoolProperty = class(TUTObjectClassProperty)
  private
  protected
  public
    function TypeName: string; override;
  end;

  // TUTObjectClassFloatProperty
  // Status: completed
  TUTObjectClassFloatProperty = class(TUTObjectClassProperty)
  private
  protected
  public
    function TypeName: string; override;
  end;

  // TUTObjectClassNameProperty
  // Status: completed
  TUTObjectClassNameProperty = class(TUTObjectClassProperty)
  private
  protected
  public
    function TypeName: string; override;
  end;

  // TUTObjectClassStrProperty
  // Status: completed
  TUTObjectClassStrProperty = class(TUTObjectClassProperty)
  private
  protected
  public
    function TypeName: string; override;
  end;

  // TUTObjectClassStringProperty
  // Status: completed
  TUTObjectClassStringProperty = class(TUTObjectClassProperty)
  private
  protected
  public
    function TypeName: string; override;
  end;

  // TUTObjectClassObjectProperty
  // Status: completed
  TUTObjectClassObjectProperty = class(TUTObjectClassProperty)
  private
    FObject: integer;
    function GetObject: integer;
  protected
    procedure InitializeObject; override;
    procedure InterpretObject; override;
    procedure DoReleaseObject; override;
  public
    property UTObjectType: integer read GetObject;
    function TypeName: string; override;
  end;

  // TUTObjectClassClassProperty
  // Status: completed
  TUTObjectClassClassProperty = class(TUTObjectClassObjectProperty)
  private
    FClass: integer;
    function GetClass: integer;
  protected
    procedure InitializeObject; override;
    procedure InterpretObject; override;
    procedure DoReleaseObject; override;
  public
    property UTClassType: integer read GetClass;
    function TypeName: string; override;
  end;

  // TUTObjectClassFixedArrayProperty
  // Status: complete
  TUTObjectClassFixedArrayProperty = class(TUTObjectClassProperty)
  private
    FInner: integer;
    FCount: integer;
    function GetCount: integer;
    function GetInner: integer;
  protected
    procedure InitializeObject; override;
    procedure InterpretObject; override;
    procedure DoReleaseObject; override;
  public
    property ElementCount: integer read GetCount;
    property InnerProperty: integer read GetInner;
    function TypeName: string; override;
  end;

  // TUTObjectClassArrayProperty
  // Status: completed
  TUTObjectClassArrayProperty = class(TUTObjectClassProperty)
  private
    FInner: integer;
    function GetInner: integer;
  protected
    procedure InitializeObject; override;
    procedure InterpretObject; override;
    procedure DoReleaseObject; override;
  public
    property InnerProperty: integer read GetInner;
    function TypeName: string; override;
  end;

  // TUTObjectClassMapProperty
  // Status: completed
  TUTObjectClassMapProperty = class(TUTObjectClassProperty)
  private
    FKey: integer;
    FValue: integer;
    function GetKey: integer;
    function GetValue: integer;
  protected
    procedure InitializeObject; override;
    procedure InterpretObject; override;
    procedure DoReleaseObject; override;
  public
    property KeyProperty: integer read GetKey;
    property ValueProperty: integer read GetValue;
    function TypeName: string; override;
  end;

  // TUTObjectClassStructProperty
  // Status: completed
  TUTObjectClassStructProperty = class(TUTObjectClassProperty)
  private
    FStruct: integer;
    function GetStruct: integer;
  protected
    procedure InitializeObject; override;
    procedure InterpretObject; override;
    procedure DoReleaseObject; override;
  public
    property Struct: integer read GetStruct;
    function TypeName: string; override;
  end;

  TUT_Struct_LabelEntry = record
    Name: integer;
    iCode: integer;
  end;

  // TUTObjectClassStruct
  // Status: completed
  TUTObjectClassStruct = class(TUTObjectClassField)
  private
    FScriptText: integer;
    FChildren: integer;
    FFriendlyName: string;
    FLine: integer;
    FTextPos: integer;
    FScriptSize: integer;
    function GetChildren: integer;
    function GetFriendlyName: string;
    function GetLine: integer;
    function GetScriptSize: integer;
    function GetScriptText: integer;
    function GetTextPos: integer;
    function ReadStatement: string;
  protected
    FScriptStart: integer;
    jumplist, nest: tlist;
    endnestlist: tstringlist;
    labellist, indent_chars: string;
    need_semicolon, context_change: boolean;
    position_icode, last_position_icode: integer;
    indent_level: integer;
    FLabelTable: array of TUT_Struct_LabelEntry;
    procedure InitializeObject; override;
    procedure InterpretObject; override;
    procedure DoReleaseObject; override;
    function ReadStatements(beautify: boolean = true): string;
    procedure SkipStatements;
  public
    property ScriptText: integer read GetScriptText;
    property FirstChild: integer read GetChildren;
    property FriendlyName: string read GetFriendlyName;
    property Line: integer read GetLine;
    property TextPos: integer read GetTextPos;
    property ScriptSize: integer read GetScriptSize;
    function GetDeclaration: string;
    function ReadToken(OuterOperatorPrecedence: byte = 255): string;
  end;

  // TUTObjectClassState
  // Status: completed
  TUTObjectClassState = class(TUTObjectClassStruct)
  private
    FProbeMask: int64;
    FIgnoreMask: int64;
    FLabelTableOffset: word;
    FStateFlags: longword;
    function GetIgnoreMask: int64;
    function GetLabelTableOffset: word;
    function GetProbeMask: int64;
    function GetStateFlags: longword;
  protected
    procedure InitializeObject; override;
    procedure InterpretObject; override;
    procedure DoReleaseObject; override;
  public
    property ProbeMask: int64 read GetProbeMask;
    property IgnoreMask: int64 read GetIgnoreMask;
    property LabelTableOffset: word read GetLabelTableOffset;
    property StateFlags: longword read GetStateFlags;
    function Decompile(beautify: boolean = true): string;
  end;

  TUT_Struct_Dependency = record
    _Class: integer;
    Deep: integer;
    ScriptTextCRC: integer;
  end;

  // TUTObjectClassClass
  // Status: completed
  TUTObjectClassClass = class(TUTObjectClassState)
  private
    FClassFlags: longword;
    FClassGuid: TGuid;
    FDependencies: array of TUT_Struct_Dependency;
    FPackageImports: array of integer;
    FClassWithin: integer;
    FClassConfigName: integer;
    function GetDependencies(i: integer): TUT_Struct_Dependency;
    function GetPackageImports(i: integer): integer;
    function GetClassConfigName: integer;
    function GetClassFlags: longword;
    function GetClassGuid: TGuid;
    function GetClassWithin: integer;
    function GetDependencyCount: integer;
    function GetPackageImportsCount: integer;
  protected
    procedure InitializeObject; override;
    procedure InterpretObject; override;
    procedure DoReleaseObject; override;
  public
    function Decompile(beautify: boolean = true): string;
    function GetSource(beautify: boolean = true): string;
    procedure SaveToFile(Filename: string);
    property ClassFlags: longword read GetClassFlags;
    property ClassGuid: TGuid read GetClassGuid;
    property DependencyCount: integer read GetDependencyCount;
    property Dependencies[i: integer]: TUT_Struct_Dependency read GetDependencies;
    property PackageImportsCount: integer read GetPackageImportsCount;
    property PackageImports[i: integer]: integer read GetPackageImports;
    property ClassWithin: integer read GetClassWithin;
    property ClassConfigName: integer read GetClassConfigName;
  end;

  // TUTObjectClassPalette
  // Status: completed
  TUTObjectClassPalette = class(TUTObject)
  private
    FColorCount: integer;
    FColors: array of TRGBQuad;
    function GetColor(n: integer): TColor;
    function GetNewPalette: HPalette;
    function GetColorCount: integer;
  protected
    procedure InitializeObject; override;
    procedure InterpretObject; override;
    procedure DoReleaseObject; override;
  public
    property ColorCount: integer read GetColorCount;
    property Color[n: integer]: TColor read GetColor;
    property GetPalette: HPalette read GetNewPalette;
  end;

  // TUTObjectClassSound
  // Status: completed
  TUTObjectClassSound = class(TUTObject)
  private
    FFormat: string;
    FData: string;
    function GetData: string;
    function GetFormat: string;
  protected
    procedure InitializeObject; override;
    procedure InterpretObject; override;
    procedure DoReleaseObject; override;
  public
    property Format: string read GetFormat;
    property Data: string read GetData;
    procedure SaveToFile(filename: string);
  end;

  // TUTObjectClassMusic
  // Status: completed
  TUTObjectClassMusic = class(TUTObject)
  private
    FFormat: string;
    FData: string;
    function GetData: string;
    function GetFormat: string;
  protected
    procedure InitializeObject; override;
    procedure InterpretObject; override;
    procedure DoReleaseObject; override;
  public
    property Format: string read GetFormat;
    property Data: string read GetData;
    procedure SaveToFile(filename: string);
  end;

  // TUTObjectClassTextBuffer
  // Status: completed
  TUTObjectClassTextBuffer = class(TUTObject)
  private
    FData: string;
    function GetData: string;
  protected
    procedure InitializeObject; override;
    procedure InterpretObject; override;
    procedure DoReleaseObject; override;
  public
    property Data: string read GetData;
    procedure SaveToFile(filename: string);
  end;

  TUT_Struct_FontCharacter = record
    Texture: integer;
    X, Y, W, H: integer;
  end;

  // TUTObjectClassFont
  // Status: completed
  TUTObjectClassFont = class(TUTObject)
  private
    FCharacters: array of TUT_Struct_FontCharacter;
  protected
    procedure InitializeObject; override;
    procedure InterpretObject; override;
    procedure DoReleaseObject; override;
  public
    procedure GetCharacterInfo(i: integer; var texture, x, y, w, h: integer);
  end;

  TUT_Struct_Vector = record
    X, Y, Z: single;
  end;

  TUT_Struct_Plane = record
    X, Y, Z, W: single;
  end;

  TUT_Struct_Rotator = record
    Yaw, Roll, Pitch: integer;
  end;

  TUT_Struct_Polygon = record
    Base, Normal, TextureU, TextureV: TUT_Struct_Vector;
    Vertex: array of TUT_Struct_Vector;
    PolyFlags, Actor, Texture, ItemName, iLink, iBrushPoly, pan_u, pan_v: integer;
  end;

  // TUTObjectClassTexture
  // Status: near completed
  //   Compressed MipMaps with formats TEXF_RGBA7, TEXF_RGB16, TEXF_DXT1,
  //   TEXF_RGB8 and TEXF_RGBA8 are not supported yet.
  TUTObjectClassTexture = class(TUTObject)
  private
    FMipMaps: array of TBitmap;
    FCompMipMaps: array of TBitmap;
    function GetMipMapCount: integer;
    function GetMipMap(i: integer): TBitmap;
    function GetCompMipMapCount: integer;
    function GetCompMipMap(i: integer): TBitmap;
  protected
    procedure InitializeObject; override;
    procedure InterpretObject; override;
    procedure DoReleaseObject; override;
  public
    property MipMapCount: integer read GetMipMapCount;
    property MipMap[i: integer]: TBitmap read GetMipMap;
    property CompMipMapCount: integer read GetCompMipMapCount;
    property CompMipMap[i: integer]: TBitmap read GetCompMipMap;
    procedure SaveMipMapToFile(mipmap: integer; filename: string); virtual;
    procedure SaveCompMipMapToFile(mipmap: integer; filename: string); virtual;
  end;

  TUT_Struct_Spark = record
    SparkType, Heat: byte;
    X, Y: byte;
    X_Speed, Y_Speed: byte;
    Age, ExpTime: byte;
  end;

  // TUTObjectClassFireTexture
  // Status: completed.
  TUTObjectClassFireTexture = class(TUTObjectClassTexture)
  private
    FSparks: array of TUT_Struct_Spark;
    function GetSpark(i: integer): TUT_Struct_Spark;
    function GetSparkCount: integer;
  protected
    procedure InitializeObject; override;
    procedure InterpretObject; override;
    procedure DoReleaseObject; override;
  public
    property SparkCount: integer read GetSparkCount;
    property Spark[i: integer]: TUT_Struct_Spark read GetSpark;
  end;

  TUT_Struct_BoundingBox = record
    Min, Max: TUT_Struct_Vector;
    Valid: byte;
  end;

  TUT_Struct_BoundingSphere = record
    Center: TUT_Struct_Vector;
    Radius: single;
  end;

  // TUTObjectClassPrimitive
  // Status: completed
  TUTObjectClassPrimitive = class(TUTObject)
  protected
    FPrimitiveBoundingBox: TUT_Struct_BoundingBox;
    FPrimitiveBoundingSphere: TUT_Struct_BoundingSphere;
    procedure InitializeObject; override;
    procedure InterpretObject; override;
    procedure DoReleaseObject; override;
  public
    property PrimitiveBoundingBox: TUT_Struct_BoundingBox read FPrimitiveBoundingBox;
    property PrimitiveBoundingSphere: TUT_Struct_BoundingSphere read FPrimitiveBoundingSphere;
  end;

  // TUTObjectClassPolys
  // Status: completed
  TUTObjectClassPolys = class(TUTObject)
  private
    FPolygons: array of TUT_Struct_Polygon;
    function GetPolygonCount: integer;
    function GetPolygon(n: integer): TUT_Struct_Polygon;
  protected
    procedure InitializeObject; override;
    procedure InterpretObject; override;
    procedure DoReleaseObject; override;
  public
    property PolygonCount: integer read GetPolygonCount;
    property Polygon[n: integer]: TUT_Struct_Polygon read GetPolygon;
  end;

  // TUTObjectClassBrush
  // Status: complete
  TUTObjectClassBrush = class(TUTObject);

  // TUTObjectClassMover
  // Status: complete
  TUTObjectClassMover = class(TUTObjectClassBrush);

  TUT_Struct_FVert = record
    pVertex, iSide: integer;
  end;

  QWORD = int64;                        // TODO : change to an unsigned 64 bits type

  TUT_Struct_BspNode = record
    Plane: TUT_Struct_Plane;
    ZoneMask: QWORD;
    iVertPool: integer;
    iSurf: integer;
    iBack: integer;
    iFront: integer;
    iPlane: integer;
    iCollisionBound: integer;
    iRenderBound: integer;
    iZone: array[0..1] of byte;
    NumVertices: byte;
    NodeFlags: byte;
    iLeaf: array[0..1] of byte;
  end;

  {TUT_Struct_Decal=record
    Vertices:array[0..3] of TUT_Struct_Vector;
    Actor:integer;
    Nodes:array of integer;
  end;}

  TUT_Struct_BspSurf = record
    Texture: integer;
    PolyFlags: DWORD;
    pBase: integer;
    vNormal: integer;
    vTextureU: integer;
    vTextureV: integer;
    iLightMap: integer;
    iBrushPoly: integer;
    PanU: word;
    PanV: word;
    Actor: integer;
    //Decals:array of TUT_Struct_Decal;
    //Nodes:array of integer;
  end;

  TUT_Struct_LightMapIndex = record
    DataOffset: integer;
    iLightActors: integer;
    Pan: TUT_Struct_Vector;
    UScale, VSCale: single;
    UClamp, VClamp: integer;
    UBits, VBits: byte;
  end;

  TUT_Struct_Leaf = record
    iZone: integer;
    iPermeating: integer;
    iVolumetric: integer;
    VisibleZones: QWORD;
  end;

  TUT_Struct_ZoneProperties = record
    ZoneActor: integer;
    LastRenderTime: single;
    Connectivity: QWORD;
    Visibility: QWORD;
  end;

  // TUTObjectClassModel
  // Status: complete
  TUTObjectClassModel = class(TUTObjectClassPrimitive)
  private
    FVectors: array of TUT_Struct_Vector;
    FPoints: array of TUT_Struct_Vector;
    FVerts: array of TUT_Struct_FVert;
    FNodes: array of TUT_Struct_BspNode;
    FSurfs: array of TUT_Struct_BspSurf;
    FLightMap: array of TUT_Struct_LightMapIndex;
    FLightBits: array of byte;
    FBounds: array of TUT_Struct_BoundingBox;
    FLeafHulls: array of integer;
    FLeaves: array of TUT_Struct_Leaf;
    FLights: array of integer;
    FRootOutside: boolean;
    FLinked: boolean;
    FNumSharedSides: integer;
    FNumZones: integer;
    FPolys: integer;
    FZones: array of TUT_Struct_ZoneProperties;
    function GetBoundCount: integer;
    function GetLeafCount: integer;
    function GetLeafHullCount: integer;
    function GetLightBitCount: integer;
    function GetLightCount: integer;
    function GetLightMapCount: integer;
    function GetNodeCount: integer;
    function GetPointCount: integer;
    function GetSurfCount: integer;
    function GetVectorCount: integer;
    function GetVertCount: integer;
    function GetBound(n: integer): TUT_Struct_BoundingBox;
    function GetLeaf(n: integer): TUT_Struct_Leaf;
    function GetLeafHull(n: integer): integer;
    function GetLight(n: integer): integer;
    function GetLightBit(n: integer): byte;
    function GetLightMap(n: integer): TUT_Struct_LightMapIndex;
    function GetNode(n: integer): TUT_Struct_BspNode;
    function GetPoint(n: integer): TUT_Struct_Vector;
    function GetSurf(n: integer): TUT_Struct_BspSurf;
    function GetVector(n: integer): TUT_Struct_Vector;
    function GetVert(n: integer): TUT_Struct_FVert;
    function GetZone(n: integer): TUT_Struct_ZoneProperties;
  protected
    procedure InitializeObject; override;
    procedure InterpretObject; override;
    procedure DoReleaseObject; override;
  public
    property VectorCount: integer read GetVectorCount;
    property Vector[n: integer]: TUT_Struct_Vector read GetVector;
    property PointCount: integer read GetPointCount;
    property Point[n: integer]: TUT_Struct_Vector read GetPoint;
    property VertCount: integer read GetVertCount;
    property Vert[n: integer]: TUT_Struct_FVert read GetVert;
    property NodeCount: integer read GetNodeCount;
    property Node[n: integer]: TUT_Struct_BspNode read GetNode;
    property SurfCount: integer read GetSurfCount;
    property Surf[n: integer]: TUT_Struct_BspSurf read GetSurf;
    property LightMapCount: integer read GetLightMapCount;
    property LightMap[n: integer]: TUT_Struct_LightMapIndex read GetLightMap;
    property LightBitCount: integer read GetLightBitCount;
    property LightBit[n: integer]: byte read GetLightBit;
    property BoundCount: integer read GetBoundCount;
    property Bound[n: integer]: TUT_Struct_BoundingBox read GetBound;
    property LeafHullCount: integer read GetLeafHullCount;
    property LeafHull[n: integer]: integer read GetLeafHull;
    property LeafCount: integer read GetLeafCount;
    property Leaf[n: integer]: TUT_Struct_Leaf read GetLeaf;
    property LightCount: integer read GetLightCount;
    property Light[n: integer]: integer read GetLight;
    property RootOutside: boolean read FRootOutside;
    property Linked: boolean read FLinked;
    property NumSharedSides: integer read FNumSharedSides;
    property ZoneCount: integer read FNumZones;
    property Zone[n: integer]: TUT_Struct_ZoneProperties read GetZone;
    property Polys: integer read FPolys;
  end;

  TUT_Struct_URL = record
    Protocol: string;
    Host: string;
    Port: integer;
    Map: string;
    Options: array of string;
    Portal: string;
    Valid: boolean;
  end;

  // TUTObjectClassLevelBase
  // Status: complete
  TUTObjectClassLevelBase = class(TUTObject)
  private
    FActors: array of integer;
    FURL: TUT_Struct_URL;
    function GetActor(n: integer): integer;
    function GetActorCount: integer;
  protected
    procedure InitializeObject; override;
    procedure InterpretObject; override;
    procedure DoReleaseObject; override;
  public
    property ActorCount: integer read GetActorCount;
    property Actor[n: integer]: integer read GetActor;
    property URL: TUT_Struct_URL read FURL;
  end;

  TUT_Struct_Map = record
    Key: string;
    Value: string;
  end;

  TUT_Struct_ReachSpec = record
    Distance: integer;
    Start, _End: integer;
    CollisionRadius: integer;
    CollisionHeight: integer;
    ReachFlags: integer;
    bPruned: byte;
  end;

  // TUTObjectClassLevel
  // Status: complete
  TUTObjectClassLevel = class(TUTObjectClassLevelBase)
  private
    FModel: integer;
    FReachSpecs: array of TUT_Struct_ReachSpec;
    FFirstDeleted: integer;
    FTextBlocks: array[0..15] of integer;
    FTravelInfo: array of TUT_Struct_Map;
    function GetReachSpec(n: integer): TUT_Struct_ReachSpec;
    function GetReachSpecCount: integer;
    function GetTextBlock(n: integer): integer;
    function GetTravelInfo(n: integer): TUT_Struct_Map;
    function GetTravelInfoCount: integer;
  protected
    procedure InitializeObject; override;
    procedure InterpretObject; override;
    procedure DoReleaseObject; override;
  public
    property Model: integer read FModel;
    property ReachSpecCount: integer read GetReachSpecCount;
    property ReachSpec[n: integer]: TUT_Struct_ReachSpec read GetReachSpec;
    property FirstDeleted: integer read FFirstDeleted;
    property TextBlocks[n: integer]: integer read GetTextBlock;
    property TravelInfoCount: integer read GetTravelInfoCount;
    property TravelInfo[n: integer]: TUT_Struct_Map read GetTravelInfo;
  end;

  // TUT_MeshExporter
  // Helper class. Requires unique (Vertex,UV) pairs (duplicated vertex or UV when needed).
  TIntegerArray = array of integer;
  TUT_MeshExporter_Material = record
    Name: string;
    DiffuseColor: array[0..2] of byte;
  end;
  TUT_MeshExporter_Vertex = record
    X, Y, Z: single;
    U, V: byte;
  end;
  TUT_MeshExporter_Face = record
    VertexIndex1, VertexIndex2, VertexIndex3: integer;
    MaterialIndex: integer;
    Flags: integer;                     // face material flags (if any)
  end;
  TUT_MeshExporter = class
  public
    Vertices: array of TUT_MeshExporter_Vertex;
    Faces: array of TUT_MeshExporter_Face;
    Materials: array of TUT_MeshExporter_Material;
    AnimationFrames: integer;
  end;
  TUT_3DStudioExporter_Smoothing = (exp3ds_smooth_None, exp3ds_smooth_One, exp3ds_smooth_exp3ds_smooth_ByMaterial);
  TUT_3DStudioExporter = class(TUT_MeshExporter)
  public
    Smoothing: TUT_3DStudioExporter_Smoothing;
    MirrorX: boolean;
    procedure Save(filename: string);
  end;
  TUT_Unreal3DExporter = class(TUT_MeshExporter)
  public
    CoordsDivisor: single;
    procedure Save(filename: string);
  end;

  TUT_Struct_Vert = record
    X, Y, Z: single;
  end;

  TUT_Struct_Tri = record
    VertexIndex1, VertexIndex2, VertexIndex3: integer;
    U1, V1, U2, V2, U3, V3: byte;
    Flags, TextureIndex: integer;
  end;

  TUT_Struct_Texture = record
    Value: integer;
  end;

  TUT_Struct_AnimSeqNotify = record
    Time: single;
    _Function: integer;
  end;

  TUT_Struct_AnimSeq = record
    Name, Group: integer;
    StartFrame, NumFrames: integer;
    Notifys: array of TUT_Struct_AnimSeqNotify;
    Rate: single;
  end;

  TUT_Struct_Connects = record
    NumVertTriangles, TriangleListOffset: integer;
  end;

  // TUTObjectClassMesh
  // Status: completed
  TUTObjectClassMesh = class(TUTObjectClassPrimitive)
  private
    function GetAnimSeq(i: integer): TUT_Struct_AnimSeq;
    function GetAnimSeqCount: integer;
    function GetAnimFrames: integer;
    function GetBoundingBox(i: integer): TUT_Struct_BoundingBox;
    function GetBoundingBoxCount: integer;
    function GetBoundingSphere(i: integer): TUT_Struct_BoundingSphere;
    function GetBoundingSphereCount: integer;
    function GetConnect(i: integer): TUT_Struct_Connects;
    function GetConnectsCount: integer;
    function GetTexture(i: integer): TUT_Struct_Texture;
    function GetTextureLOD(i: integer): single;
    function GetTextureLODCount: integer;
    function GetTexturesCount: integer;
    function GetTri(i: integer): TUT_Struct_Tri;
    function GetTrisCount: integer;
    function GetVert(i: integer): TUT_Struct_Vert;
    function GetVertLink(i: integer): integer;
    function GetVertLinksCount: integer;
    function GetVertsCount: integer;
  protected
    FVerts: array of TUT_Struct_Vert;
    FTris: array of TUT_Struct_Tri;
    FTextures: array of TUT_Struct_Texture;
    FAnimSeqs: array of TUT_Struct_AnimSeq;
    FConnects: array of TUT_Struct_Connects;
    FBoundingBox: TUT_Struct_BoundingBox;
    FBoundingSphere: TUT_Struct_BoundingSphere;
    FVertLinks: array of integer;
    FBoundingBoxes: array of TUT_Struct_BoundingBox;
    FBoundingSpheres: array of TUT_Struct_BoundingSphere;
    FScale, FOrigin: TUT_Struct_Vector;
    FRotOrigin: TUT_Struct_Rotator;
    FFrameVerts, FAnimFrames: integer;
    FANDFlags, FORFlags, FCurPoly, FCurVertex: integer;
    FTextureLOD: array of single;
    procedure InitializeObject; override;
    procedure InterpretObject; override;
    procedure DoReleaseObject; override;
  public
    property VertCount: integer read GetVertsCount;
    property Verts[i: integer]: TUT_Struct_Vert read GetVert;
    property TrisCount: integer read GetTrisCount;
    property Tris[i: integer]: TUT_Struct_Tri read GetTri;
    property TextureCount: integer read GetTexturesCount;
    property Textures[i: integer]: TUT_Struct_Texture read GetTexture;
    property AnimSeqCount: integer read GetAnimSeqCount;
    property AnimSeqs[i: integer]: TUT_Struct_AnimSeq read GetAnimSeq;
    property ConnectCount: integer read GetConnectsCount;
    property Connects[i: integer]: TUT_Struct_Connects read GetConnect;
    property BoundingBox: TUT_Struct_BoundingBox read FBoundingBox;
    property BoundingSphere: TUT_Struct_BoundingSphere read FBoundingSphere;
    property VertLinksCount: integer read GetVertLinksCount;
    property VertLinks[i: integer]: integer read GetVertLink;
    property BoundingBoxCount: integer read GetBoundingBoxCount;
    property BoundingBoxes[i: integer]: TUT_Struct_BoundingBox read GetBoundingBox;
    property BoundingSphereCount: integer read GetBoundingSphereCount;
    property BoundingSpheres[i: integer]: TUT_Struct_BoundingSphere read GetBoundingSphere;
    property Scale: TUT_Struct_Vector read FScale;
    property Origin: TUT_Struct_Vector read FOrigin;
    property RotOrigin: TUT_Struct_Rotator read FRotOrigin;
    property FrameVerts: integer read FFrameVerts;
    property AnimFrames: integer read GetAnimFrames;
    property ANDFlags: integer read FANDFlags;
    property ORFlags: integer read FORFlags;
    property CurPoly: integer read FCurPoly;
    property CurVertex: integer read FCurVertex;
    property TextureLODCount: integer read GetTextureLODCount;
    property TextureLOD[i: integer]: single read GetTextureLOD;
    procedure Save_Unreal3D(filename: string); virtual;
    procedure Save_UnrealUC(filename: string); virtual;
    procedure PrepareExporter(exporter: TUT_MeshExporter; frames: TIntegerArray);
    procedure Save_3DS(filename: string; frame: integer = 0;
      smoothing: TUT_3DStudioExporter_Smoothing = exp3ds_smooth_None; MirrorX: boolean = false); virtual;
  end;

  TUT_Struct_Wedge = record
    VertexIndex: integer;
    U, V: byte;
  end;

  TUT_Struct_Face = record
    WedgeIndex1, WedgeIndex2, WedgeIndex3, MatIndex: integer;
  end;

  TUT_Struct_Material = record
    Flags, TextureIndex: integer;
  end;

  // TUTObjectClassLodMesh
  // Status: completed
  TUTObjectClassLodMesh = class(TUTObjectClassMesh)
  private
    function GetCollapsePointThus(i: integer): word;
    function GetCollapsePointThusCount: integer;
    function GetCollapseWedgeThus(i: integer): word;
    function GetCollapseWedgeThusCount: integer;
    function GetFace(i: integer): TUT_Struct_Face;
    function GetFaceCount: integer;
    function GetFaceLevel(i: integer): word;
    function GetFaceLevelCount: integer;
    function GetMaterial(i: integer): TUT_Struct_Material;
    function GetMaterialCount: integer;
    function GetRemapAnimVerts(i: integer): word;
    function GetRemapAnimVertsCount: integer;
    function GetSpecialFace(i: integer): TUT_Struct_Face;
    function GetSpecialFaceCount: integer;
    function GetWedge(i: integer): TUT_Struct_Wedge;
    function GetWedgeCount: integer;
  protected
    FWedges: array of TUT_Struct_Wedge;
    FFaces: array of TUT_Struct_Face;
    FMaterials: array of TUT_Struct_Material;
    FCollapsePointThus: array of word;
    FFaceLevel: array of word;
    FCollapseWedgeThus: array of word;
    FSpecialFaces: array of TUT_Struct_Face;
    FRemapAnimVerts: array of word;
    FModelVerts, FSpecialVerts, FOldFrameVerts: integer;
    FMeshScaleMax, FLODHysteresis, FLODStrength, FLODMinVerts, FLODMorph, FLODZDisplace: single;
    procedure InitializeObject; override;
    procedure InterpretObject; override;
    procedure DoReleaseObject; override;
  public
    property WedgeCount: integer read GetWedgeCount;
    property Wedges[i: integer]: TUT_Struct_Wedge read GetWedge;
    property FaceCount: integer read GetFaceCount;
    property Faces[i: integer]: TUT_Struct_Face read GetFace;
    property MaterialCount: integer read GetMaterialCount;
    property Materials[i: integer]: TUT_Struct_Material read GetMaterial;
    property CollapsePointThusCount: integer read GetCollapsePointThusCount;
    property CollapsePointThus[i: integer]: word read GetCollapsePointThus;
    property FaceLevelCount: integer read GetFaceLevelCount;
    property FaceLevel[i: integer]: word read GetFaceLevel;
    property CollapseWedgeThusCount: integer read GetCollapseWedgeThusCount;
    property CollapseWedgeThus[i: integer]: word read GetCollapseWedgeThus;
    property SpecialFaceCount: integer read GetSpecialFaceCount;
    property SpecialFaces[i: integer]: TUT_Struct_Face read GetSpecialFace;
    property RemapAnimVertsCount: integer read GetRemapAnimVertsCount;
    property RemapAnimVerts[i: integer]: word read GetRemapAnimVerts;
    property ModelVerts: integer read FModelVerts;
    property SpecialVerts: integer read FSpecialVerts;
    property OldFrameVerts: integer read FOldFrameVerts;
    property MeshScaleMax: single read FMeshScaleMax;
    property LODHysteresis: single read FLODHysteresis;
    property LODStrength: single read FLODStrength;
    property LODMinVerts: single read FLODMinVerts;
    property LODMorph: single read FLODMorph;
    property LODZDisplace: single read FLODZDisplace;
    procedure Save_Unreal3D(filename: string); override;
    procedure Save_UnrealUC(filename: string); override;
    procedure PrepareExporter(exporter: TUT_MeshExporter; frames: TIntegerArray);
    procedure Save_3DS(filename: string; frame: integer = 0;
      smoothing: TUT_3DStudioExporter_Smoothing = exp3ds_smooth_None; MirrorX: boolean = false); override;
  end;

  TUT_Struct_MeshFloatUV = record
    U, V: single;
  end;

  TUT_Struct_MeshExtWedge = record
    iVertex: word;
    Flags: word;
    TexUV: TUT_Struct_MeshFloatUV;
  end;

  TUT_Struct_Quat = record
    X, Y, Z, W: single;
  end;

  TUT_Struct_JointPos = record
    Orientation: TUT_Struct_Quat;
    Position: TUT_Struct_Vector;
    Length: single;
    XSize: single;
    YSize: single;
    ZSize: single;
  end;

  TUT_Struct_MeshBone = record
    Name: integer;
    Flags: longword;
    BonePos: TUT_Struct_JointPos;
    NumChildren: integer;
    ParentIndex: integer;
    //Depth:integer; // not serialized?
  end;

  TUT_Struct_BoneInfIndex = record
    WeightIndex: word;
    Number: word;
    DetailA: word;
    DetailB: word;
  end;

  TUT_Struct_BoneInfluence = record
    PointIndex: word;
    BoneWeight: word;
  end;

  TUT_Struct_Coords = record
    Origin: TUT_Struct_Vector;
    XAxis: TUT_Struct_Vector;
    YAxis: TUT_Struct_Vector;
    ZAXis: TUT_Struct_Vector;
  end;

  // TUTObjectClassSkeletalMesh
  // Status: completed
  TUTObjectClassSkeletalMesh = class(TUTObjectClassLodMesh)
  private
    function GetBoneWeight(i: integer): TUT_Struct_BoneInfluence;
    function GetBoneWeightCount: integer;
    function GetBoneWeightIdx(i: integer): TUT_Struct_BoneInfIndex;
    function GetBoneWeightIdxCount: integer;
    function GetExtWedge(i: integer): TUT_Struct_MeshExtWedge;
    function GetExtWedgeCount: integer;
    function GetLocalPoint(i: integer): TUT_Struct_Vector;
    function GetLocalPointCount: integer;
    function GetPoint(i: integer): TUT_Struct_Vector;
    function GetPointCount: integer;
    function GetRefSkeleton(i: integer): TUT_Struct_MeshBone;
    function GetRefSkeletonCount: integer;
  protected
    FExtWedges: array of TUT_Struct_MeshExtWedge;
    FPoints: array of TUT_Struct_Vector;
    FRefSkeleton: array of TUT_Struct_MeshBone;
    FBoneWeightIdx: array of TUT_Struct_BoneInfIndex;
    FBoneWeights: array of TUT_Struct_BoneInfluence;
    FLocalPoints: array of TUT_Struct_Vector;
    FSkeletalDepth: integer;
    FDefaultAnimation: integer;
    FWeaponBoneIndex: integer;
    FWeaponAdjust: TUT_Struct_Coords;
    procedure InitializeObject; override;
    procedure InterpretObject; override;
    procedure DoReleaseObject; override;
  public
    property ExtWedgeCount: integer read GetExtWedgeCount;
    property ExtWedges[i: integer]: TUT_Struct_MeshExtWedge read GetExtWedge;
    property PointCount: integer read GetPointCount;
    property Points[i: integer]: TUT_Struct_Vector read GetPoint;
    property RefSkeletonCount: integer read GetRefSkeletonCount;
    property RefSkeleton[i: integer]: TUT_Struct_MeshBone read GetRefSkeleton;
    property BoneWeightIdxCount: integer read GetBoneWeightIdxCount;
    property BoneWeightIdx[i: integer]: TUT_Struct_BoneInfIndex read GetBoneWeightIdx;
    property BoneWeightCount: integer read GetBoneWeightCount;
    property BoneWeights[i: integer]: TUT_Struct_BoneInfluence read GetBoneWeight;
    property LocalPointCount: integer read GetLocalPointCount;
    property LocalPoints[i: integer]: TUT_Struct_Vector read GetLocalPoint;
    property SkeletalDepth: integer read FSkeletalDepth;
    property DefaultAnimation: integer read FDefaultAnimation;
    property WeaponBoneIndex: integer read FWeaponBoneIndex;
    property WeaponAdjust: TUT_Struct_Coords read FWeaponAdjust;
    procedure Save_Unreal3D(filename: string); override;
    procedure Save_UnrealUC(filename: string); override;
    procedure PrepareExporter(exporter: TUT_MeshExporter; frames: TIntegerArray);
    procedure Save_3DS(filename: string; frame: integer = 0;
      smoothing: TUT_3DStudioExporter_Smoothing = exp3ds_smooth_None; MirrorX: boolean = false); override;
  end;

  TUT_Struct_NamedBone = record
    Name: integer;
    Flags: longword;
    ParentIndex: integer;
  end;

  TUT_Struct_AnalogTrack = record
    Flags: longword;
    KeyQuat: array of TUT_Struct_Quat;
    KeyPos: array of TUT_Struct_Vector;
    KeyTime: array of single;
  end;

  TUT_Struct_MotionChunk = record
    RootSpeed3D: TUT_Struct_Vector;
    TrackTime: single;
    StartBone: integer;
    Flags: longword;
    BoneIndices: array of integer;
    AnimTracks: array of TUT_Struct_AnalogTrack;
    RootTrack: TUT_Struct_AnalogTrack;
  end;

  // TUTObjectClassAnimation
  // Status: completed
  TUTObjectClassAnimation = class(TUTObject)
  private
    function GetAnimSeqs(i: integer): TUT_Struct_AnimSeq;
    function GetAnimSeqsCount: integer;
    function GetMoves(i: integer): TUT_Struct_MotionChunk;
    function GetMovesCount: integer;
    function GetRefBones(i: integer): TUT_Struct_NamedBone;
    function GetRefBonesCount: integer;
  protected
    FRefBones: array of TUT_Struct_NamedBone;
    FMoves: array of TUT_Struct_MotionChunk;
    FAnimSeqs: array of TUT_Struct_AnimSeq;
    procedure InitializeObject; override;
    procedure InterpretObject; override;
    procedure DoReleaseObject; override;
  public
    property RefBones[i: integer]: TUT_Struct_NamedBone read GetRefBones;
    property RefBonesCount: integer read GetRefBonesCount;
    property Moves[i: integer]: TUT_Struct_MotionChunk read GetMoves;
    property MovesCount: integer read GetMovesCount;
    property AnimSeqs[i: integer]: TUT_Struct_AnimSeq read GetAnimSeqs;
    property AnimSeqsCount: integer read GetAnimSeqsCount;
  end;

  // TUTObjectClassFunction
  // Status: completed
  TUTObjectClassFunction = class(TUTObjectClassStruct)
  private
    FiNative: integer;
    FRepOffset: integer;
    FOperatorPrecedence: integer;
    FFunctionFlags: longword;
    function GetFunctionFlags: longword;
    function GetiNative: integer;
    function GetOperatorPrecedence: integer;
    function GetRepOffset: integer;
  protected
    procedure InitializeObject; override;
    procedure InterpretObject; override;
    procedure DoReleaseObject; override;
  public
    function Decompile(beautify: boolean = true): string;
    property NativeIndex: integer read GetiNative;
    property ReplicationOffset: integer read GetRepOffset;
    property OperatorPrecedence: integer read GetOperatorPrecedence;
    property FunctionFlags: longword read GetFunctionFlags;
  end;

  TUTImportTableObjectData = class
  private
    FOwner: TUTPackage;
    FObjectIndex: integer;
    FClassPackageIndex: integer;
    FClassIndex: integer;
    FPackageIndex: integer;
    procedure SetObjectIndex(const Value: integer);
    procedure SetClassIndex(const Value: integer);
    procedure SetClassPackageIndex(const Value: integer);
    procedure SetPackageIndex(const Value: integer);
    function GetClassName: string;
    function GetClassPackageName: string;
    function GetObjectName: string;
    function GetPackageName: string;
  public
    property Owner: TUTPackage read FOwner write FOwner;
    // Read data
    property UTObjectIndex: integer read FObjectIndex write SetObjectIndex;
    property UTClassPackageIndex: integer read FClassPackageIndex write SetClassPackageIndex;
    property UTClassIndex: integer read FClassIndex write SetClassIndex;
    property UTPackageIndex: integer read FPackageIndex write SetPackageIndex;
    // Generated data
    property UTObjectName: string read GetObjectName;
    property UTClassPackageName: string read GetClassPackageName;
    property UTClassName: string read GetClassName;
    property UTPackageName: string read GetPackageName;
  end;

  TUTExportTableObjectData = class
  private
    FOwner: TUTPackage;
    FSerialOffset: integer;
    FClassIndex: integer;
    FObjectIndex: integer;
    FSerialSize: integer;
    FPackageIndex: integer;
    FSuperIndex: integer;
    FFlags: integer;
    FUTObject: TUTObject;
    FExportedIndex: integer;
    procedure SetClassIndex(const Value: integer);
    procedure SetFlags(const Value: integer);
    procedure SetObjectIndex(const Value: integer);
    procedure SetPackageIndex(const Value: integer);
    procedure SetSerialOffset(const Value: integer);
    procedure SetSerialSize(const Value: integer);
    procedure SetSuperIndex(const Value: integer);
    procedure SetUTObject(const Value: TUTObject);
    function GetClassName: string;
    function GetObjectName: string;
    function GetPackageName: string;
    function GetSuperName: string;
    function GetUTObject: TUTObject;
  public
    property Owner: TUTPackage read FOwner write FOwner;
    property ExportedIndex: integer read FExportedIndex write FExportedIndex;
    procedure CreateObject;
    procedure FreeObject;
    destructor Destroy; override;
    // Read data
    property UTObjectIndex: integer read FObjectIndex write SetObjectIndex;
    property UTClassIndex: integer read FClassIndex write SetClassIndex;
    property UTPackageIndex: integer read FPackageIndex write SetPackageIndex;
    property UTSuperIndex: integer read FSuperIndex write SetSuperIndex;
    property Flags: integer read FFlags write SetFlags;
    property SerialSize: integer read FSerialSize write SetSerialSize;
    property SerialOffset: integer read FSerialOffset write SetSerialOffset;
    // Resolved data
    property UTObjectName: string read GetObjectName;
    property UTClassName: string read GetClassName;
    property UTPackageName: string read GetPackageName;
    property UTSuperName: string read GetSuperName;
    property UTObject: TUTObject read GetUTObject write SetUTObject;
  end;

  TUTPackageObjectLocations = (utolNames, utolExports, utolImports);
  TUTPackageFindWhat = (utfwName, utfwPackage, utfwClass);
  TUTPackageFindWhatSet = set of TUTPackageFindWhat;
  TUT_OnProgressEvent = procedure(Sender: TObject; position: integer) of object;
  TUT_OnGetStringConst = function(s: string): string of object;
  TUT_OnGetUnicodeStringConst = function(s: widestring): widestring of object;
  TUT_OnPackageNeeded = procedure(var package: string) of object;

  TUTPackage_GenerationInfo = record
    ExportCount: integer;
    NameCount: integer;
  end;

  // TUTPackage
  // Status: completed
  TUTPackage = class
  private
    FOnProgress: TUT_OnProgressEvent;
    Fstr: TStream;
    FPackage: string;
    FVersion: word;
    FLicenseeMode: word;
    FFlags: longword;
    FReadingPackageCount: integer;
    FNameTableList: tstringlist;
    FImportTableList: tlist;
    FExportTableList: tlist;
    FHeritageTableList: array of TGUID;
    FGenerationInfo: array of TUTPackage_GenerationInfo;
    FAllowReadingOtherPackages: boolean;
    FOnGetStringConst: TUT_OnGetStringConst;
    FOnGetUnicodeStringConst: TUT_OnGetUnicodeStringConst;
    FOnPackageNeeded: TUT_OnPackageNeeded;
    FEnumCache: tstringlist;
    procedure Process;
    procedure DoOnProgress(position, maxposition: integer);
    function GetExport(i: integer): TUTExportTableObjectData;
    function GetHeritage(i: integer): TGUID;
    function GetImport(i: integer): TUTImportTableObjectData;
    function GetName(i: integer): string;
    function GetNameFlags(i: integer): integer;
    function GetExportCount: integer;
    function GetHeritageCount: integer;
    function GetImportCount: integer;
    function GetNameCount: integer;
    function GetPackagePosition: integer;
    function GetStream: TStream;
    function GetExportIndex(objectname, classname: string): integer;
    function GetNameIndex(objectname: string): integer;
    function GetGeneration(i: integer): TUTPackage_GenerationInfo;
    function GetGenerationCount: integer;
    function GetInitialized: boolean;
    procedure SetName(i: integer; const Value: string);
    function GetStringConst(s: string): string;
    function GetUnicodeStringConst(s: widestring): widestring;
  protected
    function IndentText(indent, txt: string): string;
  public
    property stream: TStream read GetStream;
    constructor Create(package: string = '');
    procedure Initialize(package: string);
    destructor Destroy; override;
    property Package: string read FPackage;
    property Initialized: boolean read GetInitialized;
    property OnProgress: TUT_OnProgressEvent read FOnProgress write FOnProgress;
    property Version: word read FVersion;
    property LicenseeMode: word read FLicenseeMode;
    property Flags: longword read FFlags;
    property NameCount: integer read GetNameCount;
    property Names[i: integer]: string read GetName write SetName;
    property NameFlags[i: integer]: integer read GetNameFlags;
    function GetObjectFlagsText(const e: cardinal): string;
    property ExportedCount: integer read GetExportCount;
    property Exported[i: integer]: TUTExportTableObjectData read GetExport;
    property ImportedCount: integer read GetImportCount;
    property Imported[i: integer]: TUTImportTableObjectData read GetImport;
    property HeritageCount: integer read GetHeritageCount;
    property Heritages[i: integer]: TGUID read GetHeritage;
    property GenerationCount: integer read GetGenerationCount;
    property Generations[i: integer]: TUTPackage_GenerationInfo read GetGeneration;
    property ExportIndex[objectname, classname: string]: integer read GetExportIndex;
    property NameIndex[objectname: string]: integer read GetNameIndex;
    function FindObject(where: TUTPackageObjectLocations; what: TUTPackageFindWhatSet; packagename, objectname, classname: string; start: integer = 0): integer;
    procedure ReadAllObjects;
    procedure ReleaseAllObjects;
    function EncodeIndex(i: integer): string;
    procedure StartReadingPackage;
    procedure EndReadingPackage;
    property Position: integer read GetPackagePosition;
    procedure Seek(p: integer);
    function ReadProperty(prop: TUTProperty; stream: tstream): boolean;
    procedure SaveDataBlock(filename: string; position, size: integer);
    function GetObjectPath(limit, index: integer): string;
    //function GetObjectPath_Simple(const index: integer): string;
    procedure read_buffer(var buffer; const size: integer; stream: tstream);
    function read_asciiz(stream: tstream): string;
    function read_bool(stream: tstream): boolean;
    function read_byte(stream: tstream): byte;
    function read_float(stream: tstream): single;
    function read_idx(stream: tstream): integer;
    function read_int(stream: tstream): integer;
    function read_qword(stream: tstream): int64;
    function read_guid(stream: tstream): TGuid;
    function read_sizedascii(stream: tstream): string;
    function read_doublesizedasciiz(stream: tstream): string;
    function read_sizedasciiz(stream: tstream): string;
    function read_word(stream: tstream): word;
    function Read_Name(stream: tstream): string;
    property AllowReadingOtherPackages: boolean read FAllowReadingOtherPackages write FAllowReadingOtherPackages;
    property OnGetStringConst: TUT_OnGetStringConst read FOnGetStringConst write FOnGetStringConst;
    property OnGetUnicodeStringConst: TUT_OnGetUnicodeStringConst read FOnGetUnicodeStringConst write FOnGetUnicodeStringConst;
    property OnPackageNeeded: TUT_OnPackageNeeded read FOnPackageNeeded write FOnPackageNeeded;
  end;

  // Use this procedure to add classes to the package processor.
  // You can override existing registered classes.
procedure RegisterUTObjectClass(classname: string; classclass: TUTObjectClass);
procedure AddUTClassEquivalence(classname, equivalentclass: string);
procedure ClearUTClassEquivalences;

// Helper functions
function Read_Struct_Vector(owner: TUTPackage; buffer: TStream): TUT_Struct_Vector;
function Read_Struct_Rotator(owner: TUTPackage; buffer: TStream): TUT_Struct_Rotator;
function Read_Struct_Polygon(owner: TUTPackage; buffer: TStream): TUT_Struct_Polygon;
function Read_Struct_Spark(owner: TUTPackage; buffer: TStream): TUT_Struct_Spark;
function Read_Struct_BoundingBox(owner: TUTPackage; buffer: TStream): TUT_Struct_BoundingBox;
function Read_Struct_BoundingSphere(owner: TUTPackage; buffer: TStream): TUT_Struct_BoundingSphere;
//function Read_Struct_Vert (owner:TUTPackage;buffer:TStream):TUT_Struct_Vert;
function Read_Struct_Tri(owner: TUTPackage; buffer: TStream): TUT_Struct_Tri;
function Read_Struct_Texture(owner: TUTPackage; buffer: TStream): TUT_Struct_Texture;
function Read_Struct_AnimSeqNotify(owner: TUTPackage; buffer: TStream): TUT_Struct_AnimSeqNotify;
function Read_Struct_AnimSeq(owner: TUTPackage; buffer: TStream): TUT_Struct_AnimSeq;
function Read_Struct_Connects(owner: TUTPackage; buffer: TStream): TUT_Struct_Connects;
function Read_Struct_Wedge(owner: TUTPackage; buffer: TStream): TUT_Struct_Wedge;
function Read_Struct_Face(owner: TUTPackage; buffer: TStream): TUT_Struct_Face;
function Read_Struct_Material(owner: TUTPackage; buffer: TStream): TUT_Struct_Material;
function Read_Struct_MeshFloatUV(owner: TUTPackage; buffer: TStream): TUT_Struct_MeshFloatUV;
function Read_Struct_MeshExtWedge(owner: TUTPackage; buffer: TStream): TUT_Struct_MeshExtWedge;
function Read_Struct_Quat(owner: TUTPackage; buffer: TStream): TUT_Struct_Quat;
function Read_Struct_JointPos(owner: TUTPackage; buffer: TStream): TUT_Struct_JointPos;
function Read_Struct_MeshBone(owner: TUTPackage; buffer: TStream): TUT_Struct_MeshBone;
function Read_Struct_BoneInfIndex(owner: TUTPackage; buffer: TStream): TUT_Struct_BoneInfIndex;
function Read_Struct_BoneInfluence(owner: TUTPackage; buffer: TStream): TUT_Struct_BoneInfluence;
function Read_Struct_Coords(owner: TUTPackage; buffer: TStream): TUT_Struct_Coords;
function Read_Struct_NamedBone(owner: TUTPackage; buffer: TStream): TUT_Struct_NamedBone;
function Read_Struct_AnalogTrack(owner: TUTPackage; buffer: TStream): TUT_Struct_AnalogTrack;
function Read_Struct_MotionChunk(owner: TUTPackage; buffer: TStream): TUT_Struct_MotionChunk;
function Read_Struct_Dependency(owner: TUTPackage; buffer: TStream): TUT_Struct_Dependency;
function Read_Struct_LabelEntry(owner: TUTPackage; buffer: TStream): TUT_Struct_LabelEntry;
function Read_Struct_BspNode(owner: TUTPackage; buffer: TStream): TUT_Struct_BspNode;
function Read_Struct_BspSurf(owner: TUTPackage; buffer: TStream): TUT_Struct_BspSurf;
function Read_Struct_FVert(owner: TUTPackage; buffer: TStream): TUT_Struct_FVert;
function Read_Struct_Zone(owner: TUTPackage; buffer: TStream): TUT_Struct_ZoneProperties;
function Read_Struct_LightMap(owner: TUTPackage; buffer: TStream): TUT_Struct_LightMapIndex;
function Read_Struct_Leaf(owner: TUTPackage; buffer: TStream): TUT_Struct_Leaf;
function Read_Struct_URL(owner: TUTPackage; buffer: TStream): TUT_Struct_URL;
function Read_Struct_ReachSpec(owner: TUTPackage; buffer: TStream): TUT_Struct_ReachSpec;
function Read_Struct_Map(owner: TUTPackage; buffer: TStream): TUT_Struct_Map;

const
  M3DMAGIC = $4D4D;
  M3D_VERSION = $0002;
  MDATA = $3D3D;
  MESH_VERSION = $3D3E;
  MAT_ENTRY = $AFFF;
  MAT_NAME = $A000;
  MAT_DIFFUSE = $A020;
  COLOR_24 = $0011;
  NAMED_OBJECT = $4000;
  N_TRI_OBJECT = $4100;
  POINT_ARRAY = $4110;
  TEX_VERTS = $4140;
  FACE_ARRAY = $4120;
  MSH_MAT_GROUP = $4130;
  SMOOTH_GROUP = $4150;
  KFDATA = $B000;
  KFHDR = $B00A;
  KFSEG = $B008;
  KFCURTIME = $B009;
  OBJECT_NODE_TAG = $B002;
  NODE_ID = $B030;
  NODE_HDR = $B010;
  PIVOT = $B013;
  POS_TRACK_TAG = $B020;
  ROT_TRACK_TAG = $B021;
  SCL_TRACK_TAG = $B022;
  HIDE_TRACK_TAG = $B029;
  FaceCAVisable3DS = $0001;
  FaceBCVisable3DS = $0002;
  FaceABVisable3DS = $0004;

  EX_LocalVariable = $00;
  EX_InstanceVariable = $01;
  EX_DefaultVariable = $02;
  // =$03
  EX_Return = $04;
  EX_Switch = $05;
  EX_Jump = $06;
  EX_JumpIfNot = $07;
  EX_Stop = $08;
  EX_Assert = $09;
  EX_Case = $0A;
  EX_Nothing = $0B;
  EX_LabelTable = $0C;
  EX_GotoLabel = $0D;
  EX_EatString = $0E;
  EX_Let = $0F;
  EX_DynArrayElement = $10;
  EX_New = $11;
  EX_ClassContext = $12;
  EX_Metacast = $13;
  EX_LetBool = $14;
  EX_Unknown_jumpover = $15;            // ??? only seen on old packages (v61) at end of functions and in mid of code
  EX_EndFunctionParms = $16;
  EX_Self = $17;
  EX_Skip = $18;
  EX_Context = $19;
  EX_ArrayElement = $1A;
  EX_VirtualFunction = $1B;
  EX_FinalFunction = $1C;
  EX_IntConst = $1D;
  EX_FloatConst = $1E;
  EX_StringConst = $1F;
  EX_ObjectConst = $20;
  EX_NameConst = $21;
  EX_RotationConst = $22;
  EX_VectorConst = $23;
  EX_ByteConst = $24;
  EX_IntZero = $25;
  EX_IntOne = $26;
  EX_True = $27;
  EX_False = $28;
  EX_NativeParm = $29;
  EX_NoObject = $2A;
  EX_Unknown_jumpover2 = $2B;           // ??? only seen on old packages (v61)
  EX_IntConstByte = $2C;
  EX_BoolVariable = $2D;
  EX_DynamicCast = $2E;
  EX_Iterator = $2F;
  EX_IteratorPop = $30;
  EX_IteratorNext = $31;
  EX_StructCmpEq = $32;
  EX_StructCmpNe = $33;
  EX_UnicodeStringConst = $34;
  // =$35
  EX_StructMember = $36;
  // =$37
  EX_GlobalFunction = $38;
  EX_RotatorToVector = $39;
  EX_ByteToInt = $3A;
  EX_ByteToBool = $3B;
  EX_ByteToFloat = $3C;
  EX_IntToByte = $3D;
  EX_IntToBool = $3E;
  EX_IntToFloat = $3F;
  EX_BoolToByte = $40;
  EX_BoolToInt = $41;
  EX_BoolToFloat = $42;
  EX_FloatToByte = $43;
  EX_FloatToInt = $44;
  EX_FloatToBool = $45;
  EX_StringToName = $46;                // not defined in UT source, but used in unrealscript
  EX_ObjectToBool = $47;
  EX_NameToBool = $48;
  EX_StringToByte = $49;
  EX_StringToInt = $4A;
  EX_StringToBool = $4B;
  EX_StringToFloat = $4C;
  EX_StringToVector = $4D;
  EX_StringToRotator = $4E;
  EX_VectorToBool = $4F;
  EX_VectorToRotator = $50;
  EX_RotatorToBool = $51;
  EX_ByteToString = $52;
  EX_IntToString = $53;
  EX_BoolToString = $54;
  EX_FloatToString = $55;
  EX_ObjectToString = $56;
  EX_NameToString = $57;
  EX_VectorToString = $58;
  EX_RotatorToString = $59;

  EX_ExtendedNative = $60;
  EX_FirstNative = $70;

  NEST_Foreach = 1;
  NEST_Switch = 2;
  NEST_If = 3;
  NEST_Else = 4;

  nffFunction = 0;
  nffPreOperator = 1;
  nffPostOperator = 2;
  nffOperator = 3;

type
  TNativeFunction = record
    Index: integer;
    Format: byte;
    OperatorPrecedence: byte;
    Name: string;
  end;
  TNativeFunctions = array of TNativeFunction;

procedure SetNativeFunctionArray(a: array of TNativeFunction);

var
  NativeFunctions: TNativeFunctions;
  // When changing this array decrease the OperatorPrecedence for "&&", "||", "^^"
  // operators to a value smaller than that of any other operator so that they will
  // have parenthesis around their operands when that operands are other operators.

const
  NativeFunctions_UT: array[0..231] of TNativeFunction = (
    {0000}(Index: 00112; Format: nffOperator; OperatorPrecedence: 040; Name: '$'), // Core.u (ut)
    {0001}(Index: 00113; Format: nffFunction; OperatorPrecedence: 000; Name: 'GotoState'), // Core.u (ut)
    {0002}(Index: 00114; Format: nffOperator; OperatorPrecedence: 024; Name: '=='), // Core.u (ut)
    {0003}(Index: 00115; Format: nffOperator; OperatorPrecedence: 024; Name: '<'), // Core.u (ut)
    {0004}(Index: 00116; Format: nffOperator; OperatorPrecedence: 024; Name: '>'), // Core.u (ut)
    {0005}(Index: 00117; Format: nffFunction; OperatorPrecedence: 000; Name: 'Enable'), // Core.u (ut)
    {0006}(Index: 00118; Format: nffFunction; OperatorPrecedence: 000; Name: 'Disable'), // Core.u (ut)
    {0007}(Index: 00119; Format: nffOperator; OperatorPrecedence: 026; Name: '!='), // Core.u (ut)
    {0008}(Index: 00120; Format: nffOperator; OperatorPrecedence: 024; Name: '<='), // Core.u (ut)
    {0009}(Index: 00121; Format: nffOperator; OperatorPrecedence: 024; Name: '>='), // Core.u (ut)
    {0010}(Index: 00122; Format: nffOperator; OperatorPrecedence: 024; Name: '=='), // Core.u (ut)
    {0011}(Index: 00123; Format: nffOperator; OperatorPrecedence: 026; Name: '!='), // Core.u (ut)
    {0012}(Index: 00124; Format: nffOperator; OperatorPrecedence: 024; Name: '~='), // Core.u (ut)
    {0013}(Index: 00125; Format: nffFunction; OperatorPrecedence: 000; Name: 'Len'), // Core.u (ut)
    {0014}(Index: 00126; Format: nffFunction; OperatorPrecedence: 000; Name: 'InStr'), // Core.u (ut)
    {0015}(Index: 00127; Format: nffFunction; OperatorPrecedence: 000; Name: 'Mid'), // Core.u (ut)
    {0016}(Index: 00128; Format: nffFunction; OperatorPrecedence: 000; Name: 'Left'), // Core.u (ut)
    {0017}(Index: 00129; Format: nffPreOperator; OperatorPrecedence: 000; Name: '!'), // Core.u (ut)
    {0018}(Index: 00130; Format: nffOperator; OperatorPrecedence: 010 {030}; Name: '&&'), // Core.u (ut)
    {0019}(Index: 00131; Format: nffOperator; OperatorPrecedence: 010 {030}; Name: '^^'), // Core.u (ut)
    {0020}(Index: 00132; Format: nffOperator; OperatorPrecedence: 011 {032}; Name: '||'), // Core.u (ut)
    {0021}(Index: 00133; Format: nffOperator; OperatorPrecedence: 034; Name: '*='), // Core.u (ut)
    {0022}(Index: 00134; Format: nffOperator; OperatorPrecedence: 034; Name: '/='), // Core.u (ut)
    {0023}(Index: 00135; Format: nffOperator; OperatorPrecedence: 034; Name: '+='), // Core.u (ut)
    {0024}(Index: 00136; Format: nffOperator; OperatorPrecedence: 034; Name: '-='), // Core.u (ut)
    {0025}(Index: 00137; Format: nffPreOperator; OperatorPrecedence: 000; Name: '++'), // Core.u (ut)
    {0026}(Index: 00138; Format: nffPreOperator; OperatorPrecedence: 000; Name: '--'), // Core.u (ut)
    {0027}(Index: 00139; Format: nffPostOperator; OperatorPrecedence: 000; Name: '++'), // Core.u (ut)
    {0028}(Index: 00140; Format: nffPostOperator; OperatorPrecedence: 000; Name: '--'), // Core.u (ut)
    {0029}(Index: 00141; Format: nffPreOperator; OperatorPrecedence: 000; Name: '~'), // Core.u (ut)
    {0030}(Index: 00142; Format: nffOperator; OperatorPrecedence: 024; Name: '=='), // Core.u (ut)
    {0031}(Index: 00143; Format: nffPreOperator; OperatorPrecedence: 000; Name: '-'), // Core.u (ut)
    {0032}(Index: 00144; Format: nffOperator; OperatorPrecedence: 016; Name: '*'), // Core.u (ut)
    {0033}(Index: 00145; Format: nffOperator; OperatorPrecedence: 016; Name: '/'), // Core.u (ut)
    {0034}(Index: 00146; Format: nffOperator; OperatorPrecedence: 020; Name: '+'), // Core.u (ut)
    {0035}(Index: 00147; Format: nffOperator; OperatorPrecedence: 020; Name: '-'), // Core.u (ut)
    {0036}(Index: 00148; Format: nffOperator; OperatorPrecedence: 022; Name: '<<'), // Core.u (ut)
    {0037}(Index: 00149; Format: nffOperator; OperatorPrecedence: 022; Name: '>>'), // Core.u (ut)
    {0038}(Index: 00150; Format: nffOperator; OperatorPrecedence: 024; Name: '<'), // Core.u (ut)
    {0039}(Index: 00151; Format: nffOperator; OperatorPrecedence: 024; Name: '>'), // Core.u (ut)
    {0040}(Index: 00152; Format: nffOperator; OperatorPrecedence: 024; Name: '<='), // Core.u (ut)
    {0041}(Index: 00153; Format: nffOperator; OperatorPrecedence: 024; Name: '>='), // Core.u (ut)
    {0042}(Index: 00154; Format: nffOperator; OperatorPrecedence: 024; Name: '=='), // Core.u (ut)
    {0043}(Index: 00155; Format: nffOperator; OperatorPrecedence: 026; Name: '!='), // Core.u (ut)
    {0044}(Index: 00156; Format: nffOperator; OperatorPrecedence: 028; Name: '&'), // Core.u (ut)
    {0045}(Index: 00157; Format: nffOperator; OperatorPrecedence: 028; Name: '^'), // Core.u (ut)
    {0046}(Index: 00158; Format: nffOperator; OperatorPrecedence: 028; Name: '|'), // Core.u (ut)
    {0047}(Index: 00159; Format: nffOperator; OperatorPrecedence: 034; Name: '*='), // Core.u (ut)
    {0048}(Index: 00160; Format: nffOperator; OperatorPrecedence: 034; Name: '/='), // Core.u (ut)
    {0049}(Index: 00161; Format: nffOperator; OperatorPrecedence: 034; Name: '+='), // Core.u (ut)
    {0050}(Index: 00162; Format: nffOperator; OperatorPrecedence: 034; Name: '-='), // Core.u (ut)
    {0051}(Index: 00163; Format: nffPreOperator; OperatorPrecedence: 000; Name: '++'), // Core.u (ut)
    {0052}(Index: 00164; Format: nffPreOperator; OperatorPrecedence: 000; Name: '--'), // Core.u (ut)
    {0053}(Index: 00165; Format: nffPostOperator; OperatorPrecedence: 000; Name: '++'), // Core.u (ut)
    {0054}(Index: 00166; Format: nffPostOperator; OperatorPrecedence: 000; Name: '--'), // Core.u (ut)
    {0055}(Index: 00167; Format: nffFunction; OperatorPrecedence: 000; Name: 'Rand'), // Core.u (ut)
    {0056}(Index: 00168; Format: nffOperator; OperatorPrecedence: 040; Name: '@'), // Core.u (ut)
    {0057}(Index: 00169; Format: nffPreOperator; OperatorPrecedence: 000; Name: '-'), // Core.u (ut)
    {0058}(Index: 00170; Format: nffOperator; OperatorPrecedence: 012; Name: '**'), // Core.u (ut)
    {0059}(Index: 00171; Format: nffOperator; OperatorPrecedence: 016; Name: '*'), // Core.u (ut)
    {0060}(Index: 00172; Format: nffOperator; OperatorPrecedence: 016; Name: '/'), // Core.u (ut)
    {0061}(Index: 00173; Format: nffOperator; OperatorPrecedence: 018; Name: '%'), // Core.u (ut)
    {0062}(Index: 00174; Format: nffOperator; OperatorPrecedence: 020; Name: '+'), // Core.u (ut)
    {0063}(Index: 00175; Format: nffOperator; OperatorPrecedence: 020; Name: '-'), // Core.u (ut)
    {0064}(Index: 00176; Format: nffOperator; OperatorPrecedence: 024; Name: '<'), // Core.u (ut)
    {0065}(Index: 00177; Format: nffOperator; OperatorPrecedence: 024; Name: '>'), // Core.u (ut)
    {0066}(Index: 00178; Format: nffOperator; OperatorPrecedence: 024; Name: '<='), // Core.u (ut)
    {0067}(Index: 00179; Format: nffOperator; OperatorPrecedence: 024; Name: '>='), // Core.u (ut)
    {0068}(Index: 00180; Format: nffOperator; OperatorPrecedence: 024; Name: '=='), // Core.u (ut)
    {0069}(Index: 00181; Format: nffOperator; OperatorPrecedence: 026; Name: '!='), // Core.u (ut)
    {0070}(Index: 00182; Format: nffOperator; OperatorPrecedence: 034; Name: '*='), // Core.u (ut)
    {0071}(Index: 00183; Format: nffOperator; OperatorPrecedence: 034; Name: '/='), // Core.u (ut)
    {0072}(Index: 00184; Format: nffOperator; OperatorPrecedence: 034; Name: '+='), // Core.u (ut)
    {0073}(Index: 00185; Format: nffOperator; OperatorPrecedence: 034; Name: '-='), // Core.u (ut)
    {0074}(Index: 00186; Format: nffFunction; OperatorPrecedence: 000; Name: 'Abs'), // Core.u (ut)
    {0075}(Index: 00187; Format: nffFunction; OperatorPrecedence: 000; Name: 'Sin'), // Core.u (ut)
    {0076}(Index: 00188; Format: nffFunction; OperatorPrecedence: 000; Name: 'Cos'), // Core.u (ut)
    {0077}(Index: 00189; Format: nffFunction; OperatorPrecedence: 000; Name: 'Tan'), // Core.u (ut)
    {0078}(Index: 00190; Format: nffFunction; OperatorPrecedence: 000; Name: 'Atan'), // Core.u (ut)
    {0079}(Index: 00191; Format: nffFunction; OperatorPrecedence: 000; Name: 'Exp'), // Core.u (ut)
    {0080}(Index: 00192; Format: nffFunction; OperatorPrecedence: 000; Name: 'Loge'), // Core.u (ut)
    {0081}(Index: 00193; Format: nffFunction; OperatorPrecedence: 000; Name: 'Sqrt'), // Core.u (ut)
    {0082}(Index: 00194; Format: nffFunction; OperatorPrecedence: 000; Name: 'Square'), // Core.u (ut)
    {0083}(Index: 00195; Format: nffFunction; OperatorPrecedence: 000; Name: 'FRand'), // Core.u (ut)
    {0084}(Index: 00196; Format: nffOperator; OperatorPrecedence: 022; Name: '>>>'), // Core.u (ut)
    {0085}(Index: 00203; Format: nffOperator; OperatorPrecedence: 026; Name: '!='), // Core.u (ut)
    {0086}(Index: 00210; Format: nffOperator; OperatorPrecedence: 024; Name: '~='), // Core.u (ut)
    {0087}(Index: 00211; Format: nffPreOperator; OperatorPrecedence: 000; Name: '-'), // Core.u (ut)
    {0088}(Index: 00212; Format: nffOperator; OperatorPrecedence: 016; Name: '*'), // Core.u (ut)
    {0089}(Index: 00213; Format: nffOperator; OperatorPrecedence: 016; Name: '*'), // Core.u (ut)
    {0090}(Index: 00214; Format: nffOperator; OperatorPrecedence: 016; Name: '/'), // Core.u (ut)
    {0091}(Index: 00215; Format: nffOperator; OperatorPrecedence: 020; Name: '+'), // Core.u (ut)
    {0092}(Index: 00216; Format: nffOperator; OperatorPrecedence: 020; Name: '-'), // Core.u (ut)
    {0093}(Index: 00217; Format: nffOperator; OperatorPrecedence: 024; Name: '=='), // Core.u (ut)
    {0094}(Index: 00218; Format: nffOperator; OperatorPrecedence: 026; Name: '!='), // Core.u (ut)
    {0095}(Index: 00219; Format: nffOperator; OperatorPrecedence: 016; Name: 'Dot'), // Core.u (ut)
    {0096}(Index: 00220; Format: nffOperator; OperatorPrecedence: 016; Name: 'Cross'), // Core.u (ut)
    {0097}(Index: 00221; Format: nffOperator; OperatorPrecedence: 034; Name: '*='), // Core.u (ut)
    {0098}(Index: 00222; Format: nffOperator; OperatorPrecedence: 034; Name: '/='), // Core.u (ut)
    {0099}(Index: 00223; Format: nffOperator; OperatorPrecedence: 034; Name: '+='), // Core.u (ut)
    {0100}(Index: 00224; Format: nffOperator; OperatorPrecedence: 034; Name: '-='), // Core.u (ut)
    {0101}(Index: 00225; Format: nffFunction; OperatorPrecedence: 000; Name: 'VSize'), // Core.u (ut)
    {0102}(Index: 00226; Format: nffFunction; OperatorPrecedence: 000; Name: 'Normal'), // Core.u (ut)
    {0103}(Index: 00227; Format: nffFunction; OperatorPrecedence: 000; Name: 'Invert'), // Core.u (ut)
    {0104}(Index: 00229; Format: nffFunction; OperatorPrecedence: 000; Name: 'GetAxes'), // Core.u (ut)
    {0105}(Index: 00230; Format: nffFunction; OperatorPrecedence: 000; Name: 'GetUnAxes'), // Core.u (ut)
    {0106}(Index: 00231; Format: nffFunction; OperatorPrecedence: 000; Name: 'Log'), // Core.u (ut)
    {0107}(Index: 00232; Format: nffFunction; OperatorPrecedence: 000; Name: 'Warn'), // Core.u (ut)
    {0108}(Index: 00233; Format: nffFunction; OperatorPrecedence: 000; Name: 'Error'), // Engine.u (ut)
    {0109}(Index: 00234; Format: nffFunction; OperatorPrecedence: 000; Name: 'Right'), // Core.u (ut)
    {0110}(Index: 00235; Format: nffFunction; OperatorPrecedence: 000; Name: 'Caps'), // Core.u (ut)
    {0111}(Index: 00236; Format: nffFunction; OperatorPrecedence: 000; Name: 'Chr'), // Core.u (ut)
    {0112}(Index: 00237; Format: nffFunction; OperatorPrecedence: 000; Name: 'Asc'), // Core.u (ut)
    {0113}(Index: 00242; Format: nffOperator; OperatorPrecedence: 024; Name: '=='), // Core.u (ut)
    {0114}(Index: 00243; Format: nffOperator; OperatorPrecedence: 026; Name: '!='), // Core.u (ut)
    {0115}(Index: 00244; Format: nffFunction; OperatorPrecedence: 000; Name: 'FMin'), // Core.u (ut)
    {0116}(Index: 00245; Format: nffFunction; OperatorPrecedence: 000; Name: 'FMax'), // Core.u (ut)
    {0117}(Index: 00246; Format: nffFunction; OperatorPrecedence: 000; Name: 'FClamp'), // Core.u (ut)
    {0118}(Index: 00247; Format: nffFunction; OperatorPrecedence: 000; Name: 'Lerp'), // Core.u (ut)
    {0119}(Index: 00248; Format: nffFunction; OperatorPrecedence: 000; Name: 'Smerp'), // Core.u (ut)
    {0120}(Index: 00249; Format: nffFunction; OperatorPrecedence: 000; Name: 'Min'), // Core.u (ut)
    {0121}(Index: 00250; Format: nffFunction; OperatorPrecedence: 000; Name: 'Max'), // Core.u (ut)
    {0122}(Index: 00251; Format: nffFunction; OperatorPrecedence: 000; Name: 'Clamp'), // Core.u (ut)
    {0123}(Index: 00252; Format: nffFunction; OperatorPrecedence: 000; Name: 'VRand'), // Core.u (ut)
    {0124}(Index: 00254; Format: nffOperator; OperatorPrecedence: 024; Name: '=='), // Core.u (ut)
    {0125}(Index: 00255; Format: nffOperator; OperatorPrecedence: 026; Name: '!='), // Core.u (ut)
    {0126}(Index: 00256; Format: nffFunction; OperatorPrecedence: 000; Name: 'Sleep'), // Engine.u (ut)
    {0127}(Index: 00258; Format: nffFunction; OperatorPrecedence: 000; Name: 'ClassIsChildOf'), // Core.u (ut)
    {0128}(Index: 00259; Format: nffFunction; OperatorPrecedence: 000; Name: 'PlayAnim'), // Engine.u (ut)
    {0129}(Index: 00260; Format: nffFunction; OperatorPrecedence: 000; Name: 'LoopAnim'), // Engine.u (ut)
    {0130}(Index: 00261; Format: nffFunction; OperatorPrecedence: 000; Name: 'FinishAnim'), // Engine.u (ut)
    {0131}(Index: 00262; Format: nffFunction; OperatorPrecedence: 000; Name: 'SetCollision'), // Engine.u (ut)
    {0132}(Index: 00263; Format: nffFunction; OperatorPrecedence: 000; Name: 'HasAnim'), // Engine.u (ut)
    {0133}(Index: 00264; Format: nffFunction; OperatorPrecedence: 000; Name: 'PlaySound'), // Engine.u (ut)
    {0134}(Index: 00266; Format: nffFunction; OperatorPrecedence: 000; Name: 'Move'), // Engine.u (ut)
    {0135}(Index: 00267; Format: nffFunction; OperatorPrecedence: 000; Name: 'SetLocation'), // Engine.u (ut)
    {0136}(Index: 00272; Format: nffFunction; OperatorPrecedence: 000; Name: 'SetOwner'), // Engine.u (ut)
    {0137}(Index: 00275; Format: nffOperator; OperatorPrecedence: 022; Name: '<<'), // Core.u (ut)
    {0138}(Index: 00276; Format: nffOperator; OperatorPrecedence: 022; Name: '>>'), // Core.u (ut)
    {0139}(Index: 00277; Format: nffFunction; OperatorPrecedence: 000; Name: 'Trace'), // Engine.u (ut)
    {0140}(Index: 00278; Format: nffFunction; OperatorPrecedence: 000; Name: 'Spawn'), // Engine.u (ut)
    {0141}(Index: 00279; Format: nffFunction; OperatorPrecedence: 000; Name: 'Destroy'), // Engine.u (ut)
    {0142}(Index: 00280; Format: nffFunction; OperatorPrecedence: 000; Name: 'SetTimer'), // Engine.u (ut)
    {0143}(Index: 00281; Format: nffFunction; OperatorPrecedence: 000; Name: 'IsInState'), // Core.u (ut)
    {0144}(Index: 00282; Format: nffFunction; OperatorPrecedence: 000; Name: 'IsAnimating'), // Engine.u (ut)
    {0145}(Index: 00283; Format: nffFunction; OperatorPrecedence: 000; Name: 'SetCollisionSize'), // Engine.u (ut)
    {0146}(Index: 00284; Format: nffFunction; OperatorPrecedence: 000; Name: 'GetStateName'), // Core.u (ut)
    {0147}(Index: 00287; Format: nffOperator; OperatorPrecedence: 016; Name: '*'), // Core.u (ut)
    {0148}(Index: 00288; Format: nffOperator; OperatorPrecedence: 016; Name: '*'), // Core.u (ut)
    {0149}(Index: 00289; Format: nffOperator; OperatorPrecedence: 016; Name: '/'), // Core.u (ut)
    {0150}(Index: 00290; Format: nffOperator; OperatorPrecedence: 034; Name: '*='), // Core.u (ut)
    {0151}(Index: 00291; Format: nffOperator; OperatorPrecedence: 034; Name: '/='), // Core.u (ut)
    {0152}(Index: 00293; Format: nffFunction; OperatorPrecedence: 000; Name: 'GetAnimGroup'), // Engine.u (ut)
    {0153}(Index: 00294; Format: nffFunction; OperatorPrecedence: 000; Name: 'TweenAnim'), // Engine.u (ut)
    {0154}(Index: 00296; Format: nffOperator; OperatorPrecedence: 016; Name: '*'), // Core.u (ut)
    {0155}(Index: 00297; Format: nffOperator; OperatorPrecedence: 034; Name: '*='), // Core.u (ut)
    {0156}(Index: 00298; Format: nffFunction; OperatorPrecedence: 000; Name: 'SetBase'), // Engine.u (ut)
    {0157}(Index: 00299; Format: nffFunction; OperatorPrecedence: 000; Name: 'SetRotation'), // Engine.u (ut)
    {0158}(Index: 00300; Format: nffFunction; OperatorPrecedence: 000; Name: 'MirrorVectorByNormal'), // Core.u (ut)
    {0159}(Index: 00301; Format: nffFunction; OperatorPrecedence: 000; Name: 'FinishInterpolation'), // Engine.u (ut)
    {0160}(Index: 00303; Format: nffFunction; OperatorPrecedence: 000; Name: 'IsA'), // Core.u (ut)
    {0161}(Index: 00304; Format: nffFunction; OperatorPrecedence: 000; Name: 'AllActors'), // Engine.u (ut)
    {0162}(Index: 00305; Format: nffFunction; OperatorPrecedence: 000; Name: 'ChildActors'), // Engine.u (ut)
    {0163}(Index: 00306; Format: nffFunction; OperatorPrecedence: 000; Name: 'BasedActors'), // Engine.u (ut)
    {0164}(Index: 00307; Format: nffFunction; OperatorPrecedence: 000; Name: 'TouchingActors'), // Engine.u (ut)
    {0165}(Index: 00308; Format: nffFunction; OperatorPrecedence: 000; Name: 'ZoneActors'), // Engine.u (ut)
    {0166}(Index: 00309; Format: nffFunction; OperatorPrecedence: 000; Name: 'TraceActors'), // Engine.u (ut)
    {0167}(Index: 00310; Format: nffFunction; OperatorPrecedence: 000; Name: 'RadiusActors'), // Engine.u (ut)
    {0168}(Index: 00311; Format: nffFunction; OperatorPrecedence: 000; Name: 'VisibleActors'), // Engine.u (ut)
    {0169}(Index: 00312; Format: nffFunction; OperatorPrecedence: 000; Name: 'VisibleCollidingActors'), // Engine.u (ut)
    {0170}(Index: 00314; Format: nffFunction; OperatorPrecedence: 000; Name: 'Warp'), // Engine.u (ut)
    {0171}(Index: 00315; Format: nffFunction; OperatorPrecedence: 000; Name: 'UnWarp'), // Engine.u (ut)
    {0172}(Index: 00316; Format: nffOperator; OperatorPrecedence: 020; Name: '+'), // Core.u (ut)
    {0173}(Index: 00317; Format: nffOperator; OperatorPrecedence: 020; Name: '-'), // Core.u (ut)
    {0174}(Index: 00318; Format: nffOperator; OperatorPrecedence: 034; Name: '+='), // Core.u (ut)
    {0175}(Index: 00319; Format: nffOperator; OperatorPrecedence: 034; Name: '-='), // Core.u (ut)
    {0176}(Index: 00320; Format: nffFunction; OperatorPrecedence: 000; Name: 'RotRand'), // Core.u (ut)
    {0177}(Index: 00464; Format: nffFunction; OperatorPrecedence: 000; Name: 'StrLen'), // Engine.u (ut)
    {0178}(Index: 00465; Format: nffFunction; OperatorPrecedence: 000; Name: 'DrawText'), // Engine.u (ut)
    {0179}(Index: 00466; Format: nffFunction; OperatorPrecedence: 000; Name: 'DrawTile'), // Engine.u (ut)
    {0180}(Index: 00467; Format: nffFunction; OperatorPrecedence: 000; Name: 'DrawActor'), // Engine.u (ut)
    {0181}(Index: 00468; Format: nffFunction; OperatorPrecedence: 000; Name: 'DrawTileClipped'), // Engine.u (ut)
    {0182}(Index: 00469; Format: nffFunction; OperatorPrecedence: 000; Name: 'DrawTextClipped'), // Engine.u (ut)
    {0183}(Index: 00470; Format: nffFunction; OperatorPrecedence: 000; Name: 'TextSize'), // Engine.u (ut)
    {0184}(Index: 00471; Format: nffFunction; OperatorPrecedence: 000; Name: 'DrawClippedActor'), // Engine.u (ut)
    {0185}(Index: 00472; Format: nffFunction; OperatorPrecedence: 000; Name: 'DrawText'), // Engine.u (ut)
    {0186}(Index: 00473; Format: nffFunction; OperatorPrecedence: 000; Name: 'DrawTile'), // Engine.u (ut)
    {0187}(Index: 00474; Format: nffFunction; OperatorPrecedence: 000; Name: 'DrawColoredText'), // Engine.u (ut)
    {0188}(Index: 00475; Format: nffFunction; OperatorPrecedence: 000; Name: 'ReplaceTexture'), // Engine.u (ut)
    {0189}(Index: 00476; Format: nffFunction; OperatorPrecedence: 000; Name: 'TextSize'), // Engine.u (ut)
    {0190}(Index: 00480; Format: nffFunction; OperatorPrecedence: 000; Name: 'DrawPortal'), // Engine.u (ut)
    {0191}(Index: 00500; Format: nffFunction; OperatorPrecedence: 000; Name: 'MoveTo'), // Engine.u (ut)
    {0192}(Index: 00502; Format: nffFunction; OperatorPrecedence: 000; Name: 'MoveToward'), // Engine.u (ut)
    {0193}(Index: 00504; Format: nffFunction; OperatorPrecedence: 000; Name: 'StrafeTo'), // Engine.u (ut)
    {0194}(Index: 00506; Format: nffFunction; OperatorPrecedence: 000; Name: 'StrafeFacing'), // Engine.u (ut)
    {0195}(Index: 00508; Format: nffFunction; OperatorPrecedence: 000; Name: 'TurnTo'), // Engine.u (ut)
    {0196}(Index: 00510; Format: nffFunction; OperatorPrecedence: 000; Name: 'TurnToward'), // Engine.u (ut)
    {0197}(Index: 00512; Format: nffFunction; OperatorPrecedence: 000; Name: 'MakeNoise'), // Engine.u (ut)
    {0198}(Index: 00514; Format: nffFunction; OperatorPrecedence: 000; Name: 'LineOfSightTo'), // Engine.u (ut)
    {0199}(Index: 00517; Format: nffFunction; OperatorPrecedence: 000; Name: 'FindPathToward'), // Engine.u (ut)
    {0200}(Index: 00518; Format: nffFunction; OperatorPrecedence: 000; Name: 'FindPathTo'), // Engine.u (ut)
    {0201}(Index: 00519; Format: nffFunction; OperatorPrecedence: 000; Name: 'describeSpec'), // Engine.u (ut)
    {0202}(Index: 00520; Format: nffFunction; OperatorPrecedence: 000; Name: 'actorReachable'), // Engine.u (ut)
    {0203}(Index: 00521; Format: nffFunction; OperatorPrecedence: 000; Name: 'pointReachable'), // Engine.u (ut)
    {0204}(Index: 00522; Format: nffFunction; OperatorPrecedence: 000; Name: 'ClearPaths'), // Engine.u (ut)
    {0205}(Index: 00523; Format: nffFunction; OperatorPrecedence: 000; Name: 'EAdjustJump'), // Engine.u (ut)
    {0206}(Index: 00524; Format: nffFunction; OperatorPrecedence: 000; Name: 'FindStairRotation'), // Engine.u (ut)
    {0207}(Index: 00525; Format: nffFunction; OperatorPrecedence: 000; Name: 'FindRandomDest'), // Engine.u (ut)
    {0208}(Index: 00526; Format: nffFunction; OperatorPrecedence: 000; Name: 'PickWallAdjust'), // Engine.u (ut)
    {0209}(Index: 00527; Format: nffFunction; OperatorPrecedence: 000; Name: 'WaitForLanding'), // Engine.u (ut)
    {0210}(Index: 00529; Format: nffFunction; OperatorPrecedence: 000; Name: 'AddPawn'), // Engine.u (ut)
    {0211}(Index: 00530; Format: nffFunction; OperatorPrecedence: 000; Name: 'RemovePawn'), // Engine.u (ut)
    {0212}(Index: 00531; Format: nffFunction; OperatorPrecedence: 000; Name: 'PickTarget'), // Engine.u (ut)
    {0213}(Index: 00532; Format: nffFunction; OperatorPrecedence: 000; Name: 'PlayerCanSeeMe'), // Engine.u (ut)
    {0214}(Index: 00533; Format: nffFunction; OperatorPrecedence: 000; Name: 'CanSee'), // Engine.u (ut)
    {0215}(Index: 00534; Format: nffFunction; OperatorPrecedence: 000; Name: 'PickAnyTarget'), // Engine.u (ut)
    {0216}(Index: 00536; Format: nffFunction; OperatorPrecedence: 000; Name: 'SaveConfig'), // Core.u (ut)
    {0217}(Index: 00539; Format: nffFunction; OperatorPrecedence: 000; Name: 'GetMapName'), // Engine.u (ut)
    {0218}(Index: 00540; Format: nffFunction; OperatorPrecedence: 000; Name: 'FindBestInventoryPath'), // Engine.u (ut)
    {0219}(Index: 00544; Format: nffFunction; OperatorPrecedence: 000; Name: 'ResetKeyboard'), // Engine.u (ut)
    {0220}(Index: 00545; Format: nffFunction; OperatorPrecedence: 000; Name: 'GetNextSkin'), // Engine.u (ut)
    {0221}(Index: 00546; Format: nffFunction; OperatorPrecedence: 000; Name: 'UpdateURL'), // Engine.u (ut)
    {0222}(Index: 00547; Format: nffFunction; OperatorPrecedence: 000; Name: 'GetURLMap'), // Engine.u (ut)
    {0223}(Index: 00548; Format: nffFunction; OperatorPrecedence: 000; Name: 'FastTrace'), // Engine.u (ut)
    {0224}(Index: 00549; Format: nffOperator; OperatorPrecedence: 020; Name: '-'), // Engine.u (ut)
    {0225}(Index: 00550; Format: nffOperator; OperatorPrecedence: 016; Name: '*'), // Engine.u (ut)
    {0226}(Index: 00551; Format: nffOperator; OperatorPrecedence: 020; Name: '+'), // Engine.u (ut)
    {0227}(Index: 00552; Format: nffOperator; OperatorPrecedence: 016; Name: '*'), // Engine.u (ut)
    {0228}(Index: 01033; Format: nffFunction; OperatorPrecedence: 000; Name: 'RandRange'), // Core.u (ut)
    {0229}(Index: 03969; Format: nffFunction; OperatorPrecedence: 000; Name: 'MoveSmooth'), // Engine.u (ut)
    {0230}(Index: 03970; Format: nffFunction; OperatorPrecedence: 000; Name: 'SetPhysics'), // Engine.u (ut)
    {0231}(Index: 03971; Format: nffFunction; OperatorPrecedence: 000; Name: 'AutonomousPhysics') // Engine.u (ut)
    );

  // Property Flags
  CPF_Edit = $00000001;                 // Property is user-settable in the editor.
  CPF_Const = $00000002;                // Actor's property always matches class's default actor property.
  CPF_Input = $00000004;                // Variable is writable by the input system.
  CPF_ExportObject = $00000008;         // Object can be exported with actor.
  CPF_OptionalParm = $00000010;         // Optional parameter (if CPF_Param is set).
  CPF_Net = $00000020;                  // Property is relevant to network replication.
  CPF_ConstRef = $00000040;             // Reference to a constant object.
  CPF_Parm = $00000080;                 // Function/When call parameter.
  CPF_OutParm = $00000100;              // Value is copied out after function call.
  CPF_SkipParm = $00000200;             // Property is a short-circuitable evaluation function parm.
  CPF_ReturnParm = $00000400;           // Return value.
  CPF_CoerceParm = $00000800;           // Coerce args into this function parameter.
  CPF_Native = $00001000;               // Property is native: C++ code is responsible for serializing it.
  CPF_Transient = $00002000;            // Property is transient: shouldn't be saved, zero-filled at load time.
  CPF_Config = $00004000;               // Property should be loaded/saved as permanent profile.
  CPF_Localized = $00008000;            // Property should be loaded as localizable text.
  CPF_Travel = $00010000;               // Property travels across levels/servers.
  CPF_EditConst = $00020000;            // Property is uneditable in the editor.
  CPF_GlobalConfig = $00040000;         // Load config from base class, not subclass.
  CPF_OnDemand = $00100000;             // Object or dynamic array loaded on demand only.
  CPF_New = $00200000;                  // Automatically create inner object.
  CPF_NeedCtorLink = $00400000;         // Fields need construction/destruction.
  // NOTE : for vars with no category specified, the category name is the class

 // Function flags.
  FUNC_Final = $00000001;               // Function is final (prebindable, non-overridable function).
  FUNC_Defined = $00000002;             // Function has been defined (not just declared).
  FUNC_Iterator = $00000004;            // Function is an iterator.
  FUNC_Latent = $00000008;              // Function is a latent state function.
  FUNC_PreOperator = $00000010;         // Unary operator is a prefix operator.
  FUNC_Singular = $00000020;            // Function cannot be reentered.
  FUNC_Net = $00000040;                 // Function is network-replicated.
  FUNC_NetReliable = $00000080;         // Function should be sent reliably on the network.
  FUNC_Simulated = $00000100;           // Function executed on the client side.
  FUNC_Exec = $00000200;                // Executable from command line.
  FUNC_Native = $00000400;              // Native function.
  FUNC_Event = $00000800;               // Event function.
  FUNC_Operator = $00001000;            // Operator function.
  FUNC_Static = $00002000;              // Static function.
  FUNC_NoExport = $00004000;            // Don't export intrinsic function to C++.
  FUNC_Const = $00008000;               // Function doesn't modify this object.
  FUNC_Invariant = $00010000;           // Return value is purely dependent on parameters; no state dependencies or internal state changes.

  // Base flags.
  CLASS_Abstract = $00001;              // Class is abstract and can't be instantiated directly.
  CLASS_Compiled = $00002;              // Script has been compiled successfully.
  CLASS_Config = $00004;                // Load object configuration at construction time.
  CLASS_Transient = $00008;             // This object type can't be saved; null it out at save time.
  CLASS_Parsed = $00010;                // Successfully parsed.
  CLASS_Localized = $00020;             // Class contains localized text.
  CLASS_SafeReplace = $00040;           // Objects of this class can be safely replaced with default or NULL.
  CLASS_RuntimeStatic = $00080;         // Objects of this class are static during gameplay.
  CLASS_NoExport = $00100;              // Don't export to C++ header.
  CLASS_NoUserCreate = $00200;          // Don't allow users to create in the editor.
  CLASS_PerObjectConfig = $00400;       // Handle object configuration on a per-object basis, rather than per-class.
  CLASS_NativeReplication = $00800;     // Replication handled in C++

  // State flags.
  STATE_Editable = $00000001;           // State should be user-selectable in UnrealEd.
  STATE_Auto = $00000002;               // State is automatic (the default state).
  STATE_Simulated = $00000004;          // State executes on client side.

  // Node Flags
  NF_NotCsg = $01;                      // Node is not a Csg splitter, i.e. is a transparent poly.
  NF_ShootThrough = $02;                // Can shoot through (for projectile solid ops).
  NF_NotVisBlocking = $04;              // Node does not block visibility, i.e. is an invisible collision hull.
  NF_PolyOccluded = $08;                // Node's poly was occluded on the previously-drawn frame.
  NF_BoxOccluded = $10;                 // Node's bounding box was occluded.
  NF_BrightCorners = $10;               // Temporary.
  NF_IsNew = $20;                       // Editor: Node was newly-added.
  NF_IsFront = $40;                     // Filter operation bounding-sphere precomputed and guaranteed to be front.
  NF_IsBack = $80;                      // Guaranteed back.
  NF_NeverMove = 0;                     // Bsp cleanup must not move nodes with these tags.

  // Reach Flags
  R_WALK = 1;                           //walking required
  R_FLY = 2;                            //flying required
  R_SWIM = 4;                           //swimming required
  R_JUMP = 8;                           // jumping required
  R_DOOR = 16;
  R_SPECIAL = 32;
  R_PLAYERONLY = 64;

  // Poly Flags
  PF_Invisible = $00000001;             // Poly is invisible.
  PF_Masked = $00000002;                // Poly should be drawn masked.
  PF_Translucent = $00000004;           // Poly is transparent.
  PF_NotSolid = $00000008;              // Poly is not solid, doesn't block.
  PF_Environment = $00000010;           // Poly should be drawn environment mapped.
  PF_ForceViewZone = $00000010;         // Force current iViewZone in OccludeBSP (reuse Environment flag)
  PF_Semisolid = $00000020;             // Poly is semi-solid = collision solid, Csg nonsolid.
  PF_Modulated = $00000040;             // Modulation transparency.
  PF_FakeBackdrop = $00000080;          // Poly looks exactly like backdrop.
  PF_TwoSided = $00000100;              // Poly is visible from both sides.
  PF_AutoUPan = $00000200;              // Automatically pans in U direction.
  PF_AutoVPan = $00000400;              // Automatically pans in V direction.
  PF_NoSmooth = $00000800;              // Don't smooth textures.
  PF_BigWavy = $00001000;               // Poly has a big wavy pattern in it.
  PF_SpecialPoly = $00001000;           // Game-specific poly-level render control (reuse BigWavy flag)
  PF_SmallWavy = $00002000;             // Small wavy pattern (for water/enviro reflection).
  PF_Flat = $00004000;                  // Flat surface.
  PF_LowShadowDetail = $00008000;       // Low detaul shadows.
  PF_NoMerge = $00010000;               // Don't merge poly's nodes before lighting when rendering.
  PF_CloudWavy = $00020000;             // Polygon appears wavy like clouds.
  PF_DirtyShadows = $00040000;          // Dirty shadows.
  PF_BrightCorners = $00080000;         // Brighten convex corners.
  PF_SpecialLit = $00100000;            // Only speciallit lights apply to this poly.
  PF_Gouraud = $00200000;               // Gouraud shaded.
  PF_NoBoundRejection = $00200000;      // Disable bound rejection in OccludeBSP (reuse Gourard flag)
  PF_Unlit = $00400000;                 // Unlit.
  PF_HighShadowDetail = $00800000;      // High detail shadows.
  PF_Portal = $04000000;                // Portal between iZones.
  PF_Mirrored = $08000000;              // Reflective surface.
  PF_Memorized = $01000000;             // Editor: Poly is remembered.
  PF_Selected = $02000000;              // Editor: Poly is selected.
  PF_Highlighted = $10000000;           // Editor: Poly is highlighted.
  PF_FlatShaded = $40000000;            // Editor: FPoly has been split by SplitPolyWithPlane.
  PF_EdProcessed = $40000000;           // Internal: FPoly was already processed in editorBuildFPolys.
  PF_EdCut = $80000000;                 // Internal: FPoly has been split by SplitPolyWithPlane.
  PF_RenderFog = $40000000;             // Internal: Render with fogmapping.
  PF_Occlude = $80000000;               // Internal: Occludes even if PF_NoOcclude.
  PF_RenderHint = $01000000;            // Internal: Rendering optimization hint.
  PF_NoOcclude = PF_Masked or PF_Translucent or PF_Invisible or PF_Modulated;
  PF_NoEdit = PF_Memorized or PF_Selected or PF_EdProcessed or PF_NoMerge or PF_EdCut;
  PF_NoImport = PF_NoEdit or PF_NoMerge or PF_Memorized or PF_Selected or PF_EdProcessed or PF_EdCut;
  PF_AddLast = PF_Semisolid or PF_NotSolid;
  PF_NoAddToBSP = PF_EdCut or PF_EdProcessed or PF_Selected or PF_Memorized;
  PF_NoShadows = PF_Unlit or PF_Invisible or PF_Environment or PF_FakeBackdrop;
  PF_Transient = PF_Highlighted;

function GetKnownEnumValue(enumtype: string; index: integer): string;
procedure RegisterKnownEnumValues(enumtype: string; values: array of string);

implementation

resourcestring
  rsUnknownPropertyType = 'Unknown type 0x%-2.2x, scan stopped';
  rsUnknownStruct = 'Unknown struct "%s", scan stopped';
  rsErrorNoUTPackage = 'ERROR! This isn''t an Unreal package';
  rsExceptionProcessingPackage = 'Exception processing package %0:s'#13#10'%1:s';
  rsExceptionReadingProperty = 'Exception reading property %s';
  rsUnknown = 'Unknown';
  rsWarning = 'Warning!';
  rsNotImplemented = 'Not Implemented';
  rsUnknownOpcode = 'Unknown OpCode 0x%-2.2x. Will try to continue.';
  rsInvalidNativeIndex = 'Invalid native function index 0x%-2.2x';

type
  TUTClassRegistry = record
    class_name: string;
    class_class: TUTObjectClass;
  end;
  TUTClassEquivalence = record
    class_name: string;
    equivalent_class_name: string;
  end;
  TKnownEnumValues = record
    Enum: string;
    Values: array of string;
  end;

var
  RegisteredUTClasses: array of TUTClassRegistry;
  UTClassEquivalences: array of TUTClassEquivalence;
  KnownEnumValues: array of TKnownEnumValues;

procedure AddUTClassEquivalence(classname, equivalentclass: string);
begin
  setlength(UTClassEquivalences, length(UTClassEquivalences) + 1);
  with UTClassEquivalences[high(UTClassEquivalences)] do
    begin
      class_name := lowercase(classname);
      equivalent_class_name := lowercase(equivalentclass);
    end;
end;

procedure ClearUTClassEquivalences;
begin
  setlength(UTClassEquivalences, 0);
end;

procedure RegisterUTObjectClass(classname: string; classclass: TUTObjectClass);
var
  a, n: integer;
begin
  classname := lowercase(classname);
  a := 0;
  n := -1;
  while (a <= high(RegisteredUTClasses)) and (n = -1) do
    if RegisteredUTClasses[a].class_name = classname then
      n := a
    else
      inc(a);
  if n = -1 then
    begin
      setlength(RegisteredUTClasses, length(RegisteredUTClasses) + 1);
      n := high(RegisteredUTClasses);
    end;
  with RegisteredUTClasses[n] do
    begin
      class_name := classname;
      class_class := classclass;
    end;
end;

function GetUTObjectClass(classname: string): TUTObjectClass;
var
  a: integer;
begin
  classname := lowercase(classname);
  for a := 0 to high(UTClassEquivalences) do
    if UTClassEquivalences[a].class_name = classname then
      begin
        classname := UTClassEquivalences[a].equivalent_class_name;
        break;
      end;
  a := 0;
  result := TUTObject;
  while (a < length(RegisteredUTClasses)) do
    if RegisteredUTClasses[a].class_name = classname then
      begin
        result := RegisteredUTClasses[a].class_class;
        break;
      end
    else
      inc(a);
end;

{ TUTProperty }

function TUTProperty.GetDescription: string;
var
  vn, vd: string;
  vv: variant;
  vt: TUTPropertyType;
begin
  if not FIsInitialized then
    begin
      result := '';
      exit;
    end;
  result := name;
  if (FArrayIndex > -1) then result := result + format('[%d]', [FArrayIndex]);
  if specifictypename <> '' then result := result + ' (' + specifictypename + ')';
  if propertytype <> otNone then
    begin
      GetValue(-1, vn, vv, vd, vt);
      result := result + ' = ' + vd;
    end;
end;

function TUTProperty.GetFirstValue: variant;
var
  name, descriptive: string;
  _type: TUTPropertyType;
begin
  GetValue(-1, name, result, descriptive, _type);
end;

function TUTProperty.GetValueTypeName(t: TUTPropertyType): string;
begin
  case t of
    otNone: result := '';
    otByte: result := 'Byte';
    otInt: result := 'Int';
    otBool: result := 'Bool';
    otFloat: result := 'Float';
    otObject: result := 'Object';
    otName: result := 'Name';
    otString: result := 'String';
    otClass: result := 'Class';
    otArray: result := 'Array';
    otStruct: result := 'Struct';
    otVector: result := 'Vector';
    otRotator: result := 'Rotator';
    otStr: result := 'Str';
    otMap: result := 'Map';
    otFixedArray: result := 'FixedArray';

    otWord: result := 'Word';
    otBuffer:
      result := 'Buffer'
  else
    result := '';
  end;
end;

function TUTProperty.GetTypeName: string;
begin
  if FTypeName <> '' then
    result := FTypeName
  else
    result := GetValueTypeName(PropertyType);
end;

procedure TUTProperty.GetValue(i: integer; var valuename: string;
  var value: variant; var descriptivevalue: string;
  var valuetype: TUTPropertyType);
var
  w: word;
  int: integer;
  s: single;
  dbl: double;
  z, t, valuedescription: string;
  bo: boolean;
  b: byte;
  ds: char;
  rgba: array[0..3] of byte;
  vector: array[0..2] of single;
  plane: array[0..3] of single;
  rotator: array[0..2] of integer;
  pointregion: packed record
    zone: integer;
    ileaf: integer;
    zonenumber: integer;
  end;
  scale: packed record
    x, y, z, sheerrate: single;
    sheeraxis: byte;
  end;
  adropspark: packed record
    _type, heat: byte;
    x, y: byte;
    x_speed, y_speed: byte;
    Age, ExpTime: byte;
  end;
  posvalue: integer;
  procedure GetPropertyValue(var start: integer; i: integer; var valuename, descriptivevalue, valuedescription: string; var value: variant; var valuetype: TUTPropertyType; thetypename: string);
  var
    enum: string;
    valuename2, descriptivevalue2, valuedescription2: string;
    value2: variant;
    valuetype2: TUTPropertyType;
    typename2, pkg: string;
    newpackage, newpackage2: TUTPackage;
    packagedescriptor, packagefile: string;
    p: integer;
    struct: TUTObjectClassStruct;
    prop: TUTObjectClassProperty;
    pr, prcount: integer;
    complete_descriptivevalue, propclass, packagename, superobjectname, superpackagename: string;
    byteprop: TUTObjectClassByteProperty;
    enumprop: TUTObjectClassEnum;
    enumtype, parentobject: integer;
    cached_enum: string;
  begin
    case valuetype of
      otNone:
        begin
          value := 0;
        end;
      otByte:
        begin
          b := FValue[start];
          inc(start);
          if FOwner.FEnumCache.indexofname(valuename)>=0 then
            begin
              cached_enum := FOwner.FEnumCache.values[valuename]+' ';
              int := b;
              repeat
                p := pos(' ', cached_enum);
                if p = 0 then p := length(cached_enum) + 1;
                enum := copy(cached_enum, 1, p - 1);
                delete(cached_enum, 1, p);
                dec(int);
              until (int < 0) or (int = b-2);
              if int <> b - 2 then enum := '';
            end
          else
            begin
              // search the actual property variable inside the property owner
              // object or its class or its parents and get the enum type from there.
              newpackage := FOwner;
              if (FOwnerObject.UTClassName = '') or (FOwnerObject.UTClassName = 'Class') or
                (FOwnerObject.UTClassName = 'State') then
                begin                   // the object is a class or state
                  packagename := FOwnerObject.GetFullName;
                  parentobject := FOwnerObject.UTSuperIndex;
                end
              else
                begin                   // the object is an instance of a class so we get its class as first parent
                  packagename := FOwnerObject.GetFullName;
                  parentobject := FOwnerObject.UTClassIndex;
                end;
              repeat
                int := newpackage.FindObject(utolExports, [utfwName, utfwPackage, utfwClass],
                  packagename, valuename, 'ByteProperty');
                if int = -1 then
                  begin
                    // The byteproperty is not on this object, so we must search in its parent
                    if parentobject = 0 then
                      break
                    else
                      begin
                        if parentobject > 0 then
                          begin
                            packagename := newpackage.Exported[parentobject - 1].UTPackageName;
                            if packagename <> '' then packagename := packagename + '.';
                            packagename := packagename + newpackage.Exported[parentobject - 1].UTObjectName;
                            parentobject := newpackage.Exported[parentobject - 1].UTSuperIndex;
                          end
                        else if (parentobject < 0) and FOwner.AllowReadingOtherPackages then
                          begin
                            packagedescriptor := newpackage.imported[-parentobject - 1].UTPackageName;
                            p := pos('.', packagedescriptor);
                            if p = 0 then p := length(packagedescriptor) + 1;
                            packagefile := copy(packagedescriptor, 1, p - 1);
                            delete(packagedescriptor, 1, p);
                            packagename := newpackage.imported[-parentobject - 1].UTObjectName;
                            if packagedescriptor <> '' then packagename := packagedescriptor + '.' + packagename;
                            pkg := extractfilepath(FOwner.FPackage) + packagefile + '.u';
                            if assigned(FOwner.OnPackageNeeded) then FOwner.OnPackageNeeded(pkg);
                            if fileexists(pkg) then
                              begin
                                if newpackage = FOwner then
                                  newpackage := TUTPackage.create(pkg)
                                else
                                  newpackage.Initialize(pkg);
                                superobjectname := packagename;
                                p := length(superobjectname);
                                while (p > 0) and (superobjectname[p] <> '.') do
                                  dec(p);
                                superpackagename := copy(superobjectname, 1, p - 1);
                                delete(superobjectname, 1, p);
                                p := newpackage.FindObject(utolExports, [utfwName, utfwPackage],
                                  superpackagename, superobjectname, '');
                                if p = -1 then
                                  parentobject := 0
                                else
                                  parentobject := newpackage.Exported[p].UTSuperIndex;
                              end
                            else
                              break;
                          end
                        else
                          break;
                      end;
                  end;
              until (int <> -1);
              if int <> -1 then
                begin                   // we found the property
                  byteprop := TUTObjectClassByteProperty(newpackage.Exported[int].UTObject);
                  byteprop.ReadObject;
                  enumtype := byteprop.Enum;
                  byteprop.ReleaseObject;
                end
              else                      // we didnt found the property...
                begin                   // ...so we try searching the Enum type based on the property name
                  // (this should never happen if the needed packages exist)
                  int := newpackage.FindObject(utolExports, [utfwName, utfwClass],
                    'E' + valuename, '', 'Enum');
                  if int <> -1 then
                    enumtype := int + 1 // found on this package
                  else
                    begin
                      int := newpackage.FindObject(utolImports, [utfwName, utfwClass],
                        'E' + valuename, '', 'Enum');
                      if int <> -1 then
                        enumtype := -int - 1
                      else
                        enumtype := 0;  // not found
                    end;
                end;
              if enumtype > 0 then
                begin                   // the Enum type is in the current package
                  enumprop := TUTObjectClassEnum(newpackage.Exported[enumtype - 1].UTObject);
                  enumprop.ReadObject;
                  enum := enumprop.GetValueName(b);
                  cached_enum := valuename + '=';
                  for p := 0 to enumprop.Count - 1 do
                    cached_enum := cached_enum + enumprop.GetValueName(p) + ' ';
                  delete(cached_enum, length(cached_enum), 1);
                  FOwner.FEnumCache.add(cached_enum);
                  enumprop.ReleaseObject;
                end
              else if (enumtype < 0) and FOwner.AllowReadingOtherPackages then
                begin                   // the Enum type is in an imported package
                  packagedescriptor := newpackage.imported[-enumtype - 1].UTPackageName;
                  p := pos('.', packagedescriptor);
                  if p = 0 then p := length(packagedescriptor) + 1;
                  packagefile := copy(packagedescriptor, 1, p - 1);
                  delete(packagedescriptor, 1, p);
                  pkg := extractfilepath(FOwner.FPackage) + packagefile + '.u';
                  if assigned(FOwner.OnPackageNeeded) then FOwner.OnPackageNeeded(pkg);
                  if fileexists(pkg) then
                    begin
                      try
                        newpackage2 := nil;
                        try
                          newpackage2 := TUTPackage.create(pkg);
                          enumtype := newpackage2.FindObject(utolExports, [utfwName, utfwClass], '', newpackage.imported[-enumtype - 1].UTObjectName, 'Enum');
                          enumprop := TUTObjectClassEnum(newpackage2.Exported[enumtype].UTObject);
                          enumprop.ReadObject;
                          enum := enumprop.GetValueName(b);
                          cached_enum := valuename + '=';
                          for p := 0 to enumprop.Count - 1 do
                            cached_enum := cached_enum + enumprop.GetValueName(p) + ' ';
                          delete(cached_enum, length(cached_enum), 1);
                          FOwner.FEnumCache.add(cached_enum);
                          enumprop.ReleaseObject;
                        finally
                          newpackage2.free;
                        end;
                      except
                      end;
                    end;
                end
              else FOwner.FEnumCache.add(valuename+'=');
              if newpackage <> FOwner then freeandnil(newpackage);
            end;
          value := b;
          valuedescription := enum;
          if enum <> '' then
            descriptivevalue := enum
          else
            descriptivevalue := inttostr(b);
        end;
      otObject:
        begin
          move(FValue[start], int, 4);
          inc(start, 4);
          value := int;
          if int = 0 then
            valuedescription := 'None'
          else
            begin
              if int >= 0 then
                valuedescription := FOwner.Exported[int - 1].UTClassName
              else
                valuedescription := FOwner.Imported[-int - 1].UTClassName;
              if valuedescription = '' then valuedescription := 'Class';
              valuedescription := valuedescription + '''' + FOwner.GetObjectPath(-1, int) + '''';
            end;
          descriptivevalue := valuedescription;
        end;
      otInt:
        begin
          move(FValue[start], int, 4);
          inc(start, 4);
          value := int;
          descriptivevalue := inttostr(int);
        end;
      otFloat:
        begin
          move(FValue[start], s, 4);
          inc(start, 4);
          dbl := s;
          value := dbl;
          descriptivevalue := format('%f', [dbl]);
        end;
      otBool:
        begin
          move(FValue[start], bo, 1);
          inc(start, 1);
          value := bo;
          if bo then
            descriptivevalue := 'True'
          else
            descriptivevalue := 'False';
        end;
      otWord:
        begin
          move(FValue[start], w, 2);
          inc(start, 2);
          value := w;
          descriptivevalue := inttostr(w);
        end;
      otName:
        begin
          move(FValue[start], int, 4);
          inc(start, 4);
          value := int;
          valuedescription := FOwner.FNameTableList[int];
          descriptivevalue := valuedescription;
        end;
      otStr, otString:
        begin                           // TODO : check if the strings can be less than the total size
          setlength(t, length(FValue));
          move(FValue[start], t[1], length(FValue));
          inc(start, length(FValue));
          while (t <> '') and (t[length(t)] = #0) do
            delete(t, length(t), 1);
          value := t;
          descriptivevalue := FOwner.GetStringConst(t);
        end;
      otBuffer:                         // TODO : is this type needed?
        begin
          value := FValue;
          inc(start, length(FValue));
          descriptivevalue := '';
        end;
      otStruct:
        begin
          if lowercase(theTypeName) = 'color' then
            begin
              move(FValue[start], rgba[0], sizeof(rgba));
              inc(start, sizeof(rgba));
              case i of
                -1:
                  begin
                    value := format('(R=%d,G=%d,B=%d,A=%d)', [rgba[0], rgba[1], rgba[2], rgba[3]]);
                    descriptivevalue := value;
                  end;
                0:
                  begin
                    valuename := 'R';
                    valuetype := otByte;
                    value := rgba[0];
                    descriptivevalue := inttostr(rgba[0]);
                  end;
                1:
                  begin
                    valuename := 'G';
                    valuetype := otByte;
                    value := rgba[1];
                    descriptivevalue := inttostr(rgba[1]);
                  end;
                2:
                  begin
                    valuename := 'B';
                    valuetype := otByte;
                    value := rgba[2];
                    descriptivevalue := inttostr(rgba[2]);
                  end;
                3:
                  begin
                    valuename := 'A';
                    valuetype := otByte;
                    value := rgba[3];
                    descriptivevalue := inttostr(rgba[3]);
                  end;
              end;
            end
          else if lowercase(theTypeName) = 'vector' then
            begin
              move(FValue[start], vector, sizeof(vector));
              inc(start, sizeof(vector));
              case i of
                -1:
                  begin
                    value := format('(X=%f,Y=%f,Z=%f)', [vector[0], vector[1], vector[2]]);
                    descriptivevalue := value;
                  end;
                0:
                  begin
                    valuename := 'X';
                    valuetype := otFloat;
                    value := vector[0];
                    descriptivevalue := format('%f', [vector[0]]);
                  end;
                1:
                  begin
                    valuename := 'Y';
                    valuetype := otFloat;
                    value := vector[1];
                    descriptivevalue := format('%f', [vector[1]]);
                  end;
                2:
                  begin
                    valuename := 'Z';
                    valuetype := otFloat;
                    value := vector[2];
                    descriptivevalue := format('%f', [vector[2]]);
                  end;
              end;
            end
          else if lowercase(theTypeName) = 'rotator' then
            begin
              move(FValue[start], rotator, sizeof(rotator));
              inc(start, sizeof(rotator));
              case i of
                -1:
                  begin
                    value := format('(Pitch=%d,Yaw=%d,Roll=%d)', [rotator[0], rotator[1], rotator[2]]);
                    descriptivevalue := value;
                  end;
                0:
                  begin
                    valuename := 'Pitch';
                    valuetype := otInt;
                    value := rotator[0];
                    descriptivevalue := inttostr(rotator[0]);
                  end;
                1:
                  begin
                    valuename := 'Yaw';
                    valuetype := otInt;
                    value := rotator[1];
                    descriptivevalue := inttostr(rotator[1]);
                  end;
                2:
                  begin
                    valuename := 'Roll';
                    valuetype := otInt;
                    value := rotator[2];
                    descriptivevalue := inttostr(rotator[2]);
                  end;
              end;
            end
          else if lowercase(theTypeName) = 'pointregion' then
            begin
              move(FValue[start], pointregion, sizeof(pointregion));
              inc(start, sizeof(pointregion));
              case i of
                -1:
                  begin
                    if pointregion.zone = 0 then
                      z := 'None'
                    else
                      begin
                        if pointregion.zone >= 0 then
                          z := FOwner.Exported[pointregion.zone - 1].UTClassName
                        else
                          z := FOwner.Imported[-pointregion.zone - 1].UTClassName;
                        if z = '' then z := 'Class';
                        z := z + '''' + FOwner.GetObjectPath(-1, pointregion.zone) + '''';
                      end;
                    value := format('(Zone=%s, iLeaf=%d, ZoneNumber=%d)', [z, pointregion.ileaf, pointregion.zonenumber]);
                    descriptivevalue := value;
                  end;
                0:
                  begin
                    valuename := 'Zone';
                    value := pointregion.zone;
                    valuetype := otObject;
                    if value = 0 then
                      valuedescription := 'None'
                    else
                      begin
                        if value >= 0 then
                          valuedescription := FOwner.Exported[value - 1].UTClassName
                        else
                          valuedescription := FOwner.Imported[-value - 1].UTClassName;
                        if valuedescription = '' then valuedescription := 'Class';
                        valuedescription := valuedescription + '''' + FOwner.GetObjectPath(-1, value) + '''';
                      end;
                    descriptivevalue := valuedescription;
                  end;
                1:
                  begin
                    valuename := 'iLeaf';
                    value := pointregion.ileaf;
                    valuetype := otInt;
                    descriptivevalue := inttostr(pointregion.ileaf);
                  end;
                2:
                  begin
                    valuename := 'ZoneNumber';
                    value := pointregion.zonenumber;
                    valuetype := otInt;
                    descriptivevalue := inttostr(pointregion.zonenumber);
                  end;
              end;
            end
          else if lowercase(theTypeName) = 'scale' then
            begin
              move(FValue[start], scale, sizeof(scale));
              inc(start, sizeof(scale));
              case i of
                -1:
                  begin
                    value := format('(X=%f, Y=%f, Z=%f, SheerRate=%f, SheerAxis=%s)', [scale.x, scale.y, scale.z, scale.sheerrate, GetKnownEnumValue('ESheerAxis', scale.sheeraxis)]);
                    descriptivevalue := value;
                  end;
                0:
                  begin
                    valuename := 'X';
                    value := scale.x;
                    valuetype := otFloat;
                    descriptivevalue := format('%f', [scale.x]);
                  end;
                1:
                  begin
                    valuename := 'Y';
                    value := scale.y;
                    valuetype := otFloat;
                    descriptivevalue := format('%f', [scale.y]);
                  end;
                2:
                  begin
                    valuename := 'Z';
                    value := scale.z;
                    valuetype := otFloat;
                    descriptivevalue := format('%f', [scale.z]);
                  end;
                3:
                  begin
                    valuename := 'SheerRate';
                    value := scale.sheerrate;
                    valuetype := otFloat;
                    descriptivevalue := format('%f', [scale.sheerrate]);
                  end;
                4:
                  begin
                    valuename := 'SheerAxis';
                    value := scale.sheeraxis;
                    valuedescription := GetKnownEnumValue('ESheerAxis', scale.sheeraxis);
                    valuetype := otByte;
                    descriptivevalue := valuedescription;
                  end;
              end;
            end
          else if lowercase(theTypeName) = 'plane' then
            begin
              move(FValue[start], plane, sizeof(plane));
              inc(start, sizeof(plane));
              case i of
                -1:
                  begin
                    value := format('(X=%f, Y=%f, Z=%f, W=%f)', [plane[0], plane[1], plane[2], plane[3]]);
                    descriptivevalue := value;
                  end;
                0:
                  begin
                    valuename := 'X';
                    valuetype := otFloat;
                    value := plane[0];
                    descriptivevalue := format('%f', [plane[0]]);
                  end;
                1:
                  begin
                    valuename := 'Y';
                    valuetype := otFloat;
                    value := plane[1];
                    descriptivevalue := format('%f', [plane[1]]);
                  end;
                2:
                  begin
                    valuename := 'Z';
                    valuetype := otFloat;
                    value := plane[2];
                    descriptivevalue := format('%f', [plane[2]]);
                  end;
                3:
                  begin
                    valuename := 'W';
                    valuetype := otFloat;
                    value := plane[3];
                    descriptivevalue := format('%f', [plane[3]]);
                  end;
              end;
            end
          else if lowercase(theTypeName) = 'sphere' then
            begin
              move(FValue[start], plane, sizeof(plane));
              inc(start, sizeof(plane));
              case i of
                -1:
                  begin
                    value := format('(X=%f, Y=%f, Z=%f, W=%f)', [plane[0], plane[1], plane[2], plane[3]]);
                    descriptivevalue := value;
                  end;
                0:
                  begin
                    valuename := 'X';
                    valuetype := otFloat;
                    value := plane[0];
                    descriptivevalue := format('%f', [plane[0]]);
                  end;
                1:
                  begin
                    valuename := 'Y';
                    valuetype := otFloat;
                    value := plane[1];
                    descriptivevalue := format('%f', [plane[1]]);
                  end;
                2:
                  begin
                    valuename := 'Z';
                    valuetype := otFloat;
                    value := plane[2];
                    descriptivevalue := format('%f', [plane[2]]);
                  end;
                3:
                  begin
                    valuename := 'W';
                    valuetype := otFloat;
                    value := plane[3];
                    descriptivevalue := format('%f', [plane[3]]);
                  end;
              end;
            end
          else if (lowercase(theTypeName) = 'adrop') or (lowercase(theTypeName) = 'aspark') then
            begin
              move(FValue[start], adropspark, sizeof(adropspark));
              inc(start, sizeof(adropspark));
              case i of
                -1:
                  begin
                    if (lowercase(theTypeName) = 'adrop') then
                      z := GetKnownEnumValue('EDropType', adropspark._type)
                    else
                      z := GetKnownEnumValue('ESparkType', adropspark._type);
                    value := format('(Type=%s, Heat=%d, X=%d, Y=%d, XSpeed=%d, YSpeed=%d, Age=%d, ExpTime=%d)', [z, adropspark.heat, adropspark.x, adropspark.y, adropspark.x_speed, adropspark.y_speed, adropspark.age, adropspark.exptime]);
                    descriptivevalue := value;
                  end;
                0:
                  begin
                    valuename := 'Type';
                    value := adropspark._type;
                    valuetype := otByte;
                    if (lowercase(theTypeName) = 'adrop') then
                      valuedescription := GetKnownEnumValue('EDropType', adropspark._type)
                    else
                      valuedescription := GetKnownEnumValue('ESparkType', adropspark._type);
                    descriptivevalue := valuedescription;
                  end;
                1:
                  begin
                    valuename := 'Heat';
                    value := adropspark.heat;
                    valuetype := otByte;
                    descriptivevalue := inttostr(adropspark.heat);
                  end;
                2:
                  begin
                    valuename := 'X';
                    value := adropspark.x;
                    valuetype := otByte;
                    descriptivevalue := inttostr(adropspark.x);
                  end;
                3:
                  begin
                    valuename := 'Y';
                    value := adropspark.y;
                    valuetype := otByte;
                    descriptivevalue := inttostr(adropspark.y);
                  end;
                4:
                  begin
                    valuename := 'XSpeed';
                    value := adropspark.x_speed;
                    valuetype := otByte;
                    descriptivevalue := inttostr(adropspark.x_speed);
                  end;
                5:
                  begin
                    valuename := 'YSpeed';
                    value := adropspark.y_speed;
                    valuetype := otByte;
                    descriptivevalue := inttostr(adropspark.y_speed);
                  end;
                6:
                  begin
                    valuename := 'Age';
                    value := adropspark.age;
                    valuetype := otByte;
                    descriptivevalue := inttostr(adropspark.age);
                  end;
                7:
                  begin
                    valuename := 'ExpTime';
                    value := adropspark.exptime;
                    valuetype := otByte;
                    descriptivevalue := inttostr(adropspark.exptime);
                  end;
              end;
            end
          else
            begin
              // Search the struct in the current package or in an imported one
              int := FOwner.FindObject(utolExports, [utfwName, utfwClass], '', theTypeName, 'struct');
              if (int = -1) and FOwner.AllowReadingOtherPackages then
                begin
                  int := FOwner.FindObject(utolImports, [utfwName, utfwClass], '', theTypeName, 'struct');
                  if int <> -1 then
                    begin
                      packagedescriptor := FOwner.imported[int].UTPackageName;
                      p := pos('.', packagedescriptor);
                      if p = 0 then p := length(packagedescriptor) + 1;
                      packagefile := copy(packagedescriptor, 1, p - 1);
                      delete(packagedescriptor, 1, p);
                      newpackage := nil;
                      pkg := extractfilepath(FOwner.FPackage) + packagefile + '.u';
                      if assigned(FOwner.OnPackageNeeded) then FOwner.OnPackageNeeded(pkg);
                      if fileexists(pkg) then
                        begin
                          try
                            newpackage := TUTPackage.create(pkg);
                            int := newpackage.FindObject(utolExports, [utfwName, utfwPackage, utfwClass], packagedescriptor, theTypeName, 'struct');
                          except
                          end;
                        end;
                    end
                  else
                    newpackage := nil;
                end
              else
                newpackage := FOwner;
              if (int <> -1) and (newpackage <> nil) then
                begin
                  struct := TUTObjectClassStruct(newpackage.Exported[int].UTObject);
                  struct.ReadObject;
                  posvalue := 0;
                  pr := struct.FirstChild;
                  prcount := 0;
                  complete_descriptivevalue := '';
                  while pr <> 0 do
                    begin
                      inc(prcount);
                      prop := TUTObjectClassProperty(newpackage.Exported[pr - 1].UTObject);
                      prop.ReadObject;
                      valuename2 := prop.UTObjectName;
                      propclass := prop.UTClassName;
                      typename2 := prop.TypeName;
                      if propclass = 'ByteProperty' then
                        valuetype2 := otByte
                      else if propclass = 'IntProperty' then
                        valuetype2 := otInt
                      else if propclass = 'BoolProperty' then
                        valuetype2 := otBool
                      else if propclass = 'FloatProperty' then
                        valuetype2 := otFloat
                      else if propclass = 'ObjectProperty' then
                        valuetype2 := otObject
                      else if propclass = 'ClassProperty' then
                        valuetype2 := otClass
                      else if propclass = 'NameProperty' then
                        valuetype2 := otName
                      else if propclass = 'StrProperty' then
                        valuetype2 := otStr
                      else if propclass = 'StructProperty' then
                        valuetype2 := otStruct
                      else if propclass = 'StringProperty' then
                        valuetype2 := otString
                      else if propclass = 'MapProperty' then
                        valuetype2 := otMap
                      else if propclass = 'ArrayProperty' then
                        valuetype2 := otArray
                      else if propclass = 'FixedArrayProperty' then
                        valuetype2 := otFixedArray
                      else
                        valuetype2 := otBuffer;
                      GetPropertyValue(posvalue, -1, valuename2, descriptivevalue2, valuedescription2, value2, valuetype2, typename2);
                      pr := prop.Next;
                      prop.ReleaseObject;
                      if prcount - 1 = i then
                        begin
                          valuename := valuename2;
                          descriptivevalue := descriptivevalue2;
                          valuedescription := valuedescription2;
                          value := value2;
                          valuetype := valuetype2;
                          break;
                        end;
                      complete_descriptivevalue := complete_descriptivevalue + valuename2 + '=' + descriptivevalue2 + ', ';
                    end;
                  struct.ReleaseObject;
                  if i = -1 then
                    begin
                      descriptivevalue := '(' + copy(complete_descriptivevalue, 1, length(complete_descriptivevalue) - 2) + ')';
                      value := descriptivevalue;
                      valuetype := PropertyType;
                    end;
                end
              else
                begin
                  valuename := 'unknown';
                  value := 0;
                  valuetype := otBuffer;
                  descriptivevalue := inttostr(value);
                end;
              if newpackage <> FOwner then freeandnil(newpackage);
            end;
        end;
    else
      begin
        value := FValue;
        descriptivevalue := '';
      end;
    end;
  end;
begin
  if self = nil then exit;
  if not FIsInitialized then
    begin
      valuename := '';
      value := '0';
      descriptivevalue := '0';
      valuedescription := '';
      valuetype := otNone;
      exit;
    end;
  ds := {$IF CompilerVersion > 21.0}FormatSettings.{$IFEND}DecimalSeparator;
  {$IF CompilerVersion > 21.0}FormatSettings.{$IFEND}DecimalSeparator := '.';
  valuename := name;
  value := 0;
  descriptivevalue := '';
  valuedescription := '';
  valuetype := PropertyType;
  posvalue := 0;
  GetPropertyValue(posvalue, i, valuename, descriptivevalue, valuedescription, value, valuetype, FTypename);
  {$IF CompilerVersion > 21.0}FormatSettings.{$IFEND}DecimalSeparator := ds;
end;

function TUTProperty.GetValueCount: integer;
var
  struct: TUTObjectClassStruct;
  prop: TUTObjectClassProperty;
  pr, prcount, int: integer;
begin
  if not FIsInitialized then
    begin
      result := 0;
      exit;
    end;
  case PropertyType of
    otNone: result := 0;
    otStruct:
      begin
        if lowercase(FTypeName) = 'color' then
          result := 4
        else if lowercase(FTypeName) = 'vector' then
          result := 3
        else if lowercase(FTypeName) = 'pointregion' then
          result := 3
        else if lowercase(FTypeName) = 'rotator' then
          result := 3
        else if lowercase(FTypeName) = 'scale' then
          result := 5
        else if lowercase(FTypeName) = 'plane' then
          result := 4
        else if lowercase(FTypeName) = 'sphere' then
          result := 4
        else if lowercase(FTypeName) = 'adrop' then
          result := 8
        else if lowercase(FTypeName) = 'aspark' then
          result := 8
        else
          begin
            // Search the struct in the current package
            int := FOwner.FindObject(utolExports, [utfwName, utfwClass], '', FTypeName, 'struct');
            if int <> -1 then
              begin
                struct := TUTObjectClassStruct(FOwner.Exported[int].UTObject);
                struct.ReadObject;
                pr := struct.FirstChild;
                prcount := 0;
                while pr <> 0 do
                  begin
                    inc(prcount);
                    prop := TUTObjectClassProperty(FOwner.Exported[pr - 1].UTObject);
                    prop.ReadObject;
                    pr := prop.Next;
                    prop.ReleaseObject;
                  end;
                struct.ReleaseObject;
                result := prcount;
              end
            else
              begin
                int := FOwner.FindObject(utolImports, [utfwName, utfwClass], '', FTypeName, 'struct');
                if int <> -1 then
                  begin
                    result := 0;
                  end
                else
                  begin
                    result := 0;
                  end;
              end
          end;
      end
  else
    result := 0;
  end;
end;

procedure TUTProperty.SetProperty(Owner: TUTPackage; n: string; i: integer;
  t: TUTPropertyType; var value; valuesize: integer; typename: string);
begin
  FOwner := owner;
  FName := n;
  FArrayIndex := i;
  FPropertyType := t;
  setlength(FValue, valuesize);
  if valuesize > 0 then move(value, FValue[0], valuesize);
  FTypeName := typename;
  FIsInitialized := true;
end;

function TUTProperty.GetDescriptiveValue: string;
var
  name: string;
  value: variant;
  _type: TUTPropertyType;
begin
  GetValue(-1, name, value, result, _type);
end;

procedure TUTProperty.SetOwnerObject(ownerobject: TUTObject);
begin
  FOwnerObject := ownerobject;
end;

{ TUTPropertyList }

constructor TUTPropertyList.Create;
begin
  FProperties := tlist.create;
end;

destructor TUTPropertyList.Destroy;
begin
  Clear;
  FProperties.free;
end;

procedure TUTPropertyList.Clear;
var
  a: integer;
begin
  for a := 0 to FProperties.count - 1 do
    TUTProperty(FProperties[a]).free;
  FProperties.clear;
end;

function TUTPropertyList.GetProperty(i: integer): TUTProperty;
begin
  try
    result := FProperties[i];
  except
    result := nil;
  end;
end;

function TUTPropertyList.GetPropertyCount: integer;
begin
  result := FProperties.count;
end;

function TUTPropertyList.NewProperty: TUTProperty;
begin
  FProperties.add(TUTProperty.create);
  result := FProperties[FProperties.count - 1];
end;

function TUTPropertyList.GetPropertyByName(name: string): TUTProperty;
var
  a, arrayindex: integer;
begin
  result := nil;
  name := lowercase(name);
  a := pos('[', name);
  if a = 0 then
    arrayindex := -1
  else
    begin
      arrayindex := strtointdef(copy(name, a + 1, length(name) - a - 1), 0);
      name := copy(name, 1, a - 1);
    end;
  a := 0;
  while a < FProperties.count do
    if (lowercase(TUTProperty(FProperties[a]).name) = name) and
      (TUTProperty(FProperties[a]).arrayindex = arrayindex) then
      begin
        result := FProperties[a];
        break;
      end
    else
      inc(a);
end;

function TUTPropertyList.GetPropertyListDescriptions: string;
var
  a: integer;
begin
  result := '';
  for a := 0 to FProperties.count - 1 do
    result := result + #1 + TUTProperty(FProperties[a]).Description;
  delete(result, 1, 1);
end;

procedure TUTPropertyList.FixArrayIndices;
var
  a, b: integer;
  more: boolean;
  function PropertyIsArray(const name: string): boolean;
  var
    a: integer;
  const
    // TODO : make array properties list global and complete them
    arrayprops: array[0..22] of string =
    ('paths', 'visnoreachpaths', 'upstreampaths', 'prunedpaths', 'aiprofile',
      'multiskins', 'lensaflare', 'lensflareoffset', 'lensflarescale', 'delay',
      'gain', 'outevents', 'outdelays', 'objshots', 'objdesc', 'damageevent',
      'damageeventthreshold', 'tags', 'events', 'opentimes', 'closetimes',
      'splats', 'internaltime');
  begin
    result := false;
    for a := 0 to high(arrayprops) do
      if arrayprops[a] = name then
        begin
          result := true;
          break;
        end;
  end;
begin
  // fix array index of first elements
  for a := 0 to FProperties.Count - 1 do
    if (PropertyByPosition[a].ArrayIndex = -1) then
      begin
        more := PropertyIsArray(PropertyByPosition[a].Name);
        if not more then
          for b := 0 to FProperties.Count - 1 do
            begin
              if (a <> b) and (PropertyByPosition[b].Name = PropertyByPosition[a].Name) then
                begin
                  more := true;
                  break;
                end;
            end;
        if more then PropertyByPosition[a].FArrayIndex := 0;
      end;
end;

function TUTPropertyList.GetPropertyByNameValue(name: string): variant;
var
  p: TUTProperty;
begin
  p := GetPropertyByName(name);
  if p = nil then
    result := 0
  else
    result := p.value;
end;

function TUTPropertyList.GetPropertyValue(i: integer): variant;
var
  p: TUTProperty;
begin
  p := GetProperty(i);
  if p = nil then
    result := 0
  else
    result := p.value;
end;

function TUTPropertyList.GetPropertyByNameValueDefault(name: string;
  adefault: variant): variant;
var
  p: TUTProperty;
begin
  p := GetPropertyByName(name);
  if p = nil then
    result := adefault
  else
    result := p.value;
end;

function TUTPropertyList.GetPropertyValueDefault(i: integer;
  adefault: variant): variant;
var
  p: TUTProperty;
begin
  p := GetProperty(i);
  if p = nil then
    result := adefault
  else
    result := p.value;
end;

{ TUTPackage }

procedure TUTPackage.read_buffer(var buffer; const size: integer; stream: tstream);
begin
  if stream = nil then stream := Fstr;
  fillchar(buffer, size, 0);
  stream.ReadBuffer(buffer, size);
end;

function TUTPackage.read_asciiz(stream: tstream): string;
var
  b: byte;
begin
  result := '';
  repeat
    b := read_byte(stream);
    if b <> 0 then result := result + chr(b);
  until b = 0;
end;

function TUTPackage.read_sizedascii(stream: tstream): string;
var
  namesize: byte;
begin
  namesize := read_idx(stream);
  setlength(result, namesize);
  read_buffer(result[1], namesize, stream);
end;

function TUTPackage.read_sizedasciiz(stream: tstream): string;
begin
  result := read_sizedascii(stream);
  setlength(result, length(result) - 1);
end;

function TUTPackage.read_doublesizedasciiz(stream: tstream): string;
begin
  read_idx(stream);                     // tamaño
  result := read_sizedasciiz(stream);
end;

function TUTPackage.read_int(stream: tstream): integer;
begin
  if stream = nil then stream := Fstr;
  stream.ReadBuffer(result, 4);
end;

function TUTPackage.read_word(stream: tstream): word;
begin
  if stream = nil then stream := Fstr;
  stream.ReadBuffer(result, 2);
end;

function TUTPackage.read_byte(stream: tstream): byte;
begin
  if stream = nil then stream := Fstr;
  stream.ReadBuffer(result, 1);
end;

function TUTPackage.read_bool(stream: tstream): boolean;
var
  src: word;
begin
  if stream = nil then stream := Fstr;
  stream.ReadBuffer(src, 2);            // first byte=D3 (?), second byte=0 for True?
  result := ((src shr 8) = 0);
end;

function TUTPackage.read_float(stream: tstream): single;
begin
  if stream = nil then stream := Fstr;
  stream.ReadBuffer(result, 4);
end;

function TUTPackage.read_idx(stream: tstream): integer;
var
  b0, b1, b2, b3, b4: byte;
begin
  result := 0;
  b0 := read_byte(stream);
  if (b0 and $40) <> 0 then
    begin
      b1 := read_byte(stream);
      if (b1 and $80) <> 0 then
        begin
          b2 := read_byte(stream);
          if (b2 and $80) <> 0 then
            begin
              b3 := read_byte(stream);
              if (b3 and $80) <> 0 then
                begin
                  b4 := read_byte(stream);
                  result := b4;
                end;
              result := (result shl 7) or (b3 and $7F);
            end;
          result := (result shl 7) or (b2 and $7F);
        end;
      result := (result shl 7) or (b1 and $7F);
    end;
  result := (result shl 6) or (b0 and $3F);
  if (b0 and $80) <> 0 then result := -result;
end;

function TUTPackage.Read_Name(stream: tstream): string;
begin
  if FVersion >= 64 then
    begin
      result := Read_SizedASCII(stream);
      setlength(result, length(result) - 1); // remove ending #0
    end
  else
    begin
      result := Read_ASCIIZ(stream);
    end;
end;

function TUTPackage.GetObjectFlagsText(const e: cardinal): string;
begin
  result := '';
  // TODO : add support for unknown flag bits
  if (e and RF_LoadForClient) <> 0 then result := result + ', RF_LoadForClient';
  if (e and RF_NotForClient) <> 0 then result := result + ', RF_NotForClient';
  if (e and RF_LoadForServer) <> 0 then result := result + ', RF_LoadForServer';
  if (e and RF_NotForServer) <> 0 then result := result + ', RF_NotForServer';
  if (e and RF_LoadForEdit) <> 0 then result := result + ', RF_LoadForEdit';
  if (e and RF_NotForEdit) <> 0 then result := result + ', RF_NotForEdit';
  if (e and RF_Public) <> 0 then result := result + ', RF_Public';
  if (e and RF_Standalone) <> 0 then result := result + ', RF_Standalone';
  if (e and RF_Native) <> 0 then result := result + ', RF_Native';
  if (e and RF_SourceModified) <> 0 then result := result + ', RF_SourceModified';
  if (e and RF_Transactional) <> 0 then result := result + ', RF_Transactional';
  if (e and RF_HasStack) <> 0 then result := result + ', RF_HasStack';
  if (e and RF_Transient) <> 0 then result := result + ', RF_Transient';
  if (e and RF_Unreachable) <> 0 then result := result + ', RF_Unreachable';
  if (e and RF_TagImp) <> 0 then result := result + ', RF_TagImp';
  if (e and RF_TagExp) <> 0 then result := result + ', RF_TagExp';
  if (e and RF_TagGarbage) <> 0 then result := result + ', RF_TagGarbage';
  if (e and RF_NeedLoad) <> 0 then result := result + ', RF_NeedLoad';
  if (e and RF_HighlightedName) <> 0 then result := result + ', RF_HighlightedName';
  if (e and RF_InSingularFunc) <> 0 then result := result + ', RF_InSingularFunc';
  if (e and RF_Suppress) <> 0 then result := result + ', RF_Suppress';
  if (e and RF_InEndState) <> 0 then result := result + ', RF_InEndState';
  if (e and RF_PreLoading) <> 0 then result := result + ', RF_PreLoading';
  if (e and RF_Destroyed) <> 0 then result := result + ', RF_Destroyed';
  if (e and RF_NeedPostLoad) <> 0 then result := result + ', RF_NeedPostLoad';
  if (e and RF_Marked) <> 0 then result := result + ', RF_Marked';
  if (e and RF_ErrorShutdown) <> 0 then result := result + ', RF_ErrorShutdown';
  if (e and RF_DebugPostLoad) <> 0 then result := result + ', RF_DebugPostLoad';
  if (e and RF_DebugSerialize) <> 0 then result := result + ', RF_DebugSerialize';
  if (e and RF_DebugDestroy) <> 0 then result := result + ', RF_DebugDestroy';

  if (e and RF_Unk_00000080) <> 0 then result := result + ', RF_Unk_00000080';
  if (e and RF_Unk_00000100) <> 0 then result := result + ', RF_Unk_00000100';

  if result <> '' then delete(result, 1, 1);
end;

function TUTPackage.GetObjectPath(limit, index: integer): string;
var
  i: TUTImportTableObjectData;
  e: TUTExportTableObjectData;
  s: string;
begin
  result := '';
  while limit <> 0 do
    begin
      if index = 0 then
        break
      else if index < 0 then
        begin
          if - index - 1 < Fimporttablelist.count then
            begin
              i := TUTImportTableObjectData(Fimporttablelist[-index - 1]);
              s := Fnametablelist[i.UTObjectIndex] + '.';
              index := i.UTpackageindex;
            end
          else
            begin
              s := '';
              result := '';
              limit := 1;
            end;
        end
      else if index > 0 then
        begin
          if index - 1 < Fexporttablelist.count then
            begin
              e := TUTExportTableObjectData(Fexporttablelist[index - 1]);
              s := Fnametablelist[e.UTObjectIndex] + '.';
              index := e.UTpackageindex;
            end
          else
            begin
              s := '';
              result := '';
              limit := 1;
            end;
        end;
      result := s + result;
      dec(limit);
    end;
  if copy(result, length(result), 1) = '.' then setlength(result, length(result) - 1);
end;

procedure TUTPackage.Process;
var
  name: string;
  int, i: integer;
  lw, namecount, nameoffset, exportcount, exportoffset, importcount, importoffset,
    heritagecount, heritageoffset: cardinal;
  guid: TGUID;
  id: TUTImportTableObjectData;
  ed: TUTExportTableObjectData;
  maxposition, position: integer;
begin
  try
    maxposition := 100;
    try
      DoOnProgress(0, 100);
      StartReadingPackage;
      lw := cardinal(read_int(Fstr));
      if lw <> $9E2A83C1 then raise exception.create(rsErrorNoUTPackage);
      FVersion := read_word(Fstr);
      FLicenseeMode := read_word(FStr);
      FFlags := read_int(Fstr);
      namecount := read_int(Fstr);
      nameoffset := read_int(Fstr);
      exportcount := read_int(Fstr);
      exportoffset := read_int(Fstr);
      importcount := read_int(Fstr);
      importoffset := read_int(Fstr);
      setlength(Fheritagetablelist, 0);
      if FVersion < 68 then
        begin
          heritagecount := read_int(Fstr);
          heritageoffset := read_int(Fstr);
        end
      else
        begin
          heritagecount := 1;
          heritageoffset := Fstr.Position;
          guid := read_guid(Fstr);      // will be read again below
          int := read_int(Fstr);
          setlength(FGenerationInfo, int);
          for i := 0 to int - 1 do
            begin
              FGenerationInfo[i].exportcount := read_int(Fstr); // number of exports
              FGenerationInfo[i].namecount := read_int(Fstr); // number of names
            end;
        end;
      maxposition := namecount + exportcount {* 2} + importcount + heritagecount;
      position := 0;
      // name table
      Seek(nameoffset);
      Fnametablelist.clear;
      for i := 1 to namecount do
        begin
          name := Read_Name(Fstr);
          int := read_int(Fstr);
          Fnametablelist.AddObject(name, pointer(int));
          inc(position);
          DoOnProgress(position, maxposition);
        end;
      // export table
      Seek(exportoffset);
      for i := 0 to Fexporttablelist.count - 1 do
        TUTExportTableObjectData(Fexporttablelist[i]).free;
      Fexporttablelist.clear;
      for i := 1 to exportcount do
        begin
          ed := TUTExportTableObjectData.create;
          ed.Owner := self;
          ed.ExportedIndex := i - 1;
          ed.UTClassIndex := read_idx(Fstr); // class index
          ed.UTSuperIndex := read_idx(Fstr); // super index
          ed.UTPackageIndex := read_int(Fstr); // package index
          ed.UTObjectIndex := read_idx(Fstr); // object name
          ed.Flags := read_int(Fstr);   // object flags
          ed.SerialSize := read_idx(Fstr); // serial size
          if ed.SerialSize > 0 then
            ed.SerialOffset := read_idx(Fstr) // serial offset
          else
            ed.SerialOffset := 0;
          FExportTableList.add(ed);
          inc(position);
          DoOnProgress(position, maxposition);
        end;
      // import table
      Seek(importoffset);
      for i := 0 to Fimporttablelist.count - 1 do
        TUTImportTableObjectData(Fimporttablelist[i]).free;
      Fimporttablelist.clear;
      for i := 1 to importcount do
        begin
          id := TUTImportTableObjectData.create;
          id.Owner := self;
          id.UTClassPackageIndex := read_idx(Fstr); // ClassPackage
          id.UTClassIndex := read_idx(Fstr); // ClassName
          id.UTPackageIndex := read_int(Fstr); // PackageIndex
          id.UTObjectIndex := read_idx(Fstr); // ObjectName
          Fimporttablelist.add(id);
          inc(position);
          DoOnProgress(position, maxposition);
        end;
      {if FVersion < 68 then
        begin}
          // heritage table
      Seek(heritageoffset);
      setlength(Fheritagetablelist, heritagecount);
      for i := 0 to heritagecount - 1 do
        begin
          guid := read_guid(Fstr);
          Fheritagetablelist[i] := guid;
          inc(position);
          DoOnProgress(position, maxposition);
        end;
      {end;}

      {for i := 0 to Fexporttablelist.count - 1 do
        begin
          ed := TUTExportTableObjectData(Fexporttablelist[i]);
          ed.CreateObject;
          //ed.UTObject := GetUTObjectClass(ed.UTclassname).create(self, i);
          inc(position);
          DoOnProgress(position, maxposition);
        end;}

    finally
      EndReadingPackage;
      DoOnProgress(maxposition, maxposition);
    end;
  except
    on e: exception do raise exception.create(format(rsExceptionProcessingPackage, [FPackage, e.message]));
  end;
end;

procedure TUTPackage.StartReadingPackage;
begin
  if (FReadingPackageCount = 0) then
    begin
      if not fileexists(FPackage) and assigned(FOnPackageNeeded) then FOnPackageNeeded(FPackage);
      Fstr := tfilestream.create(FPackage, fmOpenRead + fmShareDenyNone);
    end;
  inc(FReadingPackageCount);
end;

procedure TUTPackage.EndReadingPackage;
begin
  if FReadingPackageCount > 0 then
    begin
      dec(FReadingPackageCount);
      if (FReadingPackageCount = 0) then
        begin
          Fstr.free;
          Fstr := nil;
        end;
    end;
end;

function TUTPackage.ReadProperty(prop: TUTProperty; stream: tstream): boolean;
var
  n, nlc, struct, nstruct: string;
  b: integer;
  infobyte, info_type, info_size, index_b, index_c, index_d, index_e: byte; index, v, size: integer;
  info_array: boolean;
  buffer: array of byte;
  f: single;
begin
  n := '<unknown>';
  try
    setlength(buffer, 256);
    b := read_idx(stream);
    n := inttostr(b);
    n := Fnametablelist[b];
    nlc := lowercase(n);
    index := -1;
    if nlc <> 'none' then               // do not localize properties names and types
      begin
        infobyte := read_byte(stream);
        info_type := infobyte and $0F;
        info_size := (infobyte shr 4) and 7;
        info_array := ((infobyte and $80) <> 0);

        if info_type = otStruct then
          begin
            struct := Fnametablelist[read_idx(stream)];
            nstruct := lowercase(struct);
          end;

        case info_size of
          0: size := 1;
          1: size := 2;
          2: size := 4;
          3: size := 12;
          4: size := 16;
          5: size := read_byte(stream);
          6: size := read_word(stream);
          7:
            size := read_int(stream)
        else
          size := 0;
        end;

        if info_array and (info_type <> otBool) then
          begin
            index_b := read_byte(stream);
            if (index_b and $80) = 0 then
              index := index_b
            else if (index_b and $C0) = $80 then
              begin
                index_c := read_byte(stream);
                index := ((index_b and $7F) shl 8) or index_c;
              end
            else
              begin
                index_c := read_byte(stream);
                index_d := read_byte(stream);
                index_e := read_byte(stream);
                index := ((index_b and $3F) shl 24) or (index_c shl 16) or (index_d shl 8) or index_e;
              end;
          end;

        case info_type of
          otByte:                       // Byte
            begin
              v := read_byte(stream);
              prop.SetProperty(self, n, index, otByte, v, 1);
            end;
          otInt:                        // Integer
            begin
              v := read_int(stream);
              prop.SetProperty(self, n, index, otInt, v, 4);
            end;
          otBool:                       // Boolean
            begin
              if info_array then
                v := 1
              else
                v := 0;
              prop.SetProperty(self, n, index, otBool, v, 4);
            end;
          otFloat:                      // Float
            begin
              f := read_float(stream);
              prop.SetProperty(self, n, index, otFloat, f, 4);
            end;
          otObject:                     // Object Reference
            begin
              v := read_idx(stream);
              prop.SetProperty(self, n, index, otObject, v, 4);
            end;
          otName:                       // Name Reference (Tag)
            begin
              v := read_idx(stream);
              prop.SetProperty(self, n, index, otName, v, 4);
            end;
          otString:
            begin
              setlength(buffer, size);
              read_buffer(buffer[0], size, stream);
              prop.SetProperty(self, n, index, otString, buffer[0], size);
            end;
          {
          otClass:
          otArray:
          }
          otStruct:                     // Struct
            begin
              if size = 0 then
                setlength(buffer, 256)
              else
                setlength(buffer, size);
              if nstruct = 'pointregion' then
                begin
                  // use a buffer because it contains indices and so the size is not fixed
                  size := 12;           // override size
                  setlength(buffer, size);
                  b := read_idx(stream);
                  move(b, buffer[0], 4);
                  b := read_int(stream);
                  move(b, buffer[4], 4);
                  b := read_idx(stream);
                  move(b, buffer[8], 4);
                end
              else
                read_buffer(buffer[0], size, stream);
              prop.SetProperty(self, n, index, otStruct, buffer[0], size, struct);
            end;
          {
          otVector:
          otRotator:
          }
          otStr:                        // Str
            begin
              v := read_idx(stream);    // length including #0
              setlength(buffer, v);
              read_buffer(buffer[0], v, stream);
              prop.SetProperty(self, n, index, otStr, buffer[0], v);
            end
            {
            otMap:
            otFixedArray:
            }
        else
          begin                         // Unknown type
            if size > sizeof(buffer) then
              read_buffer(buffer[0], sizeof(buffer), stream)
            else
              read_buffer(buffer[0], size, stream);
            prop.SetProperty(self, n, index, otBuffer, v, 0, format(rsUnknownPropertyType, [info_type]));
            result := false;
            exit;
          end;
        end;
      end
    else
      prop.SetProperty(self, n, index, otNone, v, 0);
    result := (nlc <> 'none');
  except
    on e: exception do raise exception.create(format(rsExceptionReadingProperty, [n]));
  end;
end;

constructor TUTPackage.Create(package: string = '');
begin
  FNameTablelist := tstringlist.create;
  FImportTablelist := tlist.create;
  FExportTablelist := tlist.create;
  setlength(FHeritageTableList, 0);
  FReadingPackageCount := 0;
  setlength(FGenerationInfo, 0);
  Fstr := nil;
  FAllowReadingOtherPackages := true;
  FOnGetStringConst := nil;
  FOnGetUnicodeStringConst := nil;
  FEnumCache := tstringlist.create;
  if package <> '' then
    begin
      FPackage := package;
      Process;
    end;
end;

destructor TUTPackage.Destroy;
var
  a: integer;
begin
  EndReadingPackage;
  Fnametablelist.free;
  for a := 0 to Fexporttablelist.count - 1 do
    TUTExportTableObjectData(Fexporttablelist[a]).free;
  Fexporttablelist.free;
  for a := 0 to Fimporttablelist.count - 1 do
    TUTImportTableObjectData(Fimporttablelist[a]).free;
  Fimporttablelist.free;
  setlength(FHeritageTableList, 0);
  setlength(FGenerationInfo, 0);
  FEnumCache.free;
  inherited;
end;

function TUTPackage.GetName(i: integer): string;
begin
  if (i >= 0) and (i < FNameTableList.count) then
    result := FNameTableList[i]
  else
    result := '';
end;

function TUTPackage.GetExport(i: integer): TUTExportTableObjectData;
begin
  if (i >= 0) and (i < FExportTableList.count) then
    result := TUTExportTableObjectData(FExportTableList[i])
  else
    result := nil;
end;

function TUTPackage.GetImport(i: integer): TUTImportTableObjectData;
begin
  if (i >= 0) and (i < FImportTableList.count) then
    result := TUTImportTableObjectData(FImportTableList[i])
  else
    result := nil;
end;

function TUTPackage.GetHeritage(i: integer): TGUID;
begin
  if (i >= 0) and (i < length(FHeritageTableList)) then
    result := FHeritageTableList[i]
  else
    fillchar(result, sizeof(TGUID), 0);
end;

procedure TUTPackage.Seek(p: integer);
begin
  Fstr.seek(p, soFromBeginning);
end;

procedure TUTPackage.Initialize(package: string);
var
  a: integer;
begin
  ReleaseAllObjects;

  EndReadingPackage;
  Fnametablelist.clear;
  for a := 0 to Fexporttablelist.count - 1 do
    TUTExportTableObjectData(Fexporttablelist[a]).free;
  Fexporttablelist.clear;
  for a := 0 to Fimporttablelist.count - 1 do
    TUTImportTableObjectData(Fimporttablelist[a]).free;
  Fimporttablelist.clear;
  setlength(FHeritageTableList, 0);
  setlength(FGenerationInfo, 0);
  FEnumCache.clear;

  FPackage := package;
  Process;
end;

function TUTPackage.GetNameFlags(i: integer): integer;
begin
  if (i >= 0) and (i < FNameTableList.count) then
    result := integer(Fnametablelist.objects[i])
  else
    result := 0;
end;

function TUTPackage.GetExportCount: integer;
begin
  result := FExportTableList.count;
end;

function TUTPackage.GetHeritageCount: integer;
begin
  result := length(FHeritageTableList);
end;

function TUTPackage.GetImportCount: integer;
begin
  result := FImportTableList.count;
end;

function TUTPackage.GetNameCount: integer;
begin
  result := FNameTableList.count;
end;

procedure TUTPackage.SaveDataBlock(filename: string; position, size: integer);
var
  str2: tfilestream;
begin
  Seek(position);
  str2 := tfilestream.create(filename, fmCreate);
  try
    str2.CopyFrom(Fstr, size);
  finally
    str2.free;
  end;
end;

function TUTPackage.GetPackagePosition: integer;
begin
  result := Fstr.position;
end;

function TUTPackage.GetStream: TStream;
begin
  result := Fstr;
end;

function TUTPackage.GetExportIndex(objectname, classname: string): integer;
var
  a: integer;
  found: boolean;
  ed: TUTExportTableObjectData;
begin
  a := 0;
  found := false;
  objectname := lowercase(objectname);
  classname := lowercase(classname);
  while not found and (a < Fexporttablelist.count) do
    begin
      ed := TUTExportTableObjectData(Fexporttablelist[a]);
      if (lowercase(ed.UTobjectname) = objectname) and (lowercase(ed.UTclassname) = classname) then
        found := true
      else
        inc(a);
    end;
  if found then
    result := a
  else
    result := -1;
end;

function TUTPackage.GetNameIndex(objectname: string): integer;
begin
  result := Fnametablelist.indexof(objectname);
end;

function TUTPackage.EncodeIndex(i: integer): string;
var
  v: integer;
  b0, b1, b2, b3, b4: byte;
begin
  result := '';
  v := abs(i);
  if i >= 0 then
    b0 := 0
  else
    b0 := $80;
  if v < $40 then
    b0 := b0 + v
  else
    b0 := b0 + $40 + (v and $3F);
  result := result + chr(b0);
  if (b0 and $40) <> 0 then
    begin
      v := v shr 6;
      if v < $80 then
        b1 := v
      else
        b1 := (v and $7F) + $80;
      result := result + chr(b1);
      if (b1 and $80) <> 0 then
        begin
          v := v shr 7;
          if v < $80 then
            b2 := v
          else
            b2 := (v and $7F) + $80;
          result := result + chr(b2);
          if (b2 and $80) <> 0 then
            begin
              v := v shr 7;
              if v < $80 then
                b3 := v
              else
                b3 := (v and $7F) + $80;
              result := result + chr(b3);
              if (b3 and $80) <> 0 then
                begin
                  v := v shr 7;
                  b4 := v;
                  result := result + chr(b4);
                end;
            end;
        end;
    end;
end;

function TUTPackage.FindObject(where: TUTPackageObjectLocations; what: TUTPackageFindWhatSet;
  packagename, objectname, classname: string; start: integer): integer;
var
  a: integer;
  ok: boolean;
begin
  objectname := lowercase(objectname);
  packagename := lowercase(packagename);
  classname := lowercase(classname);
  case where of
    utolNames:
      begin
        a := start;
        result := -1;
        while (a < FNameTableList.count) and (result = -1) do
          if (lowercase(FNameTableList[a]) = objectname) then
            result := a
          else
            inc(a);
      end;
    utolExports:
      begin
        a := start;
        result := -1;
        while (a < ExportedCount) and (result = -1) do
          begin
            ok := true;
            if (utfwName in what) then
              ok := ok and (lowercase(Exported[a].UTObjectName) = objectname);
            if (utfwClass in what) then
              ok := ok and (lowercase(Exported[a].UTClassName) = classname);
            if (utfwPackage in what) then
              ok := ok and (lowercase(Exported[a].UTPackageName) = packagename);
            if ok then
              result := a
            else
              inc(a);
          end;
      end;
    utolImports:
      begin
        a := start;
        result := -1;
        while (a < ImportedCount) and (result = -1) do
          begin
            ok := true;
            if (utfwName in what) then
              ok := ok and (lowercase(Imported[a].UTObjectName) = objectname);
            if (utfwClass in what) then
              ok := ok and (lowercase(Imported[a].UTClassName) = classname);
            if (utfwPackage in what) then
              ok := ok and (lowercase(Imported[a].UTPackageName) = packagename);
            if ok then
              result := a
            else
              inc(a);
          end;
      end
  else
    result := -1;
  end;
end;

procedure TUTPackage.ReadAllObjects;
var
  a, b: integer;
begin
  b := ExportedCount - 1;
  DoOnProgress(0, b);
  for a := 0 to b do
    begin
      Exported[a].UTObject.ReadObject;
      DoOnProgress(a, b);
    end;
end;

procedure TUTPackage.ReleaseAllObjects;
var
  a, b: integer;
begin
  b := ExportedCount - 1;
  //DoOnProgress(0, b);
  for a := 0 to b do
    begin
      if Exported[a].UTObject.HasBeenRead then Exported[a].UTObject.ReleaseObject;
      //DoOnProgress(a, b);
    end;
end;

procedure TUTPackage.DoOnProgress(position, maxposition: integer);
begin
  if assigned(FOnProgress) then
    if maxposition = 0 then
      FOnProgress(self, 0)
    else
      FOnProgress(self, position * 100 div maxposition);
end;

function TUTPackage.GetGeneration(i: integer): TUTPackage_GenerationInfo;
begin
  result := FGenerationInfo[i];
end;

function TUTPackage.GetGenerationCount: integer;
begin
  result := length(FGenerationInfo);
end;

function TUTPackage.IndentText(indent, txt: string): string;
var
  str: tstringlist;
  a: integer;
  ending_crlf: boolean;
begin
  ending_crlf := (copy(txt, length(txt) - 1, 2) = #13#10);
  str := tstringlist.create;
  str.text := txt;
  for a := 0 to str.count - 1 do
    str[a] := indent + str[a];
  result := str.text;
  str.free;
  if not ending_crlf then delete(result, length(result) - 1, 2);
end;

function TUTPackage.read_qword(stream: tstream): int64;
begin
  result := read_int(stream);
  result := result shl 32;
  result := result or read_int(stream);
end;

function TUTPackage.read_guid(stream: tstream): TGuid;
begin
  read_buffer(result, sizeof(result), stream);
end;

function TUTPackage.GetInitialized: boolean;
begin
  result := (FNameTableList.count > 0);
end;

procedure TUTPackage.SetName(i: integer; const Value: string);
begin
  FNameTableList[i] := value;
end;

function TUTPackage.GetStringConst(s: string): string;
begin
  if assigned(FOnGetStringConst) then
    result := FOnGetStringConst(s)
  else
    result := '"' + s + '"';
end;

function TUTPackage.GetUnicodeStringConst(s: widestring): widestring;
begin
  if assigned(FOnGetUnicodeStringConst) then
    result := FOnGetUnicodeStringConst(s)
  else
    result := '"' + s + '"';
end;

{ TUTObject }

constructor TUTObject.create(owner: TUTPackage; exportedindex: integer);
begin
  FOwner := owner;
  FExportedIndex := exportedindex;
  Buffer := nil;
  FProperties := TUTPropertyList.create;
  InitializeObject;
end;

destructor TUTObject.destroy;
begin
  ReleaseObject;
  FProperties.free;
  inherited;
end;

procedure TUTObject.ReadObject(interpret: boolean);
var
  p: integer;
begin
  inc(FReadCount);
  if not FHasBeenRead or (interpret and not FHasBeenInterpreted) then
    begin
      FOwner.StartReadingPackage;
      try
        if not FHasBeenRead then
          begin
            buffer := TMemoryStream.create;
            p := FOwner.Position;
            FStartInPackage := UTSerialOffset;
            FOwner.Seek(FStartInPackage);
            if UTSerialSize > 0 then
              buffer.CopyFrom(FOwner.GetStream, UTSerialSize);
            FOwner.Seek(p);
            buffer.Seek(0, soFromBeginning);
            FHasBeenRead := true;
          end;
        if interpret and (buffer.size > 0) then
          begin
            InitializeObject;
            InterpretObject;
            buffer.Seek(0, soFromBeginning);
            FHasBeenInterpreted := true;
          end;
      finally
        FOwner.EndReadingPackage;
      end;
    end;
end;

procedure TUTObject.ReleaseObject;
begin
  dec(FReadCount);
  if FReadCount = 0 then
    begin
      if FHasBeenRead then DoReleaseObject;
      FHasBeenRead := false;
      FHasBeenInterpreted := false;
    end;
end;

procedure TUTObject.InitializeObject;
begin
  FProperties.clear;
end;

procedure TUTObject.InterpretObject;
var
  node: integer;
begin
  if (UTFlags and RF_HasStack) <> 0 then
    begin
      node := FOwner.read_idx(buffer);  // StateFrame.Node
      FOwner.read_idx(buffer);          // StateFrame.StateNode
      FOwner.read_qword(buffer);        // StateFrame.ProbeMask
      FOwner.read_int(buffer);          // StateFrame.LatentAction
      if node <> 0 then FOwner.read_idx(buffer); // Offset
    end;
  if UTClassIndex <> 0 then ReadProperties;
end;

procedure TUTObject.ReadProperties;
var
  more: boolean;
  prop: TUTProperty;
begin
  repeat
    prop := FProperties.New;
    prop.setownerobject(self);
    more := FOwner.ReadProperty(prop, buffer);
  until not more;
  FProperties.FixArrayIndices;
end;

function TUTObject.GetClassName: string;
begin
  result := FOwner.Exported[FExportedIndex].UTClassName;
end;

function TUTObject.GetObjectname: string;
begin
  result := FOwner.Exported[FExportedIndex].UTObjectName;
end;

function TUTObject.GetClassIndex: integer;
begin
  result := FOwner.Exported[FExportedIndex].UTClassIndex;
end;

function TUTObject.GetObjectIndex: integer;
begin
  result := FOwner.Exported[FExportedIndex].UTObjectIndex;
end;

function TUTObject.GetPackageIndex: integer;
begin
  result := FOwner.Exported[FExportedIndex].UTPackageIndex;
end;

function TUTObject.GetPackageName: string;
begin
  result := FOwner.Exported[FExportedIndex].UTPackageName;
end;

function TUTObject.GetSuperIndex: integer;
begin
  result := FOwner.Exported[FExportedIndex].UTSuperIndex;
end;

function TUTObject.GetSuperName: string;
begin
  result := FOwner.Exported[FExportedIndex].UTSuperName;
end;

function TUTObject.GetSerialOffset: integer;
begin
  result := FOwner.Exported[FExportedIndex].SerialOffset;
end;

function TUTObject.GetSerialSize: integer;
begin
  result := FOwner.Exported[FExportedIndex].SerialSize;
end;

function TUTObject.GetFlags: longword;
begin
  result := FOwner.Exported[FExportedIndex].Flags;
end;

procedure TUTObject.check_initialized;
begin
  assert(buffer <> nil, UTObjectName + ': ReadObject was not called for this object!');
  {if buffer = nil then
    raise exception.create(UTObjectName + ': ReadObject was not called for this object!');}
  // could also make the ReadObject call, but the programmer would not release the object
end;

function TUTObject.GetProperties: TUTPropertyList;
begin
  check_initialized;
  result := FProperties;
end;

function TUTObject.GetFullName: string;
begin
  result := FOwner.GetObjectPath(-1, FExportedIndex + 1);
end;

function TUTObject.GetPosition: integer;
begin
  result := buffer.position;
end;

procedure TUTObject.SetPosition(const Value: integer);
begin
  buffer.seek(value, soFromBeginning);
end;

procedure TUTObject.RawSaveToFile(filename: string);
begin
  buffer.SaveToFile(filename);
end;

procedure TUTObject.RawSaveToStream(stream: TStream);
begin
  buffer.SaveToStream(stream);
end;

procedure TUTObject.DoReleaseObject;
begin
  FreeAndNil(buffer);
  FProperties.clear;
end;

function TUTObject.GetOwner: TUTPackage;
begin
  result := FOwner;
end;

{ TUTObjectClassPalette }

function TUTObjectClassPalette.GetColor(n: integer): TColor;
begin
  check_initialized;
  result := TColor(FColors[n]);
end;

function TUTObjectClassPalette.GetColorCount: integer;
begin
  check_initialized;
  result := FColorCount;
end;

function TUTObjectClassPalette.GetNewPalette: HPalette;
var
  palette_struct: PLogPalette;
  buffer: array[0..4 + 256 * 4 - 1] of byte;
  y: integer;
begin
  check_initialized;
  palette_struct := @buffer;
  palette_struct^.palVersion := $300;
  palette_struct^.palNumEntries := 256;
  {$IFOPT R+}
  {$DEFINE RangeCheck}
  {$ENDIF}
  {$R-}
  for y := 0 to 255 do
    begin
      move(FColors[y], palette_struct^.palPalEntry[y], 4);
      palette_struct^.palPalEntry[y].peFlags := 0;
    end;
  {$IFDEF RangeCheck}
  {$R+}
  {$ENDIF}
  result := CreatePalette(palette_struct^);
end;

procedure TUTObjectClassPalette.InitializeObject;
begin
  inherited;
  FColorCount := 0;
  setlength(FColors, 0);
end;

procedure TUTObjectClassPalette.InterpretObject;
var
  a: integer;
begin
  inherited;
  FColorCount := FOwner.read_idx(buffer);
  setlength(FColors, FColorCount);
  for a := 0 to FColorCount - 1 do
    FOwner.read_buffer(FColors[a], 4, buffer);
end;

procedure TUTObjectClassPalette.DoReleaseObject;
begin
  FColorCount := 0;
  setlength(FColors, 0);
  inherited;
end;

{ TUTObjectClassSound }

function TUTObjectClassSound.GetData: string;
begin
  check_initialized;
  result := FData;
end;

function TUTObjectClassSound.GetFormat: string;
begin
  check_initialized;
  result := FFormat;
end;

procedure TUTObjectClassSound.InitializeObject;
begin
  inherited;
  FFormat := '';
  FData := '';
end;

procedure TUTObjectClassSound.InterpretObject;
begin
  inherited;
  FFormat := FOwner.Names[FOwner.read_idx(buffer)];
  if FOwner.Version >= 63 then FOwner.read_int(buffer); // next object offset
  setlength(FData, FOwner.read_idx(buffer));
  FOwner.read_buffer(FData[1], length(FData), buffer);
end;

procedure TUTObjectClassSound.DoReleaseObject;
begin
  FFormat := '';
  FData := '';
  inherited;
end;

procedure TUTObjectClassSound.SaveToFile(filename: string);
var
  f: file;
begin
  check_initialized;
  assignfile(f, filename);
  try
    rewrite(f, 1);
    blockwrite(f, FData[1], length(FData));
  finally
    closefile(f);
  end;
end;

{ TUTObjectClassTextBuffer }

function TUTObjectClassTextBuffer.GetData: string;
begin
  check_initialized;
  result := FData;
end;

procedure TUTObjectClassTextBuffer.InitializeObject;
begin
  inherited;
  FData := '';
end;

procedure TUTObjectClassTextBuffer.InterpretObject;
begin
  inherited;
  FOwner.read_int(buffer);              // pos
  FOwner.read_int(buffer);              // top
  setlength(FData, FOwner.read_idx(buffer) - 1);
  FOwner.read_buffer(FData[1], length(FData), buffer);
  FOwner.read_byte(buffer);             // null
end;

procedure TUTObjectClassTextBuffer.DoReleaseObject;
begin
  FData := '';
  inherited;
end;

procedure TUTObjectClassTextBuffer.SaveToFile(filename: string);
var
  f: file;
begin
  check_initialized;
  assignfile(f, filename);
  try
    rewrite(f, 1);
    blockwrite(f, FData[1], length(FData));
  finally
    closefile(f);
  end;
end;

{ TUTObjectClassMusic }

function TUTObjectClassMusic.GetData: string;
begin
  check_initialized;
  result := FData;
end;

function TUTObjectClassMusic.GetFormat: string;
begin
  check_initialized;
  result := FFormat;
end;

procedure TUTObjectClassMusic.InitializeObject;
begin
  inherited;
  FFormat := '';
  FData := '';
end;

procedure TUTObjectClassMusic.InterpretObject;
begin
  inherited;
  FFormat := FOwner.Names[0];
  FOwner.Read_word(buffer);             // numchunks?
  FOwner.read_int(buffer);              // always 1 ?
  setlength(FData, FOwner.read_idx(buffer));
  FOwner.read_buffer(FData[1], length(FData), buffer);
end;

procedure TUTObjectClassMusic.DoReleaseObject;
begin
  FFormat := '';
  FData := '';
  inherited;
end;

procedure TUTObjectClassMusic.SaveToFile(filename: string);
var
  f: file;
begin
  check_initialized;
  assignfile(f, filename);
  try
    rewrite(f, 1);
    blockwrite(f, FData[1], length(FData));
  finally
    closefile(f);
  end;
end;

{ TUTObjectClassFont }

procedure TUTObjectClassFont.GetCharacterInfo(i: integer; var texture, x,
  y, w, h: integer);
begin
  check_initialized;
  if (i >= 0) and (i <= high(FCharacters)) then
    begin
      texture := FCharacters[i].texture;
      x := FCharacters[i].x;
      y := FCharacters[i].y;
      w := FCharacters[i].w;
      h := FCharacters[i].h;
    end
  else
    begin
      texture := -1;
      x := -1;
      y := -1;
      w := -1;
      h := -1;
    end;
end;

procedure TUTObjectClassFont.InitializeObject;
begin
  inherited;
  setlength(FCharacters, 0);
end;

procedure TUTObjectClassFont.InterpretObject;
var
  numtextures, charidx, a, b, numchars, idx: integer;
begin
  inherited;
  numtextures := FOwner.read_byte(buffer);
  setlength(FCharacters, 256);
  charidx := 0;
  for a := 1 to numtextures do
    begin
      idx := FOwner.read_idx(buffer);   // texture inedx
      numchars := FOwner.read_idx(buffer); // character count
      for b := 1 to numchars do
        begin
          FCharacters[charidx].texture := idx;
          FCharacters[charidx].x := FOwner.read_int(buffer);
          FCharacters[charidx].y := FOwner.read_int(buffer);
          FCharacters[charidx].w := FOwner.read_int(buffer);
          FCharacters[charidx].h := FOwner.read_int(buffer);
          inc(charidx);
        end;
    end;
  setlength(FCharacters, charidx);
end;

procedure TUTObjectClassFont.DoReleaseObject;
begin
  setlength(FCharacters, 0);
  inherited;
end;

{ TUTObjectClassPolys }

function TUTObjectClassPolys.GetPolygonCount: integer;
begin
  check_initialized;
  result := high(FPolygons);
end;

function TUTObjectClassPolys.GetPolygon(n: integer): TUT_Struct_Polygon;
begin
  check_initialized;
  result := FPolygons[n];
end;

procedure TUTObjectClassPolys.InitializeObject;
begin
  inherited;
  setlength(FPolygons, 0);
end;

procedure TUTObjectClassPolys.InterpretObject;
var
  p: integer;
begin
  inherited;
  FOwner.read_int(buffer);              // num polys?
  setlength(FPolygons, Fowner.read_int(buffer)); // max polys?
  for p := 0 to high(FPolygons) do
    FPolygons[p] := Read_Struct_Polygon(Fowner, buffer);
end;

procedure TUTObjectClassPolys.DoReleaseObject;
begin
  setlength(FPolygons, 0);
  inherited;
end;

{ TUTObjectClassTexture }

function TUTObjectClassTexture.GetCompMipMap(i: integer): TBitmap;
begin
  check_initialized;
  result := FCompMipMaps[i];
end;

function TUTObjectClassTexture.GetCompMipMapCount: integer;
begin
  check_initialized;
  result := length(FCompMipMaps);
end;

function TUTObjectClassTexture.GetMipMap(i: integer): TBitmap;
begin
  check_initialized;
  if (i>=0) and (i<length(FMipMaps)) then result := FMipMaps[i] else result:=nil;
end;

function TUTObjectClassTexture.GetMipMapCount: integer;
begin
  check_initialized;
  result := length(FMipMaps);
end;

procedure TUTObjectClassTexture.InitializeObject;
begin
  inherited;
  setlength(FMipMaps, 0);
  setlength(FCompMipMaps, 0);
end;

procedure TUTObjectClassTexture.InterpretObject;
var
  a, data_pos, block_size: integer;
  y: integer;
  compformat: integer;
const
  TEXF_P8 = 0;
  TEXF_RGBA7 = 1;                       // TEXF_RGB32 ?
  TEXF_RGB16 = 2;                       // TEXF_RGB64 ?
  TEXF_DXT1 = 3;
  TEXF_RGB8 = 4;                        // TEXF_RGB24 ?
  TEXF_RGBA8 = 5;                       // none?

  procedure ReadMipMapData(format, block_size: integer; MipMap: TBitmap);
  var
    x, palette: integer;
    ed2: TUTExportTableObjectData;
    color: array[0..3] of word;
    yy: array[0..3] of byte;
    real_color: array[0..3] of tcolor;
    y, c, bx, by, yd4, xd4: integer;
    yv: byte;
  begin
    if format = TEXF_P8 then
      begin
        MipMap.pixelformat := pf8Bit;
        // Extract palette
        palette := Properties['palette']; // do not localize
        if palette > 0 then
          begin
            ed2 := FOwner.Exported[palette - 1];
            ed2.UTObject.ReadObject;
            MipMap.palette := TUTObjectClassPalette(ed2.UTObject).GetPalette;
            ed2.UTObject.ReleaseObject;
          end;
        //else : don't supports imported palettes
      end
    else
      MipMap.pixelformat := pf24Bit;
    // Extract bitmap
    if block_size <> 0 then             // block_size=0 in some Texture descendants
      begin
        case format of
          TEXF_P8:
            begin                       // Palettized
              for y := 0 to MipMap.height - 1 do
                FOwner.read_buffer(MipMap.scanline[y]^, MipMap.width, buffer);
            end;
          TEXF_DXT1:
            begin                       // DirectX-1
              // The texture needs to have a size divisible by 4
              // This format allows for one transparent color, but we dont use that.
              yd4 := (MipMap.height div 4);
              xd4 := (MipMap.width div 4);
              if yd4 = 0 then yd4 := 1;
              if xd4 = 0 then xd4 := 1;
              for y := 0 to yd4 - 1 do
                for x := 0 to xd4 - 1 do
                  begin
                    // read 4x4 block
                    color[0] := FOwner.read_word(buffer);
                    color[1] := FOwner.read_word(buffer);
                    yy[0] := FOwner.read_byte(buffer);
                    yy[1] := FOwner.read_byte(buffer);
                    yy[2] := FOwner.read_byte(buffer);
                    yy[3] := FOwner.read_byte(buffer);
                    // get colors
                    for c := 0 to 1 do
                      real_color[c] := rgb(((color[c] and $001F) shl 3),
                        ((color[c] and $07E0) shr 3),
                        ((color[c] and $F800) shr 8)
                        );
                    if color[0] > color[1] then
                      begin
                        real_color[2] := rgb((2 * GetRValue(real_color[0]) + GetRValue(real_color[1])) div 3,
                          (2 * GetGValue(real_color[0]) + GetGValue(real_color[1])) div 3,
                          (2 * GetBValue(real_color[0]) + GetBValue(real_color[1])) div 3);
                        real_color[3] := rgb((GetRValue(real_color[0]) + 2 * GetRValue(real_color[1])) div 3,
                          (GetGValue(real_color[0]) + 2 * GetGValue(real_color[1])) div 3,
                          (GetBValue(real_color[0]) + 2 * GetBValue(real_color[1])) div 3);
                      end
                    else
                      begin
                        real_color[2] := rgb((GetRValue(real_color[0]) + GetRValue(real_color[1])) div 2,
                          (GetGValue(real_color[0]) + GetGValue(real_color[1])) div 2,
                          (GetBValue(real_color[0]) + GetBValue(real_color[1])) div 2);
                        real_color[3] := 0;
                      end;
                    // get pixels
                    for by := 0 to 3 do
                      begin
                        yv := yy[by];
                        for bx := 0 to 3 do
                          begin
                            if (y * 4 + by < MipMap.height) and (x * 4 + bx < MipMap.width) then
                              move(real_color[yv and 3], PByteArray(MipMap.scanline[y * 4 + by])^[3 * (x * 4 + bx)], 3);
                            yv := yv shr 2;
                          end;
                      end;
                  end;
            end
        else
          buffer.Seek(block_size, soFromCurrent);
        end;
      end;
  end;

begin
  inherited;
  // Read MipMaps
  setlength(FMipMaps, FOwner.read_byte(buffer));
  for a := 0 to high(FMipMaps) do
    begin
      if FOwner.Version >= 63 then
        begin
          y := FOwner.read_int(buffer) - FStartInPackage; // position after block
          block_size := FOwner.read_idx(buffer); // block size
          data_pos := buffer.position;
        end
      else
        begin
          block_size := FOwner.read_idx(buffer); // block size
          data_pos := buffer.position;
          y := data_pos + block_size;
        end;
      buffer.seek(y, soFromBeginning);
      FMipMaps[a] := tbitmap.create;
      FMipMaps[a].width := FOwner.read_int(buffer);
      FMipMaps[a].height := FOwner.read_int(buffer);
      buffer.seek(data_pos, soFromBeginning);
      compformat := Properties.GetPropertyByNameValueDefault('Format', TEXF_P8);
      ReadMipMapData(compformat, block_size, FMipMaps[a]);
      FOwner.read_int(buffer);          // Width
      FOwner.read_int(buffer);          // Height
      FOwner.read_byte(buffer);         // Width bits
      FOwner.read_byte(buffer);         // Height bits
    end;
  // Read Compressed MipMaps
  if Properties['bHasComp'] then
    begin
      compformat := Properties.GetPropertyByNameValueDefault('CompFormat', TEXF_P8);
      setlength(FCompMipMaps, FOwner.read_byte(buffer));
      for a := 0 to high(FCompMipMaps) do
        begin
          if FOwner.Version >= 63 then
            begin
              y := FOwner.read_int(buffer) - FStartInPackage; // position after block
              block_size := FOwner.read_idx(buffer); // block size
              data_pos := buffer.position;
            end
          else
            begin
              block_size := FOwner.read_idx(buffer); // block size
              data_pos := buffer.position;
              y := data_pos + block_size;
            end;
          buffer.seek(y, soFromBeginning);
          FCompMipMaps[a] := tbitmap.create;
          FCompMipMaps[a].width := FOwner.read_int(buffer);
          FCompMipMaps[a].height := FOwner.read_int(buffer);
          buffer.seek(data_pos, soFromBeginning);
          ReadMipMapData(compformat, block_size, FCompMipMaps[a]);
          FOwner.read_int(buffer);      // Width
          FOwner.read_int(buffer);      // Height
          FOwner.read_byte(buffer);     // Width bits
          FOwner.read_byte(buffer);     // Height bits
        end;
    end;
end;

procedure TUTObjectClassTexture.DoReleaseObject;
var
  a: integer;
begin
  for a := 0 to high(FMipMaps) do
    FMipMaps[a].free;
  setlength(FMipMaps, 0);
  for a := 0 to high(FCompMipMaps) do
    FCompMipMaps[a].free;
  setlength(FCompMipMaps, 0);
  inherited;
end;

procedure TUTObjectClassTexture.SaveCompMipMapToFile(mipmap: integer;
  filename: string);
begin
  check_initialized;
  FCompMipMaps[mipmap].savetofile(filename);
end;

procedure TUTObjectClassTexture.SaveMipMapToFile(mipmap: integer;
  filename: string);
begin
  check_initialized;
  FMipMaps[mipmap].savetofile(filename);
end;

{ TUTObjectClassPrimitive }

procedure TUTObjectClassPrimitive.InitializeObject;
begin
  inherited;
  fillchar(FPrimitiveBoundingBox, sizeof(FPrimitiveBoundingBox), 0);
  fillchar(FPrimitiveBoundingSphere, sizeof(FPrimitiveBoundingSphere), 0);
end;

procedure TUTObjectClassPrimitive.InterpretObject;
begin
  inherited;
  // UPrimitive.BoundingBox
  FPrimitiveBoundingBox := Read_Struct_BoundingBox(FOwner, buffer);
  // UPrimitive.BoundingSphere
  FPrimitiveBoundingSphere := Read_Struct_BoundingSphere(FOwner, buffer);
end;

procedure TUTObjectClassPrimitive.DoReleaseObject;
begin
  fillchar(FPrimitiveBoundingBox, sizeof(FPrimitiveBoundingBox), 0);
  fillchar(FPrimitiveBoundingSphere, sizeof(FPrimitiveBoundingSphere), 0);
  inherited;
end;

{ TUTObjectClassMesh }

function TUTObjectClassMesh.GetAnimFrames: integer;
begin
  check_initialized;
  result := FAnimFrames;
end;

function TUTObjectClassMesh.GetAnimSeq(i: integer): TUT_Struct_AnimSeq;
begin
  check_initialized;
  result := FAnimSeqs[i];
end;

function TUTObjectClassMesh.GetAnimSeqCount: integer;
begin
  check_initialized;
  result := length(FAnimSeqs);
end;

function TUTObjectClassMesh.GetBoundingBox(
  i: integer): TUT_Struct_BoundingBox;
begin
  check_initialized;
  result := FBoundingBoxes[i];
end;

function TUTObjectClassMesh.GetBoundingBoxCount: integer;
begin
  check_initialized;
  result := length(FBoundingBoxes);
end;

function TUTObjectClassMesh.GetBoundingSphere(
  i: integer): TUT_Struct_BoundingSphere;
begin
  check_initialized;
  result := FBoundingSpheres[i];
end;

function TUTObjectClassMesh.GetBoundingSphereCount: integer;
begin
  check_initialized;
  result := length(FBoundingSpheres);
end;

function TUTObjectClassMesh.GetConnect(i: integer): TUT_Struct_Connects;
begin
  check_initialized;
  result := FConnects[i];
end;

function TUTObjectClassMesh.GetConnectsCount: integer;
begin
  check_initialized;
  result := length(FConnects);
end;

function TUTObjectClassMesh.GetTexture(i: integer): TUT_Struct_Texture;
begin
  check_initialized;
  result := FTextures[i];
end;

function TUTObjectClassMesh.GetTextureLOD(i: integer): single;
begin
  check_initialized;
  result := FTextureLOD[i];
end;

function TUTObjectClassMesh.GetTextureLODCount: integer;
begin
  check_initialized;
  result := length(FTextureLOD);
end;

function TUTObjectClassMesh.GetTexturesCount: integer;
begin
  check_initialized;
  result := length(FTextures);
end;

function TUTObjectClassMesh.GetTri(i: integer): TUT_Struct_Tri;
begin
  check_initialized;
  result := FTris[i];
end;

function TUTObjectClassMesh.GetTrisCount: integer;
begin
  check_initialized;
  result := length(FTris);
end;

function TUTObjectClassMesh.GetVert(i: integer): TUT_Struct_Vert;
begin
  check_initialized;
  result := FVerts[i];
end;

function TUTObjectClassMesh.GetVertLink(i: integer): integer;
begin
  check_initialized;
  result := FVertLinks[i];
end;

function TUTObjectClassMesh.GetVertLinksCount: integer;
begin
  check_initialized;
  result := length(FVertLinks);
end;

function TUTObjectClassMesh.GetVertsCount: integer;
begin
  check_initialized;
  result := length(FVerts);
end;

procedure TUTObjectClassMesh.InitializeObject;
begin
  inherited;
  setlength(FVerts, 0);
  setlength(FTris, 0);
  setlength(FTextures, 0);
  setlength(FAnimSeqs, 0);
  setlength(FConnects, 0);
  setlength(FBoundingBoxes, 0);
  setlength(FBoundingSpheres, 0);
  setlength(FVertLinks, 0);
  setlength(FTextureLOD, 0);
end;

procedure TUTObjectClassMesh.InterpretObject;
var
  a, seekpos, size, p, game: integer;
  xyz64: int64;
  x, y, z: single;
  xyz: cardinal;
begin
  inherited;
  // UMesh.Verts
  if FOwner.Version > 61 then
    seekpos := FOwner.read_int(buffer) - FStartInPackage
  else
    seekpos := 0;
  size := FOwner.read_idx(buffer);
  p := buffer.position;
  if (size <> 0) and (seekpos > 0) and ((seekpos - p) div size = 8) then
    game := 1                           // DeusEx
  else
    game := 0;                          // UT
  setlength(FVerts, size);
  case game of
    1:
      begin                             // DeusEX vertices have more resolution
        for a := 0 to size - 1 do
          begin
            FOwner.read_buffer(xyz64, 8, buffer);
            x := (xyz64 and $FFFF) / 256;
            y := ((xyz64 shr 16) and $FFFF) / 256;
            z := ((xyz64 shr 32) and $FFFF) / 256;
            if y > 128 then y := y - 256;
            if x > 128 then x := x - 256;
            if z > 128 then z := z - 256;
            FVerts[a].x := x;
            FVerts[a].y := y;
            FVerts[a].z := z;
          end
      end;
  else
    begin                               // 0 = UT
      for a := 0 to size - 1 do
        begin
          FOwner.read_buffer(xyz, 4, buffer);
          x := (xyz and $7FF) / 8;
          y := ((xyz shr 11) and $7FF) / 8;
          z := ((xyz shr 22) and $3FF) / 4;
          if y > 128 then y := y - 256;
          if x > 128 then x := x - 256;
          if z > 128 then z := z - 256;
          FVerts[a].x := x;
          FVerts[a].y := y;
          FVerts[a].z := z;
        end;
    end;
  end;
  // UMesh.Tris
  if FOwner.Version > 61 then FOwner.read_int(buffer);
  size := FOwner.read_idx(buffer);
  setlength(FTris, size);
  for a := 0 to size - 1 do
    FTris[a] := Read_Struct_Tri(Fowner, buffer);
  // UMesh.AnimSeqs
  size := FOwner.read_idx(buffer);
  setlength(Fanimseqs, size);
  for a := 0 to size - 1 do
    FAnimSeqs[a] := Read_Struct_AnimSeq(FOwner, buffer);
  // UMesh.Connects
  if FOwner.Version > 61 then FOwner.read_int(buffer);
  size := FOwner.read_idx(buffer);
  setlength(FConnects, size);
  for a := 0 to size - 1 do
    FConnects[a] := Read_Struct_Connects(FOwner, buffer);
  // UMesh.BoundingBox
  FBoundingBox := Read_Struct_BoundingBox(FOwner, buffer);
  // UMesh.BoundingSphere
  FBoundingSphere := Read_Struct_BoundingSphere(FOwner, buffer);
  // UMesh.VertLinks
  if FOwner.Version > 61 then FOwner.read_int(buffer);
  size := FOwner.read_idx(buffer);
  setlength(FVertLinks, size);
  for a := 0 to size - 1 do
    FVertLinks[a] := FOwner.read_int(buffer);
  // UMesh.Textures
  size := FOwner.read_idx(buffer);
  setlength(FTextures, size);
  for a := 0 to size - 1 do
    FTextures[a] := Read_Struct_Texture(FOwner, buffer);
  // UMesh.BoundingBoxes
  size := FOwner.read_idx(buffer);
  setlength(FBoundingBoxes, size);
  for a := 0 to size - 1 do
    FBoundingBoxes[a] := Read_Struct_BoundingBox(FOwner, buffer);
  // UMesh.BoundingSpheres
  size := FOwner.read_idx(buffer);
  setlength(FBoundingSpheres, size);
  for a := 0 to size - 1 do
    FBoundingSpheres[a] := Read_Struct_BoundingSphere(FOwner, buffer);
  // UMesh.FrameVerts
  FFrameVerts := FOwner.read_int(buffer);
  // UMesh.AnimFrames
  FAnimFrames := FOwner.read_int(buffer);
  // UMesh.ANDFlags
  FANDFlags := FOwner.read_int(buffer);
  // UMesh.ORFlags
  FORFlags := FOwner.read_int(buffer);
  // UMesh.Scale
  FScale := Read_Struct_Vector(FOwner, buffer);
  // UMesh.Origin
  FOrigin := Read_Struct_Vector(FOwner, buffer);
  // UMesh.RotOrigin
  FRotOrigin := Read_Struct_Rotator(FOwner, buffer);
  // UMesh.CurPoly
  FCurPoly := FOwner.read_int(buffer);
  // UMesh.CurVertex
  FCurVertex := FOwner.read_int(buffer);
  // UMesh.TextureLOD
  if FOwner.Version >= 66 then
    begin
      size := FOwner.read_idx(buffer);
      setlength(FTextureLOD, size);
      for a := 0 to size - 1 do
        FTextureLOD[a] := FOwner.read_FLOAT(buffer);
    end
  else if FOwner.Version = 65 then
    begin
      setlength(FTextureLOD, 1);
      FTextureLOD[0] := FOwner.read_FLOAT(buffer);
    end;
end;

procedure TUTObjectClassMesh.DoReleaseObject;
begin
  setlength(FVerts, 0);
  setlength(FTris, 0);
  setlength(FTextures, 0);
  setlength(FAnimSeqs, 0);
  setlength(FConnects, 0);
  setlength(FBoundingBoxes, 0);
  setlength(FBoundingSpheres, 0);
  setlength(FVertLinks, 0);
  setlength(FTextureLOD, 0);
  inherited;
end;

procedure TUTObjectClassMesh.PrepareExporter(exporter: TUT_MeshExporter; frames: TIntegerArray);
const
  material_colors: array[0..5] of TColor = (clBlue, clRed, clLime, clYellow, clAqua, clSilver);
var
  m, firstvert, v, f: integer;
begin
  check_initialized;
  if length(frames) = 0 then
    begin
      setlength(frames, 1);
      frames[0] := 0;
    end;
  setlength(exporter.Materials, length(FTextures));
  for m := 0 to high(FTextures) do
    begin
      exporter.Materials[m].name := 'Material' + inttostr(FTextures[m].Value);
      if m <= high(material_colors) then
        begin
          exporter.Materials[m].diffusecolor[0] := material_colors[m] and $FF;
          exporter.Materials[m].diffusecolor[1] := (material_colors[m] shr 8) and $FF;
          exporter.Materials[m].diffusecolor[2] := (material_colors[m] shr 16) and $FF;
        end
      else
        begin
          exporter.Materials[m].diffusecolor[0] := random(256);
          exporter.Materials[m].diffusecolor[1] := random(256);
          exporter.Materials[m].diffusecolor[2] := random(256);
        end;
    end;
  exporter.AnimationFrames := length(frames);
  setlength(exporter.Faces, length(FTris));
  setlength(exporter.Vertices, 3 * length(frames) * length(FTris));
  v := 0;
  for f := 0 to high(frames) do
    begin
      firstvert := frames[f] * FFrameVerts;
      for m := 0 to high(FTris) do
        begin
          inc(v);
          exporter.Vertices[v].x := FVerts[firstvert + FTris[m].VertexIndex1].X;
          exporter.Vertices[v].y := FVerts[firstvert + FTris[m].VertexIndex1].Y;
          exporter.Vertices[v].z := FVerts[firstvert + FTris[m].VertexIndex1].Z;
          exporter.Vertices[v].U := FTris[m].U1;
          exporter.Vertices[v].V := FTris[m].V1;
          inc(v);
          exporter.Vertices[v].x := FVerts[firstvert + FTris[m].VertexIndex2].X;
          exporter.Vertices[v].y := FVerts[firstvert + FTris[m].VertexIndex2].Y;
          exporter.Vertices[v].z := FVerts[firstvert + FTris[m].VertexIndex2].Z;
          exporter.Vertices[v].U := FTris[m].U2;
          exporter.Vertices[v].V := FTris[m].V2;
          inc(v);
          exporter.Vertices[v].x := FVerts[firstvert + FTris[m].VertexIndex3].X;
          exporter.Vertices[v].y := FVerts[firstvert + FTris[m].VertexIndex3].Y;
          exporter.Vertices[v].z := FVerts[firstvert + FTris[m].VertexIndex3].Z;
          exporter.Vertices[v].U := FTris[m].U3;
          exporter.Vertices[v].V := FTris[m].V3;
          if f = 0 then
            begin
              exporter.Faces[m].VertexIndex1 := v - 2;
              exporter.Faces[m].VertexIndex2 := v - 1;
              exporter.Faces[m].VertexIndex3 := v;
              exporter.Faces[m].MaterialIndex := FTris[m].TextureIndex;
              exporter.Faces[m].Flags := FTris[m].Flags;
            end;
        end;
    end;
end;

procedure TUTObjectClassMesh.Save_3DS(filename: string; frame: integer = 0;
  smoothing: TUT_3DStudioExporter_Smoothing = exp3ds_smooth_None; MirrorX: boolean = false);
var
  exporter: TUT_3DStudioExporter;
  frames: TIntegerArray;
begin
  check_initialized;
  exporter := TUT_3DStudioExporter.create;
  setlength(frames, 1);
  frames[0] := frame;
  PrepareExporter(exporter, frames);
  exporter.mirrorX := mirrorX;
  exporter.smoothing := smoothing;
  exporter.Save(filename);
  exporter.free;
end;

procedure TUTObjectClassMesh.Save_Unreal3D(filename: string);
var
  exporter: TUT_Unreal3DExporter;
  frames: TIntegerArray;
  a: integer;
begin
  check_initialized;
  exporter := TUT_Unreal3DExporter.create;
  setlength(frames, FAnimFrames);
  for a := 0 to FAnimFrames - 1 do
    frames[a] := a;
  PrepareExporter(exporter, frames);
  exporter.Save(filename);
  exporter.free;
end;

procedure TUTObjectClassMesh.Save_UnrealUC(filename: string);
var
  k: char;
  uc, parent_class, basename: string;
  a, b, script_idx: integer;
  ed2: TUTExportTableObjectData;
  id: TUTImportTableObjectData;
  str_uc: tfilestream;
begin
  check_initialized;
  // Find a class with the same name as the mesh
  a := FOwner.FindObject(utolExports, [utfwName, utfwClass, utfwPackage], '', UTobjectname, '');
  if a <> -1 then
    begin
      ed2 := FOwner.Exported[a];
      ed2.UTObject.ReadObject;
      parent_class := FOwner.GetObjectPath(1, TUTObjectClassClass(ed2.UTObject).SuperField);
      script_idx := TUTObjectClassClass(ed2.UTObject).ScriptText - 1;
      ed2.UTObject.ReleaseObject;
    end
  else
    begin
      parent_class := 'TournamentPlayer'; // do not localize these strings
      // Find the correct script object
      script_idx := FOwner.FindObject(utolExports, [utfwName, utfwClass, utfwPackage],
        UTobjectname, 'ScriptText', 'TextBuffer');
    end;
  if script_idx <> -1 then
    begin                               // the script was found
      ed2 := FOwner.Exported[script_idx];
      ed2.UTObject.ReadObject;
      TUTObjectClassTextBuffer(ed2.UTObject).SaveToFile(filename);
      ed2.UTObject.ReleaseObject;
    end
  else
    begin                               // the script wasn't found, we must recreate it
      k := {$IF CompilerVersion > 21.0}FormatSettings.{$IFEND}DecimalSeparator;
      {$IF CompilerVersion > 21.0}FormatSettings.{$IFEND}decimalSeparator := '.';
      basename := UTobjectname;
      // do not localize
      uc := '//============================================================================='#13#10;
      uc := uc + format('// %s.'#13#10, [basename]);
      uc := uc + '//============================================================================='#13#10;
      uc := uc + format('class %s extends %s;'#13#10#13#10, [basename, parent_class]);
      uc := uc + format('#exec MESH IMPORT MESH=%s ANIVFILE=MODELS\%s_a.3d DATAFILE=MODELS\%s_d.3d' {+' X=0 Y=0 Z=0'}, [basename, basename, basename]);
      uc := uc + ' MLOD=0'#13#10;
      uc := uc + format('#exec MESH ORIGIN MESH=%s X=%f Y=%f Z=%f YAW=%f ROLL=%f PITCH=%f'#13#10#13#10,
        [basename, FOrigin.x, FOrigin.y, FOrigin.z, FRotorigin.Yaw / 256, FRotOrigin.Roll / 256, FRotOrigin.Pitch / 256]);
      for a := 0 to high(FAnimSeqs) do
        begin
          uc := uc + format('#exec MESH SEQUENCE MESH=%s SEQ=%-9s STARTFRAME=%d NUMFRAMES=%d', [basename, FOwner.Names[FAnimSeqs[a].name], FAnimSeqs[a].startframe, FAnimSeqs[a].numframes]);
          if FAnimSeqs[a].rate <> 30 then uc := uc + format(' RATE=%f', [FAnimSeqs[a].rate]);
          if FOwner.Names[FAnimSeqs[a].group] <> 'None' then uc := uc + format(' GROUP=%s', [FOwner.Names[FAnimSeqs[a].group]]);
          uc := uc + #13#10;
        end;
      uc := uc + #13#10;
      for a := 0 to high(FTextures) do
        if FTextures[a].value > 0 then
          begin
            ed2 := FOwner.Exported[FTextures[a].value - 1];
            uc := uc + format('#exec TEXTURE IMPORT NAME=%s FILE=%s.PCX GROUP=%s'#13#10,
              [ed2.UTobjectname, ed2.UTobjectname, ed2.UTpackagename]);
            // TODO : TUTObjectClassMesh.Save_UnrealUC : FLAGS=%d should put correct flags...
          end
        else if FTextures[a].value < 0 then
          begin
            id := FOwner.Imported[-FTextures[a].value - 1];
            uc := uc + format('#exec OBJ LOAD FILE=%s.utx PACKAGE=%s'#13#10, [id.UTobjectname, id.UTpackagename]);
          end;
      uc := uc + #13#10;
      for a := 0 to high(FTextures) do
        if FTextures[a].value > 0 then
          begin
            ed2 := FOwner.Exported[FTextures[a].value - 1];
            uc := uc + format('#exec MESHMAP SETTEXTURE MESHMAP=%s NUM=%d TEXTURE=%s'#13#10, [basename, a, ed2.UTobjectname]);
          end
        else if FTextures[a].value < 0 then
          begin
            id := FOwner.Imported[-FTextures[a].value - 1];
            uc := uc + format('#exec MESHMAP SETTEXTURE MESHMAP=%s NUM=%d TEXTURE=%s'#13#10, [basename, a, id.UTpackagename + '.' + id.UTobjectname]);
          end;
      uc := uc + #13#10;
      //uc:=uc+format('#exec MESHMAP NEW   MESHMAP=%s MESH=%s'#13#10,[basename,basename]);
      if (FScale.x <> 0.1) or (FScale.y <> 0.1) or (FScale.z <> 0.2) then
        uc := uc + format('#exec MESHMAP SCALE MESHMAP=%s X=%f Y=%f Z=%f'#13#10#13#10, [basename, FScale.x, FScale.y, FScale.z]);
      // FScale is incorrect, sometimes is 0 and it shouldnt be.
      for a := 0 to high(FAnimSeqs) do
        for b := 0 to high(FAnimSeqs[a].notifys) do
          uc := uc + format('#exec MESH NOTIFY MESH=%s SEQ=%-9s TIME=%f FUNCTION=%s'#13#10, [basename, FOwner.Names[FAnimSeqs[a].name], FAnimSeqs[a].notifys[b].time, FOwner.Names[FAnimSeqs[a].notifys[b]._function]]);
      uc := uc + #13#10;
      (*uc:=uc+#13#10+
      'defaultproperties'#13#10+
      '{'#13#10+
      '    DrawType=DT_Mesh'#13#10+
      format('    Mesh=%s'#13#10,[basename])+
      '}'#13#10;*)
      {$IF CompilerVersion > 21.0}FormatSettings.{$IFEND}DecimalSeparator := k;
      str_uc := tfilestream.create(filename, fmCreate);
      try
        str_uc.write(uc[1], length(uc));
      finally
        str_uc.free;
      end;
    end;
end;

{ TUTObjectClassLodMesh }

function TUTObjectClassLodMesh.GetCollapsePointThus(i: integer): word;
begin
  check_initialized;
  result := FCollapsePointThus[i];
end;

function TUTObjectClassLodMesh.GetCollapsePointThusCount: integer;
begin
  check_initialized;
  result := length(FCollapsePointThus);
end;

function TUTObjectClassLodMesh.GetCollapseWedgeThus(i: integer): word;
begin
  check_initialized;
  result := FCollapseWedgeThus[i];
end;

function TUTObjectClassLodMesh.GetCollapseWedgeThusCount: integer;
begin
  check_initialized;
  result := length(FCollapseWedgeThus);
end;

function TUTObjectClassLodMesh.GetFace(i: integer): TUT_Struct_Face;
begin
  check_initialized;
  result := FFaces[i];
end;

function TUTObjectClassLodMesh.GetFaceCount: integer;
begin
  check_initialized;
  result := length(FFaces);
end;

function TUTObjectClassLodMesh.GetFaceLevel(i: integer): word;
begin
  check_initialized;
  result := FFaceLevel[i];
end;

function TUTObjectClassLodMesh.GetFaceLevelCount: integer;
begin
  check_initialized;
  result := length(FFaceLevel);
end;

function TUTObjectClassLodMesh.GetMaterial(
  i: integer): TUT_Struct_Material;
begin
  check_initialized;
  result := FMaterials[i];
end;

function TUTObjectClassLodMesh.GetMaterialCount: integer;
begin
  check_initialized;
  result := length(FMaterials);
end;

function TUTObjectClassLodMesh.GetRemapAnimVerts(i: integer): word;
begin
  check_initialized;
  result := FRemapAnimVerts[i];
end;

function TUTObjectClassLodMesh.GetRemapAnimVertsCount: integer;
begin
  check_initialized;
  result := length(FRemapAnimVerts);
end;

function TUTObjectClassLodMesh.GetSpecialFace(i: integer): TUT_Struct_Face;
begin
  check_initialized;
  result := FSpecialFaces[i];
end;

function TUTObjectClassLodMesh.GetSpecialFaceCount: integer;
begin
  check_initialized;
  result := length(FSpecialFaces);
end;

function TUTObjectClassLodMesh.GetWedge(i: integer): TUT_Struct_Wedge;
begin
  check_initialized;
  result := FWedges[i];
end;

function TUTObjectClassLodMesh.GetWedgeCount: integer;
begin
  check_initialized;
  result := length(FWedges);
end;

procedure TUTObjectClassLodMesh.InitializeObject;
begin
  inherited;
  setlength(FWedges, 0);
  setlength(FFaces, 0);
  setlength(FMaterials, 0);
  setlength(FCollapsePointThus, 0);
  setlength(FFaceLevel, 0);
  setlength(FCollapseWedgeThus, 0);
  setlength(FSpecialFaces, 0);
  setlength(FRemapAnimVerts, 0);
end;

procedure TUTObjectClassLodMesh.InterpretObject;
var
  size, a: integer;
begin
  inherited;
  // ULodMesh.CollapsePointThus
  size := FOwner.read_idx(buffer);
  setlength(FCollapsePointThus, size);
  for a := 0 to size - 1 do
    FCollapsePointThus[a] := FOwner.read_WORD(buffer);
  // ULodMesh.FaceLevel
  size := FOwner.read_idx(buffer);
  setlength(FFaceLevel, size);
  for a := 0 to size - 1 do
    FFaceLevel[a] := FOwner.read_WORD(buffer);
  // UlodMesh.Faces
  size := FOwner.read_idx(buffer);
  setlength(FFaces, size);
  for a := 0 to size - 1 do
    FFaces[a] := Read_Struct_Face(FOwner, buffer);
  // ULodMesh.CollapseWedgeThus
  size := FOwner.read_idx(buffer);
  setlength(FCollapseWedgeThus, size);
  for a := 0 to size - 1 do
    FCollapseWedgeThus[a] := FOwner.read_WORD(buffer);
  // ULodMesh.Wedges
  size := FOwner.read_idx(buffer);
  setlength(FWedges, size);
  for a := 0 to size - 1 do
    FWedges[a] := Read_Struct_Wedge(FOwner, buffer);
  // ULodMesh.Materials
  size := FOwner.read_idx(buffer);
  setlength(FMaterials, size);
  for a := 0 to size - 1 do
    FMaterials[a] := Read_Struct_Material(FOwner, buffer);
  // ULodMesh.SpecialFaces
  size := FOwner.read_idx(buffer);
  setlength(FSpecialFaces, size);
  for a := 0 to size - 1 do
    FSpecialFaces[a] := Read_Struct_Face(FOwner, buffer);
  // ULodMesh.ModelVerts
  FModelVerts := FOwner.read_int(buffer);
  // ULodMesh.SpecialVerts
  FSpecialVerts := FOwner.read_int(buffer);
  // ULodMesh.MeshScaleMax
  FMeshScaleMax := FOwner.read_FLOAT(buffer);
  // ULodMesh.LODHysteresis
  FLODHysteresis := FOwner.read_FLOAT(buffer);
  // ULodMesh.LODStrength
  FLODStrength := FOwner.read_FLOAT(buffer);
  // ULodMesh.LODMinVerts
  FLODMinVerts := FOwner.read_int(buffer);
  // ULodMesh.LODMorph
  FLODMorph := FOwner.read_FLOAT(buffer);
  // ULodMesh.LODZDisplace
  FLODZDisplace := FOwner.read_FLOAT(buffer);
  // ULodMesh.RemapAnimVerts
  size := FOwner.read_idx(buffer);
  setlength(FRemapAnimVerts, size);
  for a := 0 to size - 1 do
    FRemapAnimVerts[a] := FOwner.read_WORD(buffer);
  // ULodMesh.OldFrameVerts
  FOldFrameVerts := FOwner.read_int(buffer);

end;

procedure TUTObjectClassLodMesh.DoReleaseObject;
begin
  setlength(FWedges, 0);
  setlength(FFaces, 0);
  setlength(FMaterials, 0);
  setlength(FCollapsePointThus, 0);
  setlength(FFaceLevel, 0);
  setlength(FCollapseWedgeThus, 0);
  setlength(FSpecialFaces, 0);
  setlength(FRemapAnimVerts, 0);
  inherited;
end;

procedure TUTObjectClassLodMesh.PrepareExporter(exporter: TUT_MeshExporter;
  frames: TIntegerArray);
const
  material_colors: array[0..5] of TColor = (clBlue, clRed, clLime, clYellow, clAqua, clSilver);
var
  matname: string;
  m, firstvert, f, v: integer;
  weapon_material_exists: integer;
begin
  check_initialized;
  if length(frames) = 0 then
    begin
      setlength(frames, 1);
      frames[0] := 0;
    end;
  weapon_material_exists := -1;
  setlength(exporter.Materials, length(FMaterials));
  for m := 0 to high(FMaterials) do
    begin
      matname := 'SKIN' + inttostr(FMaterials[m].textureindex);
      if (FMaterials[m].flags and (PF_TwoSided or PF_Modulated)) = (PF_TwoSided or PF_Modulated) then
        matname := matname + '.MODU'    //LATED'
      else if (FMaterials[m].flags and (PF_TwoSided or PF_Translucent)) = (PF_TwoSided or PF_Translucent) then
        matname := matname + '.TRAN'    //SLUCENT'
      else if (FMaterials[m].flags and (PF_TwoSided or PF_Masked)) = (PF_TwoSided or PF_Masked) then
        matname := matname + '.MASK'    //ED'
      else if (FMaterials[m].flags and PF_TwoSided) = PF_TwoSided then
        matname := matname + '.TWOS'    //IDED'
      else if (FMaterials[m].flags and PF_NotSolid) = PF_NotSolid then
        begin
          matname := 'WEAPON';
          weapon_material_exists := m;
        end;
      matname := copy(matname, 1, 10);
      exporter.Materials[m].name := matname;
      if m <= high(material_colors) then
        begin
          exporter.Materials[m].diffusecolor[0] := material_colors[m] and $FF;
          exporter.Materials[m].diffusecolor[1] := (material_colors[m] shr 8) and $FF;
          exporter.Materials[m].diffusecolor[2] := (material_colors[m] shr 16) and $FF;
        end
      else
        begin
          exporter.Materials[m].diffusecolor[0] := random(256);
          exporter.Materials[m].diffusecolor[1] := random(256);
          exporter.Materials[m].diffusecolor[2] := random(256);
        end;
    end;
  if (weapon_material_exists = -1) and (length(FSpecialFaces) > 0) then
    begin
      m := length(FMaterials);
      weapon_material_exists := m;
      setlength(exporter.Materials, m + 1);
      exporter.Materials[m].name := 'WEAPON';
      if m <= high(material_colors) then
        begin
          exporter.Materials[m].diffusecolor[0] := material_colors[m] and $FF;
          exporter.Materials[m].diffusecolor[1] := (material_colors[m] shr 8) and $FF;
          exporter.Materials[m].diffusecolor[2] := (material_colors[m] shr 16) and $FF;
        end
      else
        begin
          exporter.Materials[m].diffusecolor[0] := random(256);
          exporter.Materials[m].diffusecolor[1] := random(256);
          exporter.Materials[m].diffusecolor[2] := random(256);
        end;
    end;
  exporter.AnimationFrames := length(frames);
  setlength(exporter.Vertices, (FSpecialVerts + length(FWedges)) * length(frames));
  for f := 0 to high(frames) do
    begin
      firstvert := frames[f] * FFrameVerts;
      for m := 0 to FSpecialVerts - 1 do
        begin
          v := f * (FSpecialVerts + length(FWedges)) + m;
          exporter.Vertices[v].x := FVerts[firstvert + m].X;
          exporter.Vertices[v].y := FVerts[firstvert + m].Y;
          exporter.Vertices[v].z := FVerts[firstvert + m].Z;
          exporter.Vertices[v].U := 0;
          exporter.Vertices[v].V := 0;
        end;
      for m := 0 to high(FWedges) do
        begin
          v := f * (FSpecialVerts + length(FWedges)) + FSpecialVerts + m;
          exporter.Vertices[v].x := FVerts[firstvert + FSpecialVerts + FWedges[m].VertexIndex].X;
          exporter.Vertices[v].y := FVerts[firstvert + FSpecialVerts + FWedges[m].VertexIndex].Y;
          exporter.Vertices[v].z := FVerts[firstvert + FSpecialVerts + FWedges[m].VertexIndex].Z;
          exporter.Vertices[v].U := FWedges[m].U;
          exporter.Vertices[v].V := FWedges[m].V;
        end;
    end;
  setlength(exporter.Faces, length(FFaces) + length(FSpecialFaces));
  for m := 0 to high(FFaces) do
    begin
      exporter.Faces[m].VertexIndex1 := FSpecialVerts + FFaces[m].WedgeIndex1;
      exporter.Faces[m].VertexIndex2 := FSpecialVerts + FFaces[m].WedgeIndex2;
      exporter.Faces[m].VertexIndex3 := FSpecialVerts + FFaces[m].WedgeIndex3;
      exporter.Faces[m].MaterialIndex := FFaces[m].MatIndex;
      exporter.Faces[m].Flags := FMaterials[FFaces[m].MatIndex].Flags;
    end;
  for m := 0 to high(FSpecialFaces) do
    begin
      exporter.Faces[length(FFaces) + m].VertexIndex1 := FSpecialFaces[m].WedgeIndex1;
      exporter.Faces[length(FFaces) + m].VertexIndex2 := FSpecialFaces[m].WedgeIndex2;
      exporter.Faces[length(FFaces) + m].VertexIndex3 := FSpecialFaces[m].WedgeIndex3;
      exporter.Faces[length(FFaces) + m].MaterialIndex := weapon_material_exists;
      exporter.Faces[length(FFaces) + m].Flags := PF_NotSolid;
    end;
end;

procedure TUTObjectClassLodMesh.Save_3DS(filename: string; frame: integer = 0;
  smoothing: TUT_3DStudioExporter_Smoothing = exp3ds_smooth_None; MirrorX: boolean = false);
var
  exporter: TUT_3DStudioExporter;
  frames: TIntegerArray;
begin
  check_initialized;
  exporter := TUT_3DStudioExporter.create;
  setlength(frames, 1);
  frames[0] := frame;
  PrepareExporter(exporter, frames);
  exporter.mirrorx := mirrorx;
  exporter.smoothing := smoothing;
  exporter.Save(filename);
  exporter.free;
end;

procedure TUTObjectClassLodMesh.Save_Unreal3D(filename: string);
var
  exporter: TUT_Unreal3DExporter;
  frames: TIntegerArray;
  a: integer;
begin
  check_initialized;
  exporter := TUT_Unreal3DExporter.create;
  setlength(frames, FAnimFrames);
  for a := 0 to FAnimFrames - 1 do
    frames[a] := a;
  PrepareExporter(exporter, frames);
  exporter.Save(filename);
  exporter.free;
end;

procedure TUTObjectClassLodMesh.Save_UnrealUC(filename: string);
var
  k: char;
  uc, parent_class, basename: string;
  a, b, script_idx: integer;
  ed2: TUTExportTableObjectData;
  id: TUTImportTableObjectData;
  str_uc: tfilestream;
begin
  check_initialized;
  a := FOwner.FindObject(utolExports, [utfwName, utfwClass, utfwPackage], '', UTobjectname, '');
  if a <> -1 then
    begin
      ed2 := FOwner.Exported[a];
      ed2.UTObject.ReadObject;
      parent_class := FOwner.GetObjectPath(1, TUTObjectClassClass(ed2.UTObject).SuperField);
      script_idx := TUTObjectClassClass(ed2.UTObject).ScriptText - 1;
      ed2.UTObject.ReleaseObject;
    end
  else
    begin
      parent_class := 'TournamentPlayer'; // do not localize these strings
      script_idx := FOwner.FindObject(utolExports, [utfwName, utfwClass, utfwPackage],
        UTobjectname, 'ScriptText', 'TextBuffer');
    end;
  if script_idx <> -1 then
    begin
      ed2 := FOwner.Exported[script_idx];
      ed2.UTObject.ReadObject;
      TUTObjectClassTextBuffer(ed2.UTObject).SaveToFile(filename);
      ed2.UTObject.ReleaseObject;
    end
  else
    begin
      k := {$IF CompilerVersion > 21.0}FormatSettings.{$IFEND}DecimalSeparator;
      {$IF CompilerVersion > 21.0}FormatSettings.{$IFEND}decimalSeparator := '.';
      basename := UTobjectname;
      // do not localize
      uc := '//============================================================================='#13#10;
      uc := uc + format('// %s.'#13#10, [basename]);
      uc := uc + '//============================================================================='#13#10;
      uc := uc + format('class %s extends %s;'#13#10#13#10, [basename, parent_class]);
      uc := uc + format('#exec MESH IMPORT MESH=%s ANIVFILE=MODELS\%s_a.3d DATAFILE=MODELS\%s_d.3d' {+' X=0 Y=0 Z=0'}, [basename, basename, basename]);
      uc := uc + #13#10;
      uc := uc + format('#exec MESH LODPARAMS MESH=%s HYSTERESIS=%f STRENGTH=%f MINVERTS=%f MORPH=%f ZDISP=%f'#13#10,
        [basename, FLODHysteresis, FLODStrength, FLODMinVerts, FLODMorph, FLODZDisplace]);
      uc := uc + format('#exec MESH ORIGIN MESH=%s X=%f Y=%f Z=%f YAW=%f ROLL=%f PITCH=%f'#13#10#13#10,
        [basename, FOrigin.x, FOrigin.y, FOrigin.z, FRotorigin.Yaw / 256, FRotOrigin.Roll / 256, FRotOrigin.Pitch / 256]);
      for a := 0 to high(FAnimSeqs) do
        begin
          uc := uc + format('#exec MESH SEQUENCE MESH=%s SEQ=%-9s STARTFRAME=%d NUMFRAMES=%d', [basename, FOwner.Names[FAnimSeqs[a].name], FAnimSeqs[a].startframe, FAnimSeqs[a].numframes]);
          if FAnimSeqs[a].rate <> 30 then uc := uc + format(' RATE=%f', [FAnimSeqs[a].rate]);
          if FOwner.Names[FAnimSeqs[a].group] <> 'None' then uc := uc + format(' GROUP=%s', [FOwner.Names[FAnimSeqs[a].group]]);
          uc := uc + #13#10;
        end;
      uc := uc + #13#10;
      for a := 0 to high(FTextures) do
        if FTextures[a].value > 0 then
          begin
            ed2 := FOwner.Exported[FTextures[a].value - 1];
            uc := uc + format('#exec TEXTURE IMPORT NAME=%s FILE=%s.PCX GROUP=%s'#13#10,
              [ed2.UTobjectname, ed2.UTobjectname, ed2.UTpackagename]);
            // TODO : TUTObjectClassLodMesh.Save_UnrealUC : FLAGS=%d should put correct flags...
          end
        else if FTextures[a].value < 0 then
          begin
            id := FOwner.Imported[-FTextures[a].value - 1];
            uc := uc + format('#exec OBJ LOAD FILE=%s.utx PACKAGE=%s'#13#10, [id.UTobjectname, id.UTpackagename]);
          end;
      uc := uc + #13#10;
      for a := 0 to high(FTextures) do
        if FTextures[a].value > 0 then
          begin
            ed2 := FOwner.Exported[FTextures[a].value - 1];
            uc := uc + format('#exec MESHMAP SETTEXTURE MESHMAP=%s NUM=%d TEXTURE=%s'#13#10, [basename, a, ed2.UTobjectname]);
          end
        else if FTextures[a].value < 0 then
          begin
            id := FOwner.Imported[-FTextures[a].value - 1];
            uc := uc + format('#exec MESHMAP SETTEXTURE MESHMAP=%s NUM=%d TEXTURE=%s'#13#10, [basename, a, id.UTpackagename + '.' + id.UTobjectname]);
          end;
      uc := uc + #13#10;
      //uc:=uc+format('#exec MESHMAP NEW   MESHMAP=%s MESH=%s'#13#10,[basename,basename]);
      if (FScale.x <> 0.1) or (FScale.y <> 0.1) or (FScale.z <> 0.2) then
        uc := uc + format('#exec MESHMAP SCALE MESHMAP=%s X=%f Y=%f Z=%f'#13#10#13#10, [basename, FScale.x, FScale.y, FScale.z]);
      // FScale is incorrect, sometimes is 0 and it shouldnt be.
      for a := 0 to high(FAnimSeqs) do
        for b := 0 to high(FAnimSeqs[a].notifys) do
          uc := uc + format('#exec MESH NOTIFY MESH=%s SEQ=%-9s TIME=%f FUNCTION=%s'#13#10, [basename, FOwner.Names[FAnimSeqs[a].name], FAnimSeqs[a].notifys[b].time, FOwner.Names[FAnimSeqs[a].notifys[b]._function]]);
      uc := uc + #13#10;
      (*uc:=uc+#13#10+
      'defaultproperties'#13#10+
      '{'#13#10+
      '    DrawType=DT_Mesh'#13#10+
      format('    Mesh=%s'#13#10,[basename])+
      '}'#13#10;*)
      {$IF CompilerVersion > 21.0}FormatSettings.{$IFEND}DecimalSeparator := k;
      str_uc := tfilestream.create(filename, fmCreate);
      try
        str_uc.write(uc[1], length(uc));
      finally
        str_uc.free;
      end;
    end;
end;

{ TUTObjectClassFireTexture }

function TUTObjectClassFireTexture.GetSpark(i: integer): TUT_Struct_Spark;
begin
  check_initialized;
  result := FSparks[i];
end;

function TUTObjectClassFireTexture.GetSparkCount: integer;
begin
  check_initialized;
  result := length(FSparks);
end;

procedure TUTObjectClassFireTexture.InitializeObject;
begin
  inherited;
  setlength(FSparks, 0);
end;

procedure TUTObjectClassFireTexture.InterpretObject;
var
  s: integer;
begin
  inherited;
  setlength(FSparks, FOwner.read_idx(buffer));
  for s := 0 to high(FSparks) do
    FSparks[s] := Read_Struct_Spark(FOwner, buffer);
end;

procedure TUTObjectClassFireTexture.DoReleaseObject;
begin
  setlength(FSparks, 0);
  inherited;
end;

{ TUTObjectClassField }

function TUTObjectClassField.GetNext: integer;
begin
  check_initialized;
  result := FNext;
end;

function TUTObjectClassField.GetSuperField: integer;
begin
  check_initialized;
  result := FSuperField;
end;

procedure TUTObjectClassField.InitializeObject;
begin
  inherited;
  FSuperField := 0;
  FNext := 0;
end;

procedure TUTObjectClassField.InterpretObject;
begin
  inherited;
  FSuperField := FOwner.read_idx(buffer);
  FNext := FOwner.read_idx(buffer);
end;

procedure TUTObjectClassField.DoReleaseObject;
begin
  FSuperField := 0;
  FNext := 0;
  inherited;
end;

{ TUTObjectEnum }

function TUTObjectClassEnum.GetCount: integer;
begin
  check_initialized;
  result := length(FValues);
end;

function TUTObjectClassEnum.GetDeclaration: string;
var
  a: integer;
begin
  check_initialized;
  result := '';
  for a := 0 to count - 1 do
    begin
      result := result + EnumName[a];
      if a < count - 1 then result := result + ',';
      result := result + #13#10;
    end;
  result := FOwner.IndentText(#9, result);
  result := 'enum ' + UTobjectname + ' {'#13#10 + result + '}';
end;

function TUTObjectClassEnum.GetValue(i: integer): integer;
begin
  check_initialized;
  if (i >= 0) and (i < length(FValues)) then
    result := FValues[i]
  else
    result := 0;
end;

function TUTObjectClassEnum.GetValueName(i: integer): string;
begin
  check_initialized;
  if (i >= 0) and (i < length(FValues)) then
    result := FOwner.Names[FValues[i]]
  else
    result := '';
end;

procedure TUTObjectClassEnum.InitializeObject;
begin
  inherited;
  setlength(FValues, 0);
end;

procedure TUTObjectClassEnum.InterpretObject;
var
  a: integer;
begin
  inherited;
  setlength(FValues, FOwner.read_idx(buffer));
  for a := 0 to high(FValues) do
    FValues[a] := FOwner.read_idx(buffer);
end;

procedure TUTObjectClassEnum.DoReleaseObject;
begin
  setlength(FValues, 0);
  inherited;
end;

{ TUTObjectClassConst }

function TUTObjectClassConst.GetDeclaration: string;
begin
  check_initialized;
  result := 'const ' + UTobjectname + '=' + Value;
end;

function TUTObjectClassConst.GetValue: string;
begin
  check_initialized;
  result := FValue;
end;

procedure TUTObjectClassConst.InitializeObject;
begin
  inherited;
  FValue := '';
end;

procedure TUTObjectClassConst.InterpretObject;
begin
  inherited;
  FValue := FOwner.read_sizedasciiz(buffer);
end;

procedure TUTObjectClassConst.DoReleaseObject;
begin
  FValue := '';
  inherited;
end;

{ TUTObjectClassProperty }

function TUTObjectClassProperty.GetArrayDimension: integer;
begin
  check_initialized;
  result := FArrayDimension;
end;

function TUTObjectClassProperty.GetCategory: string;
begin
  check_initialized;
  result := FCategory;
end;

function TUTObjectClassProperty.GetDeclaration(context, cn: string): string;
var
  flags: string;
begin
  check_initialized;
  flags := GetFlags(cn);
  if (context <> '') and (copy(flags, 1, 1) <> '(') then context := context + ' ';
  result := format('%s%s%s %s', [context, flags, TypeName, UTObjectName]);
  if FArrayDimension > 1 then result := result + format('[%d]', [FArrayDimension]);
end;

function TUTObjectClassProperty.GetElementSize: integer;
begin
  check_initialized;
  result := FElementSize;
end;

function TUTObjectClassProperty.GetFlags(cn: string): string;
var
  flags, varcategory: string;
begin
  check_initialized;
  flags := '';
  if (PropertyFlags and CPF_Edit) <> 0 then
    begin
      if category = cn then
        varcategory := ''
      else
        varcategory := category;
      varcategory := '(' + varcategory + ')';
      varcategory := varcategory + ' ';
    end
  else
    varcategory := '';
  if (PropertyFlags and CPF_Const) <> 0 then flags := flags + 'const ';
  if (PropertyFlags and CPF_Input) <> 0 then flags := flags + 'input ';
  if (PropertyFlags and CPF_ExportObject) <> 0 then flags := flags + 'exportobject ';
  if (PropertyFlags and CPF_OptionalParm) <> 0 then flags := flags + 'optional ';
  //if (PropertyFlags and CPF_Net) <> 0 then flags := flags + 'net ';
  if (PropertyFlags and CPF_ConstRef) <> 0 then flags := flags + 'constref ';
  if ((PropertyFlags and CPF_OutParm) <> 0) and
    ((PropertyFlags and CPF_ReturnParm) = 0) then flags := flags + 'out ';
  if (PropertyFlags and CPF_SkipParm) <> 0 then flags := flags + 'skip ';
  if (PropertyFlags and CPF_CoerceParm) <> 0 then flags := flags + 'coerce ';
  if (PropertyFlags and CPF_Native) <> 0 then flags := flags + 'native ';
  if (PropertyFlags and CPF_Transient) <> 0 then flags := flags + 'transient ';
  if ((PropertyFlags and CPF_Config) <> 0) and
    ((PropertyFlags and CPF_GlobalConfig) = 0) then flags := flags + 'config ';
  if (PropertyFlags and CPF_Localized) <> 0 then flags := flags + 'localized ';
  if (PropertyFlags and CPF_Travel) <> 0 then flags := flags + 'travel ';
  if (PropertyFlags and CPF_EditConst) <> 0 then flags := flags + 'editconst ';
  if (PropertyFlags and CPF_GlobalConfig) <> 0 then flags := flags + 'globalconfig ';
  if (PropertyFlags and CPF_OnDemand) <> 0 then flags := flags + 'ondemand ';
  if (PropertyFlags and CPF_New) <> 0 then flags := flags + 'new ';
  //if (variable.PropertyFlags and CPF_NeedCtorLink) <> 0 then flags := flags + 'needctorlink ';
  if (UTflags and RF_Public) = 0 then flags := flags + 'private ';
  result := varcategory + flags;
end;

function TUTObjectClassProperty.GetPropertyFlags: longword;
begin
  check_initialized;
  result := FPropertyFlags;
end;

function TUTObjectClassProperty.GetRepOffset: word;
begin
  check_initialized;
  result := FRepOffset;
end;

procedure TUTObjectClassProperty.InitializeObject;
begin
  inherited;
  FArrayDimension := 0;
  FElementSize := 0;
  FPropertyFlags := 0;
  FCategory := '';
  FRepOffset := $FFFF;
end;

procedure TUTObjectClassProperty.InterpretObject;
begin
  inherited;
  FArrayDimension := FOwner.read_word(buffer);
  FElementSize := FOwner.read_word(buffer);
  FPropertyFlags := FOwner.read_int(buffer);
  FCategory := FOwner.Names[FOwner.read_idx(buffer)];
  if (FPropertyFlags and CPF_Net) <> 0 then FRepOffset := FOwner.read_word(buffer);
end;

procedure TUTObjectClassProperty.DoReleaseObject;
begin
  FArrayDimension := 0;
  FElementSize := 0;
  FPropertyFlags := 0;
  FCategory := '';
  FRepOffset := $FFFF;
  inherited;
end;

function TUTObjectClassProperty.TypeName: string;
begin
  check_initialized;
  result := 'property';
end;

{ TUTObjectClassByteProperty }

function TUTObjectClassByteProperty.GetEnum: integer;
begin
  check_initialized;
  result := FEnum;
end;

procedure TUTObjectClassByteProperty.InitializeObject;
begin
  inherited;
  FEnum := 0;
end;

procedure TUTObjectClassByteProperty.InterpretObject;
begin
  inherited;
  FEnum := FOwner.read_idx(buffer);
end;

procedure TUTObjectClassByteProperty.DoReleaseObject;
begin
  FEnum := 0;
  inherited;
end;

function TUTObjectClassByteProperty.TypeName: string;
begin
  check_initialized;
  if FEnum = 0 then
    result := 'byte'
  else
    result := FOwner.GetObjectPath(1, FEnum);
end;

{ TUTObjectClassObjectProperty }

function TUTObjectClassObjectProperty.GetObject: integer;
begin
  check_initialized;
  result := FObject;
end;

procedure TUTObjectClassObjectProperty.InitializeObject;
begin
  inherited;
  FObject := 0;
end;

procedure TUTObjectClassObjectProperty.InterpretObject;
begin
  inherited;
  FObject := FOwner.read_idx(buffer);
end;

procedure TUTObjectClassObjectProperty.DoReleaseObject;
begin
  FObject := 0;
  inherited;
end;

function TUTObjectClassObjectProperty.TypeName: string;
begin
  check_initialized;
  result := FOwner.GetObjectPath(1, FObject);
end;

{ TUTObjectClassFixedArrayProperty }

function TUTObjectClassFixedArrayProperty.GetCount: integer;
begin
  check_initialized;
  result := FCount;
end;

function TUTObjectClassFixedArrayProperty.GetInner: integer;
begin
  check_initialized;
  result := FInner;
end;

procedure TUTObjectClassFixedArrayProperty.InitializeObject;
begin
  inherited;
  FInner := 0;
  FCount := 0;
end;

procedure TUTObjectClassFixedArrayProperty.InterpretObject;
begin
  inherited;
  FInner := FOwner.read_idx(buffer);
  FCount := FOwner.read_idx(buffer);
end;

procedure TUTObjectClassFixedArrayProperty.DoReleaseObject;
begin
  FInner := 0;
  FCount := 0;
  inherited;
end;

function TUTObjectClassFixedArrayProperty.TypeName: string;
begin
  check_initialized;
  result := FOwner.GetObjectPath(1, FInner) + '[' + inttostr(FCount) + ']'; // TODO : the variable name should go in-between?
end;

{ TUTObjectClassArrayProperty }

function TUTObjectClassArrayProperty.GetInner: integer;
begin
  check_initialized;
  result := FInner;
end;

procedure TUTObjectClassArrayProperty.InitializeObject;
begin
  inherited;
  FInner := 0;
end;

procedure TUTObjectClassArrayProperty.InterpretObject;
begin
  inherited;
  FInner := FOwner.read_idx(buffer);
end;

procedure TUTObjectClassArrayProperty.DoReleaseObject;
begin
  FInner := 0;
  inherited;
end;

function TUTObjectClassArrayProperty.TypeName: string;
var
  inner: string;
begin
  check_initialized;
  FOwner.Exported[FInner - 1].UTObject.ReadObject;
  inner := TUTObjectClassProperty(FOwner.Exported[FInner - 1].UTObject).TypeName;
  FOwner.Exported[FInner - 1].UTObject.ReleaseObject;
  result := 'array<' + inner + '>';
end;

{ TUTObjectClassMapProperty }

function TUTObjectClassMapProperty.GetKey: integer;
begin
  check_initialized;
  result := FKey;
end;

function TUTObjectClassMapProperty.GetValue: integer;
begin
  check_initialized;
  result := FValue;
end;

procedure TUTObjectClassMapProperty.InitializeObject;
begin
  inherited;
  FKey := 0;
  FValue := 0;
end;

procedure TUTObjectClassMapProperty.InterpretObject;
begin
  inherited;
  FKey := FOwner.read_idx(buffer);
  FValue := FOwner.read_idx(buffer);
end;

procedure TUTObjectClassMapProperty.DoReleaseObject;
begin
  FKey := 0;
  FValue := 0;
  inherited;
end;

function TUTObjectClassMapProperty.TypeName: string;
begin
  check_initialized;
  result := 'map';                      // TODO : fix map typename
end;

{ TUTObjectClassClassProperty }

function TUTObjectClassClassProperty.GetClass: integer;
begin
  check_initialized;
  result := FClass;
end;

procedure TUTObjectClassClassProperty.InitializeObject;
begin
  inherited;
  FClass := 0;
end;

procedure TUTObjectClassClassProperty.InterpretObject;
begin
  inherited;
  FClass := FOwner.read_idx(buffer);
end;

procedure TUTObjectClassClassProperty.DoReleaseObject;
begin
  FClass := 0;
  inherited;
end;

function TUTObjectClassClassProperty.TypeName: string;
begin
  check_initialized;
  result := FOwner.GetObjectPath(1, FClass);
  if lowercase(result) = 'object' then
    result := ''
  else
    result := '<' + result + '>';
  result := inherited TypeName + result;
end;

{ TUTObjectClassStructProperty }

function TUTObjectClassStructProperty.GetStruct: integer;
begin
  check_initialized;
  result := FStruct;
end;

procedure TUTObjectClassStructProperty.InitializeObject;
begin
  inherited;
  FStruct := 0;
end;

procedure TUTObjectClassStructProperty.InterpretObject;
begin
  inherited;
  FStruct := FOwner.read_idx(buffer);
end;

procedure TUTObjectClassStructProperty.DoReleaseObject;
begin
  FStruct := 0;
  inherited;
end;

function TUTObjectClassStructProperty.TypeName: string;
begin
  check_initialized;
  result := FOwner.GetObjectPath(1, FStruct);
end;

{ TUTObjectClassStruct }

function TUTObjectClassStruct.GetDeclaration: string;
var
  c: integer;
  child: TUTObjectClassField;
  r: string;
begin
  check_initialized;
  r := '';
  c := FChildren;
  while c <> 0 do
    begin
      child := TUTObjectClassField(FOwner.Exported[c - 1].UTObject);
      child.ReadObject;
      try
        if child is TUTObjectClassProperty then
          r := r + TUTObjectClassProperty(child).GetDeclaration('var', UTObjectName) + ';'#13#10;
        if child is TUTObjectClassEnum then
          r := r + TUTObjectClassEnum(child).GetDeclaration + ';'#13#10;
        c := child.next;
      finally
        child.ReleaseObject;
      end;
    end;
  r := FOwner.IndentText(#9, r);
  result := 'struct ' + UTObjectName;
  if FSuperField = 0 then
    result := result + #13#10'{'#13#10
  else
    result := result + ' expands ' + FOwner.GetObjectPath(1, FSuperField) + #13#10'{'#13#10;
  result := result + r + '}';
end;

procedure TUTObjectClassStruct.InitializeObject;
begin
  inherited;
  FScriptText := 0;
  FChildren := 0;
  FFriendlyName := '';
  FLine := 0;
  FTextPos := 0;
  FScriptSize := 0;
  FScriptStart := 0;
  JumpList := nil;
  indent_level := 0;
  position_icode := 0;
  last_position_icode := 0;
  setlength(FLabelTable, 0);
end;

procedure TUTObjectClassStruct.InterpretObject;
begin
  inherited;
  FScriptText := FOwner.read_idx(buffer);
  FChildren := FOwner.read_idx(buffer);
  FFriendlyName := FOwner.Names[FOwner.read_idx(buffer)];
  FLine := FOwner.read_int(buffer);
  FTextPos := FOwner.read_int(buffer);
  FScriptSize := FOwner.read_int(buffer);
  FScriptStart := buffer.position;
  JumpList := tlist.create;
  position_icode := 0;
  last_position_icode := 0;
  indent_level := 0;
  setlength(FLabelTable, 0);
  //SkipStatements;
end;

procedure TUTObjectClassStruct.DoReleaseObject;
begin
  FScriptText := 0;
  FChildren := 0;
  FFriendlyName := '';
  FTextPos := 0;
  FLine := 0;
  FScriptSize := 0;
  FScriptStart := 0;
  freeandnil(JumpList);
  position_icode := 0;
  last_position_icode := 0;
  indent_level := 0;
  setlength(FLabelTable, 0);
  inherited;
end;

function TUTObjectClassStruct.ReadToken(OuterOperatorPrecedence: byte): string;
var
  b: byte;
  i1, i2, i3: integer;
  f1, f2, f3: single;
  r1, r2, r3, r4, msg: string;
  letmp: TUT_Struct_LabelEntry;
  ds: char;
  wc: widestring;
  procedure read_parameters(var r: string);
  var
    r1: string;
  begin
    repeat
      r1 := ReadToken;
      if r1 = ')' then
        begin
          if copy(r, length(r), 1) = ',' then
            delete(r, length(r), 1);    // remove last comma
          r := r + r1;
        end
      else
        r := r + r1 + ',';
    until r1 = ')';
  end;
begin
  result := '';                         // gives a false warning
  check_initialized;
  inc(indent_level);
  b := FOwner.read_byte(buffer);
  inc(position_icode);
  case b of
    EX_JumpIfNot:
      begin
        i1 := FOwner.read_word(buffer);
        inc(position_icode, 2);
        r1 := ReadToken(OuterOperatorPrecedence); //(0); // the zero precedence will make it include parenthesis if it is an expression
        if (nest <> nil) and
          (i1 > position_icode) then    // we jump forward (the exclusion of an equal address is intentional)
          begin
            endnestlist.addobject('IF', pointer((position_icode shl 16) or i1));
            result := format('if ( %s )', [r1]);
            nest.add(pointer(NEST_If));
            need_semicolon := false;
          end
        else
          begin
            i2 := jumplist.indexof(pointer(i1));
            if i2 = -1 then i2 := jumplist.add(pointer(i1));
            //if copy(r1, 1, 1) <> '(' then r1 := '(' + r1 + ')';
            result := format('if (! %s ) goto JL%-4.4x', [r1, integer(jumplist[i2])]);
            need_semicolon := true;
          end;
      end;
    EX_LocalVariable, EX_InstanceVariable,
      EX_NativeParm:                    // EX_NativeParm will always be in the body of a native function
      begin
        i1 := FOwner.read_idx(buffer);
        inc(position_icode, 4);
        result := FOwner.GetObjectPath(1, i1);
      end;
    EX_DefaultVariable:
      begin
        i1 := FOwner.read_idx(buffer);
        inc(position_icode, 4);
        result := 'Default.' + FOwner.GetObjectPath(1, i1);
      end;
    EX_Return:
      begin
        if FOwner.Version > 61 then     // version 61 packages seem to not have a return value (KHGdemo)
          result := ReadToken(OuterOperatorPrecedence);
        if result <> '' then result := ' ' + result;
        result := 'return' + result;
        need_semicolon := true;
      end;
    EX_Nothing:
      begin
        result := '';
      end;
    EX_Let, EX_LetBool:
      begin
        if (b = EX_LetBool {0x14}) and (FOwner.Version = 61) and (position_icode = 1) then
          begin
            // Jump over unknown data (maybe an obsolete label table?)
            repeat
              i1 := FOwner.read_byte(buffer);
              inc(position_icode);
              if i1 > 0 then
                begin
                  FOwner.read_byte(buffer);
                  inc(position_icode);
                end;
            until i1 = 0;
          end
        else
          begin
            r1 := ReadToken(OuterOperatorPrecedence);
            r2 := ReadToken(OuterOperatorPrecedence);
            result := r1 + '=' + r2;
            need_semicolon := true;
          end;
      end;
    EX_ClassContext, EX_Context:
      begin
        result := ReadToken(OuterOperatorPrecedence) + '.';
        // following fields only used when class context is null -> not needed for source code
        FOwner.read_word(buffer);
        inc(position_icode, 2);         // wSkip
        FOwner.read_byte(buffer);
        inc(position_icode);            // bSize
        context_change := true;
        result := result + ReadToken(OuterOperatorPrecedence);
        context_change := false;
      end;
    EX_Unknown_jumpover:
      begin
        // This opcode has an unknown meaning, so we jump over it.
        // It has been seen in old packages (version 61, from the Klingon Honor Guard Demo)
        // at the end of functions and in the middle of some statements (if)
        // We treat it depending on the position.
        if indent_level = 1 then
          result := ''                  // do nothing
        else
          result := ReadToken(OuterOperatorPrecedence); // skip it
      end;
    EX_Unknown_jumpover2:
      begin
        // This opcode has an unknown meaning, so we jump over it.
        // It has been seen in old packages (version 61, from the Klingon Honor Guard Demo)
        // It seems to be some type of context change or type cast
        FOwner.read_byte(buffer);       // unknown byte
        inc(position_icode);
        result := ReadToken(OuterOperatorPrecedence);
      end;
    EX_EndFunctionParms:
      begin
        result := ')';
      end;
    EX_Self:
      begin
        result := 'self';
      end;
    EX_IntConst:
      begin
        result := format('%d', [FOwner.read_int(buffer)]);
        inc(position_icode, 4);
      end;
    EX_ByteConst, EX_IntConstByte:
      begin
        result := format('%d', [FOwner.read_byte(buffer)]);
        inc(position_icode);
      end;
    EX_FloatConst:
      begin
        ds := {$IF CompilerVersion > 21.0}FormatSettings.{$IFEND}DecimalSeparator;
        {$IF CompilerVersion > 21.0}FormatSettings.{$IFEND}DecimalSeparator := '.';
        result := format('%f', [FOwner.read_float(buffer)]);
        {$IF CompilerVersion > 21.0}FormatSettings.{$IFEND}DecimalSeparator := ds;
        inc(position_icode, 4);
      end;
    EX_ObjectConst:
      begin
        i1 := FOwner.read_idx(buffer);
        if i1 > 0 then
          result := FOwner.exported[i1 - 1].UTclassname
        else
          result := FOwner.imported[-i1 - 1].UTclassname;
        if result = '' then result := 'Class';
        result := format('%s''%s''', [result, FOwner.GetObjectPath(1, i1)]);
        inc(position_icode, 4);
      end;
    EX_NameConst:
      begin
        result := format('''%s''', [FOwner.Names[FOwner.read_idx(buffer)]]);
        inc(position_icode, 4);
      end;
    EX_StringConst:
      begin
        r1 := FOwner.read_asciiz(buffer);
        result := FOwner.GetStringConst(r1);
        inc(position_icode, length(r1) + 1);
      end;
    EX_UnicodeStringConst:
      begin
        wc := '';
        repeat
          i1 := FOwner.read_word(buffer);
          inc(position_icode, 2);
          if i1 > 0 then wc := wc + widechar(i1);
        until i1 = 0;
        result := FOwner.GetUnicodeStringConst(wc);
      end;
    EX_EatString:
      begin
        result := ReadToken(OuterOperatorPrecedence);
      end;
    EX_RotationConst:
      begin
        i1 := FOwner.read_int(buffer);
        inc(position_icode, 4);
        i2 := FOwner.read_int(buffer);
        inc(position_icode, 4);
        i3 := FOwner.read_int(buffer);
        inc(position_icode, 4);
        result := format('rot(%d,%d,%d)', [i1, i2, i3]);
      end;
    EX_VectorConst:
      begin
        f1 := FOwner.read_float(buffer);
        inc(position_icode, 4);
        f2 := FOwner.read_float(buffer);
        inc(position_icode, 4);
        f3 := FOwner.read_float(buffer);
        inc(position_icode, 4);
        ds := {$IF CompilerVersion > 21.0}FormatSettings.{$IFEND}DecimalSeparator;
        {$IF CompilerVersion > 21.0}FormatSettings.{$IFEND}DecimalSeparator := '.';
        result := format('vect(%f,%f,%f)', [f1, f2, f3]);
        {$IF CompilerVersion > 21.0}FormatSettings.{$IFEND}DecimalSeparator := ds;
      end;
    EX_IntZero:
      begin
        result := '0';
      end;
    EX_IntOne:
      begin
        result := '1';
      end;
    EX_True:
      begin
        result := 'True';
      end;
    EX_False:
      begin
        result := 'False';
      end;
    EX_NoObject:
      begin
        result := 'None';
      end;
    EX_DynamicCast:
      begin
        i1 := FOwner.read_idx(buffer);
        inc(position_icode, 4);
        result := FOwner.GetObjectPath(1, i1) + '(' + ReadToken(OuterOperatorPrecedence) + ')';
      end;
    EX_MetaCast:
      begin
        i1 := FOwner.read_idx(buffer);
        inc(position_icode, 4);
        result := 'Class<' + FOwner.GetObjectPath(1, i1) + '>(' + ReadToken(OuterOperatorPrecedence) + ')';
      end;
    EX_StructMember:
      begin
        i1 := FOwner.read_idx(buffer);
        inc(position_icode, 4);
        result := ReadToken(OuterOperatorPrecedence) + '.' + FOwner.GetObjectPath(1, i1);
      end;
    EX_Skip:
      begin
        FOwner.read_word(buffer);
        inc(position_icode, 2);         // jump address
        result := ReadToken(OuterOperatorPrecedence);
      end;
    EX_VectorToRotator, EX_StringToRotator:
      begin
        result := 'rotator(' + ReadToken(OuterOperatorPrecedence) + ')';
      end;
    EX_RotatorToVector, EX_StringToVector:
      begin
        result := 'vector(' + ReadToken(OuterOperatorPrecedence) + ')';
      end;
    EX_ObjectToBool, EX_NameToBool, EX_StringToBool, EX_VectorToBool, EX_RotatorToBool:
      begin
        result := 'bool(' + ReadToken(OuterOperatorPrecedence) + ')';
      end;
    EX_StringToByte:
      begin
        result := 'byte(' + ReadToken(OuterOperatorPrecedence) + ')';
      end;
    EX_StringToInt:
      begin
        result := 'int(' + ReadToken(OuterOperatorPrecedence) + ')';
      end;
    EX_StringToFloat:
      begin
        result := 'float(' + ReadToken(OuterOperatorPrecedence) + ')';
      end;
    EX_ByteToString, EX_IntToString, EX_BoolToString, EX_FloatToString,
      EX_ObjectToString, EX_NameToString, EX_VectorToString, EX_RotatorToString:
      begin
        result := 'string(' + ReadToken(OuterOperatorPrecedence) + ')';
      end;
    EX_StringToName:
      begin
        result := 'name(' + ReadToken(OuterOperatorPrecedence) + ')';
      end;
    EX_ByteToInt, EX_ByteToBool, EX_ByteToFloat, EX_IntToByte,
      EX_IntToBool, EX_IntToFloat, EX_BoolToByte, EX_BoolToInt, EX_BoolToFloat,
      EX_FloatToByte, EX_FloatToInt, EX_FloatToBool, EX_BoolVariable:
      begin
        result := ReadToken(OuterOperatorPrecedence);
      end;
    EX_Jump:
      begin
        i1 := FOwner.read_word(buffer);
        inc(position_icode, 2);         // jump address
        // check "If" case (end of if block)
        if (nest <> nil) and
          (nest.count > 0) and
          (endnestlist.count > 0) and
          (nest[nest.count - 1] = pointer(NEST_If)) and // we are inside an If statement
        (position_icode = (integer(endnestlist.objects[endnestlist.count - 1]) and $FFFF)) and // and we are at the end of the If block
        (position_icode - 3 > integer(endnestlist.objects[endnestlist.count - 1]) shr 16) and // but we are not at the start (case of a break inside an if)
        (i1 >= position_icode) then     // and we jump forward
          begin
            result := #8'}'#13#10'else'#13#10'{'; // the initial backspace is to correct indentation
            endnestlist[endnestlist.count - 1] := 'ELSE';
            endnestlist.objects[endnestlist.count - 1] := pointer(integer((longword(endnestlist.objects[endnestlist.count - 1]) and $FFFF0000)) or i1);
            nest[nest.count - 1] := pointer(NEST_Else);
            need_semicolon := false;
          end
            // check "Switch" case (break statement -> end of switch block)
        else if (nest <> nil) and
          (nest.count > 0) and
          (nest[nest.count - 1] = pointer(NEST_Switch)) and // we are inside a Switch statement
        (i1 >= position_icode) then     // and we jump forward
          begin
            result := 'break';
            need_semicolon := true;
            if ((endnestlist.count = 0) or ((integer(endnestlist.objects[endnestlist.count - 1]) and $FFFF) <> i1)) then
              endnestlist.addobject('SWITCH-BREAK', pointer((position_icode shl 16) or i1));
          end
        else
          begin
            i2 := jumplist.indexof(pointer(i1));
            if i2 = -1 then i2 := jumplist.add(pointer(i1));
            result := format('goto JL%-4.4x', [integer(jumplist[i2])]);
            need_semicolon := true;
          end;
      end;
    EX_ArrayElement:
      begin
        r1 := ReadToken(OuterOperatorPrecedence); // index
        r2 := ReadToken(OuterOperatorPrecedence); // base element
        result := r2 + '[' + r1 + ']';
      end;
    EX_DynArrayElement:
      begin
        r1 := ReadToken(OuterOperatorPrecedence); // index
        r2 := ReadToken(OuterOperatorPrecedence); // base element: not checked ???
        result := r2 + '[' + r1 + ']';
      end;
    EX_Switch:
      begin
        FOwner.read_byte(buffer);
        inc(position_icode);            // switch size
        r1 := ReadToken(OuterOperatorPrecedence); // switch expression
        if copy(r1, 1, 1) <> '(' then r1 := '(' + r1 + ')';
        result := 'switch ' + r1;
        need_semicolon := false;
        if nest <> nil then
          nest.add(pointer(NEST_Switch))
        else
          result := result + ' {';
      end;
    EX_Case:
      begin
        i1 := FOwner.read_word(buffer);
        inc(position_icode, 2);         // address of next case
        if i1 = $FFFF then
          begin
            result := 'default:';
            // add end of switch here is we had no break statements (but we could displace some default case statements)
            if (nest <> nil) and
              (nest.count > 0) and
              (nest[nest.count - 1] = pointer(NEST_Switch)) and // we are inside a Switch statement
            ((endnestlist.count = 0) or (endnestlist[endnestlist.count - 1] <> 'SWITCH-BREAK')) then // we dont have a previous switch end (by break)
              endnestlist.addobject('SWITCH', pointer((position_icode shl 16) or position_icode));
          end
        else
          result := 'case ' + ReadToken(OuterOperatorPrecedence) + ':';
        need_semicolon := false;
        // we dont know where the switch ends except for any "break" inside the cases
      end;
    EX_Iterator:
      begin
        r1 := ReadToken(OuterOperatorPrecedence);
        FOwner.read_word(buffer);
        inc(position_icode, 2);         // end of loop
        result := format('foreach %s', [r1]);
        need_semicolon := false;
        if nest <> nil then
          nest.add(pointer(NEST_Foreach))
        else
          result := result + ' {';
      end;
    EX_IteratorPop:
      begin
      end;
    EX_IteratorNext:
      begin
        if nest <> nil then
          nest.delete(nest.count - 1)
        else
          result := '}';
      end;
    EX_Stop:
      begin
        result := 'stop';               // just to flag the end, then removed
      end;
    EX_Assert:
      begin
        FOwner.read_word(buffer);
        inc(position_icode, 2);         // line number
        result := 'assert (' + ReadToken(OuterOperatorPrecedence) + ')';
        need_semicolon := true;
      end;
    EX_GotoLabel:
      begin
        result := 'goto (' + ReadToken(OuterOperatorPrecedence) + ')';
        need_semicolon := true;
      end;
    EX_StructCmpEq:
      begin
        FOwner.read_idx(buffer);
        inc(position_icode, 4);
        r1 := ReadToken(OuterOperatorPrecedence);
        r2 := ReadToken(OuterOperatorPrecedence);
        result := r1 + '==' + r2;
      end;
    EX_StructCmpNe:
      begin
        FOwner.read_idx(buffer);
        inc(position_icode, 4);
        r1 := ReadToken(OuterOperatorPrecedence);
        r2 := ReadToken(OuterOperatorPrecedence);
        result := r1 + '!=' + r2;
      end;
    EX_New:
      begin
        r1 := ReadToken(OuterOperatorPrecedence); // outer
        r2 := ReadToken(OuterOperatorPrecedence); // name
        r3 := ReadToken(OuterOperatorPrecedence); // flags
        r4 := ReadToken(OuterOperatorPrecedence); // class
        if r2 <> '' then r2 := ',' + r2;
        if r3 <> '' then r3 := ',' + r3;
        if r4 <> '' then r4 := ',' + r4;
        result := 'new (' + r1 + r2 + r3 + r4 + ')';
      end;
    EX_LabelTable:
      begin
        // follows an EX_Stop, and it will be aligned to 4 (filled with EX_Nothing)
        repeat
          letmp := Read_Struct_LabelEntry(FOwner, buffer);
          inc(position_icode, 8);
          if (lowercase(FOwner.Names[letmp.name]) <> 'none') then
            begin
              setlength(FLabelTable, length(FLabelTable) + 1);
              FLabelTable[high(FLabelTable)] := letmp;
            end;
        until (lowercase(FOwner.Names[letmp.name]) = 'none');
      end;
    EX_VirtualFunction:
      begin
        result := FOwner.Names[FOwner.read_idx(buffer)] + '(';
        inc(position_icode, 4);
        read_parameters(result);
        need_semicolon := true;
      end;
    EX_GlobalFunction:
      begin
        result := 'Global.' + FOwner.Names[FOwner.read_idx(buffer)] + '(';
        inc(position_icode, 4);
        read_parameters(result);
        need_semicolon := true;
      end;
    EX_FinalFunction:
      begin
        i1 := FOwner.read_idx(buffer);
        if (lowercase(FOwner.GetObjectPath(1, i1)) = lowercase(UTObjectName)) and
          (lowercase(FOwner.GetObjectPath(2, i1)) <> lowercase(FOwner.GetObjectPath(2, FExportedIndex))) then
          begin                         // If it is the same name as self but different owner
            // TODO : may fail if owner is an State ?
            // get called function owner
            r1 := FOwner.GetObjectPath(2, i1);
            i2 := pos('.', r1);
            r1 := copy(r1, 1, i2 - 1);
            // get owner from current function owner
            r2 := FOwner.GetObjectPath(2, FSuperField);
            i2 := pos('.', r2);
            r2 := copy(r2, 1, i2 - 1);
            // compare
            if lowercase(r1) = lowercase(r2) then
              result := 'Super.'
            else
              result := 'Super(' + r1 + ').';
          end
        else
          result := '';
        result := result + FOwner.GetObjectPath(1, i1) + '(';
        inc(position_icode, 4);
        read_parameters(result);
        need_semicolon := true;
      end
  else
    begin
      if b < EX_ExtendedNative then
        begin
          msg := format(rsUnknownOpcode, [b]);
          //windows.messagebox(0, pchar(msg), pchar(rsWarning), mb_ok);
          result := format('UnknownOpcode0x%-2.2x(', [b]) + ReadToken(OuterOperatorPrecedence) + ')'; // we suppose it has function/conversion format
          raise Exception.create(msg);
        end
      else                              // other native function
        begin
          if (b and $F0) = EX_ExtendedNative then // high native flag
            begin
              i1 := ((b - EX_ExtendedNative) shl 8) + FOwner.read_byte(buffer);
              inc(position_icode, 1);
            end
          else
            i1 := b;
          if i1 < EX_FirstNative then raise exception.create(format(rsInvalidNativeIndex, [i1]));
          i3 := -1;
          for i2 := 0 to high(NativeFunctions) do
            if NativeFunctions[i2].index = i1 then
              begin
                i3 := i2;
                break;
              end;
          if i3 <> -1 then
            begin
              if lowercase(NativeFunctions[i3].Name) = lowercase(UTObjectName) then
                begin                   // If it is the same name as self. Could also be recursion.
                  result := 'Super.';
                end
              else
                result := '';
              case NativeFunctions[i3].Format of
                nffFunction:
                  begin
                    result := result + NativeFunctions[i3].Name + '(';
                    read_parameters(result);
                  end;
                nffPreOperator:
                  begin
                    result := result + NativeFunctions[i3].Name + ReadToken(OuterOperatorPrecedence);
                    ReadToken(OuterOperatorPrecedence); // end params
                    if indent_level > 1 then result := ' ' + result;
                  end;
                nffPostOperator:
                  begin
                    result := ReadToken(OuterOperatorPrecedence) + result + NativeFunctions[i3].Name;
                    ReadToken(OuterOperatorPrecedence); // end params
                    if indent_level > 1 then result := result + ' ';
                  end;
                nffOperator:
                  begin
                    r1 := ReadToken(NativeFunctions[i3].OperatorPrecedence);
                    r2 := ReadToken(NativeFunctions[i3].OperatorPrecedence);
                    ReadToken(OuterOperatorPrecedence); // end params
                    result := r1 + ' ' + result + NativeFunctions[i3].Name + ' ' + r2;
                    if indent_level > 1 then
                      if NativeFunctions[i3].OperatorPrecedence > OuterOperatorPrecedence then
                        result := '(' + result + ')';
                  end;
              end;
            end
          else
            begin
              result := result + format('UnknownFunction%d(', [i1]);
              read_parameters(result);
            end;
          need_semicolon := true;
        end;
    end;
  end;
  dec(indent_level);
end;

function TUTObjectClassStruct.ReadStatement: string;
var
  a, previous_nest_level, n: integer;
  s, comment: string;
begin
  if nest <> nil then
    previous_nest_level := nest.count
  else
    previous_nest_level := 0;
  last_position_icode := position_icode;
  result := ReadToken;
  // remove backspaces (when it is an Else)
  s := indent_chars;
  while copy(result, 1, 1) = #8 do
    begin
      delete(s, length(s), 1);
      delete(result, 1, 1);
    end;
  // add indent and semicolon
  if (result <> '') then
    begin
      result := FOwner.indenttext(s, result);
      if need_semicolon then result := result + ';';
    end;

  // check jumps
  n := 0;
  if nest <> nil then
    begin
      for a := 0 to endnestlist.count - 1 do
        if (last_position_icode < integer(endnestlist.objects[a]) and $FFFF) and
          (integer(endnestlist.objects[a]) and $FFFF < position_icode) then inc(n);
    end
  else
    begin
      for a := 0 to jumplist.count - 1 do
        if (last_position_icode < integer(jumplist[a])) and
          (integer(jumplist[a]) < position_icode) then inc(n);
    end;
  if n > 0 then result := result + #13#10 + indent_chars + '// There are ' + inttostr(n) + ' jump destination(s) inside the last statement!';

  // change indent
  if nest <> nil then
    begin
      // add indenting and block open braces
      a := previous_nest_level;
      while a < nest.Count do
        begin
          if result <> '' then result := result + #13#10;
          result := result + indent_chars + '{';
          indent_chars := indent_chars + #9;
          inc(a);
        end;
      // decrease nest levels
      comment := '';
      while (endnestlist.count > 0) and
        (integer(endnestlist.objects[endnestlist.count - 1]) and $FFFF <= position_icode) do
        begin
          //if (integer(endnestlist.objects[endnestlist.count - 1]) and $FFFF < position_icode) then comment:=' // there is a jump destination in-between the last statement!';
          nest.delete(nest.count - 1);
          endnestlist.delete(endnestlist.count - 1);
        end;
      // add unindenting and block close braces
      a := previous_nest_level;
      while a > nest.Count do
        begin
          if result <> '' then result := result + #13#10;
          delete(indent_chars, length(indent_chars), 1);
          result := result + indent_chars + '}' + comment;
          comment := '';
          dec(a);
        end;
    end;
end;

function TUTObjectClassStruct.ReadStatements(beautify: boolean): string;
var
  statement: string;
  code: tstringlist;
  a, i: integer;
begin
  check_initialized;
  result := '';
  jumplist.clear;
  setlength(FLabelTable, 0);
  // read code statements
  code := tstringlist.create;
  if beautify then
    begin
      nest := tlist.create;
      endnestlist := tstringlist.create;
    end;
  indent_chars := '';
  while position_icode < FScriptSize do
    begin
      need_semicolon := false;
      labellist := '';
      i := position_icode;
      statement := ReadStatement;
      if statement <> '' then code.addobject(statement, pointer(i));
    end;
  if beautify then
    begin
      freeandnil(nest);
      freeandnil(endnestlist);
    end;
  // add labels and indent
  a := 0;
  while a < code.count do
    begin
      if (integer(code.objects[a]) and $FFFF) >= 0 then
        begin
          // normal labels
          i := JumpList.indexof(pointer(integer(code.objects[a]) and $FFFF));
          if i >= 0 then
            begin
              code.InsertObject(a, format('JL%-4.4x:', [integer(code.objects[a]) and $FFFF]), pointer(-1));
              inc(a);
              jumplist.delete(i);
            end;
          // state labels
          for i := 0 to high(FLabelTable) do
            if FLabelTable[i].iCode = (integer(code.objects[a]) and $FFFF) then
              begin
                code.InsertObject(a, FOwner.Names[FLabelTable[i].name] + ':', pointer(-1));
                inc(a);
              end;
        end;
      code[a] := FOwner.indenttext(#9, code[a]);
      inc(a);
    end;
  result := code.text;
  code.free;
end;

procedure TUTObjectClassStruct.SkipStatements;
begin
  check_initialized;
  while position_icode < FScriptSize do
    ReadToken;
  setlength(FLabelTable, 0);
  jumplist.clear;
end;

function TUTObjectClassStruct.GetChildren: integer;
begin
  check_initialized;
  result := FChildren;
end;

function TUTObjectClassStruct.GetFriendlyName: string;
begin
  check_initialized;
  result := FFriendlyName;
end;

function TUTObjectClassStruct.GetLine: integer;
begin
  check_initialized;
  result := FLine;
end;

function TUTObjectClassStruct.GetScriptSize: integer;
begin
  check_initialized;
  result := FScriptSize;
end;

function TUTObjectClassStruct.GetScriptText: integer;
begin
  check_initialized;
  result := FScriptText;
end;

function TUTObjectClassStruct.GetTextPos: integer;
begin
  check_initialized;
  result := FTextPos;
end;

{ TUTObjectClassFunction }

procedure TUTObjectClassFunction.InitializeObject;
begin
  inherited;
  FiNative := 0;
  FRepOffset := $FFFF;
  FOperatorPrecedence := 0;
  FFunctionFlags := 0;
end;

procedure TUTObjectClassFunction.InterpretObject;
begin
  inherited;
  try
    SkipStatements;
    if FOwner.Version <= 63 then FOwner.read_word(buffer); // ParmsSize
    FiNative := FOwner.read_word(buffer);
    if FOwner.Version <= 63 then FOwner.read_byte(buffer); // NumParms
    FOperatorPrecedence := FOwner.read_byte(buffer);
    if FOwner.Version <= 63 then FOwner.read_word(buffer); // ReturnValueOffset
    FFunctionFlags := FOwner.read_int(buffer);
    if (FunctionFlags and FUNC_Net) <> 0 then FRepOffset := FOwner.read_word(buffer);
  except
  end;
end;

procedure TUTObjectClassFunction.DoReleaseObject;
begin
  FiNative := 0;
  FRepOffset := $FFFF;
  FOperatorPrecedence := 0;
  FFunctionFlags := 0;
  inherited;
end;

function TUTObjectClassFunction.Decompile(beautify: boolean): string;
const
  indentation = #9;
var
  code, function_name, parameters, result_type,
    locals, function_flags: string;
  c: integer;
  prop: TUTObjectClassProperty;
begin
  check_initialized;
  buffer.seek(FScriptStart, soFromBeginning);
  result := '';
  code := '';
  try
    function_name := FFriendlyName;
    result_type := '';
    parameters := '';
    locals := '';
    function_flags := '';
    if (FFunctionFlags and FUNC_Native) <> 0 then
      begin
        if FiNative > 0 then
          function_flags := function_flags + format('native(%d) ', [FiNative])
        else
          function_flags := function_flags + 'native ';
      end;
    if (FFunctionFlags and FUNC_Static) <> 0 then function_flags := function_flags + 'static ';
    if (FFunctionFlags and FUNC_Final) <> 0 then function_flags := function_flags + 'final ';
    //if (FFunctionFlags and FUNC_Defined)<>0 then function_flags:=function_flags+'defined ';
    if (FFunctionFlags and FUNC_Iterator) <> 0 then function_flags := function_flags + 'iterator ';
    if (FFunctionFlags and FUNC_Latent) <> 0 then function_flags := function_flags + 'latent ';
    if (FFunctionFlags and FUNC_Singular) <> 0 then function_flags := function_flags + 'singular ';
    //if (FFunctionFlags and FUNC_Net) <> 0 then function_flags := function_flags + 'net ';
    //if (FFunctionFlags and FUNC_NetReliable) <> 0 then function_flags := function_flags + 'netreliable ';
    if (FFunctionFlags and FUNC_Simulated) <> 0 then function_flags := function_flags + 'simulated ';
    if (FFunctionFlags and FUNC_Exec) <> 0 then function_flags := function_flags + 'exec ';
    if (FFunctionFlags and FUNC_Event) <> 0 then function_flags := function_flags + 'event ';
    if (FFunctionFlags and FUNC_NoExport) <> 0 then function_flags := function_flags + 'noexport ';
    if (FFunctionFlags and FUNC_Const) <> 0 then function_flags := function_flags + 'const ';
    if (FFunctionFlags and FUNC_Invariant) <> 0 then function_flags := function_flags + 'invariant ';
    if (FFunctionFlags and FUNC_Operator) <> 0 then
      begin
        if (FFunctionFlags and FUNC_PreOperator) <> 0 then
          function_flags := function_flags + 'preoperator '
        else if FOperatorPrecedence = 0 then
          function_flags := function_flags + 'postoperator '
        else
          function_flags := function_flags + format('operator(%d) ', [FOperatorPrecedence]);
      end;
    if ((FFunctionFlags and FUNC_Operator) = 0) and
      ((FFunctionFlags and FUNC_Event) = 0) then
      function_flags := function_flags + 'function ';

    c := FChildren;
    while c <> 0 do
      begin
        dec(c);
        if not (FOwner.Exported[c].UTObject is TUTObjectClassProperty) then break;
        prop := TUTObjectClassProperty(FOwner.Exported[c].UTObject);
        try
          try
            prop.ReadObject;
            if (prop.PropertyFlags and CPF_Parm) <> 0 then
              begin                     // function parameter, could also be a return value
                if (prop.PropertyFlags and CPF_ReturnParm) <> 0 then
                  begin
                    result_type := prop.GetFlags(UTobjectname) + prop.TypeName;
                  end
                else
                  begin
                    parameters := parameters + prop.GetDeclaration('', UTobjectname) + ', ';
                  end;
              end
            else
              begin                     // local variable
                locals := locals + indentation + prop.GetDeclaration('local', UTobjectname) + ';'#13#10;
              end;
            c := prop.Next;
          finally
            prop.ReleaseObject;
          end;
        except
          c := 0;
        end;
      end;
    if parameters <> '' then delete(parameters, length(parameters) - 1, 2);
    if result_type <> '' then result_type := result_type + ' ';
    if locals <> '' then locals := locals + #13#10;
    code := format('%s%s%s (%s)', [function_flags, result_type, function_name, parameters]);
    if (FFunctionFlags and FUNC_Defined) <> 0 then
      begin
        position_icode := 0;
        code := code + format(#13#10'{'#13#10'%s', [locals]);
        code := code + ReadStatements(beautify);
        // remove last "return;" line
        c := length(code);
        while (c > 0) and (code[c] <> #13) do
          dec(c);
        while (c > 0) and (code[c] <> #10) do
          dec(c);
        code := copy(code, 1, c);
        code := code + '}'#13#10;
      end
    else
      code := code + ';'#13#10;         // native functions do not have code
  except
  end;
  result := code;
end;

function TUTObjectClassFunction.GetFunctionFlags: longword;
begin
  check_initialized;
  result := FFunctionFlags;
end;

function TUTObjectClassFunction.GetiNative: integer;
begin
  check_initialized;
  result := FiNative;
end;

function TUTObjectClassFunction.GetOperatorPrecedence: integer;
begin
  check_initialized;
  result := FOperatorPrecedence;
end;

function TUTObjectClassFunction.GetRepOffset: integer;
begin
  check_initialized;
  result := FRepOffset;
end;

{ TUTObjectClassIntProperty }

function TUTObjectClassIntProperty.TypeName: string;
begin
  check_initialized;
  result := 'int';
end;

{ TUTObjectClassBoolProperty }

function TUTObjectClassBoolProperty.TypeName: string;
begin
  check_initialized;
  result := 'bool';
end;

{ TUTObjectClassFloatProperty }

function TUTObjectClassFloatProperty.TypeName: string;
begin
  check_initialized;
  result := 'float';
end;

{ TUTObjectClassNameProperty }

function TUTObjectClassNameProperty.TypeName: string;
begin
  check_initialized;
  result := 'name';
end;

{ TUTObjectClassStrProperty }

function TUTObjectClassStrProperty.TypeName: string;
begin
  check_initialized;
  result := 'string';
end;

{ TUTObjectClassStringProperty }

function TUTObjectClassStringProperty.TypeName: string;
begin
  check_initialized;
  result := 'string';                   // old fixed-length string type
end;

{ TUTObjectClassState }

function TUTObjectClassState.Decompile(beautify: boolean): string;
var
  c: integer;
  child: TUTObject;
  statements, header, var_block, ignored_functions: string;
  result_str: tstringlist;
begin
  check_initialized;
  buffer.seek(FScriptStart, soFromBeginning);
  result := '';
  c := FChildren;
  var_block := '';
  ignored_functions := '';
  while c <> 0 do
    begin
      child := FOwner.Exported[c - 1].UTObject;
      try
        child.ReadObject;
        if child is TUTObjectClassField then
          begin
            if child is TUTObjectClassFunction then
              begin
                if (TUTObjectClassFunction(child).FunctionFlags and FUNC_Defined) <> 0 then
                  result := TUTObjectClassFunction(child).Decompile(beautify) + #13#10 + result
                else
                  ignored_functions := ignored_functions + ', ' + TUTObjectClassFunction(child).UTObjectName;
              end
            else if child is TUTObjectClassProperty then
              begin                     // it is a variable (may not exist in states?)
                var_block := var_block + TUTObjectClassProperty(child).GetDeclaration('local', UTobjectname) + ';'#13#10;
              end
            else if child is TUTObjectClassConst then
              begin                     // it is a const
                var_block := var_block + TUTObjectClassConst(child).GetDeclaration + ';'#13#10;
              end
            else if child is TUTObjectClassEnum then
              begin                     // it is an enum
                var_block := var_block + TUTObjectClassEnum(child).GetDeclaration + ';'#13#10#13#10;
              end
            else if (child is TUTObjectClassStruct) and
              not ((child is TUTObjectClassFunction) or (child is TUTObjectClassState)) then
              begin                     // it is an struct
                var_block := var_block + TUTObjectClassStruct(child).GetDeclaration + ';'#13#10#13#10;
              end;
            c := TUTObjectClassField(child).Next;
          end
        else
          c := 0;
      finally
        child.ReleaseObject;
      end;
    end;

  if ignored_functions <> '' then
    begin
      delete(ignored_functions, 1, 1);
      ignored_functions := 'ignores ' + ignored_functions + ';'#13#10#13#10;
    end;
  if var_block <> '' then var_block := var_block + #13#10;

  result := var_block + ignored_functions + result;
  position_icode := 0;
  header := '';
  if (FStateFlags and STATE_Auto) <> 0 then header := header + 'auto ';
  if (FStateFlags and STATE_Simulated) <> 0 then header := header + 'simulated ';
  if (FStateFlags and STATE_Editable) <> 0 then
    header := header + 'state() '
  else
    header := header + 'state ';
  header := header + UTObjectName;
  if SuperField <> 0 then header := header + ' expands ' + FOwner.GetObjectPath(1, SuperField);
  result := header + #13#10'{'#13#10 + FOwner.IndentText(#9, result);
  statements := ReadStatements(beautify);
  if statements <> '' then result := result + Statements;
  result_str := tstringlist.create;
  result_str.text := result;
  result_str.delete(result_str.count - 1); // remove last "stop;" line
  result := result_str.text;
  result := result + '}'#13#10;
end;

function TUTObjectClassState.GetIgnoreMask: int64;
begin
  check_initialized;
  result := FIgnoreMask;
end;

function TUTObjectClassState.GetLabelTableOffset: word;
begin
  check_initialized;
  result := FLabelTableOffset;
end;

function TUTObjectClassState.GetProbeMask: int64;
begin
  check_initialized;
  result := FProbeMask;
end;

function TUTObjectClassState.GetStateFlags: longword;
begin
  check_initialized;
  result := FStateFlags;
end;

procedure TUTObjectClassState.InitializeObject;
begin
  inherited;
  FProbeMask := 0;
  FIgnoreMask := 0;
  FStateFlags := 0;
  FLabelTableOffset := 0;
end;

procedure TUTObjectClassState.InterpretObject;
begin
  inherited;
  SkipStatements;
  FProbeMask := FOwner.read_qword(buffer);
  FIgnoreMask := FOwner.read_qword(buffer);
  FLabelTableOffset := FOwner.read_word(buffer);
  FStateFlags := FOwner.read_int(buffer);
end;

procedure TUTObjectClassState.DoReleaseObject;
begin
  FProbeMask := 0;
  FIgnoreMask := 0;
  FStateFlags := 0;
  FLabelTableOffset := 0;
  inherited;
end;

{ TUTObjectClassClass }

function TUTObjectClassClass.GetSource(beautify: boolean = true): string;
var
  txtObj: TUTObjectClassTextBuffer;
  p: integer;
  pname, pdescvalue: string;
  pvalue: variant;
  pvaluetype: cardinal;
begin
  check_initialized;
  // First try and get the source from the associated TextBuffer
  result := '';
  if ScriptText > 0 then
    begin
      txtObj := TUTObjectClassTextBuffer(FOwner.Exported[ScriptText - 1].UTObject);
      if txtObj <> nil then
        begin
          txtObj.ReadObject;
          result := txtObj.Data;
          txtObj.free;
        end;
    end;
  if trim(result) <> '' then
    begin
      // Get the default Properties
      result := result + 'defaultproperties'#13#10'{'#13#10;
      for p := 0 to properties.count - 2 do
        begin
          properties.propertybyposition[p].GetValue(-1, pname, pvalue, pdescvalue, pvaluetype);
          if properties.propertybyposition[p].arrayindex >= 0 then
            pname := pname + '(' + inttostr(properties.propertybyposition[p].arrayindex) + ')';
          if pdescvalue = '' then pdescvalue := pvalue;
          result := result + format('    %s=%s'#13#10, [pname, pdescvalue]);
        end;
      result := result + '}'#13#10;
    end
  else                                  // No Source.. decompile it
    result := Decompile(beautify);
end;

procedure TUTObjectClassClass.SaveToFile(Filename: string);
var
  f: TFileStream;
  s: string;
begin
  s := GetSource;
  if s <> '' then
    begin
      f := TFileStream.Create(Filename, fmCreate);
      f.Write(s[1], length(s));
      f.free;
    end;
end;

function TUTObjectClassClass.Decompile(beautify: boolean): string;
type
  TUTGUID = record
    case byte of
      0: (guid: TGUID);
      1: (A, B, C, D: integer);
      2: (n: int64);
  end;
var
  a, b, c, o, offs, is_reliable: integer;
  child: TUTObject;
  var_block, func_block, replication_block, within, flags, rep_condition, n,
    rep_type, bars, pname, pdescvalue: string;
  pvalue: variant;
  pvaluetype: cardinal;
  g: TUTGUID;
  replication_list: tstringlist;
begin
  check_initialized;
  buffer.seek(FScriptStart, soFromBeginning);
  result := '';
  replication_list := tstringlist.create;
  // TODO : add "import" clause: import (enum|package) <name> [from <package>]

  // read functions & states
  func_block := '';
  c := FChildren;
  while c <> 0 do
    begin
      child := FOwner.Exported[c - 1].UTObject;
      try
        child.ReadObject;
        if child is TUTObjectClassField then
          begin
            if child is TUTObjectClassState then
              func_block := TUTObjectClassState(child).Decompile(beautify) + #13#10 + func_block
            else if child is TUTObjectClassFunction then
              begin
                func_block := TUTObjectClassFunction(child).Decompile(beautify) + #13#10 + func_block;
                if ((TUTObjectClassFunction(child).functionflags and FUNC_Net) <> 0) and
                  (TUTObjectClassFunction(child).ReplicationOffset < $FFFF) then
                  if (TUTObjectClassFunction(child).functionflags and FUNC_NetReliable) <> 0 then
                    replication_list.addobject(TUTObjectClassFunction(child).UTobjectname, pointer($C0000000 or longword(TUTObjectClassFunction(child).ReplicationOffset)))
                  else
                    replication_list.addobject(TUTObjectClassFunction(child).UTobjectname, pointer($80000000 or longword(TUTObjectClassFunction(child).ReplicationOffset)));
              end;
            c := TUTObjectClassField(child).Next;
          end
        else
          c := 0;
      finally
        child.ReleaseObject;
      end;
    end;

  // read variable declarations
  var_block := '';
  c := FChildren;
  while c <> 0 do
    begin
      child := FOwner.Exported[c - 1].UTObject;
      try
        child.ReadObject;
        if child is TUTObjectClassField then
          begin
            if child is TUTObjectClassProperty then
              begin                     // it is a global variable
                var_block := var_block + TUTObjectClassProperty(child).GetDeclaration('var', UTobjectname) + ';'#13#10;
                if (TUTObjectClassProperty(child).propertyflags and CPF_Net) <> 0 then
                  begin
                    // TODO : get actual reliable flag
                    // try to find whether it is reliable based on functions with same RepOffset
                    is_reliable := $00000000; // default is unknown
                    for a := 0 to replication_list.count - 1 do
                      if (integer(replication_list.objects[a]) and $3FFFFFFF) = TUTObjectClassProperty(child).ReplicationOffset then
                        begin
                          is_reliable := integer(replication_list.objects[a]) and $C0000000;
                          break;
                        end;
                    replication_list.addobject(TUTObjectClassProperty(child).UTobjectname, pointer(is_Reliable or TUTObjectClassProperty(child).ReplicationOffset));
                  end;
              end
            else if child is TUTObjectClassConst then
              begin                     // it is a const
                var_block := var_block + TUTObjectClassConst(child).GetDeclaration + ';'#13#10;
              end
            else if child is TUTObjectClassEnum then
              begin                     // it is an enum
                var_block := var_block + TUTObjectClassEnum(child).GetDeclaration + ';'#13#10#13#10;
              end
            else if (child is TUTObjectClassStruct) and
              not ((child is TUTObjectClassFunction) or (child is TUTObjectClassState)) then
              begin                     // it is an struct
                var_block := var_block + TUTObjectClassStruct(child).GetDeclaration + ';'#13#10#13#10;
              end;
            c := TUTObjectClassField(child).Next;
          end
        else
          c := 0;
      finally
        child.ReleaseObject;
      end;
    end;

  if var_block <> '' then var_block := var_block + #13#10;

  // construct the replication block
  replication_block := '';
  while replication_list.count > 0 do
    begin
      o := integer(replication_list.objects[0]);
      offs := o and $3FFFFFFF;
      buffer.seek(FScriptStart, soFromBeginning);
      position_icode := 0;
      while position_icode <= offs do
        rep_condition := ReadToken;
      case (o and $C0000000) of
        $C0000000: rep_type := 'reliable';
        $80000000: rep_type := 'unreliable';
      else
        rep_type := 'un?reliable';
      end;
      n := '';
      b := replication_list.count - 1;
      while b > 0 do
        begin
          if replication_list.objects[b] = pointer(o) then
            begin
              n := replication_list[b] + ',' + n;
              replication_list.delete(b);
            end;
          dec(b);
        end;
      if n <> '' then n := ',' + copy(n, 1, length(n) - 1);
      n := replication_list[0] + n;
      replication_list.delete(0);
      replication_block := replication_block + #9 + rep_type + ' if ( ' + rep_condition + ' )'#13#10 + #9#9 + n + ';'#13#10;
    end;
  if replication_block <> '' then replication_block := 'replication'#13#10'{'#13#10 + replication_block + '}'#13#10#13#10;

  flags := #13#10;
  if (UTFlags and RF_Native) <> 0 then flags := flags + #9'native'#13#10;
  if (ClassFlags and CLASS_NoExport) <> 0 then flags := flags + #9'noexport'#13#10;
  if (ClassFlags and CLASS_NativeReplication) <> 0 then flags := flags + #9'nativereplication'#13#10;
  if (ClassFlags and CLASS_PerObjectConfig) <> 0 then flags := flags + #9'perobjectconfig'#13#10;
  if (ClassFlags and CLASS_NoUserCreate) <> 0 then flags := flags + #9'nousercreate'#13#10;
  if (ClassFlags and CLASS_Abstract) <> 0 then flags := flags + #9'abstract'#13#10;
  g.guid := FClassGuid;
  if g.n <> 0 then flags := flags + format(#9'guid(%d,%d,%d,%d)'#13#10, [g.A, g.B, g.C, g.D]);
  if (ClassFlags and CLASS_Transient) <> 0 then flags := flags + #9'transient'#13#10;
  //if (ClassFlags and CLASS_Localized)<>0 then flags:=flags+' localized'; // no longer required
  if ((ClassFlags and CLASS_Config) <> 0) and
    (lowercase(FOwner.Names[FClassConfigName]) <> 'system') then
    flags := flags + format(#9'config(%s)'#13#10, [FOwner.Names[FClassConfigName]]);
  if (ClassFlags and CLASS_SafeReplace) <> 0 then flags := flags + #9'safereplace'#13#10;
  if flags <> '' then delete(flags, length(flags) - 1, 2);

  within := '';
  if (FClassWithin <> 0) and (lowercase(FOwner.GetObjectPath(1, FClassWithin)) <> 'object') then
    within := ' within ' + FOwner.GetObjectPath(1, FClassWithin);

  setlength(bars, 80);
  fillchar(bars[1], 80, ord('='));
  result := '//' + bars + #13#10 + '// ' + UTObjectName + '.'#13#10 + '//' + bars + #13#10;
  result := result + 'class ' + UTObjectName;
  if SuperField <> 0 then result := result + ' expands ' + FOwner.GetObjectPath(1, SuperField);
  result := result + within + flags + ';'#13#10#13#10;
  result := result + var_block + replication_block + func_block;

  if properties.count > 1 then
    begin
      result := result + 'defaultproperties'#13#10'{'#13#10;
      for c := 0 to properties.count - 2 do
        begin
          properties.propertybyposition[c].GetValue(-1, pname, pvalue, pdescvalue, pvaluetype);
          if properties.propertybyposition[c].arrayindex >= 0 then
            pname := pname + '(' + inttostr(properties.propertybyposition[c].arrayindex) + ')';
          if pdescvalue = '' then pdescvalue := pvalue;
          result := result + format('    %s=%s'#13#10, [pname, pdescvalue]);
        end;
      result := result + '}'#13#10;
    end;

  replication_list.free;
end;

function TUTObjectClassClass.GetDependencyCount: integer;
begin
  check_initialized;
  result := length(FDependencies);
end;

function TUTObjectClassClass.GetClassConfigName: integer;
begin
  check_initialized;
  result := FClassConfigName;
end;

function TUTObjectClassClass.GetClassFlags: longword;
begin
  check_initialized;
  result := FClassFlags;
end;

function TUTObjectClassClass.GetClassGuid: TGuid;
begin
  check_initialized;
  result := FClassGuid;
end;

function TUTObjectClassClass.GetClassWithin: integer;
begin
  check_initialized;
  result := FClassWithin;
end;

function TUTObjectClassClass.GetDependencies(i: integer): TUT_Struct_Dependency;
begin
  check_initialized;
  result := FDependencies[i];
end;

function TUTObjectClassClass.GetPackageImports(i: integer): integer;
begin
  check_initialized;
  result := FPackageImports[i];
end;

procedure TUTObjectClassClass.InitializeObject;
begin
  inherited;
  FClassFlags := 0;
  fillchar(FClassGuid, sizeof(TGuid), 0);
  setlength(FDependencies, 0);
  setlength(FPackageImports, 0);
  FClassWithin := 0;
  FClassConfigName := 0;
end;

procedure TUTObjectClassClass.InterpretObject;
var
  a: integer;
begin
  inherited;
  SkipStatements;
  if FOwner.Version <= 61 then FOwner.read_int(buffer); // OldClassRecordSize
  FClassFlags := FOwner.read_int(buffer);
  FClassGuid := FOwner.read_guid(buffer);
  setlength(FDependencies, FOwner.read_idx(buffer));
  for a := 0 to high(FDependencies) do
    FDependencies[a] := Read_Struct_Dependency(Fowner, buffer);
  setlength(FPackageImports, FOwner.read_idx(buffer));
  for a := 0 to high(FPackageImports) do
    FPackageImports[a] := FOwner.read_idx(buffer);
  if FOwner.Version >= 62 then
    begin
      FClassWithin := FOwner.read_idx(buffer); // object
      FClassConfigName := FOwner.read_idx(buffer); // name
    end;
  ReadProperties;
end;

function TUTObjectClassClass.GetPackageImportsCount: integer;
begin
  check_initialized;
  result := length(FPackageImports);
end;

procedure TUTObjectClassClass.DoReleaseObject;
begin
  FClassFlags := 0;
  fillchar(FClassGuid, sizeof(TGuid), 0);
  setlength(FDependencies, 0);
  setlength(FPackageImports, 0);
  FClassWithin := 0;
  FClassConfigName := 0;
  inherited;
end;

{ TUTObjectClassSkeletalMesh }

function TUTObjectClassSkeletalMesh.GetBoneWeight(
  i: integer): TUT_Struct_BoneInfluence;
begin
  check_initialized;
  result := FBoneWeights[i];
end;

function TUTObjectClassSkeletalMesh.GetBoneWeightCount: integer;
begin
  check_initialized;
  result := length(FBoneWeights);
end;

function TUTObjectClassSkeletalMesh.GetBoneWeightIdx(
  i: integer): TUT_Struct_BoneInfIndex;
begin
  check_initialized;
  result := FBoneWeightIdx[i];
end;

function TUTObjectClassSkeletalMesh.GetBoneWeightIdxCount: integer;
begin
  check_initialized;
  result := length(FBoneWeightIdx);
end;

function TUTObjectClassSkeletalMesh.GetExtWedge(
  i: integer): TUT_Struct_MeshExtWedge;
begin
  check_initialized;
  result := FExtWedges[i];
end;

function TUTObjectClassSkeletalMesh.GetExtWedgeCount: integer;
begin
  check_initialized;
  result := length(FExtWedges);
end;

function TUTObjectClassSkeletalMesh.GetLocalPoint(
  i: integer): TUT_Struct_Vector;
begin
  check_initialized;
  result := FLocalPoints[i];
end;

function TUTObjectClassSkeletalMesh.GetLocalPointCount: integer;
begin
  check_initialized;
  result := length(FLocalPoints);
end;

function TUTObjectClassSkeletalMesh.GetPoint(
  i: integer): TUT_Struct_Vector;
begin
  check_initialized;
  result := FPoints[i];
end;

function TUTObjectClassSkeletalMesh.GetPointCount: integer;
begin
  check_initialized;
  result := length(FPoints);
end;

function TUTObjectClassSkeletalMesh.GetRefSkeleton(
  i: integer): TUT_Struct_MeshBone;
begin
  check_initialized;
  result := FRefSkeleton[i];
end;

function TUTObjectClassSkeletalMesh.GetRefSkeletonCount: integer;
begin
  check_initialized;
  result := length(FRefSkeleton);
end;

procedure TUTObjectClassSkeletalMesh.InitializeObject;
begin
  inherited;
  setlength(FExtWedges, 0);
  setlength(FPoints, 0);
  setlength(FRefSkeleton, 0);
  setlength(FBoneWeightIdx, 0);
  setlength(FBoneWeights, 0);
  setlength(FLocalPoints, 0);
  FSkeletalDepth := 0;
  FDefaultAnimation := 0;
  FWeaponBoneIndex := 0;
  fillchar(FWeaponAdjust, sizeof(TUT_Struct_Coords), 0);
end;

procedure TUTObjectClassSkeletalMesh.InterpretObject;
var
  size, a: integer;
begin
  inherited;
  size := FOwner.read_idx(buffer);
  setlength(FExtWedges, size);
  for a := 0 to size - 1 do
    FExtWedges[a] := Read_Struct_MeshExtWedge(FOwner, buffer);
  size := FOwner.read_idx(buffer);
  setlength(FPoints, size);
  for a := 0 to size - 1 do
    FPoints[a] := Read_Struct_Vector(FOwner, buffer);
  size := FOwner.read_idx(buffer);
  setlength(FRefSkeleton, size);
  for a := 0 to size - 1 do
    FRefSkeleton[a] := Read_Struct_MeshBone(FOwner, buffer);
  size := FOwner.read_idx(buffer);
  setlength(FBoneWeightIdx, size);
  for a := 0 to size - 1 do
    FBoneWeightIdx[a] := Read_Struct_BoneInfIndex(FOwner, buffer);
  size := FOwner.read_idx(buffer);
  setlength(FBoneWeights, size);
  for a := 0 to size - 1 do
    FBoneWeights[a] := Read_Struct_BoneInfluence(FOwner, buffer);
  size := FOwner.read_idx(buffer);
  setlength(FLocalPoints, size);
  for a := 0 to size - 1 do
    FLocalPoints[a] := Read_Struct_Vector(FOwner, buffer);
  FSkeletalDepth := FOwner.read_int(buffer);
  FDefaultAnimation := FOwner.read_idx(buffer);
  FWeaponBoneIndex := FOwner.read_int(buffer);
  FWeaponAdjust := Read_Struct_Coords(FOwner, buffer);
end;

procedure TUTObjectClassSkeletalMesh.DoReleaseObject;
begin
  setlength(FExtWedges, 0);
  setlength(FPoints, 0);
  setlength(FRefSkeleton, 0);
  setlength(FBoneWeightIdx, 0);
  setlength(FBoneWeights, 0);
  setlength(FLocalPoints, 0);
  FSkeletalDepth := 0;
  FDefaultAnimation := 0;
  FWeaponBoneIndex := 0;
  fillchar(FWeaponAdjust, sizeof(TUT_Struct_Coords), 0);
  inherited;
end;

procedure TUTObjectClassSkeletalMesh.PrepareExporter(exporter: TUT_MeshExporter; frames: TIntegerArray);
const
  material_colors: array[0..5] of TColor = (clBlue, clRed, clLime, clYellow, clAqua, clSilver);
var
  matname: string;
  m: integer;
begin
  check_initialized;
  if length(frames) = 0 then
    begin
      setlength(frames, 1);
      frames[0] := 0;
    end;
  setlength(exporter.Materials, length(FMaterials));
  for m := 0 to high(FMaterials) do
    begin
      matname := 'SKIN' + inttostr(FMaterials[m].textureindex);
      if (FMaterials[m].flags and (PF_TwoSided or PF_Modulated)) = (PF_TwoSided or PF_Modulated) then
        matname := matname + '.MODU'    //LATED'
      else if (FMaterials[m].flags and (PF_TwoSided or PF_Translucent)) = (PF_TwoSided or PF_Translucent) then
        matname := matname + '.TRAN'    //SLUCENT'
      else if (FMaterials[m].flags and (PF_TwoSided or PF_Masked)) = (PF_TwoSided or PF_Masked) then
        matname := matname + '.MASK'    //ED'
      else if (FMaterials[m].flags and PF_TwoSided) = PF_TwoSided then
        matname := matname + '.TWOS'    //IDED'
      else if (FMaterials[m].flags and PF_NotSolid) = PF_NotSolid then
        matname := 'WEAPON';
      matname := copy(matname, 1, 10);
      exporter.Materials[m].name := matname;
      if m <= high(material_colors) then
        begin
          exporter.Materials[m].diffusecolor[0] := material_colors[m] and $FF;
          exporter.Materials[m].diffusecolor[1] := (material_colors[m] shr 8) and $FF;
          exporter.Materials[m].diffusecolor[2] := (material_colors[m] shr 16) and $FF;
        end
      else
        begin
          exporter.Materials[m].diffusecolor[0] := random(256);
          exporter.Materials[m].diffusecolor[1] := random(256);
          exporter.Materials[m].diffusecolor[2] := random(256);
        end;
    end;
  setlength(exporter.Vertices, length(FWedges) * length(frames));
  exporter.AnimationFrames := 1;
  for m := 0 to high(FWedges) do
    begin
      exporter.Vertices[m].x := FPoints[FSpecialVerts + FWedges[m].VertexIndex].X;
      exporter.Vertices[m].y := FPoints[FSpecialVerts + FWedges[m].VertexIndex].Y;
      exporter.Vertices[m].z := FPoints[FSpecialVerts + FWedges[m].VertexIndex].Z;
      exporter.Vertices[m].U := FWedges[m].U;
      exporter.Vertices[m].V := FWedges[m].V;
    end;
  setlength(exporter.Faces, length(FFaces));
  for m := 0 to high(FFaces) do
    begin
      exporter.Faces[m].VertexIndex1 := FFaces[m].WedgeIndex2; // corrected winding
      exporter.Faces[m].VertexIndex2 := FFaces[m].WedgeIndex1;
      exporter.Faces[m].VertexIndex3 := FFaces[m].WedgeIndex3;
      exporter.Faces[m].MaterialIndex := FFaces[m].MatIndex;
      exporter.Faces[m].Flags := FMaterials[FFaces[m].MatIndex].Flags;
    end;
end;

procedure TUTObjectClassSkeletalMesh.Save_3DS(filename: string;
  frame: integer; smoothing: TUT_3DStudioExporter_Smoothing; MirrorX: boolean);
var
  exporter: TUT_3DStudioExporter;
  frames: TIntegerArray;
begin
  check_initialized;
  exporter := TUT_3DStudioExporter.create;
  setlength(frames, 1);
  frames[0] := 0;
  PrepareExporter(exporter, frames);
  exporter.mirrorx := mirrorx;
  exporter.smoothing := smoothing;
  exporter.Save(filename);
  exporter.free;
end;

procedure TUTObjectClassSkeletalMesh.Save_Unreal3D(filename: string);
var
  exporter: TUT_Unreal3DExporter;
  frames: TIntegerArray;
begin
  check_initialized;
  exporter := TUT_Unreal3DExporter.create;
  setlength(frames, 1);
  frames[0] := 0;
  PrepareExporter(exporter, frames);
  exporter.CoordsDivisor := 4;
  exporter.Save(filename);
  exporter.free;
end;

procedure TUTObjectClassSkeletalMesh.Save_UnrealUC(filename: string);
var
  parent_class, basename, uc: string;
  k: char;
  a, script_idx: integer;
  ed2: TUTExportTableObjectData;
  id: TUTImportTableObjectData;
  str_uc: tfilestream;
begin
  check_initialized;
  a := FOwner.FindObject(utolExports, [utfwName, utfwClass, utfwPackage], '', UTobjectname, '');
  if a <> -1 then
    begin
      ed2 := FOwner.Exported[a];
      ed2.UTObject.ReadObject;
      parent_class := FOwner.GetObjectPath(1, TUTObjectClassClass(ed2.UTObject).SuperField);
      script_idx := TUTObjectClassClass(ed2.UTObject).ScriptText - 1;
      ed2.UTObject.ReleaseObject;
    end
  else
    begin
      parent_class := 'TournamentPlayer'; // do not localize these strings
      script_idx := FOwner.FindObject(utolExports, [utfwName, utfwClass, utfwPackage],
        UTobjectname, 'ScriptText', 'TextBuffer');
    end;
  if script_idx <> -1 then
    begin
      ed2 := FOwner.Exported[script_idx];
      ed2.UTObject.ReadObject;
      TUTObjectClassTextBuffer(ed2.UTObject).SaveToFile(filename);
      ed2.UTObject.ReleaseObject;
    end
  else
    begin
      k := {$IF CompilerVersion > 21.0}FormatSettings.{$IFEND}DecimalSeparator;
      {$IF CompilerVersion > 21.0}FormatSettings.{$IFEND}decimalSeparator := '.';
      basename := UTobjectname;
      // do not localize
      uc := '//============================================================================='#13#10;
      uc := uc + format('// %s.'#13#10, [basename]);
      uc := uc + '//============================================================================='#13#10;
      uc := uc + format('class %s extends %s;'#13#10#13#10, [basename, parent_class]);
      if DefaultAnimation > 0 then
        begin
          uc := uc + format('#exec ANIM IMPORT ANIM=%s ANIMFILE=MODELS\%s.PSA' {+' COMPRESS=x IMPORTSEQS=x MAXKEYS=x'} + #13#10, [FOwner.GetObjectPath(1, FDefaultAnimation), FOwner.GetObjectPath(1, FDefaultAnimation)]);
          uc := uc + #13#10;
        end;
      uc := uc + format('#exec MESH MODELIMPORT MESH=%s MODELFILE=MODELS\%s.PSK' {+' LODSTYLE=x X=x Y=x Z=x'} + #13#10, [basename, basename]);
      {uc := uc + format('#exec MESH LODPARAMS MESH=%s HYSTERESIS=%f STRENGTH=%f MINVERTS=%f MORPH=%f ZDISP=%f'#13#10,
        [basename, FLODHysteresis, FLODStrength, FLODMinVerts, FLODMorph, FLODZDisplace]);}
      uc := uc + format('#exec MESH ORIGIN MESH=%s X=%f Y=%f Z=%f YAW=%f ROLL=%f PITCH=%f'#13#10#13#10,
        [basename, FOrigin.x, FOrigin.y, FOrigin.z, FRotorigin.Yaw / 256, FRotOrigin.Roll / 256, FRotOrigin.Pitch / 256]);
      uc := uc + format('#exec MESH WEAPONATTACH MESH=%s BONE="%s"'#13#10, [basename, FOwner.Names[RefSkeleton[WeaponBoneIndex].name]]);
      uc := uc + format('#exec MESH WEAPONPOSITION MESH=%s YAW=%f PITCH=%f ROLL=%f X=%f Y=%f Z=%f'#13#10, [basename,
        0.0, 0.0, 0.0,                  // TODO : get this from weaponadjust.Xaxis, Yaxis and Zaxis (but with some calculation)
        weaponadjust.origin.x, weaponadjust.origin.y, weaponadjust.origin.z]);
      uc := uc + #13#10;
      for a := 0 to high(FTextures) do
        if FTextures[a].value > 0 then
          begin
            ed2 := FOwner.Exported[FTextures[a].value - 1];
            uc := uc + format('#exec TEXTURE IMPORT NAME=%s FILE=%s.PCX GROUP=%s'#13#10,
              [ed2.UTobjectname, ed2.UTobjectname, ed2.UTpackagename]);
            // TODO : TUTObjectClassSkeletalMesh.Save_UnrealUC : FLAGS=%d should put correct flags...
          end
        else if FTextures[a].value < 0 then
          begin
            id := FOwner.Imported[-FTextures[a].value - 1];
            uc := uc + format('#exec OBJ LOAD FILE=%s.utx PACKAGE=%s'#13#10, [id.UTobjectname, id.UTpackagename]);
          end;
      uc := uc + #13#10;
      for a := 0 to high(FTextures) do
        if FTextures[a].value > 0 then
          begin
            ed2 := FOwner.Exported[FTextures[a].value - 1];
            uc := uc + format('#exec MESHMAP SETTEXTURE MESHMAP=%s NUM=%d TEXTURE=%s'#13#10, [basename, a, ed2.UTobjectname]);
          end
        else if FTextures[a].value < 0 then
          begin
            id := FOwner.Imported[-FTextures[a].value - 1];
            uc := uc + format('#exec MESHMAP SETTEXTURE MESHMAP=%s NUM=%d TEXTURE=%s'#13#10, [basename, a, id.UTpackagename + '.' + id.UTobjectname]);
          end;
      uc := uc + #13#10;
      //uc:=uc+format('#exec MESHMAP NEW   MESHMAP=%s MESH=%s'#13#10,[basename,basename]);
      if (FScale.x <> 0.1) or (FScale.y <> 0.1) or (FScale.z <> 0.2) then
        uc := uc + format('#exec MESHMAP SCALE MESHMAP=%s X=%f Y=%f Z=%f'#13#10#13#10, [basename, FScale.x, FScale.y, FScale.z]);
      // FScale is incorrect, sometimes is 0 and it shouldnt be.

      uc := uc + format('#exec MESH DEFAULTANIM MESH=%s ANIM=%s'#13#10, [basename, FOwner.GetObjectPath(1, FDefaultAnimation)]);
      uc := uc + #13#10;
      if DefaultAnimation > 0 then
        begin
          uc := uc + '// Animation sequences not generated.'#13#10;
          //#exec ANIM SEQUENCE ANIM=SkeletalAnimation1 SEQ=All STARTFRAME=0 NUMFRAMES=25 RATE=0.2 GROUP=Default
          uc := uc + #13#10;
          uc := uc + format('#exec ANIM DIGEST ANIM=%s VERBOSE'#13#10, [FOwner.GetObjectPath(1, FDefaultAnimation)]);
          uc := uc + #13#10;
          uc := uc + '// Animation notifications not generated.'#13#10;
          //#exec ANIM NOTIFY ANIM=RiotAnim SEQ=RunLG TIME=0.25 FUNCTION=PlayFootStep
          uc := uc + #13#10;
        end;
      (*uc:=uc+#13#10+
      'defaultproperties'#13#10+
      '{'#13#10+
      '    DrawType=DT_Mesh'#13#10+
      format('    Mesh=%s'#13#10,[basename])+
      '}'#13#10;*)
      {$IF CompilerVersion > 21.0}FormatSettings.{$IFEND}DecimalSeparator := k;
      str_uc := tfilestream.create(filename, fmCreate);
      try
        str_uc.write(uc[1], length(uc));
      finally
        str_uc.free;
      end;
    end;
end;

{ TUT_3DStudioExporter }

procedure TUT_3DStudioExporter.Save(filename: string);
type
  P3DSChunk = ^T3DSChunk;
  T3DSChunk = packed record
    tag: word;
    size: cardinal;
    datasize: cardinal;
    data: pointer;
    subchunks: tlist;
  end;
var
  str: tfilestream;
  m, m2, n: integer;
  dummy: byte;
  matname, meshname: string;
  p: pointer;
  facelist: array of word;
  rootchunk, mdatachunk, matentrychunk, namedobjectchunk, ntriobjectchunk,
    faceschunk, diffusechunk, {kfdatachunk, objectnodetagchunk, } x: P3DSChunk;
  function new_chunk(tag: word; datasize: cardinal; hasvalue: boolean; var value): P3DSChunk;
  begin
    new(result);
    result^.tag := tag;
    result^.size := 0;
    result^.datasize := datasize;
    if datasize > 0 then
      begin
        getmem(result^.data, datasize);
        if hasvalue then move(value, result^.data^, datasize);
      end
    else
      result^.data := nil;
    result^.subchunks := tlist.create;
  end;
  procedure calculate_chunk_size(chunk: P3DSChunk);
  var
    a: integer;
  begin
    chunk.size := sizeof(word) + sizeof(cardinal) + chunk.datasize;
    for a := 0 to chunk.subchunks.count - 1 do
      begin
        calculate_chunk_size(chunk.subchunks[a]);
        inc(chunk.size, P3DSChunk(chunk.subchunks[a]).size);
      end;
  end;
  procedure save_chunk(str: tstream; chunk: P3DSChunk);
  var
    a: integer;
  begin
    str.Write(chunk.tag, sizeof(word));
    str.write(chunk.size, sizeof(cardinal));
    if chunk.data <> nil then str.write(chunk.data^, chunk.datasize);
    for a := 0 to chunk.subchunks.count - 1 do
      save_chunk(str, chunk.subchunks[a]);
  end;
  procedure free_chunk(chunk: P3DSChunk);
  var
    a: integer;
  begin
    if chunk.data <> nil then freemem(chunk.data, chunk.datasize);
    for a := chunk.subchunks.count - 1 downto 0 do
      free_chunk(chunk.subchunks[a]);
    chunk.subchunks.free;
    dispose(chunk);
  end;
  function put_integer(p: pointer; v: integer): pointer;
  begin
    move(v, p^, sizeof(integer));
    result := pointer(integer(p) + sizeof(integer));
  end;
  function put_single(p: pointer; v: single): pointer;
  begin
    move(v, p^, sizeof(single));
    result := pointer(integer(p) + sizeof(single));
  end;
  function put_smallint(p: pointer; v: smallint): pointer;
  begin
    move(v, p^, sizeof(smallint));
    result := pointer(integer(p) + sizeof(smallint));
  end;
  function put_word(p: pointer; v: word): pointer;
  begin
    move(v, p^, sizeof(word));
    result := pointer(integer(p) + sizeof(word));
  end;
  function put_string(p: pointer; v: string): pointer;
  begin
    move(v[1], p^, length(v) + 1);
    result := pointer(integer(p) + length(v) + 1);
  end;
begin
  // Generate chunk tree
  // main chunk
  rootchunk := new_chunk(M3DMAGIC, 0, false, dummy);
  try
    x := new_chunk(M3D_VERSION, sizeof(cardinal), false, dummy);
    put_integer(x.data, 3);
    rootchunk.subchunks.add(x);
    // mesh data chunk
    x := new_chunk(MDATA, 0, false, dummy);
    rootchunk.subchunks.add(x);
    mdatachunk := x;
    // mesh version chunk
    x := new_chunk(MESH_VERSION, sizeof(integer), false, dummy);
    put_integer(x.data, 3);
    mdatachunk.subchunks.add(x);

    for m := 0 to high(Materials) do
      begin
        // material chunk
        x := new_chunk(MAT_ENTRY, 0, false, dummy);
        mdatachunk.subchunks.add(x);
        matentrychunk := x;
        matname := copy(Materials[m].name, 1, 10);
        // material name chunk
        x := new_chunk(MAT_NAME, length(matname) + 1, true, matname[1]);
        matentrychunk.subchunks.add(x);
        // TODO : must add support for material flags in parameters
        // material diffuse color chunk
        x := new_chunk(MAT_DIFFUSE, 0, false, dummy);
        matentrychunk.subchunks.add(x);
        diffusechunk := x;
        x := new_chunk(COLOR_24, 3, true, Materials[m].DiffuseColor[0]);
        diffusechunk.subchunks.add(x);
      end;

    // mesh chunk
    meshname := extractfilename(filename);
    meshname := copy(meshname, 1, 10);
    x := new_chunk(NAMED_OBJECT, length(meshname) + 1, true, meshname[1]);
    mdatachunk.subchunks.add(x);
    namedobjectchunk := x;
    // triangles chunk
    x := new_chunk(N_TRI_OBJECT, 0, false, dummy);
    namedobjectchunk.subchunks.add(x);
    ntriobjectchunk := x;
    // vertices chunk
    x := new_chunk(POINT_ARRAY, sizeof(word) + length(Vertices) * sizeof(single) * 3, false, dummy);
    p := put_word(x.data, length(Vertices));
    for m := 0 to high(Vertices) do
      begin
        if not mirrorx then
          p := put_single(p, Vertices[m].X)
        else
          p := put_single(p, -Vertices[m].X);
        p := put_single(p, Vertices[m].Y);
        p := put_single(p, Vertices[m].Z);
      end;
    ntriobjectchunk.subchunks.add(x);
    // texture coordinates chunk
    x := new_chunk(TEX_VERTS, sizeof(word) + length(Vertices) * sizeof(single) * 2, false, dummy);
    p := put_word(x.data, length(Vertices));
    for m := 0 to high(Vertices) do
      begin
        p := put_single(p, Vertices[m].U / 255);
        p := put_single(p, 1 - (Vertices[m].V / 255)); // reversed
      end;
    ntriobjectchunk.subchunks.add(x);
    // TODO : MESH_MATRIX chunk (not needed!?)
    // faces chunk
    x := new_chunk(FACE_ARRAY, sizeof(word) + length(Faces) * sizeof(word) * 4, false, dummy);
    p := put_word(x.data, length(Faces));
    for m := 0 to high(Faces) do
      begin
        if not mirrorX then
          begin
            p := put_word(p, Faces[m].VertexIndex1);
            p := put_word(p, Faces[m].VertexIndex2);
            p := put_word(p, Faces[m].VertexIndex3);
          end
        else
          begin                         // change vertex winding
            p := put_word(p, Faces[m].VertexIndex3);
            p := put_word(p, Faces[m].VertexIndex2);
            p := put_word(p, Faces[m].VertexIndex1);
          end;
        p := put_word(p, FaceCAVisable3DS or FaceBCVisable3DS or FaceABVisable3DS);
      end;
    ntriobjectchunk.subchunks.add(x);
    faceschunk := x;

    for m := 0 to high(Materials) do
      begin
        // face<->material chunk
        setlength(facelist, length(Faces));
        n := 0;
        for m2 := 0 to high(Faces) do
          begin
            if Faces[m2].MaterialIndex = m then
              begin
                facelist[n] := m2;
                inc(n);
              end;
          end;
        setlength(facelist, n);
        if n > 0 then
          begin
            matname := copy(Materials[m].name, 1, 10);
            x := new_chunk(MSH_MAT_GROUP, length(matname) + 1 + sizeof(word) + length(facelist) * sizeof(word), false, dummy);
            p := put_string(x.data, matname);
            p := put_word(p, length(facelist));
            for m2 := 0 to high(facelist) do
              p := put_word(p, facelist[m2]);
            faceschunk.subchunks.add(x);
          end;
      end;
    case smoothing of
      exp3ds_smooth_None: ;             // no smoothing groups
      exp3ds_smooth_One:
        begin                           // one smoothing group for all faces
          // Smooth Group chunk
          x := new_chunk(SMOOTH_GROUP, length(Faces) * sizeof(cardinal), false, dummy);
          p := x.data;
          for m := 0 to high(Faces) do
            p := put_integer(p, 1);
          faceschunk.subchunks.add(x);
        end;
      exp3ds_smooth_exp3ds_smooth_ByMaterial:
        begin                           // one smoothing group for each material
          // Smooth Group chunk
          x := new_chunk(SMOOTH_GROUP, length(Faces) * sizeof(cardinal), false, dummy);
          p := x.data;
          for m := 0 to high(Faces) do
            p := put_integer(p, 1 shl Faces[m].MaterialIndex); // one bit for each material
          faceschunk.subchunks.add(x);
        end;
    end;

    // keyframes chunk
      (*x := new_chunk(KFDATA, 0, false, dummy);
      rootchunk.subchunks.add(x);
      kfdatachunk := x;
      // keyframes header chunk
      name := 'MAXSCENE';
      x := new_chunk(KFHDR, sizeof(smallint) + length(name) + 1 + sizeof(integer), false, dummy);
      p := put_smallint(x.data, 5);
      p := put_string(p, name);
      {if allframes then
         put_integer(p, FAnimFrames)
      else}
      put_integer(p, 1);
      kfdatachunk.subchunks.add(x);
      // keyframes segments chunk
      x := new_chunk(KFSEG, sizeof(integer) + sizeof(integer), false, dummy);
      p := put_integer(x.data, 0);
      {if allframes then
         put_integer(p, FAnimFrames)
      else}
      put_integer(p, 1);
      kfdatachunk.subchunks.add(x);

      for frame := 0 to FAnimFrames - 1 do
        begin
          // keyframes current time chunk
          x := new_chunk(KFCURTIME, sizeof(integer), false, dummy);
          put_integer(x.data, frame);
          kfdatachunk.subchunks.add(x);
          // object node chunk
          x := new_chunk(OBJECT_NODE_TAG, 0, false, dummy);
          kfdatachunk.subchunks.add(x);
          objectnodetagchunk := x;
          // node id chunk
          x := new_chunk(NODE_ID, sizeof(smallint), false, dummy);
          put_smallint(x.data, frame);
          objectnodetagchunk.subchunks.add(x);
          // node header chunk
          meshname := extractfilename(filename);
          meshname:=copy(meshname,1,7);
          if allframes then meshname := meshname + format('%-3.3d', [frame]);
          x := new_chunk(NODE_HDR, length(meshname) + 1 + sizeof(word) + sizeof(word) + sizeof(smallint), false, dummy);
          p := put_string(x.data, meshname); // Mesh object
          p := put_word(p, $4000); // flags1=PRIMARY_NODE
          p := put_word(p, 0);     // flags2
          put_smallint(p, -1);     // Parent=No Parent
          objectnodetagchunk.subchunks.add(x);

          {
          // PIVOT chunk
          x := new_chunk(PIVOT, 3 * sizeof(single), false, dummy);
          p := put_single(x.data, 0);
          p := put_single(p, 0);
          put_single(p, 0);
          objectnodetagchunk.subchunks.add(x);
          // POS_TRACK_TAG chunk
          x := new_chunk(POS_TRACK_TAG, sizeof(word) + 3 * sizeof(integer) + 1 * (sizeof(integer) + sizeof(word) + 3 * sizeof(single)), false, dummy);
          p := put_word(x.data, 0);         // flags
          p := put_integer(p, 0);           // nu1
          p := put_integer(p, 0);           // nu2
          p := put_integer(p, 1);           // keycount
          // key 0
          p := put_integer(p, 0);           // time
          p := put_word(p, 0);              // rflags
          p := put_single(p, 0);            // point.X
          p := put_single(p, 0);            // point.Y
          put_single(p, 0);                 // point.Z
          objectnodetagchunk.subchunks.add(x);
          // ROT_TRACK_TAG chunk
          x := new_chunk(ROT_TRACK_TAG, sizeof(word) + 3 * sizeof(integer) + 1 * (sizeof(integer) + sizeof(word) + 4 * sizeof(single)), false, dummy);
          p := put_word(x.data, 0);         // flags
          p := put_integer(p, 0);           // nu1
          p := put_integer(p, 0);           // nu2
          p := put_integer(p, 1);           // keycount
          // key 0
          p := put_integer(p, 0);           // time
          p := put_word(p, 0);              // rflags
          p := put_single(p, 0);            // Angle
          p := put_single(p, 0);            // Axis.X
          p := put_single(p, 1);            // Axis.Y
          put_single(p, 0);                 // Axis.Z
          objectnodetagchunk.subchunks.add(x);
          // SCL_TRACK_TAG chunk
          x := new_chunk(SCL_TRACK_TAG, sizeof(word) + 3 * sizeof(integer) + 1 * (sizeof(integer) + sizeof(word) + 3 * sizeof(single)), false, dummy);
          p := put_word(x.data, 0);         // flags
          p := put_integer(p, 0);           // nu1
          p := put_integer(p, 0);           // nu2
          p := put_integer(p, 1);           // keycount
          // key 0
          p := put_integer(p, 0);           // time
          p := put_word(p, 0);              // rflags
          p := put_single(p, 1);            // scale.X
          p := put_single(p, 1);            // scale.Y
          put_single(p, 1);                 // scale.Z
          objectnodetagchunk.subchunks.add(x);
          }
          if not allframes then break;
        end;
      *)

      // calculate chunk sizes
    calculate_chunk_size(rootchunk);
    // Save chunk tree
    str := tfilestream.create(filename + '.3ds', fmCreate);
    try
      save_chunk(str, rootchunk);
    finally
      str.free;
    end;
  finally
    // free chunks
    free_chunk(rootchunk);
  end;
end;

{ TUT_Unreal3DExporter }

procedure TUT_Unreal3DExporter.Save(filename: string);
var
  a, xyz: integer;
  xx, yy, zz: single;
  data: word;
  str_d, str_a: tfilestream;
  // From 3DS2UNR
  _3D_dHeader: packed record
    NumPolygons: word;
    NumVertices: word;
    BogusRot: word;
    BogusFrame: word;
    BogusNormX: cardinal;
    BogusNormY: cardinal;
    BogusNormZ: cardinal;
    FixScale: cardinal;
    Unused: array[0..2] of cardinal;
    Unknown: array[0..11] of char;
  end;
  _3D_dPolygon: packed record
    mVertex: array[0..2] of word;       // Vertex indices.
    mType: byte;                        // James' mesh type.
    mColor: byte;                       // Color for flat and Gouraud shaded.
    mTex: array[0..2, 0..1] of byte;    // Texture UV coordinates.
    mTextureNum: byte;                  // Source texture offset.
    mFlags: byte;                       // Unreal mesh flags (currently unused).
  end;
begin
  if coordsdivisor < 1 then coordsdivisor := 1;
  filename := changefileext(filename, '');
  // Create file _d.3d
  fillchar(_3D_dHeader, sizeof(_3D_dHeader), 0);
  with _3D_dHeader do
    begin
      NumPolygons := length(Faces);
      NumVertices := length(Vertices) div AnimationFrames;
    end;
  str_d := tfilestream.create(filename + '_d.3d', fmCreate);
  try
    str_d.Write(_3D_dHeader, sizeof(_3D_dHeader));
    for a := 0 to high(Faces) do
      begin
        fillchar(_3D_dPolygon, sizeof(_3D_dPolygon), 0);
        _3D_dPolygon.mVertex[0] := Faces[a].vertexindex1;
        _3D_dPolygon.mVertex[1] := Faces[a].vertexindex2;
        _3D_dPolygon.mVertex[2] := Faces[a].vertexindex3;
        if (Faces[a].flags and PF_NotSolid) = PF_NotSolid then
          _3D_dPolygon.mType := 8       // Weapon
        else if (Faces[a].flags and (PF_TwoSided or PF_Modulated)) = (PF_TwoSided or PF_Modulated) then
          _3D_dPolygon.mType := 4       // MODULATED 2-Sided
        else if (Faces[a].flags and (PF_TwoSided or PF_Translucent)) = (PF_TwoSided or PF_Translucent) then
          _3D_dPolygon.mType := 3       // TRANSLUCENT 2-Sided
        else if (Faces[a].flags and (PF_TwoSided or PF_Masked)) = (PF_TwoSided or PF_Masked) then
          _3D_dPolygon.mType := 2       // MASKED 2-Sided
        else if (Faces[a].flags and PF_TwoSided) <> 0 then
          _3D_dPolygon.mType := 1       // 2-Sided
        else
          _3D_dPolygon.mType := 0;
        if (Faces[a].flags and PF_Unlit) <> 0 then _3D_dPolygon.mType := _3D_dPolygon.mType or $10;
        if (Faces[a].flags and PF_Flat) <> 0 then _3D_dPolygon.mType := _3D_dPolygon.mType or $20;
        if (Faces[a].flags and PF_Environment) <> 0 then _3D_dPolygon.mType := _3D_dPolygon.mType or $40;
        if (Faces[a].flags and PF_NoSmooth) <> 0 then _3D_dPolygon.mType := _3D_dPolygon.mType or $80;
        _3D_dPolygon.mTextureNum := Faces[a].MaterialIndex;
        _3D_dPolygon.mTex[0, 0] := Vertices[Faces[a].vertexindex1].U;
        _3D_dPolygon.mTex[0, 1] := Vertices[Faces[a].vertexindex1].V;
        _3D_dPolygon.mTex[1, 0] := Vertices[Faces[a].vertexindex2].U;
        _3D_dPolygon.mTex[1, 1] := Vertices[Faces[a].vertexindex2].V;
        _3D_dPolygon.mTex[2, 0] := Vertices[Faces[a].vertexindex3].U;
        _3D_dPolygon.mTex[2, 1] := Vertices[Faces[a].vertexindex3].V;
        str_d.write(_3D_dPolygon, sizeof(_3D_dPolygon));
      end;
  finally
    str_d.free;
  end;

  // Create file _a.3d
  str_a := tfilestream.create(filename + '_a.3d', fmCreate);
  try
    data := AnimationFrames;
    str_a.Write(data, sizeof(data));
    data := length(Vertices) * 4 div AnimationFrames;
    str_a.write(data, sizeof(data));
    for a := 0 to high(Vertices) do
      begin
        xx := Vertices[a].x / CoordsDivisor;
        yy := Vertices[a].y / CoordsDivisor;
        zz := Vertices[a].z / CoordsDivisor;
        xyz := (trunc(xx * 8) and $7FF) or
          ((trunc(yy * 8) and $7FF) shl 11) or
          ((trunc(zz * 4) and $3FF) shl 22);
        str_a.Write(xyz, 4);
      end;
  finally
    str_a.free;
  end;
end;

{ TUTImportTableObjectData }

function TUTImportTableObjectData.GetClassName: string;
begin
  result := FOwner.names[UTClassIndex];
end;

function TUTImportTableObjectData.GetClassPackageName: string;
begin
  result := FOwner.names[UTClassPackageIndex];
end;

function TUTImportTableObjectData.GetObjectName: string;
begin
  result := FOwner.names[UTObjectIndex];
end;

function TUTImportTableObjectData.GetPackageName: string;
begin
  result := FOwner.GetObjectPath(-1, UTPackageIndex);
end;

procedure TUTImportTableObjectData.SetClassIndex(const Value: integer);
begin
  FClassIndex := Value;
end;

procedure TUTImportTableObjectData.SetClassPackageIndex(
  const Value: integer);
begin
  FClassPackageIndex := Value;
end;

procedure TUTImportTableObjectData.SetObjectIndex(const Value: integer);
begin
  FObjectIndex := Value;
end;

procedure TUTImportTableObjectData.SetPackageIndex(const Value: integer);
begin
  FPackageIndex := Value;
end;

{ TUTExportTableObjectData }

procedure TUTExportTableObjectData.CreateObject;
begin
  if FUTObject = nil then
    FUTObject := GetUTObjectClass(UTclassname).create(FOwner, FExportedIndex);
end;

destructor TUTExportTableObjectData.Destroy;
begin
  FreeObject;
end;

procedure TUTExportTableObjectData.FreeObject;
begin
  FreeAndNil(FUTObject);
end;

function TUTExportTableObjectData.GetClassName: string;
begin
  result := FOwner.GetObjectPath(1, UTClassIndex);
end;

function TUTExportTableObjectData.GetObjectName: string;
begin
  result := FOwner.names[UTObjectIndex];
end;

function TUTExportTableObjectData.GetPackageName: string;
begin
  result := FOwner.GetObjectPath(-1, UTPackageIndex);
end;

function TUTExportTableObjectData.GetSuperName: string;
begin
  result := FOwner.GetObjectPath(-1, UTSuperIndex);
end;

function TUTExportTableObjectData.GetUTObject: TUTObject;
begin
  CreateObject;
  result := FUTObject;
end;

procedure TUTExportTableObjectData.SetClassIndex(const Value: integer);
begin
  FClassIndex := Value;
end;

procedure TUTExportTableObjectData.SetFlags(const Value: integer);
begin
  FFlags := Value;
end;

procedure TUTExportTableObjectData.SetObjectIndex(const Value: integer);
begin
  FObjectIndex := Value;
end;

procedure TUTExportTableObjectData.SetPackageIndex(const Value: integer);
begin
  FPackageIndex := Value;
end;

procedure TUTExportTableObjectData.SetSerialOffset(const Value: integer);
begin
  FSerialOffset := Value;
end;

procedure TUTExportTableObjectData.SetSerialSize(const Value: integer);
begin
  FSerialSize := Value;
end;

procedure TUTExportTableObjectData.SetSuperIndex(const Value: integer);
begin
  FSuperIndex := Value;
end;

procedure TUTExportTableObjectData.SetUTObject(const Value: TUTObject);
begin
  FUTObject := Value;
end;

{ TUTObjectClassAnimation }

function TUTObjectClassAnimation.GetAnimSeqs(i: integer): TUT_Struct_AnimSeq;
begin
  check_initialized;
  result := FAnimSeqs[i];
end;

function TUTObjectClassAnimation.GetAnimSeqsCount: integer;
begin
  check_initialized;
  result := length(FAnimSeqs);
end;

function TUTObjectClassAnimation.GetMoves(i: integer): TUT_Struct_MotionChunk;
begin
  check_initialized;
  result := FMoves[i];
end;

function TUTObjectClassAnimation.GetMovesCount: integer;
begin
  check_initialized;
  result := length(FMoves);
end;

function TUTObjectClassAnimation.GetRefBones(i: integer): TUT_Struct_NamedBone;
begin
  check_initialized;
  result := FRefBones[i];
end;

function TUTObjectClassAnimation.GetRefBonesCount: integer;
begin
  check_initialized;
  result := length(FRefBones);
end;

procedure TUTObjectClassAnimation.InitializeObject;
begin
  inherited;
  setlength(FRefBones, 0);
  setlength(FMoves, 0);
  setlength(FAnimSeqs, 0);
end;

procedure TUTObjectClassAnimation.InterpretObject;
var
  size, a: integer;
begin
  inherited;
  size := FOwner.read_idx(buffer);
  setlength(FRefBones, size);
  for a := 0 to size - 1 do
    FRefBones[a] := Read_Struct_NamedBone(FOwner, buffer);
  size := FOwner.read_idx(buffer);
  setlength(FMoves, size);
  for a := 0 to size - 1 do
    FMoves[a] := Read_Struct_MotionChunk(FOwner, buffer);
end;

procedure TUTObjectClassAnimation.DoReleaseObject;
begin
  setlength(FRefBones, 0);
  setlength(FMoves, 0);
  setlength(FAnimSeqs, 0);
  inherited;
end;

{ TUTObjectClassModel }

procedure TUTObjectClassModel.DoReleaseObject;
begin
  setlength(FVectors, 0);
  setlength(FPoints, 0);
  setlength(FVerts, 0);
  setlength(FNodes, 0);
  setlength(FSurfs, 0);
  setlength(FLightMap, 0);
  setlength(FLightBits, 0);
  setlength(FBounds, 0);
  setlength(FLeafHulls, 0);
  setlength(FLeaves, 0);
  setlength(FLights, 0);
  FRootOutside := false;
  FLinked := false;
  FNumSharedSides := 0;
  FNumZones := 0;
  FPolys := 0;
  setlength(FZones, 0);
  inherited;
end;

function TUTObjectClassModel.GetBound(n: integer): TUT_Struct_BoundingBox;
begin
  result := FBounds[n];
end;

function TUTObjectClassModel.GetBoundCount: integer;
begin
  result := length(FBounds);
end;

function TUTObjectClassModel.GetLeaf(n: integer): TUT_Struct_Leaf;
begin
  result := FLeaves[n];
end;

function TUTObjectClassModel.GetLeafCount: integer;
begin
  result := length(FLeaves);
end;

function TUTObjectClassModel.GetLeafHull(n: integer): integer;
begin
  result := FLeafHulls[n];
end;

function TUTObjectClassModel.GetLeafHullCount: integer;
begin
  result := length(FLeafHulls);
end;

function TUTObjectClassModel.GetLight(n: integer): integer;
begin
  result := FLights[n];
end;

function TUTObjectClassModel.GetLightBit(n: integer): byte;
begin
  result := FLightBits[n];
end;

function TUTObjectClassModel.GetLightBitCount: integer;
begin
  result := length(FLightBits);
end;

function TUTObjectClassModel.GetLightCount: integer;
begin
  result := length(FLights);
end;

function TUTObjectClassModel.GetLightMap(
  n: integer): TUT_Struct_LightMapIndex;
begin
  result := FLightMap[n];
end;

function TUTObjectClassModel.GetLightMapCount: integer;
begin
  result := length(FLightMap);
end;

function TUTObjectClassModel.GetNode(n: integer): TUT_Struct_BspNode;
begin
  result := FNodes[n];
end;

function TUTObjectClassModel.GetNodeCount: integer;
begin
  result := length(FNodes);
end;

function TUTObjectClassModel.GetPoint(n: integer): TUT_Struct_Vector;
begin
  result := FPoints[n];
end;

function TUTObjectClassModel.GetPointCount: integer;
begin
  result := length(FPoints);
end;

function TUTObjectClassModel.GetSurf(n: integer): TUT_Struct_BspSurf;
begin
  result := FSurfs[n];
end;

function TUTObjectClassModel.GetSurfCount: integer;
begin
  result := length(FSurfs);
end;

function TUTObjectClassModel.GetVector(n: integer): TUT_Struct_Vector;
begin
  result := FVectors[n];
end;

function TUTObjectClassModel.GetVectorCount: integer;
begin
  result := length(FVectors);
end;

function TUTObjectClassModel.GetVert(n: integer): TUT_Struct_FVert;
begin
  result := FVerts[n];
end;

function TUTObjectClassModel.GetVertCount: integer;
begin
  result := length(FVerts);
end;

function TUTObjectClassModel.GetZone(
  n: integer): TUT_Struct_ZoneProperties;
begin
  result := FZones[n];
end;

procedure TUTObjectClassModel.InitializeObject;
begin
  inherited;
  setlength(FVectors, 0);
  setlength(FPoints, 0);
  setlength(FVerts, 0);
  setlength(FNodes, 0);
  setlength(FSurfs, 0);
  setlength(FLightMap, 0);
  setlength(FLightBits, 0);
  setlength(FBounds, 0);
  setlength(FLeafHulls, 0);
  setlength(FLeaves, 0);
  setlength(FLights, 0);
  FRootOutside := false;
  FLinked := false;
  FNumSharedSides := 0;
  FNumZones := 0;
  FPolys := 0;
  setlength(FZones, 0);
end;

procedure TUTObjectClassModel.InterpretObject;
var
  size, a: integer;
begin
  inherited;
  if FOwner.Version > 61 then
    begin
      size := FOwner.read_idx(buffer);
      setlength(FVectors, size);
      for a := 0 to size - 1 do
        FVectors[a] := Read_Struct_Vector(FOwner, buffer);
      size := FOwner.read_idx(buffer);
      setlength(FPoints, size);
      for a := 0 to size - 1 do
        FPoints[a] := Read_Struct_Vector(FOwner, buffer);
      size := FOwner.read_idx(buffer);
      setlength(FNodes, size);
      for a := 0 to size - 1 do
        FNodes[a] := Read_Struct_BspNode(FOwner, buffer);
      size := FOwner.read_idx(buffer);
      setlength(FSurfs, size);
      for a := 0 to size - 1 do
        FSurfs[a] := Read_Struct_BspSurf(FOwner, buffer);
      size := FOwner.read_idx(buffer);
      setlength(FVerts, size);
      for a := 0 to size - 1 do
        FVerts[a] := Read_Struct_FVert(FOwner, buffer);
      FNumSharedSides := FOwner.read_int(buffer);
      FNumZones := Fowner.read_int(buffer);
      setlength(FZones, FNumZones);
      for a := 0 to FNumZones - 1 do
        FZones[a] := Read_Struct_Zone(FOwner, buffer);
    end
  else
    begin
      // TODO : fill
    end;
  FPolys := FOwner.read_idx(buffer);
  size := FOwner.read_idx(buffer);
  setlength(FLightMap, size);
  for a := 0 to size - 1 do
    FLightMap[a] := Read_Struct_LightMap(FOwner, buffer);
  size := FOwner.read_idx(buffer);
  setlength(FLightBits, size);
  for a := 0 to size - 1 do
    FLightBits[a] := FOwner.read_byte(buffer);
  size := FOwner.read_idx(buffer);
  setlength(FBounds, size);
  for a := 0 to size - 1 do
    FBounds[a] := Read_Struct_BoundingBox(FOwner, buffer);
  size := FOwner.read_idx(buffer);
  setlength(FLeafHulls, size);
  for a := 0 to size - 1 do
    FLeafHulls[a] := FOwner.read_int(buffer);
  size := FOwner.read_idx(buffer);
  setlength(FLeaves, size);
  for a := 0 to size - 1 do
    FLeaves[a] := Read_Struct_Leaf(FOwner, buffer);
  size := FOwner.read_idx(buffer);
  setlength(FLights, size);
  for a := 0 to size - 1 do
    FLights[a] := FOwner.read_idx(buffer);
  FRootOutside := FOwner.read_int(buffer) <> 0;
  FLinked := FOwner.read_int(buffer) <> 0;
end;

{ TUTObjectClassLevelBase }

procedure TUTObjectClassLevelBase.DoReleaseObject;
begin
  setlength(FActors, 0);
  FURL.Protocol := '';
  FURL.Host := '';
  FURL.Port := 0;
  FURL.Map := '';
  setlength(FURL.Options, 0);
  FURL.Portal := '';
  FURL.Valid := false;
  inherited;
end;

function TUTObjectClassLevelBase.GetActor(n: integer): integer;
begin
  result := FActors[n];
end;

function TUTObjectClassLevelBase.GetActorCount: integer;
begin
  result := length(FActors);
end;

procedure TUTObjectClassLevelBase.InitializeObject;
begin
  inherited;
  setlength(FActors, 0);
  FURL.Protocol := '';
  FURL.Host := '';
  FURL.Port := 0;
  FURL.Map := '';
  setlength(FURL.Options, 0);
  FURL.Portal := '';
  FURL.Valid := false;
end;

procedure TUTObjectClassLevelBase.InterpretObject;
var
  size, a: integer;
begin
  inherited;
  FOwner.read_int(buffer);
  size := FOwner.read_int(buffer);
  setlength(FActors, size);
  for a := 0 to size - 1 do
    FActors[a] := FOwner.read_idx(buffer);
  FURL := Read_Struct_URL(FOwner, buffer);
end;

{ TUTObjectClassLevel }

procedure TUTObjectClassLevel.DoReleaseObject;
var
  a: integer;
begin
  FModel := 0;
  setlength(FReachSpecs, 0);
  FFirstDeleted := 0;
  for a := 0 to 15 do
    FTextBlocks[a] := 0;
  setlength(FTravelInfo, 0);
  inherited;
end;

function TUTObjectClassLevel.GetReachSpec(
  n: integer): TUT_Struct_ReachSpec;
begin
  result := FReachSpecs[n];
end;

function TUTObjectClassLevel.GetReachSpecCount: integer;
begin
  result := length(FReachSpecs);
end;

function TUTObjectClassLevel.GetTextBlock(n: integer): integer;
begin
  result := FTextBlocks[n];
end;

function TUTObjectClassLevel.GetTravelInfo(n: integer): TUT_Struct_Map;
begin
  result := FTravelInfo[n];
end;

function TUTObjectClassLevel.GetTravelInfoCount: integer;
begin
  result := length(FTravelInfo);
end;

procedure TUTObjectClassLevel.InitializeObject;
var
  a: integer;
begin
  inherited;
  FModel := 0;
  setlength(FReachSpecs, 0);
  FFirstDeleted := 0;
  for a := 0 to 15 do
    FTextBlocks[a] := 0;
  setlength(FTravelInfo, 0);
end;

procedure TUTObjectClassLevel.InterpretObject;
var
  a, size: integer;
begin
  inherited;
  FModel := FOwner.read_idx(buffer);
  size := FOwner.read_idx(buffer);
  setlength(FReachSpecs, size);
  for a := 0 to size - 1 do
    FReachSpecs[a] := Read_Struct_ReachSpec(FOwner, buffer);
  FOwner.read_float(buffer);            // AproxTime
  FFirstDeleted := FOwner.read_idx(buffer);
  for a := 0 to 15 do
    FTextBlocks[a] := FOwner.read_idx(buffer);
  if FOwner.Version > 62 then
    begin
      size := FOwner.read_idx(buffer);
      setlength(FTravelInfo, size);
      for a := 0 to size - 1 do
        FTravelInfo[a] := Read_Struct_Map(FOwner, buffer);
    end
  else if FOwner.Version >= 61 then
    begin
      // TODO : fill
    end;
end;

// Helper functions

function Read_Struct_Vector(owner: TUTPackage; buffer: TStream): TUT_Struct_Vector;
begin
  with result do
    begin
      x := owner.read_float(buffer);
      y := owner.read_float(buffer);
      z := owner.read_float(buffer);
    end;
end;

function Read_Struct_Plane(owner: TUTPackage; buffer: TStream): TUT_Struct_Plane;
begin
  with result do
    begin
      x := owner.read_float(buffer);
      y := owner.read_float(buffer);
      z := owner.read_float(buffer);
      w := owner.read_float(buffer);
    end;
end;

function Read_Struct_Rotator(owner: TUTPackage; buffer: TStream): TUT_Struct_Rotator;
begin
  with result do
    begin
      Yaw := owner.read_int(buffer);
      Roll := owner.read_int(buffer);
      Pitch := owner.read_int(buffer);
    end;
end;

function Read_Struct_Polygon(owner: TUTPackage; buffer: TStream): TUT_Struct_Polygon;
var
  v: integer;
  function coord: single;
  var
    i: integer;
    sign: boolean;
  const
    sign_flag = $80000000;
  begin
    i := owner.read_int(buffer);
    sign := (i and sign_flag) = sign_flag;
    i := i and not sign_flag;
    move(i, result, 4);
    if sign then result := -result;
  end;
begin
  with result do
    begin
      setlength(Vertex, Owner.read_idx(buffer));
      Base.x := coord;
      Base.y := coord;
      Base.z := coord;
      Normal.x := coord;
      Normal.y := coord;
      Normal.z := coord;
      TextureU.x := coord;
      TextureU.y := coord;
      TextureU.z := coord;
      TextureV.x := coord;
      TextureV.y := coord;
      TextureV.z := coord;
      for v := 0 to high(Vertex) do
        begin
          Vertex[v].x := coord;
          Vertex[v].y := coord;
          Vertex[v].z := coord;
        end;
      PolyFlags := Owner.read_int(buffer);
      Actor := Owner.read_idx(buffer);
      Texture := Owner.read_idx(buffer);
      ItemName := Owner.read_idx(buffer);
      iLink := Owner.read_idx(buffer);
      iBrushPoly := Owner.read_idx(buffer);
      pan_u := Owner.read_word(buffer);
      pan_v := Owner.read_word(buffer);
      if pan_u > $8000 then pan_u := integer($FFFF0000 or cardinal(pan_u));
      if pan_v > $8000 then pan_v := integer($FFFF0000 or cardinal(pan_v));
    end;
end;

function Read_Struct_Spark(owner: TUTPackage; buffer: TStream): TUT_Struct_Spark;
begin
  with result do
    begin
      SparkType := owner.read_byte(buffer);
      Heat := owner.read_byte(buffer);
      X := owner.read_byte(buffer);
      Y := owner.read_byte(buffer);
      X_Speed := owner.read_byte(buffer);
      Y_Speed := owner.read_byte(buffer);
      Age := owner.read_byte(buffer);
      ExpTime := owner.read_byte(buffer);
    end;
end;

function Read_Struct_BoundingBox(owner: TUTPackage; buffer: TStream): TUT_Struct_BoundingBox;
begin
  with result do
    begin
      Min := Read_Struct_Vector(owner, buffer);
      Max := Read_Struct_Vector(owner, buffer);
      Valid := Owner.read_byte(buffer);
    end;
end;

function Read_Struct_BoundingSphere(owner: TUTPackage; buffer: TStream): TUT_Struct_BoundingSphere;
begin
  with result do
    begin
      Center := Read_Struct_Vector(owner, buffer);
      if Owner.Version > 61 then
        Radius := Owner.read_float(buffer)
      else
        Radius := -1;
    end;
end;

{function Read_Struct_Vert (owner:TUTPackage;buffer:TStream):TUT_Struct_Vert;
begin
     // Not Used because of the differences between games
end;}

function Read_Struct_Tri(owner: TUTPackage; buffer: TStream): TUT_Struct_Tri;
begin
  with result do
    begin
      vertexindex1 := Owner.read_word(buffer);
      vertexindex2 := Owner.read_word(buffer);
      vertexindex3 := Owner.read_word(buffer);
      u1 := Owner.read_byte(buffer);
      v1 := Owner.read_byte(buffer);
      u2 := Owner.read_byte(buffer);
      v2 := Owner.read_byte(buffer);
      u3 := Owner.read_byte(buffer);
      v3 := Owner.read_byte(buffer);
      flags := Owner.read_int(buffer);
      textureindex := Owner.read_int(buffer);
    end;
end;

function Read_Struct_Texture(owner: TUTPackage; buffer: TStream): TUT_Struct_Texture;
begin
  result.value := Owner.read_idx(buffer);
end;

function Read_Struct_AnimSeqNotify(owner: TUTPackage; buffer: TStream): TUT_Struct_AnimSeqNotify;
begin
  with result do
    begin
      time := Owner.read_float(buffer); //time
      _function := Owner.read_idx(buffer); // function name index
    end;
end;

function Read_Struct_AnimSeq(owner: TUTPackage; buffer: TStream): TUT_Struct_AnimSeq;
var
  a2, size2: integer;
begin
  with result do
    begin
      name := Owner.read_idx(buffer);   // name index
      group := Owner.read_idx(buffer);  // group index
      startframe := Owner.read_int(buffer); // startframe
      numframes := Owner.read_int(buffer); // numframes
      size2 := Owner.read_idx(buffer);
      setlength(notifys, size2);
      for a2 := 0 to size2 - 1 do
        Notifys[a2] := Read_Struct_AnimSeqNotify(owner, buffer);
      rate := Owner.read_float(buffer); //rate
    end;
end;

function Read_Struct_Connects(owner: TUTPackage; buffer: TStream): TUT_Struct_Connects;
begin
  with result do
    begin
      NumVertTriangles := Owner.read_int(buffer); // numverttriangles
      TriangleListOffset := Owner.read_int(buffer); // trianglelistoffset
    end;
end;

function Read_Struct_Wedge(owner: TUTPackage; buffer: TStream): TUT_Struct_Wedge;
begin
  with result do
    begin
      VertexIndex := Owner.read_word(buffer);
      U := Owner.read_byte(buffer);
      V := Owner.read_byte(buffer);
    end;
end;

function Read_Struct_Face(owner: TUTPackage; buffer: TStream): TUT_Struct_Face;
begin
  with result do
    begin
      WedgeIndex1 := Owner.read_word(buffer);
      WedgeIndex2 := Owner.read_word(buffer);
      WedgeIndex3 := Owner.read_word(buffer);
      MatIndex := Owner.read_word(buffer);
    end;
end;

function Read_Struct_Material(owner: TUTPackage; buffer: TStream): TUT_Struct_Material;
begin
  with result do
    begin
      flags := Owner.read_int(buffer);
      textureindex := Owner.read_int(buffer);
    end;
end;

function Read_Struct_MeshFloatUV(owner: TUTPackage; buffer: TStream): TUT_Struct_MeshFloatUV;
begin
  with result do
    begin
      U := Owner.read_float(buffer);
      V := Owner.read_float(buffer);
    end;
end;

function Read_Struct_MeshExtWedge(owner: TUTPackage; buffer: TStream): TUT_Struct_MeshExtWedge;
begin
  with result do
    begin
      iVertex := Owner.read_word(buffer);
      Flags := Owner.read_word(buffer);
      TexUV := Read_Struct_MeshFloatUV(owner, buffer);
    end;
end;

function Read_Struct_Quat(owner: TUTPackage; buffer: TStream): TUT_Struct_Quat;
begin
  with result do
    begin
      X := Owner.read_float(buffer);
      Y := Owner.read_float(buffer);
      Z := Owner.read_float(buffer);
      W := Owner.read_float(buffer);
    end;
end;

function Read_Struct_JointPos(owner: TUTPackage; buffer: TStream): TUT_Struct_JointPos;
begin
  with result do
    begin
      Orientation := Read_Struct_Quat(owner, buffer);
      Position := Read_Struct_Vector(owner, buffer);
      Length := Owner.read_float(buffer);
      XSize := Owner.read_float(buffer);
      YSize := Owner.read_float(buffer); // bug in UT? Y=X ?
      ZSize := Owner.read_float(buffer);
    end;
end;

function Read_Struct_MeshBone(owner: TUTPackage; buffer: TStream): TUT_Struct_MeshBone;
begin
  with result do
    begin
      Name := Owner.read_idx(buffer);
      Flags := Owner.read_int(buffer);
      BonePos := Read_Struct_JointPos(owner, buffer);
      NumChildren := Owner.read_int(buffer);
      ParentIndex := Owner.read_int(buffer);
    end;
end;

function Read_Struct_BoneInfIndex(owner: TUTPackage; buffer: TStream): TUT_Struct_BoneInfIndex;
begin
  with result do
    begin
      WeightIndex := Owner.read_word(buffer);
      Number := Owner.read_word(buffer);
      DetailA := Owner.read_word(buffer);
      DetailB := Owner.read_word(buffer);
    end;
end;

function Read_Struct_BoneInfluence(owner: TUTPackage; buffer: TStream): TUT_Struct_BoneInfluence;
begin
  with result do
    begin
      PointIndex := Owner.read_word(buffer);
      BoneWeight := Owner.read_word(buffer);
    end;
end;

function Read_Struct_Coords(owner: TUTPackage; buffer: TStream): TUT_Struct_Coords;
begin
  with result do
    begin
      Origin := Read_Struct_vector(owner, buffer);
      XAxis := Read_Struct_vector(owner, buffer);
      YAxis := Read_Struct_vector(owner, buffer);
      ZAXis := Read_Struct_vector(owner, buffer);
    end;
end;

function Read_Struct_NamedBone(owner: TUTPackage; buffer: TStream): TUT_Struct_NamedBone;
begin
  with result do
    begin
      Name := owner.read_idx(buffer);
      Flags := Owner.read_int(buffer);
      ParentIndex := Owner.read_int(buffer);
    end;
end;

function Read_Struct_AnalogTrack(owner: TUTPackage; buffer: TStream): TUT_Struct_AnalogTrack;
var
  size3, c: integer;
begin
  with result do
    begin
      Flags := Owner.read_int(buffer);
      size3 := Owner.read_idx(buffer);
      setlength(KeyQuat, size3);
      for c := 0 to size3 - 1 do
        KeyQuat[c] := Read_Struct_Quat(owner, buffer);
      size3 := Owner.read_idx(buffer);
      setlength(KeyPos, size3);
      for c := 0 to size3 - 1 do
        KeyPos[c] := Read_Struct_Vector(owner, buffer);
      size3 := Owner.read_idx(buffer);
      setlength(KeyTime, size3);
      for c := 0 to size3 - 1 do
        KeyTime[c] := owner.read_float(buffer);
    end;
end;

function Read_Struct_MotionChunk(owner: TUTPackage; buffer: TStream): TUT_Struct_MotionChunk;
var
  size2, b: integer;
begin
  with result do
    begin
      RootSpeed3D := Read_Struct_Vector(owner, buffer);
      TrackTime := owner.read_float(buffer);
      StartBone := Owner.read_int(buffer);
      Flags := Owner.read_int(buffer);
      size2 := Owner.read_idx(buffer);
      setlength(boneindices, size2);
      for b := 0 to size2 - 1 do
        BoneIndices[b] := Owner.read_int(buffer);
      size2 := Owner.read_idx(buffer);
      setlength(AnimTracks, size2);
      for b := 0 to size2 - 1 do
        AnimTracks[b] := Read_Struct_AnalogTrack(owner, buffer);
      RootTrack := Read_Struct_AnalogTrack(owner, buffer);
    end;
end;

function Read_Struct_Dependency(owner: TUTPackage; buffer: TStream): TUT_Struct_Dependency;
begin
  with result do
    begin
      _Class := Owner.read_idx(buffer);
      Deep := Owner.read_int(buffer);
      ScriptTextCRC := Owner.read_int(buffer);
    end;
end;

function Read_Struct_LabelEntry(owner: TUTPackage; buffer: TStream): TUT_Struct_LabelEntry;
begin
  with result do
    begin
      Name := Owner.read_idx(buffer);   // label name
      iCode := Owner.read_int(buffer);  // iCode
    end;
end;

function Read_Struct_BspNode(owner: TUTPackage; buffer: TStream): TUT_Struct_BspNode;
begin
  with result do
    begin
      Plane := Read_Struct_Plane(owner, buffer);
      ZoneMask := owner.read_qword(buffer);
      NodeFlags := owner.read_byte(buffer);
      iVertPool := owner.read_idx(buffer);
      iSurf := owner.read_idx(buffer);
      iFront := owner.read_idx(buffer);
      iBack := owner.read_idx(buffer);
      iPlane := owner.read_idx(buffer);
      iCollisionBound := owner.read_idx(buffer);
      iRenderBound := owner.read_idx(buffer);
      iZone[0] := owner.read_byte(buffer);
      iZone[1] := owner.read_byte(buffer);
      NumVertices := owner.read_byte(buffer);
      iLeaf[0] := owner.read_int(buffer);
      iLeaf[1] := owner.read_int(buffer);
    end;
end;

function Read_Struct_BspSurf(owner: TUTPackage; buffer: TStream): TUT_Struct_BspSurf;
begin
  with result do
    begin
      Texture := owner.read_idx(buffer);
      PolyFlags := owner.read_int(buffer);
      pBase := owner.read_idx(buffer);
      vNormal := owner.read_idx(buffer);
      vTextureU := owner.read_idx(buffer);
      vTextureV := owner.read_idx(buffer);
      iLightMap := owner.read_idx(buffer);
      iBrushPoly := owner.read_idx(buffer);
      PanU := owner.read_word(buffer);
      PanV := owner.read_word(buffer);
      Actor := owner.read_idx(buffer);
      // Decals ?
      // Nodes ?
    end;
end;

function Read_Struct_FVert(owner: TUTPackage; buffer: TStream): TUT_Struct_FVert;
begin
  with result do
    begin
      pVertex := owner.read_idx(buffer);
      iSide := owner.read_idx(buffer);
    end;
end;

function Read_Struct_Zone(owner: TUTPackage; buffer: TStream): TUT_Struct_ZoneProperties;
begin
  with result do
    begin
      ZoneActor := owner.read_idx(buffer);
      Connectivity := owner.read_qword(buffer);
      Visibility := owner.read_qword(buffer);
      if owner.Version < 68 then        // TODO : fix this version?
        LastRenderTime := owner.read_float(buffer);
    end;
end;

function Read_Struct_LightMap(owner: TUTPackage; buffer: TStream): TUT_Struct_LightMapIndex;
begin
  with result do
    begin
      DataOffset := owner.read_int(buffer);
      Pan := Read_Struct_Vector(owner, buffer);
      UClamp := owner.read_idx(buffer);
      VClamp := owner.read_idx(buffer);
      UScale := owner.read_float(buffer);
      VScale := owner.read_float(buffer);
      iLightActors := owner.read_int(buffer);
    end;
end;

function Read_Struct_Leaf(owner: TUTPackage; buffer: TStream): TUT_Struct_Leaf;
begin
  with result do
    begin
      iZone := owner.read_idx(buffer);
      iPermeating := owner.read_idx(buffer);
      iVolumetric := owner.read_idx(buffer);
      VisibleZones := owner.read_qword(buffer);
    end;
end;

function Read_Struct_URL(owner: TUTPackage; buffer: TStream): TUT_Struct_URL;
var
  size, a: integer;
begin
  with result do
    begin
      Protocol := owner.read_sizedasciiz(buffer);
      Host := owner.read_sizedasciiz(buffer);
      Map := owner.read_sizedasciiz(buffer);
      size := owner.read_idx(buffer);
      setlength(Options, size);
      for a := 0 to size - 1 do
        Options[a] := owner.read_sizedasciiz(buffer);
      Portal := owner.read_sizedasciiz(buffer);
      Port := owner.read_int(buffer);
      Valid := owner.read_int(buffer) <> 0;
    end;
end;

function Read_Struct_ReachSpec(owner: TUTPackage; buffer: TStream): TUT_Struct_ReachSpec;
begin
  with result do
    begin
      Distance := owner.read_int(buffer);
      Start := owner.read_idx(buffer);
      _End := owner.read_idx(buffer);
      CollisionRadius := owner.read_int(buffer);
      CollisionHeight := owner.read_int(buffer);
      ReachFlags := owner.read_int(buffer);
      bPruned := owner.read_byte(buffer);
    end;
end;

function Read_Struct_Map(owner: TUTPackage; buffer: TStream): TUT_Struct_Map;
begin
  with result do
    begin
      Key := owner.read_sizedasciiz(buffer);
      Value := owner.read_sizedasciiz(buffer);
    end;
end;

procedure SetNativeFunctionArray(a: array of TNativeFunction);
var
  i: integer;
begin
  setlength(NativeFunctions, length(a));
  for i := 0 to high(a) do
    NativeFunctions[i] := a[i];
end;

procedure RegisterKnownEnumValues(enumtype: string; values: array of string);
var
  i: integer;
begin
  setlength(KnownEnumValues, length(KnownEnumValues) + 1);
  KnownEnumValues[high(KnownEnumValues)].Enum := enumtype;
  setlength(KnownEnumValues[high(KnownEnumValues)].Values, length(values));
  for i := 0 to high(values) do
    KnownEnumValues[high(KnownEnumValues)].Values[i] := values[i];
end;

function GetKnownEnumValue(enumtype: string; index: integer): string;
var
  e: integer;
begin
  result := '';
  for e := 0 to high(KnownEnumValues) do
    if lowercase(KnownEnumValues[e].Enum) = lowercase(enumtype) then
      begin
        if (index >= 0) and (index <= high(KnownEnumValues[e].Values)) then
          result := KnownEnumValues[e].Values[index];
        break;
      end;
end;

procedure RegisterAllKnownEnumValues;
begin
  // This function registers some needed enums, the others can be read directly from the packages.
  RegisterKnownEnumValues('ESheerAxis', ['SHEER_None', 'SHEER_XY', 'SHEER_XZ', 'SHEER_YX', 'SHEER_YZ', 'SHEER_ZX', 'SHEER_ZY']);
  RegisterKnownEnumValues('EDropType', ['DROP_FixedDepth', 'DROP_PhaseSpot', 'DROP_ShallowSpot', 'DROP_HalfAmpl', 'DROP_RandomMover', 'DROP_FixedRandomMover', 'DROP_WhirlyThing', 'DROP_BigWhirly', 'DROP_HorizontalLine', 'DROP_VerticalLine', 'DROP_DiagonalLine1', 'DROP_DiagonalLine2', 'DROP_HorizontalOsc', 'DROP_VerticalOsc', 'DROP_DiagonalOsc1', 'DROP_DiagonalOsc2', 'DROP_RainDrops', 'DROP_AreaClamp', 'DROP_LeakyTap', 'DROP_DrippyTap']);
  RegisterKnownEnumValues('ESparkType', ['SPARK_Burn', 'SPARK_Sparkle', 'SPARK_Pulse', 'SPARK_Signal', 'SPARK_Blaze', 'SPARK_OzHasSpoken', 'SPARK_Cone', 'SPARK_BlazeRight', 'SPARK_BlazeLeft', 'SPARK_Cylinder', 'SPARK_Cylinder3D', 'SPARK_Lissajous', 'SPARK_Jugglers', 'SPARK_Emit', 'SPARK_Fountain', 'SPARK_Flocks', 'SPARK_Eels', 'SPARK_Organic', 'SPARK_WanderOrganic', 'SPARK_RandomCloud', ',SPARK_CustomCloud', 'SPARK_LocalCloud', 'SPARK_Starts', 'SPARK_LineLightning', 'SPARK_RampLightning', 'SPARK_SphereLightning', 'SPARK_Wheel', 'SPARK_Gametes', 'SPARK_Sprinkler']);
  // following not used anymore
  {RegisterKnownEnumValues ('CsgOper',['CSG_Active', 'CSG_Add', 'CSG_Substract', 'CSG_Intersect', 'CSG_Deintersect']);
  RegisterKnownEnumValues ('DrawType',['DT_None', 'DT_Sprite', 'DT_Mesh', 'DT_Brush', 'DT_RopeSprite', 'DT_VerticalSprite', 'DT_TerraForm', 'DT_SpriteAnimOnce']);
  RegisterKnownEnumValues ('Style',['STY_None', 'STY_Normal', 'STY_Masked', 'STY_Translucent', 'STY_Modulated']);
  RegisterKnownEnumValues ('LightEffect',['LE_None', 'LE_TorchWaver', 'LE_FireWaver', 'LE_WateryShimmer', 'LE_Searchlight', 'LE_SlowWave', 'LE_FastWave', 'LE_CloudCast', 'LE_StaticSpot', 'LE_Shock', 'LE_Disco', 'LE_Warp', 'LE_Spotlight', 'LE_NonIncidence', 'LE_Shell', 'LE_OmniBumpMap', 'LE_Interference', 'LE_Cylinder', 'LE_Rotor', 'LE_Unused']);
  RegisterKnownEnumValues ('LightType',['LT_None', 'LT_Steady', 'LT_Pulse', 'LT_Blink', 'LT_Flicker', 'LT_Strobe', 'LT_BackdropLight', 'LT_SubtlePulse', 'LT_TexturePaletteOnce', 'LT_TexturePaletteLoop']);
  RegisterKnownEnumValues ('Physics',['PHYS_None', 'PHYS_Walking', 'PHYS_Falling', 'PHYS_Swimming', 'PHYS_Flying', 'PHYS_Rotating', 'PHYS_Projectile', 'PHYS_Rolling', 'PHYS_Interpolating', 'PHYS_MovingBrush', 'PHYS_Spider', 'PHYS_Trailer']);
  RegisterKnownEnumValues ('RemoteRole',['ROLE_None', 'ROLE_DumbProxy', 'ROLE_SimulatedProxy', 'ROLE_AutonomousProxy', 'ROLE_Authority']);
  RegisterKnownEnumValues ('DrawMode',['DRAW_Normal', 'DRAW_Lathe', 'DRAW_Lathe_2', 'DRAW_Lathe_3', 'DRAW_Lathe_4']);
  RegisterKnownEnumValues ('TimeDistribution',['DIST_Constant', 'DIST_Uniform', 'DIST_Gaussian']);
  RegisterKnownEnumValues ('AttitudeToPlayer',['ATTITUDE_Fear', 'ATTITUDE_Hate', 'ATTITUDE_Frenzy', 'ATTITUDE_Threaten', 'ATTITUDE_Ignore', 'ATTITUDE_Friendly', 'ATTITUDE_Follow']);
  RegisterKnownEnumValues ('Intelligence',['BRAINS_None', 'BRAINS_Reptile', 'BRAINS_Mammal', 'BRAINS_Human']);
  RegisterKnownEnumValues ('BumpType',['BT_PlayerBump', 'BT_PawnBump', 'BT_AnyBump']);
  RegisterKnownEnumValues ('MoverEncroachType',['ME_StopWhenEncroach', 'ME_ReturnWhenEncroach', 'ME_CrushWhenEncroach', 'ME_IgnoreWhenEncroach']);
  RegisterKnownEnumValues ('MoverGlideType',['MV_MoveByTime', 'MV_GlideByTime']);
  RegisterKnownEnumValues ('LODSet',['LODSET_None', 'LODSET_World', 'LODSET_Skin']);
  RegisterKnownEnumValues ('CompFormat',['TEXF_P8', 'TEXF_RGBA7', 'TEXF_RGB16', 'TEXF_DXT1', 'TEXF_RGB8', 'TEXF_RGBA8']);}
                        // could also be: TEXF_P8 ,  TEXF_RGB32 ,  TEXF_RGB64 ,  TEXF_DXT1 ,  TEXF_RGB24
end;

procedure Register2DClasses;
begin
  RegisterUTObjectClass('Palette', TUTObjectClassPalette);
  RegisterUTObjectClass('Font', TUTObjectClassFont);
  //RegisterUTObjectClass ('Bitmap',TUTObjectClassBitmap); {abstract}
  {****} RegisterUTObjectClass('Texture', TUTObjectClassTexture);
  {****}{****}// RegisterUTObjectClass('FractalTexture', TUTObjectClassTexture); {abstract}
  {****}{****}{****} RegisterUTObjectClass('FireTexture', TUTObjectClassFireTexture);
  {****}{****}{****} RegisterUTObjectClass('IceTexture', TUTObjectClassTexture);
  {****}{****}{****} RegisterUTObjectClass('WaterTexture', TUTObjectClassTexture);
  {****}{****}{****}{****} RegisterUTObjectClass('WaveTexture', TUTObjectClassTexture);
  {****}{****}{****}{****} RegisterUTObjectClass('WetTexture', TUTObjectClassTexture);
  {****}{****} RegisterUTObjectClass('ScriptedTexture', TUTObjectClassTexture);
end;

procedure Register3DClasses;
begin
  RegisterUTObjectClass('Primitive', TUTObjectClassPrimitive);
  {****} RegisterUTObjectClass('Mesh', TUTObjectClassMesh);
  {****}{****} RegisterUTObjectClass('LodMesh', TUTObjectClassLodMesh);
  {****}{****}{****} RegisterUTObjectClass('SkeletalMesh', TUTObjectClassSkeletalMesh);
  RegisterUTObjectClass('Animation', TUTObjectClassAnimation);

  RegisterUTObjectClass('Brush', TUTObjectClassBrush);
  {****} RegisterUTObjectClass('Mover', TUTObjectClassMover);
  RegisterUTObjectClass('Model', TUTObjectClassModel);
  RegisterUTObjectClass('Polys', TUTObjectClassPolys);
end;

procedure RegisterSoundClasses;
begin
  RegisterUTObjectClass('Sound', TUTObjectClassSound);
  RegisterUTObjectClass('Music', TUTObjectClassMusic);
end;

procedure RegisterCodeClasses;
begin
  RegisterUTObjectClass('', TUTObjectClassClass); // special case, the class definitions do not have a class name
  RegisterUTObjectClass('TextBuffer', TUTObjectClassTextBuffer);
  RegisterUTObjectClass('Field', TUTObjectClassField);
  {****} RegisterUTObjectClass('Const', TUTObjectClassConst);
  {****} RegisterUTObjectClass('Enum', TUTObjectClassEnum);
  {****} RegisterUTObjectClass('Property', TUTObjectClassProperty);
  {****}{****} RegisterUTObjectClass('ByteProperty', TUTObjectClassByteProperty);
  {****}{****} RegisterUTObjectClass('IntProperty', TUTObjectClassIntProperty);
  {****}{****} RegisterUTObjectClass('BoolProperty', TUTObjectClassBoolProperty);
  {****}{****} RegisterUTObjectClass('FloatProperty', TUTObjectClassFloatProperty);
  {****}{****} RegisterUTObjectClass('ObjectProperty', TUTObjectClassObjectProperty);
  {****}{****}{****} RegisterUTObjectClass('ClassProperty', TUTObjectClassClassProperty);
  {****}{****} RegisterUTObjectClass('NameProperty', TUTObjectClassNameProperty);
  {****}{****} RegisterUTObjectClass('StructProperty', TUTObjectClassStructProperty);
  {****}{****} RegisterUTObjectClass('StrProperty', TUTObjectClassStrProperty);
  {****}{****} RegisterUTObjectClass('ArrayProperty', TUTObjectClassArrayProperty);
  {****}{****} RegisterUTObjectClass('FixedArrayProperty', TUTObjectClassFixedArrayProperty);
  {****}{****} RegisterUTObjectClass('MapProperty', TUTObjectClassMapProperty);
  {****}{****} RegisterUTObjectClass('StringProperty', TUTObjectClassStringProperty);
  {****} RegisterUTObjectClass('Struct', TUTObjectClassStruct);
  {****}{****} RegisterUTObjectClass('Function', TUTObjectClassFunction);
  {****}{****} RegisterUTObjectClass('State', TUTObjectClassState);
  {****}{****}{****} RegisterUTObjectClass('Class', TUTObjectClassClass);
end;

procedure RegisterOtherClasses;
begin
  RegisterUTObjectClass('Package', TUTObject);
  RegisterUTObjectClass('LevelBase', TUTObjectClassLevelBase);
  {****} RegisterUTObjectClass('Level', TUTObjectClassLevel);
end;

procedure RegisterAllClasses;
begin
  Register2DClasses;
  Register3DClasses;
  RegisterSoundClasses;
  RegisterCodeClasses;
  RegisterOtherClasses;
end;

initialization
  // do not localize class names
  ClearUTClassEquivalences;
  setlength(RegisteredUTClasses, 0);
  SetNativeFunctionArray(NativeFunctions_UT);
  RegisterAllKnownEnumValues;
end.

