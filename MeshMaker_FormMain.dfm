�
 TFORMMAIN 0�A  TPF0	TFormMainFormMainLeft� Top}BorderIconsbiSystemMenu
biMinimize BorderStylebsSingleCaption	MeshMakerClientHeight2ClientWidth�Color	clBtnFaceFont.CharsetANSI_CHARSET
Font.ColorclWindowTextFont.Height�	Font.NameTahoma
Font.Style OldCreateOrderPositionpoScreenCenterOnCreate
FormCreate	OnDestroyFormDestroyOnShowFormShowPixelsPerInch`
TextHeight TPageControlPageControlLeftTopWidth�Height
ActivePageTabSheetPrefabTabOrder OnChangePageControlChange 	TTabSheetTabSheetPrefabCaptionStep OneOnShowTabSheetPrefabShow TLabelLabelWelcomeLeftTopWidth� HeightCaptionWelcome to MeshMaker!Font.CharsetANSI_CHARSET
Font.ColorclWindowTextFont.Height�	Font.NameTahoma
Font.StylefsBold 
ParentFont  TLabelLabelDescriptionWelcome1LeftTop(WidthYHeightCaptionGThis tool makes it easy to convert UnrealEd prefabs to meshes. Start by  TLabelLabelDescriptionWelcome2LeftTop7Width� HeightCaption3specifying the UnrealEd prefab you want to convert.  TPanelPanelTexturesLeft Top7Width�Height� 
BevelOuterbvNoneTabOrderVisible TLabelLabelDescriptionTexturesLeftTop!WidthcHeightCaptionGCheck the following texture/package mappings. Modify them if necessary.  TLabelLabelTexturesLeftTopWidth3HeightCaptionTexturesFont.CharsetANSI_CHARSET
Font.ColorclWindowTextFont.Height�	Font.NameTahoma
Font.StylefsBold 
ParentFont  TBevelBevelTexturesLeftFTopWidth2HeightShape	bsTopLine  TLabelLabelStatusTexturesLeftTop� Width� HeightCaptionToo many textures used.Font.CharsetANSI_CHARSET
Font.ColorclWindowTextFont.Height�	Font.NameTahoma
Font.StylefsBold 
ParentFontVisible  TPanelPanelTexturesTableLeftTop8WidthlHeighta
BevelOuterbvNoneBorderStylebsSingleTabOrder  TStringGridStringGridTexturesLeft TopWidthhHeightKAlignalClientBorderStylebsNoneColCountDefaultRowHeightDefaultDrawing	FixedCols RowCount	FixedRows Options
goHorzLinegoThumbTracking 
ScrollBars
ssVerticalTabOrder 
OnDrawCellStringGridTexturesDrawCell	OnKeyDownStringGridTexturesKeyDownOnMouseDownStringGridTexturesMouseDown	OnMouseUpStringGridTexturesMouseUpOnSelectCellStringGridTexturesSelectCell	ColWidths@@@   THeaderControlHeaderControlTexturesLeft Top WidthhHeightEnabledSections
AllowClick
ImageIndex�TextTextureWidth�  
AllowClick
ImageIndex�TextPackageWidth�  
AllowClick
ImageIndex�TextStatusWidthF     TPanelPanelTexturesProgressLeft Top!Width�Height)
BevelOuterbvNoneTabOrderVisible TLabelLabelDescriptionTextureProgressLeftTop Width� HeightCaption(Searching texture packages. Please wait.  TProgressBarProgressBarTexturesLeftTopWidthkHeightTabOrder     TPanelPanelPrefabLeft TopEWidth�Height� 
BevelOuterbvNoneTabOrder  TLabelLabelPrefabLeftTopWidth%HeightCaptionPrefabFont.CharsetANSI_CHARSET
Font.ColorclWindowTextFont.Height�	Font.NameTahoma
Font.StylefsBold 
ParentFont  TBevelBevelPrefabLeft7TopWidthAHeightShape	bsTopLine  TLabelLabelDescriptionPrefabLeftTop!WidthTHeightCaptionJEnter the name of a prefab file, or drag-and-drop it onto this edit field.  TLabelLabelStatusPrefabLeftTopNWidthfHeightCaptionInvalid prefab file.Font.CharsetANSI_CHARSET
Font.ColorclWindowTextFont.Height�	Font.NameTahoma
Font.StylefsBold 
ParentFontVisible  TLabelLabelPasteBrushLeft
Top_WidtheHeightCaptionOr paste brush here:  TEdit
EditPrefabLeftTop8WidthNHeightTabOrderOnChangeEditPrefabChangeOnExitEditPrefabExit	OnKeyDownEditPrefabKeyDown
OnKeyPressEditPrefabKeyPress  TPanelPanelEnterPrefabLeft5Top;Width!Height
BevelOuterbvNoneTabOrder Visible
DesignSize!  TSpeedButtonSpeedButtonEnterPrefabLeft Top Width!HeightAnchorsakLeftakTopakRightakBottom CaptionEnterFont.CharsetANSI_CHARSET
Font.ColorclWindowTextFont.Height�	Font.NameTahoma
Font.Style 
ParentFontOnClickSpeedButtonEnterPrefabClick   TBitBtnButtonBrowsePrefabLeft_Top6WidthHeightTabOrderOnClickButtonBrowsePrefabClick
Glyph.Data

    BM      6   (               �              ������������������������������������������������                                 ���������������      ���������������������������   ������������   ���   ���������������������������   ���������   ������   ���������������������������   ������   ���������   ���������������������������   ���   ������������                                    ���������������������������   ���������������   ���������������������������   ���������������   ���������                     ������������������         ������������������������         ������������������������������������������      ���������������������������   ���������   ���   ������������������������������         ������������������������������������������������������������  TMemoMemoPasteBrushLeftsTopPWidthHeight� TabOrderOnChangeMemoPasteBrushChange    	TTabSheetTabSheetMeshCaptionStep Two
ImageIndex TPanel	PanelMeshLeft TopWidth�Heighte
BevelOuterbvNoneTabOrder  TLabel	LabelMeshLeftTopWidthHeightCaptionMeshFont.CharsetANSI_CHARSET
Font.ColorclWindowTextFont.Height�	Font.NameTahoma
Font.StylefsBold 
ParentFont  TBevel	BevelMeshLeft0TopWidthHHeightShape	bsTopLine  TLabelLabelDescriptionMesh1LeftTop!WidthhHeightCaptionLYou can either just export the prefab as a model for further editing, or you  TLabelLabelDescriptionMesh2LeftTop0Width&HeightCaption;can let MeshMaker create a ready-to-use decoration for you.  TLabelLabelCaptionExportClassLeftTopXWidthHeightCaptionClass:  TLabelLabelCaptionExportPackageLeftToptWidth,HeightCaptionPackage:  TLabelLabelDescriptionModel1LeftTop� Width7HeightCaptionBIf you select this option, MeshMaker will just place the model and  TLabelLabelDescriptionModel2LeftTop� Width HeightCaption6UnrealScript source files in a subdirectory named '%s'  TLabelLabelDescriptionModel3LeftTop� Width� HeightCaption'under your Unreal Tournament directory.  TLabelLabelDescriptionDecoration1LeftTopWidthHeightCaption:With this option, MeshMaker will automatically create %s.u  TLabelLabelDescriptionDecoration2LeftTopWidth.HeightCaption=containing the converted prefab as a ready-to-use decoration.  TRadioButtonRadioButtonExportModelLeftTop� WidthlHeightCaptionExport the prefab as a modelFont.CharsetANSI_CHARSET
Font.ColorclWindowTextFont.Height�	Font.NameTahoma
Font.StylefsBold 
ParentFontTabOrder  TRadioButtonRadioButtonExportDecorationLeftTop� WidthlHeightCaption Create a ready-to-use decorationChecked	Font.CharsetANSI_CHARSET
Font.ColorclWindowTextFont.Height�	Font.NameTahoma
Font.StylefsBold 
ParentFontTabOrderTabStop	  TEditEditExportClassLeftJTopUWidthyHeightTabOrder OnChangeEditExportChange  TEditEditExportPackageLeftJTopqWidthyHeightTabOrderOnChangeEditExportChange  	TCheckBoxCheckBoxExportCollisionLeft� TopWWidth� HeightCaptionGenerate collision hullChecked	State	cbCheckedTabOrder    	TTabSheetTabSheetDoneCaption
It's Done!
ImageIndex TLabel	LabelDoneLeftTopWidth6HeightCaption	Congrats!Font.CharsetANSI_CHARSET
Font.ColorclWindowTextFont.Height�	Font.NameTahoma
Font.StylefsBold 
ParentFont  TLabelLabelDescriptionFiles1LeftTop� Width]HeightCaptionIMeshMaker has created the following files for you, all located under your  TLabelLabelCaptionFileModelLeft$Top� Width%HeightCaptionModel:Font.CharsetANSI_CHARSET
Font.ColorclWindowTextFont.Height�	Font.NameTahoma
Font.StylefsBold 
ParentFont  TLabelLabelCaptionFileCodeLeft$Top� WidthHeightCaptionCode:Font.CharsetANSI_CHARSET
Font.ColorclWindowTextFont.Height�	Font.NameTahoma
Font.StylefsBold 
ParentFont  TLabelLabelCaptionFilePackageLeft$Top� Width3HeightCaptionPackage:Font.CharsetANSI_CHARSET
Font.ColorclWindowTextFont.Height�	Font.NameTahoma
Font.StylefsBold 
ParentFont  TLabel
LabelFilesLeftTopoWidthIHeightCaptionCreated FilesFont.CharsetANSI_CHARSET
Font.ColorclWindowTextFont.Height�	Font.NameTahoma
Font.StylefsBold 
ParentFont  TBevel
BevelFilesLeft[TopvWidthHeightShape	bsTopLine  TLabelLabelDescriptionFiles2LeftTop� Width� HeightCaption!Unreal Tournament base directory:  TLabelLabelCopyright_NoLocLeftTopTWidthlHeight	AlignmenttaCenterAutoSizeCaption=   MeshMaker © 2001 by Mychaeel ‹mychaeel@planetunreal.com›Font.CharsetANSI_CHARSET
Font.ColorclWindowTextFont.Height�	Font.NameTahoma
Font.Style 
ParentFont  TLabelLabelEmail_NoLocLeft� TopTWidth� HeightCursorcrHandPointCaptionmychaeel@planetunreal.comOnMouseMoveLabelEmail_NoLocMouseMove	OnMouseUpLabelEmail_NoLocMouseUp  TLabelLabelDescriptionPackage1LeftTopWidth-HeightCaption<You only have to bundle %s.u with your map release; or check  TLabelLabelDescriptionPackage2LeftTop!WidthZHeightCaptionFthe documentation for how to embed the decorations into your map file.  TPanelPanelDoneDecorationLeft Top Width�Height9
BevelOuterbvNoneTabOrder TLabelLabelDoneDecoration2LeftTopWidthYHeightCaptionIdecoration. Simply load the package in the Actor browser; you'll find the  TLabelLabelDoneDecoration1LeftTopWidthRHeightCaptionDYour prefab has been successfully converted to a ready-to-use Unreal  TLabelLabelDoneDecoration3LeftTop&Width� HeightCaption-converted prefab in the 'Decoration' subtree.   TPanelPanelDoneModelLeft Top Width�Height9
BevelOuterbvNoneTabOrder  TLabelLabelDoneModel2LeftTopWidth^HeightCaptionInow modify and animate it using a modeling application of your choice, or  TLabelLabelDoneModel1LeftTopWidth_HeightCaptionFYour prefab has been successfully converted to an Unreal mesh. You can  TLabelLabelDoneModel3LeftTop&Width_HeightCaptionLyou can add UnrealScript code to its class to give it in-game functionality.   TEditEditFileModel1LefthTop� WidthHeightBorderStylebsNoneColor	clBtnFaceReadOnly	TabOrderTextMyPrefab\Models\MyPrefab_a.3d  TEditEditFileModel2LefthTop� WidthHeightBorderStylebsNoneColor	clBtnFaceReadOnly	TabOrderTextMyPrefab\Models\MyPrefab_d.3d  TEditEditFileCodeLefthTop� WidthHeightBorderStylebsNoneColor	clBtnFaceReadOnly	TabOrderTextMyPrefab\Classes\MyPrefab.uc  TEditEditFilePackageLefthTop� WidthHeightBorderStylebsNoneColor	clBtnFaceReadOnly	TabOrderTextSystem\MyPrefab.u  TPanelPanelDoneFocusLeft Top Width Height TabOrder    TButtonButtonCancelLeft?TopWidthQHeightCancel	CaptionCancelTabOrderOnClickButtonCancelClick  TButton
ButtonNextLeft� TopWidthQHeightCaption   Next ››EnabledTabOrderOnClickButtonNextClick  TButton
ButtonBackLeft� TopWidthQHeightCaption   ‹‹ BackTabOrderVisibleOnClickButtonBackClick  
TImageListImageListPackageLeft(Top@Bitmap
&  IL     �������������BM6       6   (   @                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                              �   �   �                   �   �   �                                          �   �   �                                                       �   �   �                                                                                                        �   �   �   �           �   �   �   �                                      �   �   �   �                                                   �   �   �   �                                                                                                            �   �   �   �   �   �   �   �                                      �   �   �   �   �   �                                           �   �   �   �   �   �                                                                                                            �   �   �   �   �   �                                      �   �   �   �   �   �   �                                       �   �   �   �   �   �   �                                                                                                                �   �   �   �                                              �   �       �   �   �   �                                       �   �       �   �   �   �                                                                                                        �   �   �   �   �   �                                                          �   �   �                                                       �   �   �                                                                                                    �   �   �   �   �   �   �   �                                                      �   �   �   �                                                   �   �   �   �                                                                                            �   �   �   �           �   �   �   �                                                      �   �   �                                                       �   �   �                                                                                            �   �   �                   �   �   �                                                      �   �   �                                                       �   �   �                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                              BM>       >   (   @            �                       ��� ������  ������  ������  ������  ���?�?  ��?�?  ���  ���  �?��  �����  �����  �����  ������  ������  ������  ������                          TOpenDialogOpenDialogPrefab
DefaultExtt3dFilterPrefabs|*.t3d|All Files|*.*OptionsofHideReadOnlyofPathMustExistofFileMustExistofEnableSizing TitleSelect PrefabLeftHTop  
TPopupMenuPopupMenuTexturesAutoHotkeysmaManualMenuAnimationmaTopToBottom 	OwnerDraw	Left^Top@ 	TMenuItemMenuItemTexturesSeparatorTag�Caption-  	TMenuItemMenuItemTexturesBrowseTag�Caption	Browse...OnClickMenuItemTexturesBrowseClick
OnDrawItemPopupMenuTexturesDrawItemOnMeasureItemPopupMenuTexturesMeasureItem   TOpenDialogOpenDialogTexture
DefaultExtutxFilter&Packages|*.u;*.utx;*.unr|All Files|*.*OptionsofHideReadOnlyofPathMustExistofFileMustExistofEnableSizing TitleSelect Texture PackageLeft� Top@  TTimer
TimerEmailEnabledIntervaldOnTimerTimerEmailTimerLeftXTop�   