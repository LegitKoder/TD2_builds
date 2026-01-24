unit WindowEffects;

interface

uses
  System.SysUtils,
  System.UITypes,
  System.Win.Registry,
  Winapi.Windows,
  Winapi.Dwmapi,
  Winapi.UxTheme,
  Winapi.Messages,
  FMX.Forms,
  {$IFDEF MSWINDOWS}
    FMX.Platform.Win,
  {$ENDIF}
    FMX.Platform,
  FMX.Graphics;

type
  // Matches Windows 11 backdrop materials.
  // - weMica   : DWMSBT_MAINWINDOW (Mica)
  // - weAcrylic: DWMSBT_TRANSIENTWINDOW (Desktop Acrylic)
  // - weTabbed : DWMSBT_TABBEDWINDOW (Mica Alt)
  TWindowEffect = (weNone, weMica, weAcrylic, weTabbed, weAuto, weAcrylicBlurBehind);

  TWindowEffects = class
  public
    // Call after the HWND exists (FormCreate works for FMX on Windows, but FormShow is safest).
    class procedure ApplyEffect(const Form: TCommonCustomForm; Effect: TWindowEffect; DarkMode: Boolean = True);

    // Low-level helpers
    class function WindowsBuildNumber: Integer;
    class function IsHighContrastEnabled: Boolean;
    class function TrySetImmersiveDarkMode(hWnd: HWND; Enabled: Boolean): Boolean;
    class function TrySetSystemBackdropType(hWnd: HWND; BackdropValue: Integer): Boolean;
    class function TrySetRoundedCorners(hWnd: HWND; CornerPreference: Integer): Boolean;
    class function TrySetCaptionColorNone(hWnd: HWND): Boolean;
    class function TryExtendFrameIntoClientArea(hWnd: HWND): Boolean;
    class function IsAppsDarkMode: Boolean; static;

    // Legacy fallback (Windows 10 / when system backdrop isn't supported)
    class function TrySetAccentPolicy(hWnd: HWND; AccentState: Integer; Color: TAlphaColor): Boolean;
  end;

implementation

type
  // Undocumented/legacy COMPOSITION API for Windows 10 acrylic/blur behind.
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

const
  // Documented in Windows SDK headers (Windows 11 22621+ for SYSTEMBACKDROP_TYPE).
  DWMWA_SYSTEMBACKDROP_TYPE         = 38; // DWM_SYSTEMBACKDROP_TYPE
  DWMWA_WINDOW_CORNER_PREFERENCE    = 33;
  DWMWA_CAPTION_COLOR               = 35;
  DWMWA_MICA_EFFECT                 = 1029; // Older Win11 builds

  // Dark title bar attribute value is not consistently documented across Windows versions;
  // try both 20 and 19 for broad compatibility.
  DWMWA_USE_IMMERSIVE_DARK_MODE_20  = 20;
  DWMWA_USE_IMMERSIVE_DARK_MODE_19  = 19;

  // DWM_SYSTEMBACKDROP_TYPE values
  DWMSBT_AUTO            = 0;
  DWMSBT_NONE            = 1;
  DWMSBT_MAINWINDOW      = 2; // Mica
  DWMSBT_TRANSIENTWINDOW = 3; // Desktop Acrylic
  DWMSBT_TABBEDWINDOW    = 4; // Mica Alt (tabbed)

  // DWM_WINDOW_CORNER_PREFERENCE values
  DWMWCP_DEFAULT       = 0;
  DWMWCP_DONOTROUND    = 1;
  DWMWCP_ROUND         = 2;
  DWMWCP_ROUNDSMALL    = 3;

  // Caption color special values
  DWMWA_COLOR_NONE     = $FFFFFFFE; // Suppress caption (useful to avoid tinted titlebar when using backdrop)

  // Composition attribute for SetWindowCompositionAttribute
  WCA_ACCENT_POLICY = 19;

  // Accent Policy values
  ACCENT_DISABLED               = 0;
  ACCENT_ENABLE_BLURBEHIND      = 3;
  ACCENT_ENABLE_ACRYLICBLURBEHIND = 4;

  // A good default: draw all borders (helps avoid odd artifacts for some styles)
  ACCENT_BORDER_FLAGS = $20 or $40 or $80 or $100;

var
  SetWindowCompositionAttribute: TSetWindowCompositionAttribute = nil;

function FormToHWND(const Form: TCommonCustomForm): HWND;
begin
  Result := FMX.Platform.Win.FormToHWND(Form);
end;

procedure InitUser32;
var
  HUser32: HMODULE;
