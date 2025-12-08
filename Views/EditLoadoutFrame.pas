unit EditLoadoutFrame;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes,
  System.Variants,
  FMX.Types, FMX.Graphics, FMX.Controls, FMX.Forms, FMX.Dialogs, FMX.StdCtrls,
  FMX.Layouts, FMX.Controls.Presentation, FMX.Edit, Skia, FMX.Skia;

type
  TEditLoadout = class(TFrame)
    EditLoadoutName: TEdit;
    Ok: TCornerButton;
    Cancel: TCornerButton;
    GridPanelLayout1: TGridPanelLayout;
    Rename: TSkLabel;
  private
    { Private declarations }
  public
    { Public declarations }
  end;

implementation

{$R *.fmx}

end.
