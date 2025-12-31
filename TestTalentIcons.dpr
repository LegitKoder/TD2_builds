program TestTalentIcons;

{$APPTYPE CONSOLE}

uses
  System.SysUtils,
  System.Classes,
  System.IOUtils,
  System.Generics.Collections,
  FMX.Graphics,
  FMX.ImgList,
  System.ImageList,
  Game.JsonIterator in 'Resources/Game.JsonIterator.pas',
  Game.Types in 'Resources/Game.Types.pas',
  Game.Player in 'Resources/Game.Player.pas',
  Utils in 'Resources/Utils.pas';

var
  Data: TDataJsonIterator;
  Idx: Integer;
  TalentName: string;
begin
  try
    WriteLn('Initializing DataJsonIterator...');
    Data := TDataJsonIterator.Create(nil);
    try
      // Data.Init is called in Create.

      TalentName := 'Braced';
      WriteLn('Testing talent: ' + TalentName);

      if Data.GearTalentDefinitions.ContainsKey(TalentName) then
        WriteLn('Talent definition found.')
      else
        WriteLn('Error: Talent definition NOT found.');

      Idx := Data.GetTalentImageIndex(TalentName);
      WriteLn('Image Index for ' + TalentName + ': ' + IntToStr(Idx));

      if Idx = -1 then
      begin
        WriteLn('Error: Image index is -1.');
        // Debug why
        if Data.GetTalentBitmap(TalentName) = nil then
           WriteLn('GetTalentBitmap returned nil.')
        else
           WriteLn('GetTalentBitmap returned a bitmap.');
      end
      else
      begin
        WriteLn('Success: Image index found.');
        WriteLn('ImageList Source Count: ' + IntToStr(Data.ImageList_GTalents.Source.Count));
      end;

      // Test a perfect talent
      TalentName := 'Perfect Adrenaline Rush';
      WriteLn('Testing talent: ' + TalentName);
      Idx := Data.GetTalentImageIndex(TalentName);
      WriteLn('Image Index for ' + TalentName + ': ' + IntToStr(Idx));

    finally
      Data.Free;
    end;
  except
    on E: Exception do
      WriteLn(E.ClassName, ': ', E.Message);
  end;
end.
