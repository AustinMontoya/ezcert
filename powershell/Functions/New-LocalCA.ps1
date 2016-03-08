function New-LocalCA {
    Param(
        [string]$Name = "localCA",
        [string]$Password = "password",
        [string]$OutputPath = $null,
        [bool]$AutoImport = $true
    );

    if ($Name -eq "localCA" -and $Password -eq "password") {
        if (gci -Path Cert:\LocalMachine\Root | Where-Object {$_.Subject -eq "CN=localCA"}) {
            Write-Host "Default Local CA already exists, skipping"
            return;
        }
    }

    if (!$OutputPath) {
        $OutputPath = [System.IO.Path]::Combine($PWD, "$Name.pfx") 
    }

    & $ezcertExecutablePath CreateCaCert -name="$Name" -password="$Password" -outputPath="$OutputPath"

    Write-Host "CA created at $OutputPath"

    if (!$AutoImport) {
        return;
    }
    
    $cmd = 
@"
`$securePassword = ConvertTo-SecureString -String $Password -AsPlainText -Force
Write-Host "Importing CA into Local Machine Trusted Root store..."
Import-PfxCertificate -FilePath '$OutputPath' -Password `$securePassword -CertStoreLocation "Cert:\LocalMachine\Root" -Exportable
"@

    Start-Process -FilePath powershell.exe -Verb RunAs -ArgumentList ([Scriptblock]::Create($cmd))
}

