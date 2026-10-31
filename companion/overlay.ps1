param([switch]$SmokeTest)
$ErrorActionPreference = 'Stop'
trap { [Console]::Error.WriteLine($_.ToString()); [Console]::Error.WriteLine($_.ScriptStackTrace); exit 1 }
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
[Windows.Forms.Application]::EnableVisualStyles()
Add-Type -ReferencedAssemblies System.Windows.Forms,System.Drawing -TypeDefinition @'
using System;
using System.Runtime.InteropServices;
using System.Windows.Forms;
public class ClapbackWindow : Form {
  [DllImport("user32.dll")] public static extern bool RegisterHotKey(IntPtr h, int id, uint mods, uint key);
  [DllImport("user32.dll")] public static extern bool UnregisterHotKey(IntPtr h, int id);
  protected override void WndProc(ref Message m) {
    if(m.Msg==0x0312) { if(Visible) Hide(); else { Show(); Activate(); } }
    base.WndProc(ref m);
  }
}
'@
$script:base = 'http://127.0.0.1:' + $env:CLAPBACK_PORT
$script:headers = @{'X-Clapback-Token'=$env:CLAPBACK_TOKEN}
function Api($route, $data=$null) {
  if ($null -eq $data) { return Invoke-RestMethod -Uri ($script:base+$route) -Headers $script:headers -TimeoutSec 3 }
  $json = ConvertTo-Json -InputObject $data -Depth 10 -Compress
  return Invoke-RestMethod -Uri ($script:base+$route) -Headers $script:headers -Method Post -Body ([Text.Encoding]::UTF8.GetBytes($json)) -ContentType 'application/json; charset=utf-8' -TimeoutSec 10
}
function Safe($action) { try { & $action } catch { $message=$_.Exception.Message; if($_.ErrorDetails.Message){try{$message=($_.ErrorDetails.Message|ConvertFrom-Json).error}catch{}};[Windows.Forms.MessageBox]::Show($message,'Clapback')|Out-Null } }
$purple=[Drawing.Color]::FromArgb(151,92,230)
$bg=[Drawing.Color]::FromArgb(20,16,29)
function Label($parent,$text,$x,$y,$w,$h=23) { $c=New-Object Windows.Forms.Label;$c.Text=$text;$c.SetBounds($x,$y,$w,$h);$c.ForeColor=[Drawing.Color]::Gainsboro;$parent.Controls.Add($c);return $c }
function Button($parent,$text,$x,$y,$w,$action) { $c=New-Object Windows.Forms.Button;$c.Text=$text;$c.SetBounds($x,$y,$w,30);$c.FlatStyle='Flat';$c.BackColor=[Drawing.Color]::FromArgb(65,38,92);$c.ForeColor=[Drawing.Color]::White;$c.Add_Click($action);$parent.Controls.Add($c);return $c }
function Textbox($parent,$x,$y,$w,$h=25,$multi=$false) {$c=New-Object Windows.Forms.TextBox;$c.SetBounds($x,$y,$w,$h);$c.Multiline=$multi;$c.BackColor=[Drawing.Color]::FromArgb(34,27,45);$c.ForeColor=[Drawing.Color]::White;if($multi){$c.ScrollBars='Vertical'};$parent.Controls.Add($c);return $c}
$form=New-Object ClapbackWindow
$form.Text='VoidMark Clapback';$form.ClientSize=New-Object Drawing.Size(570,710);$form.BackColor=$bg;$form.ForeColor=[Drawing.Color]::White;$form.Font=New-Object Drawing.Font('Segoe UI',10);$form.FormBorderStyle='FixedSingle';$form.MaximizeBox=$false
$title=Label $form 'VOIDMARK / CLAPBACK' 14 12 390 26;$title.ForeColor=$purple;$title.Font=New-Object Drawing.Font('Segoe UI',14,[Drawing.FontStyle]::Bold)
$null=Button $form 'Settings' 454 10 100 {Safe {Show-Settings}}
$players=New-Object Windows.Forms.ComboBox;$players.SetBounds(14,48,540,28);$players.DropDownStyle='DropDownList';$form.Controls.Add($players)
$latest=Label $form 'Waiting for a whisper or copied addon context.' 14 84 540 42
$history=Textbox $form 14 130 540 142 $true;$history.ReadOnly=$true
$tabs=New-Object Windows.Forms.TabControl;$tabs.SetBounds(14,282,540,138);$form.Controls.Add($tabs)
$quick=New-Object Windows.Forms.TabPage;$quick.Text='Quick Replies';$quick.BackColor=$bg;$tabs.TabPages.Add($quick)
$custom=New-Object Windows.Forms.TabPage;$custom.Text='Custom AI';$custom.BackColor=$bg;$tabs.TabPages.Add($custom)
$null=Label $quick 'Choose a style, then Generate. All replies use recent context.' 10 12 505
$styles=New-Object Windows.Forms.ComboBox;$styles.SetBounds(10,45,290,28);$styles.DropDownStyle='DropDownList';$styles.Items.AddRange(@('Sarcastic','Fake Apology','Dry Humor','Friendly Trolling','Passive Aggressive','Completely Ridiculous'));$quick.Controls.Add($styles)
$null=Label $custom 'Describe your reply. Later instructions refine this conversation.' 10 4 510
$instructions=Textbox $custom 10 30 510 72 $true
$replies=New-Object Windows.Forms.ListBox;$replies.SetBounds(14,430,540,112);$replies.BackColor=[Drawing.Color]::FromArgb(34,27,45);$replies.ForeColor=[Drawing.Color]::White;$replies.HorizontalScrollbar=$true;$form.Controls.Add($replies)
$draft=Textbox $form 14 550 540 52 $true
$null=Button $form 'Generate / Regenerate' 14 610 180 {Safe {
  if(!$script:state.selected){throw 'Select a player or paste addon context first.'}
  if($styles.SelectedItem -ne $script:state.settings.style){$script:state.settings.style=[string]$styles.SelectedItem;$null=Api '/settings' $script:state.settings}
  $text='';if($tabs.SelectedTab -eq $custom){$text=$instructions.Text}
  $null=Api '/generate' @{key=$script:state.selected;instructions=$text}
}}
$null=Button $form 'Copy Reply' 202 610 112 {Safe {if($draft.Text){[Windows.Forms.Clipboard]::SetText($draft.Text);$status.Text='Copied. Open the whisper in WoW, paste, review recipient, then Enter.'}}}
$null=Button $form 'Paste Context' 322 610 132 {Safe {$null=Api '/import' @{text=[Windows.Forms.Clipboard]::GetText()};Refresh-State}}
$null=Button $form 'Hide' 462 610 92 {$form.Hide()}
$status=Label $form 'Connecting...' 14 649 540 50
$script:state=$null;$script:updating=$false;$script:replySignature='';$script:keys=@();$script:registered=$false
$players.Add_SelectedIndexChanged({if(!$script:updating -and $players.SelectedIndex -ge 0){Safe {$null=Api '/select' @{key=$script:keys[$players.SelectedIndex]};$instructions.Text='';Refresh-State}}})
$replies.Add_SelectedIndexChanged({if($replies.SelectedIndex -ge 0){$draft.Text=[string]$replies.SelectedItem}})
function Refresh-State {
  $s=Api '/state';$script:state=$s;$script:updating=$true
  try {
    $keys=@($s.conversations|ForEach-Object {$_.key})
    if(($keys -join '|') -ne ($script:keys -join '|')){$players.Items.Clear();foreach($c in $s.conversations){$null=$players.Items.Add($c.player)};$script:keys=$keys}
    $players.SelectedIndex=[Array]::IndexOf($script:keys,$s.selected)
    $c=@($s.conversations|Where-Object {$_.key -eq $s.selected})|Select-Object -First 1
    $text=(@($c.messages|ForEach-Object { $who=if($_.direction -eq 'in'){$c.player}else{'Me'}; $who+': '+$_.text }) -join "`r`n")
    if($history.Text -ne $text){$history.Text=$text;$history.SelectionStart=$history.Text.Length;$history.ScrollToCaret()}
    $incoming=@($c.messages|Where-Object {$_.direction -eq 'in'})|Select-Object -Last 1
    $latest.Text=if($incoming){'Latest: '+$incoming.text}else{'Waiting for a whisper or copied addon context.'}
    $signature=$s.selected+'|'+$c.version+'|'+(@($c.replies) -join '|')
    if($signature -ne $script:replySignature){$script:replySignature=$signature;$replies.Items.Clear();foreach($r in $c.replies){$null=$replies.Items.Add($r)};$draft.Clear()}
    if($styles.SelectedIndex -lt 0){$styles.SelectedItem=$s.settings.style}
    $status.Text=$s.status+"`r`n"+$s.logStatus
    $form.TopMost=$s.settings.topmost
    if($s.settings.hotkey -and !$script:registered){$script:registered=[ClapbackWindow]::RegisterHotKey($form.Handle,1,0x4003,0x43);if(!$script:registered){$status.Text+=' | Ctrl+Alt+C unavailable'}}
    if(!$s.settings.hotkey -and $script:registered){[ClapbackWindow]::UnregisterHotKey($form.Handle,1)|Out-Null;$script:registered=$false}
  } finally {$script:updating=$false}
}
function Show-Settings {
  $d=New-Object Windows.Forms.Form;$d.Text='Clapback Settings';$d.ClientSize=New-Object Drawing.Size(570,610);$d.BackColor=$bg;$d.ForeColor=[Drawing.Color]::White;$d.Font=$form.Font;$d.StartPosition='CenterParent';$d.FormBorderStyle='FixedDialog';$d.MaximizeBox=$false
  $fields=@{};$y=12
  foreach($pair in @(@('character','Local character (Name-Realm)'),@('logPath','WoW chat log'),@('model','OpenAI model'),@('count','Reply count (3-5)'),@('maxLength','Reply byte limit (40-240)'),@('historyLength','Context messages (2-40)'),@('cooldown','API cooldown seconds (5-300)'),@('retentionMinutes','Memory retention minutes (1-1440)'))){
    $null=Label $d $pair[1] 12 $y 250;$box=Textbox $d 265 $y 290;$box.Text=[string]$script:state.settings.($pair[0]);$fields[$pair[0]]=$box;$y+=33
  }
  $checks=@{}
  foreach($pair in @(@('auto','Automatically send new whisper context to OpenAI'),@('topmost','Keep overlay on top (windowed / borderless WoW)'),@('hotkey','Ctrl+Alt+C toggles overlay visibility'))){$c=New-Object Windows.Forms.CheckBox;$c.Text=$pair[1];$c.SetBounds(12,$y,540,25);$c.Checked=$script:state.settings.($pair[0]);$d.Controls.Add($c);$checks[$pair[0]]=$c;$y+=29}
  $null=Label $d 'API key (Windows user encryption; never stored in addon)' 12 $y 540;$y+=25
  $key=Textbox $d 12 $y 540;$key.UseSystemPasswordChar=$true;$y+=35
  $null=Label $d 'History stays in memory. WoW retains its own log separately. Change the' 12 $y 540;$y+=22
  $null=Label $d 'local character when switching alts. Log parser currently supports English.' 12 $y 540;$y+=32
  $save=Button $d 'Save' 12 $y 110 {Safe {
    $s=$script:state.settings
    foreach($k in $fields.Keys){$s.$k=$fields[$k].Text}
    foreach($k in $checks.Keys){$s.$k=$checks[$k].Checked}
    $null=Api '/settings' $s
    if($key.Text){$null=Api '/key' @{key=$key.Text};$key.Clear()}
    $d.Close();Refresh-State
  }}
  $null=Button $d 'Delete API key' 132 $y 140 {Safe {$null=Api '/key' @{key=''};$key.Clear()}}
  $null=Button $d 'Clear history' 282 $y 125 {Safe {$null=Api '/clear' @{};Refresh-State}}
  $null=Button $d 'Cancel' 417 $y 135 {$d.Close()}
  $null=$d.ShowDialog($form);$d.Dispose()
}
$tray=New-Object Windows.Forms.NotifyIcon;$tray.Icon=[Drawing.SystemIcons]::Application;$tray.Text='VoidMark Clapback - double-click to open';$tray.Visible=$true;$tray.Add_DoubleClick({$form.Show();$form.Activate()})
$timer=New-Object Windows.Forms.Timer;$timer.Interval=800;$timer.Add_Tick({try{Refresh-State}catch{$status.Text='Companion connection interrupted.'}})
$form.Add_Shown({Safe {Refresh-State;$form.StartPosition='Manual';$p=New-Object Drawing.Point([int]$script:state.settings.x,[int]$script:state.settings.y);if([Windows.Forms.Screen]::AllScreens.WorkingArea|Where-Object {$_.Contains($p)}){$form.Location=$p};$timer.Start()}})
$form.Add_FormClosing({$timer.Stop();$tray.Visible=$false;$tray.Dispose();if($script:registered){[ClapbackWindow]::UnregisterHotKey($form.Handle,1)|Out-Null};try{$s=$script:state.settings;$s.x=$form.Location.X;$s.y=$form.Location.Y;$null=Api '/settings' $s}catch{}})
if ($SmokeTest) {
  Refresh-State
  if (!$script:state.settings.model -or $form.Controls.Count -lt 10) { throw 'Overlay initialization failed.' }
  $tray.Visible=$false;$tray.Dispose()
  if($script:registered){[ClapbackWindow]::UnregisterHotKey($form.Handle,1)|Out-Null}
  $form.Dispose();[Console]::WriteLine('Overlay controls and backend connection passed');exit 0
}
[Windows.Forms.Application]::Run($form)
$form.Dispose()
