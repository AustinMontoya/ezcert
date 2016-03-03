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

