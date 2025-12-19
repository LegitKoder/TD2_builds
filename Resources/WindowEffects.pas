unit WindowEffects;

interface

uses
  System.SysUtils, Winapi.Windows, Winapi.Messages, FMX.Forms, FMX.Platform.Win, FMX.Types,
  System.UITypes, Winapi.Dwmapi, Winapi.UxTheme;

type
  TWindowEffect = (weNone, weMica, weAcrylic, weTabbed, weAcrylicBlurBehind);

  TWindowEffects = class
  public
    class procedure ApplyEffect(const Form: TCommonCustomForm; Effect: TWindowEffect; DarkMode: Boolean = True);
    class function SetSystemBackdropType(Handle: HWND; Value: Integer): Boolean;
    class function SetAccentPolicy(Handle: HWND; State: Integer; Color: TAlphaColor): Boolean;
    class function ExtendFrameIntoClientArea(Handle: HWND; Margins: TRect): Boolean;
  end;

implementation

uses
  System.Win.Registry, FMX.Graphics;

const
  DWMWA_USE_IMMERSIVE_DARK_MODE = 20;
  DWMWA_WINDOW_CORNER_PREFERENCE = 33;
  DWMWA_SYSTEMBACKDROP_TYPE = 38;
  DWMWA_MICA_EFFECT = 1029;

  // DWM_SYSTEMBACKDROP_TYPE values
  DWMSBT_AUTO = 0;
  DWMSBT_NONE = 1;
  DWMSBT_MAINWINDOW = 2; // Mica
  DWMSBT_TRANSIENTWINDOW = 3; // Acrylic
  DWMSBT_TABBEDWINDOW = 4; // Tabbed Mica

  // Accent Policy constants
  WCA_ACCENT_POLICY = 19;
  ACCENT_DISABLED = 0;
  ACCENT_ENABLE_GRADIENT = 1;
  ACCENT_ENABLE_TRANSPARENTGRADIENT = 2;
  ACCENT_ENABLE_BLURBEHIND = 3;
  ACCENT_ENABLE_ACRYLICBLURBEHIND = 4; // RS4 1803
  ACCENT_ENABLE_HOSTBACKDROP = 5; // RS5 1809

  DrawLeftBorder = $20;
  DrawTopBorder = $40;
  DrawRightBorder = $80;
  DrawBottomBorder = $100;

type
  TAccentPolicy = packed record
    AccentState: DWORD;
    AccentFlags: DWORD;
    GradientColor: DWORD;
    AnimationId: DWORD;
  end;

  TWindowCompositionAttribData = packed record
    Attribute: DWORD;
    Data: Pointer;
    DataSize: ULONG;
  end;

  TSetWindowCompositionAttribute = function(Wnd: HWND; const AttrData: TWindowCompositionAttribData): BOOL; stdcall;

var
  SetWindowCompositionAttribute: TSetWindowCompositionAttribute = nil;

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

procedure InitUser32;
var
  HUser32: HMODULE;
begin
  if Assigned(SetWindowCompositionAttribute) then Exit;
  HUser32 := GetModuleHandle('user32.dll');
  if HUser32 <> 0 then
    @SetWindowCompositionAttribute := GetProcAddress(HUser32, 'SetWindowCompositionAttribute');
end;

class function TWindowEffects.SetSystemBackdropType(Handle: HWND; Value: Integer): Boolean;
begin
  Result := Succeeded(DwmSetWindowAttribute(Handle, DWMWA_SYSTEMBACKDROP_TYPE, @Value, SizeOf(Value)));
end;

class function TWindowEffects.SetAccentPolicy(Handle: HWND; State: Integer; Color: TAlphaColor): Boolean;
var
  Policy: TAccentPolicy;
  Data: TWindowCompositionAttribData;
begin
  InitUser32;
  if not Assigned(SetWindowCompositionAttribute) then Exit(False);

  FillChar(Policy, SizeOf(Policy), 0);
  Policy.AccentState := State;
  Policy.AccentFlags := DrawLeftBorder or DrawTopBorder or DrawRightBorder or DrawBottomBorder;
  Policy.GradientColor := Color; // Format is usually ABGR or ARGB depending on version, 0 is fully transparent

  Data.Attribute := WCA_ACCENT_POLICY;
  Data.Data := @Policy;
  Data.DataSize := SizeOf(Policy);

  Result := SetWindowCompositionAttribute(Handle, Data);
end;

class function TWindowEffects.ExtendFrameIntoClientArea(Handle: HWND; Margins: TRect): Boolean;
var
  M: TMargins;
begin
  M.cxLeftWidth := Margins.Left;
  M.cxRightWidth := Margins.Right;
  M.cyTopHeight := Margins.Top;
  M.cyBottomHeight := Margins.Bottom;
  Result := Succeeded(DwmExtendFrameIntoClientArea(Handle, M));
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

  // 1. Dark Mode
  if Build >= 17763 then
  begin
    Value := Ord(DarkMode);
    DwmSetWindowAttribute(Handle, DWMWA_USE_IMMERSIVE_DARK_MODE, @Value, SizeOf(Value));
  end;

  // 2. Extend Frame (Required for some effects to look seamless)
  // Usually extending into the title bar area (-1) is good for custom drawn titlebars,
  // but for standard forms, passing a small margin or 0,0,0,0 might be sufficient depending on the brush.
  // For Mica, the client area needs to be transparent.
  // ExtendFrameIntoClientArea(Handle, TRect.Create(-1, -1, -1, -1));

  // 3. Apply Effect based on Windows Version and Request
  if Build >= 22621 then // Windows 11 22H2+
  begin
    case Effect of
      weMica:    Value := DWMSBT_MAINWINDOW;
      weAcrylic: Value := DWMSBT_TRANSIENTWINDOW;
      weTabbed:  Value := DWMSBT_TABBEDWINDOW;
      weNone:    Value := DWMSBT_NONE;
    else
      Value := DWMSBT_AUTO;
    end;
    SetSystemBackdropType(Handle, Value);
  end
  else if (Build >= 22000) and (Effect = weMica) then // Windows 11 21H2
  begin
    Value := 1;
    DwmSetWindowAttribute(Handle, DWMWA_MICA_EFFECT, @Value, SizeOf(Value));
  end
  else if (Effect in [weAcrylic, weAcrylicBlurBehind]) then
  begin
    // Fallback for Windows 10 or when explicit blur behind is requested
    // This uses the undocumented SetWindowCompositionAttribute
    SetAccentPolicy(Handle, ACCENT_ENABLE_BLURBEHIND, 0);
    // Or ACCENT_ENABLE_ACRYLICBLURBEHIND with a color if specific transparency is needed
  end;
end;

end.