begin
  if Assigned(SetWindowCompositionAttribute) then
    Exit;
  HUser32 := GetModuleHandle('user32.dll');
  if HUser32 <> 0 then
    @SetWindowCompositionAttribute := GetProcAddress(HUser32, 'SetWindowCompositionAttribute');
end;

function AlphaColorToABGR(const C: TAlphaColor): DWORD;
var
  A, R, G, B: Byte;
begin
  A := TAlphaColorRec(C).A;
  R := TAlphaColorRec(C).R;
  G := TAlphaColorRec(C).G;
  B := TAlphaColorRec(C).B;
  // AccentPolicy expects ABGR on most modern builds.
  Result := (DWORD(A) shl 24) or (DWORD(B) shl 16) or (DWORD(G) shl 8) or DWORD(R);
end;

class function TWindowEffects.WindowsBuildNumber: Integer;
type
  TRtlGetVersion = function(var Info: OSVERSIONINFOEXW): LongInt; stdcall;
var
  Info: OSVERSIONINFOEXW;
  RtlGetVersion: TRtlGetVersion;
  hNtdll: HMODULE;
begin
  // Prefer RtlGetVersion (accurate even when app isn't manifested).
  Result := 0;
  FillChar(Info, SizeOf(Info), 0);
  Info.dwOSVersionInfoSize := SizeOf(Info);

  hNtdll := GetModuleHandle('ntdll.dll');
  if hNtdll <> 0 then
  begin
    @RtlGetVersion := GetProcAddress(hNtdll, 'RtlGetVersion');
    if Assigned(RtlGetVersion) and (RtlGetVersion(Info) = 0) then
      Exit(Info.dwBuildNumber);
  end;

  // Fallback
  Result := TOSVersion.Build;
end;

class function TWindowEffects.IsHighContrastEnabled: Boolean;
var
  HC: HIGHCONTRAST;
begin
  FillChar(HC, SizeOf(HC), 0);
  HC.cbSize := SizeOf(HC);
  if SystemParametersInfo(SPI_GETHIGHCONTRAST, SizeOf(HC), @HC, 0) then
    Result := (HC.dwFlags and HCF_HIGHCONTRASTON) <> 0
  else
    Result := False;
end;

class function TWindowEffects.TrySetImmersiveDarkMode(hWnd: HWND; Enabled: Boolean): Boolean;
var
  V: Integer;
begin
  V := Ord(Enabled);
  // Try the most common attribute id first.
  Result := Succeeded(DwmSetWindowAttribute(hWnd, DWMWA_USE_IMMERSIVE_DARK_MODE_20, @V, SizeOf(V)));
  if not Result then
    Result := Succeeded(DwmSetWindowAttribute(hWnd, DWMWA_USE_IMMERSIVE_DARK_MODE_19, @V, SizeOf(V)));
end;

class function TWindowEffects.TrySetSystemBackdropType(hWnd: HWND; BackdropValue: Integer): Boolean;
begin
  Result := Succeeded(DwmSetWindowAttribute(hWnd, DWMWA_SYSTEMBACKDROP_TYPE, @BackdropValue, SizeOf(BackdropValue)));
end;

class function TWindowEffects.TrySetRoundedCorners(hWnd: HWND; CornerPreference: Integer): Boolean;
begin
  Result := Succeeded(DwmSetWindowAttribute(hWnd, DWMWA_WINDOW_CORNER_PREFERENCE, @CornerPreference, SizeOf(CornerPreference)));
end;

class function TWindowEffects.TrySetCaptionColorNone(hWnd: HWND): Boolean;
var
  C: DWORD;
begin
  C := DWMWA_COLOR_NONE;
  Result := Succeeded(DwmSetWindowAttribute(hWnd, DWMWA_CAPTION_COLOR, @C, SizeOf(C)));
end;

class function TWindowEffects.TryExtendFrameIntoClientArea(hWnd: HWND): Boolean;
var
  M: TMargins;
begin
  // Extend the DWM surface across the full client area so the backdrop shows behind FMX controls.
  M.cxLeftWidth := -1;
  M.cxRightWidth := -1;
  M.cyTopHeight := -1;
  M.cyBottomHeight := -1;
  Result := Succeeded(DwmExtendFrameIntoClientArea(hWnd, M));
end;

class function TWindowEffects.TrySetAccentPolicy(hWnd: HWND; AccentState: Integer; Color: TAlphaColor): Boolean;
var
  Policy: TAccentPolicy;
  Data: TWindowCompositionAttribData;
