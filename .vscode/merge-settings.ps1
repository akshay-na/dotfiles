$localSettingsPath = "$env:APPDATA\Code\User\settings.json"
$workspaceSettingsPath = ".vscode\settings.json"

if (Test-Path $workspaceSettingsPath) {
    $workspaceSettings = Get-Content -Raw $workspaceSettingsPath | ConvertFrom-Json
    if (Test-Path $localSettingsPath) {
        $localSettings = Get-Content -Raw $localSettingsPath | ConvertFrom-Json
        $mergedSettings = $localSettings.PSObject.Properties.Name | ForEach-Object {
            if ($workspaceSettings.PSObject.Properties.Name -contains $_) {
                $workspaceSettings.$_
            } else {
                $localSettings.$_
            }
        } | ConvertTo-Json -Depth 10
    } else {
        $mergedSettings = $workspaceSettings | ConvertTo-Json -Depth 10
    }
    Set-Content -Path $localSettingsPath -Value $mergedSettings
}
