. ".\utils.ps1"
$here = Split-Path -Parent $MyInvocation.MyCommand.Path
. "$here\Unlock-AppHostSecuritySection.ps1"
$ezcertExecutablePath = "$here\..\..\ezcert\bin\Release\ezcert.exe"

Describe "Unlock-AppHostSecuritySection" {
  It "Modifies the file at the provided path" {
    $tempSourcePath = "TestData\applicationhost_unmodified.xml"
    $tempDestPath = "$env:TEMP\applicationhost_unmodified.xml"
    cp -force $tempSourcePath $tempDestPath
    
    Unlock-AppHostSecuritySection -Path $tempDestPath
    
    [xml]$doc = Get-Content $tempDestPath
    $el = $doc.getElementsByTagName("section") | Where-Object { $_.name -eq "access" }
    $el.overrideModeDefault | Should Be "Allow"
  }

  # How do we test finding the config in the global location?
}