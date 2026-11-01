[CmdletBinding()]
param(
    [string]$Configuration = 'Release'
)

$ErrorActionPreference = 'Stop'
if ($Configuration -notin @('Release', 'Debug')) {
    throw 'Configuration must be Release or Debug.'
}

$assembler = Join-Path $env:WINDIR 'Microsoft.NET\Framework64\v4.0.30319\ilasm.exe'
if (-not (Test-Path -LiteralPath $assembler -PathType Leaf)) {
    throw "The .NET Framework 4.x x64 IL assembler was not found at $assembler. Enable/install .NET Framework 4.8 on 64-bit Windows."
}

$outputDirectory = Join-Path $PSScriptRoot 'bin'
$output = Join-Path $outputDirectory 'FolderMap.exe'
New-Item -ItemType Directory -Path $outputDirectory -Force | Out-Null
$arguments = @(
    (Join-Path $PSScriptRoot 'FolderMap.il'),
    '/nologo', '/quiet', '/exe', '/x64', '/pe64', '/highentropyva',
    '/subsystem=2', "/include=$PSScriptRoot", "/output=$output"
)
if ($Configuration -eq 'Debug') {
    $arguments += '/debug'
} else {
    $arguments += '/optimize'
}

& $assembler @arguments
if ($LASTEXITCODE -ne 0) {
    throw "ILAsm failed with exit code $LASTEXITCODE."
}
Copy-Item -LiteralPath (Join-Path $PSScriptRoot 'FolderMap.exe.config') -Destination "$output.config" -Force

$stream = [System.IO.File]::OpenRead($output)
$reader = New-Object System.IO.BinaryReader($stream)
try {
    $stream.Position = 0x3c
    $peOffset = $reader.ReadInt32()
    $stream.Position = $peOffset
    if ($reader.ReadUInt32() -ne 0x00004550 -or $reader.ReadUInt16() -ne 0x8664) {
        throw 'The output is not an AMD64 PE executable.'
    }
    $stream.Position = $peOffset + 24
    if ($reader.ReadUInt16() -ne 0x020b) {
        throw 'The output is not a PE32+ (64-bit) image.'
    }
    $stream.Position = $peOffset + 24 + 68
    if ($reader.ReadUInt16() -ne 2) {
        throw 'The output is not a Windows GUI executable.'
    }
} finally {
    $reader.Dispose()
}

Write-Host "Built x64 Windows GUI: $output"
