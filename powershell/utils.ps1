function Get-ConfigPath($path, $targetPath) {
    if ($path.ToString() -eq [IO.Path]::GetPathRoot($path)) {
        return $null
    }

    $localConfigPath = [IO.Path]::Combine($path, $targetPath)
    if (Test-Path $localConfigPath) {
        return $localConfigPath
    }

    return Get-ConfigPath -path (Get-Item $path).Parent.FullName -targetPath $targetPath
}

function Read-Input ($defaultValue) {
    $result = (Read-Host).ToLowerInvariant()
    if ([string]::IsNullOrEmpty($result)) {
        $result = $defaultValue
    }

    return $result
}