begin
  InitUser32;
  if not Assigned(SetWindowCompositionAttribute) then
    Exit(False);

  FillChar(Policy, SizeOf(Policy), 0);
  Policy.AccentState := AccentState;
  Policy.AccentFlags := ACCENT_BORDER_FLAGS;
  Policy.GradientColor := AlphaColorToABGR(Color);

  Data.Attribute := WCA_ACCENT_POLICY;
  Data.Data := @Policy;
  Data.DataSize := SizeOf(Policy);

  Result := SetWindowCompositionAttribute(hWnd, Data);
end;

class function TWindowEffects.IsAppsDarkMode: Boolean;
var
  R: TRegistry;
begin
  // Default to Dark (safer readability on Acrylic)
  Result := True;

  R := TRegistry.Create(KEY_READ);
  try
    R.RootKey := HKEY_CURRENT_USER;
    if R.OpenKeyReadOnly('\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize') then
      if R.ValueExists('AppsUseLightTheme') then
        Result := (R.ReadInteger('AppsUseLightTheme') = 0);
  finally
    R.Free;
  end;
end;

class procedure TWindowEffects.ApplyEffect(const Form: TCommonCustomForm; Effect: TWindowEffect; DarkMode: Boolean);
var
  hWnd_: HWND;
  Build: Integer;
  Backdrop: Integer;
begin
  if (Form = nil) then
    Exit;

  hWnd_ := FormToHWND(Form);
  if hWnd_ = 0 then
    Exit;

  // In High Contrast, Windows generally disables fancy materials; respect that.
  if IsHighContrastEnabled then
    Effect := weNone;

  Build := WindowsBuildNumber;

  // Make sure FMX doesn't paint an opaque background over the DWM material.
  // (You already do this in MainBuilds.FormCreate)
  try
    if Form is TForm then
    begin
      // Keep a surface but make it fully transparent so DWM shows through.
      TForm(Form).Fill.Color := TAlphaColors.Null;
      TForm(Form).Fill.Kind := TBrushKind.Solid;
    end;
  except
  end;

  // Dark title bar (supported starting Windows 11 22000 per docs)
  if Build >= 22000 then
    TrySetImmersiveDarkMode(hWnd_, DarkMode);

  // Rounded corners look better with Mica/Acrylic
  if Build >= 22000 then
    TrySetRoundedCorners(hWnd_, DWMWCP_ROUND);

  // Make sure the DWM surface is drawn across the full client area.
  if Effect <> weNone then
    TryExtendFrameIntoClientArea(hWnd_);

  // Prefer the supported API on Windows 11 22H2+ (Build 22621)
  if Build >= 22621 then
  begin
    case Effect of
      weNone:    Backdrop := DWMSBT_NONE;
      weMica:    Backdrop := DWMSBT_MAINWINDOW;
      weAcrylic: Backdrop := DWMSBT_TRANSIENTWINDOW;
      weTabbed:  Backdrop := DWMSBT_TABBEDWINDOW;
      weAuto:    Backdrop := DWMSBT_AUTO;
    else
      Backdrop := DWMSBT_AUTO;
    end;

    if not TrySetSystemBackdropType(hWnd_, Backdrop) then
      Backdrop := DWMSBT_AUTO;

    // Optional: suppress caption tinting issues some apps see with backdrops
    // (safe no-op if unsupported)
    TrySetCaptionColorNone(hWnd_);

    Exit;
  end;

  // Older Win11 (22000) Mica flag: harmless no-op on newer builds.
  if (Build >= 22000) and (Effect in [weMica, weTabbed, weAuto]) then
  begin
    var Enabled: BOOL := True;
    DwmSetWindowAttribute(hWnd_, DWMWA_MICA_EFFECT, @Enabled, SizeOf(Enabled));
  end;

  // Windows 10/11 fallback: legacy acrylic/blur-behind via SetWindowCompositionAttribute.
  if Effect in [weAcrylic, weAcrylicBlurBehind] then
  begin
    // Pick a subtle translucent tint; tweak alpha to your taste.
    // Example: 0x80 (~50%) opacity keeps more of the DWM blur visible.
    if Effect = weAcrylicBlurBehind then
      TrySetAccentPolicy(hWnd_, ACCENT_ENABLE_BLURBEHIND, $401F1F1F)
    else
      TrySetAccentPolicy(hWnd_, ACCENT_ENABLE_ACRYLICBLURBEHIND, $801F1F1F);
    end
  else
  begin
    // No supported system backdrop, disable legacy accent.
    TrySetAccentPolicy(hWnd_, ACCENT_DISABLED, 0);
  end;
end;

end.
