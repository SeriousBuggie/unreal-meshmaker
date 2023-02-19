object FormCompile: TFormCompile
  Left = 290
  Top = 276
  BorderIcons = [biSystemMenu]
  BorderStyle = bsDialog
  Caption = 'MeshMaker'
  ClientHeight = 97
  ClientWidth = 288
  Color = clBtnFace
  Font.Charset = ANSI_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  OldCreateOrder = False
  Position = poOwnerFormCenter
  OnActivate = FormActivate
  OnClose = FormClose
  OnCreate = FormCreate
  PixelsPerInch = 96
  TextHeight = 13
  object LabelWait: TLabel
    Left = 12
    Top = 12
    Width = 253
    Height = 13
    Caption = 'Please wait while MeshMaker compiles your package.'
  end
  object ButtonCancel: TButton
    Left = 196
    Top = 60
    Width = 81
    Height = 25
    Cancel = True
    Caption = 'Cancel'
    TabOrder = 0
    OnClick = ButtonCancelClick
  end
  object ProgressBarCompile: TProgressBar
    Left = 12
    Top = 35
    Width = 264
    Height = 15
    Step = 1
    TabOrder = 1
  end
  object PanelFocus: TPanel
    Left = 0
    Top = 0
    Width = 0
    Height = 0
    BevelOuter = bvNone
    TabOrder = 2
  end
  object MemoOutput: TMemo
    Left = 12
    Top = 104
    Width = 265
    Height = 161
    TabOrder = 3
  end
  object TimerClose: TTimer
    Enabled = False
    Interval = 100
    OnTimer = TimerCloseTimer
    Left = 16
    Top = 56
  end
end
