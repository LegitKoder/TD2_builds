unit WindowEffects;

interface

uses
  System.SysUtils, Winapi.Windows, Winapi.Messages, FMX.Forms, FMX.Platform.Win, FMX.Types;

type
  TWindowEffect = (weNone, weMica, weAcrylic, weTabbed);

  TWindowEffects = class
  public
    class procedure ApplyEffect(const Form: TCommonCustomForm; Effect: TWindowEffect; DarkMode: Boolean = True);
  end;

implementation

uses
  System.Win.Registry;

const
  DWMWA_USE_IMMERSIVE_DARK_MODE = 20;
  DWMWA_WINDOW_CORNER_PREFERENCE = 33;
  DWMWA_SYSTEMBACKDROP_TYPE = 38;
  DWMWA_MICA_EFFECT = 1029; // Undocumented Windows 11 build 22000

  // DWM_SYSTEMBACKDROP_TYPE values
  DWMSBT_AUTO = 0;
  DWMSBT_NONE = 1;
  DWMSBT_MAINWINDOW = 2; // Mica
  DWMSBT_TRANSIENTWINDOW = 3; // Acrylic
  DWMSBT_TABBEDWINDOW = 4; // Tabbed Mica

function DwmSetWindowAttribute(hwnd: HWND; dwAttribute: DWORD; pvAttribute: Pointer; cbAttribute: DWORD): HRESULT; stdcall; external 'dwmapi.dll';

function GetWindowsBuildNumber: Integer;
var
  Reg: TRegistry;
begin
  Result := 0;
  Reg := TRegistry.Create(KEY_READ);
  try
    Reg.RootKey := HKEY_LOCAL_MACHINE;
    if Reg.OpenKey('SOFTWARE\Microsoft\Windows NT\CurrentVersion', False) then
    begin
      if Reg.ValueExists('CurrentBuild') then
        Result := StrToIntDef(Reg.ReadString('CurrentBuild'), 0);
    end;
  finally
    Reg.Free;
  end;
end;

class procedure TWindowEffects.ApplyEffect(const Form: TCommonCustomForm; Effect: TWindowEffect; DarkMode: Boolean);
var
  Handle: HWND;
  Value: Integer;
  Build: Integer;
begin
  if not Assigned(Form) then Exit;

  Handle := FormToHWND(Form);
  if Handle = 0 then Exit;

  Build := GetWindowsBuildNumber;

  // 1. Dark Mode (Available on Win10 1809+)
  if Build >= 17763 then
  begin
    Value := Ord(DarkMode);
    DwmSetWindowAttribute(Handle, DWMWA_USE_IMMERSIVE_DARK_MODE, @Value, SizeOf(Value));
  end;

  // 2. Backdrop Effect (Win11)
  if Build >= 22621 then // Windows 11 22H2+
  begin
    case Effect of
      weNone:    Value := DWMSBT_NONE;
      weMica:    Value := DWMSBT_MAINWINDOW;
      weAcrylic: Value := DWMSBT_TRANSIENTWINDOW;
      weTabbed:  Value := DWMSBT_TABBEDWINDOW;
    else
      Value := DWMSBT_AUTO;
    end;
    DwmSetWindowAttribute(Handle, DWMWA_SYSTEMBACKDROP_TYPE, @Value, SizeOf(Value));
  end
  else if (Build >= 22000) and (Effect = weMica) then // Windows 11 21H2 (Initial Release)
  begin
    Value := 1;
    DwmSetWindowAttribute(Handle, DWMWA_MICA_EFFECT, @Value, SizeOf(Value));
  end;

  // Note: For these effects to be visible in FMX, the form usually needs transparency
  // or a transparent brush. However, setting Transparency=True in FMX often removes window borders/caption.
  // A common trick is to keep Transparency=False but ensure the background color is handled correctly
  // (e.g. handled by DWM).
  // In FMX, often just enabling this DWM attribute works if the style allows it,
  // but sometimes we need to set Form.Fill.Kind := TBrushKind.None or Color to transparent.
end;

end.
