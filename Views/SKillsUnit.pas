unit SKillsUnit;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs, FMX.Layouts,
  FMX.StdCtrls, FMX.Controls.Presentation, FMX.ScrollBox, FMX.ListView.Types,
  FMX.ListView.Appearances, FMX.ListView.Adapters.Base, FMX.ListView,
  Game.Types, Game.JsonIterator, System.IOUtils, Utils, FMX.Objects;

type
  TForm_Skills = class(TForm)
    LayoutRoot: TLayout;
    ToolBar: TToolBar;
    LabelTitle: TLabel;
    LayoutSkills: TLayout;
    ScrollBoxSkills: TScrollBox;
    FlowLayoutSkills: TFlowLayout;
    Splitter: TSplitter;
    LayoutDetails: TLayout;
    ImageSkill: TImage;
    LabelSkillName: TLabel;
    LabelSkillDescription: TLabel;
    ListViewVariants: TListView;
    procedure FormCreate(Sender: TObject);
    procedure SkillClick(Sender: TObject);
    procedure VariantClick(Sender: TObject; const AItem: TListViewItem);
  private
    { Private declarations }
//    FSelectedSkill: TSkillData;
    procedure PopulateSkills;
//    procedure DisplaySkillDetails(const ASkill: TSkillData);
  public
    { Public declarations }
    SelectedSkillID: string;
    SelectedVariantName: string;
  end;

var
  Form_Skills: TForm_Skills;

implementation

{$R *.fmx}

procedure TForm_Skills.FormCreate(Sender: TObject);
begin
  PopulateSkills;
  ListViewVariants.OnItemClick := VariantClick;
end;

procedure TForm_Skills.PopulateSkills;
var
  Skill: TSkillData;
  Image: TImage;
begin
  FlowLayoutSkills.Clear;
  for Skill in DataJsonIterator.Skills.Values do
  begin
    Image := TImage.Create(FlowLayoutSkills);
    Image.Parent := FlowLayoutSkills;
    Image.Size.Size := TPointF.Create(64, 64);
    Image.WrapMode := TImageWrapMode.Stretch;
    Image.Bitmap.LoadFromFile(TPath.Combine(TUtils.AssetsPath, Skill.ImagePath));
    Image.TagString := Skill.SkillID;
    Image.OnClick := SkillClick;
  end;
end;

procedure TForm_Skills.SkillClick(Sender: TObject);
var
  SkillID: string;
  Skill: TSkillData;
begin
  if Sender is TImage then
  begin
    SkillID := (Sender as TImage).TagString;
    if DataJsonIterator.Skills.TryGetValue(SkillID, Skill) then
    begin
      DisplaySkillDetails(Skill);
    end;
  end;
end;

procedure TForm_Skills.DisplaySkillDetails(const ASkill: TSkillData);
var
  Variant: TSkillVariant;
begin
  FSelectedSkill := ASkill;

  ImageSkill.Bitmap.LoadFromFile(TPath.Combine(TUtils.AssetsPath, ASkill.ImagePath));
  LabelSkillName.Text := ASkill.SkillName;
  LabelSkillDescription.Text := ASkill.Description;

  ListViewVariants.Items.Clear;
  for Variant in ASkill.Variants do
  begin
    ListViewVariants.Items.Add.Text := Variant.VariantName;
  end;
end;

procedure TForm_Skills.VariantClick(Sender: TObject; const AItem: TListViewItem);
begin
  SelectedSkillID := FSelectedSkill.SkillID;
  SelectedVariantName := AItem.Text;
  ModalResult := TModalResult.mrOk;
end;

end.
