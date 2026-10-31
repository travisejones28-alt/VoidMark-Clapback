param([ValidateSet('Protect','Unprotect')][string]$Mode)
$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Security
$value = [Console]::In.ReadToEnd().Trim()
if ($Mode -eq 'Protect') {
  $bytes = [Text.Encoding]::UTF8.GetBytes($value)
  [Console]::Write([Convert]::ToBase64String([Security.Cryptography.ProtectedData]::Protect($bytes, $null, [Security.Cryptography.DataProtectionScope]::CurrentUser)))
} else {
  $bytes = [Convert]::FromBase64String($value)
  [Console]::Write([Text.Encoding]::UTF8.GetString([Security.Cryptography.ProtectedData]::Unprotect($bytes, $null, [Security.Cryptography.DataProtectionScope]::CurrentUser)))
}
