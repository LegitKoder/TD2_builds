program TD2BrandGearSets;

uses
  System.StartUpCopy,
  FMX.Types,
  FMX.Forms,
  FMX.Skia,
  MainBuilds in 'MainBuilds.pas' {MainForm},
  FormSets in 'Views\FormSets.pas' {FormSlots},
  Acrylic in 'Resources\Acrylic.pas' {AcrylicFrame: TFrame},
  FormWeapons in 'Views\FormWeapons.pas' {FormCw},
  Utils in 'Resources\Utils.pas',
  Game.Types in 'Resources\Game.Types.pas',
  CalcEngine in 'Resources\CalcEngine.pas',
  FormSkills in 'Views\FormSkills.pas' {FormSkill},
  Game.Player in 'Resources\Game.Player.pas',
  LoadoutManager in 'Resources\LoadoutManager.pas',
  Game.JsonIterator in 'Resources\Game.JsonIterator.pas' {DataJsonIterator: TDataModule},
  BuildGenerator in 'Resources\BuildGenerator.pas',
  RecommendationEngine in 'Resources\RecommendationEngine.pas',
  BuildArchetypes in 'Resources\BuildArchetypes.pas',
  FormRecPrefs in 'Views\FormRecPrefs.pas' {FrmRecPrefs},
  MainController in 'Controllers\MainController.pas',
  WindowEffects in 'Resources\WindowEffects.pas';

{$R *.res}

begin
  // Avoid crashing in GPU shader creation (style shadow/glow) on some drivers.
  GlobalUseDX := True;

  GlobalUseSkia := True;
  Application.Initialize;
  Application.CreateForm(TMainForm, MainForm);
  Application.CreateForm(TFormSlots, FormSlots);
  Application.CreateForm(TFormCw, FormCw);
  Application.CreateForm(TFormSkill, FormSkill);
  Application.CreateForm(TDataJsonIterator, DataJsonIterator);
  Application.CreateForm(TFrmRecPrefs, FrmRecPrefs);
  Application.Run;

end.
