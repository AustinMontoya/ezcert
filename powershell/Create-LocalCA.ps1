Add-Type -Path 'ezcert.util.dll'

function Create-LocalCA {
    Param(
        [string]$Name = "localCA",
        [string]$Password = "password",
        [string]$OutputFileName = "localCA.pfx",
        [bool]$AutoImport = $true
    );

    if ($Name -eq "localCA" -and $Password -eq "password") {
        if (gci -Path Cert:\LocalMachine\Root | Where-Object {$_.Subject -eq "CN=localCA"}) {
            Write-Host "Default Local CA already exists, skipping"
            return;
        }
    }

    $currentDirectoryPath = (Get-Item -Path ".\" -Verbose).FullName
    $outputPath = [System.IO.Path]::Combine($currentDirectoryPath, $OutputFileName) 
    $cert = [ezcert.util.CertUtils]::CreateCertificateAuthorityCertificate($Name, $Password)
    [ezcert.util.CertUtils]::WriteCertificate($cert, $Password, $outputPath)

    Write-Host "CA created at $outputPath"

    if (!$AutoImport) {
        return;
    }

    
    $cmd = 
@"
`$securePassword = ConvertTo-SecureString -String $Password -AsPlainText -Force
Write-Host "Importing CA into Local Machine Trusted Root store..."
Import-PfxCertificate -FilePath '$outputPath' -Password `$securePassword -CertStoreLocation "Cert:\LocalMachine\Root" 
"@

    Start-Process -FilePath powershell.exe -Verb RunAs -ArgumentList ([Scriptblock]::Create($cmd))
        
       
}

function Create-LocalClientCertificate {
    Param(
        [string]$Name = "clientCertificate",
        [string]$Password = "password",
        [string]$OutputFileName = "clientCertificate.pfx",
        [string]$CaPath,
        [string]$CaPassword,
        [bool]$UseDefaultCa = $true,
        [bool]$AutoImport = $true,
        [bool]$UnlockConfigSections = $false,
        [switch]$MergeConfig = $false
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
            Write-Host "Default CA not detected"
            Create-LocalCA
        }   
    } 

    $caCert = [ezcert.util.CertUtils]::LoadCertificate((Get-Item -Path $CaPath -Verbose).FullName, $CaPassword)

    Write-Host "Creating client certificate"
    $clientCert = [ezcert.util.CertUtils]::IssueCertificate($Name, $caCert)

    $currentDirectoryPath = (Get-Item -Path ".\" -Verbose).FullName
    $outputPath = [System.IO.Path]::Combine($currentDirectoryPath, $OutputFileName) 
    [ezcert.util.CertUtils]::WriteCertificate($clientCert, $Password, $outputPath)

    if (!$AutoImport) {
        return
    }
    
    Write-Host "Importing client certificate into Current User Root store..."
    $securePassword = ConvertTo-SecureString -String $Password -AsPlainText -Force
    Import-PfxCertificate -FilePath $outputPath -Password $securePassword -CertStoreLocation "Cert:\CurrentUser\My" 
}
