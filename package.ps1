$msBuildPath = $MSBUILD_PATH
if (!$msBuildPath) {
  $msBuildPath = 'C:\Program Files (x86)\MSBuild\14.0\Bin'
}

$args = '/p:Configuration=Release'
iex "& '$msBuildPath\msbuild.exe' $args"

$outputFolder = '.\artifacts'

if (Test-Path $outputFolder) {
  rm -r -force $outputFolder
}

mkdir $outputFolder
gci "$PWD\ezcert\bin\Release" -exclude "*.vshost.*" | cp -dest $outputFolder

$psSource = (Get-Item .\powershell).FullName
gci $psSource -r | where { 
  $_.fullName -notmatch "Tests.ps1" -and ($_.fullName -notmatch "TestData")  
} | cp -d {Join-Path $outputFolder $_.FullName.Substring($psSource.length)}

$workDir = (Get-Item -Path $PWD).FullName
$packageDest = "$workDir\package.zip"

if (Test-Path $packageDest) {
  rm -r -force $packageDest
}

Add-Type -A 'System.IO.Compression.FileSystem'
[IO.Compression.ZipFile]::CreateFromDirectory("$workDir\artifacts", $packageDest)
