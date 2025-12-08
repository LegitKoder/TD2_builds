unit Game.Player;

interface

uses
  System.SysUtils, Game.Types;

type
  TEquippedSkill = record
    SkillID: string;
    VariantName: string;
  end;

  TPlayer = class
  private
    FStats: TPlayerStats;
    FEquippedSkill1: TEquippedSkill;
    FEquippedSkill2: TEquippedSkill;
    procedure SetStats(AValue: TPlayerStats);
  public
    constructor Create;
    destructor Destroy; override;

    procedure LoadFromJSON(const AFilename: string);
    procedure SaveToJSON(const AFilename: string);

    property Stats: TPlayerStats read FStats write SetStats;
    property EquippedSkill1: TEquippedSkill read FEquippedSkill1
      write FEquippedSkill1;
    property EquippedSkill2: TEquippedSkill read FEquippedSkill2
      write FEquippedSkill2;
  end;

implementation

{ TPlayer }

constructor TPlayer.Create;
begin
  inherited;
  // Initialiser les statistiques avec des valeurs par défaut
  FillChar(FStats, SizeOf(TPlayerStats), 0);
  FEquippedSkill1.SkillID := '';
  FEquippedSkill1.VariantName := '';
  FEquippedSkill2.SkillID := '';
  FEquippedSkill2.VariantName := '';
end;

destructor TPlayer.Destroy;
begin
  // Pas de nettoyage spécifique nécessaire pour TPlayerStats
  inherited;
end;

procedure TPlayer.LoadFromJSON(const AFilename: string);
begin
  //
end;

procedure TPlayer.SaveToJSON(const AFilename: string);
begin
  //
end;

procedure TPlayer.SetStats(AValue: TPlayerStats);
begin
  FStats := AValue;
end;

end.
