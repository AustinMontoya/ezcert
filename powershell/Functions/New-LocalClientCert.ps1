function New-LocalClientCert {
    Param(
        [string]$Name = "clientCertificate",
        [string]$Password = "password",
        [string]$OutputFileName = "clientCertificate.pfx",
        [string]$CaPath,
        [string]$CaPassword,
        [bool]$UseDefaultCa = $true,
        [bool]$AutoImport = $true
    )
    $clientCert = $null

    if (!$UseDefaultCa -and ([string]::IsNullOrEmpty($CaPath) -or [string]::IsNullOrEmpty($CaPath))) {
        throw "-CaPath and -CaPassword must be specified if not using the default CA"
    }

    if ($UseDefaultCa) {
        $defaultCaExists = gci -Path Cert:\LocalMachine\Root | Where-Object {$_.Subject -eq "CN=localCA"} 
        $CaPath = "localCa.pfx"
        $CaPassword = "password"

        if (!$defaultCaExists) {
            Write-Info "Default CA not detected"
            New-LocalCA
        }
    } 

    $fullCaPath = (Get-Item -Path $CaPath -Verbose).FullName
    $outputPath = [System.IO.Path]::Combine($currentDirectoryPath, $OutputFileName) 

    Write-Log "Creating client certificate"
    & $ezcertExecutablePath CreateClientCert -name="$Name" -password="$Password" -caPath="$fullCaPath" -caPassword="$CaPassword" -outputPath="$outputPath"
    Write-Success "Client certificate created at $outputPath"
    if (!$AutoImport) {
        return
    }
    
    Write-Log "Importing client certificate into Current User Personal store..."
    $securePassword = ConvertTo-SecureString -String $Password -AsPlainText -Force
    Import-PfxCertificate -FilePath $outputPath -Password $securePassword -CertStoreLocation "Cert:\CurrentUser\My" 
    Write-Success "Certificate imported."
}
