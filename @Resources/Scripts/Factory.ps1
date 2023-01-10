# Get skin root path and set script location to it
$rootConfig = "$($RmAPI.VariableStr('ROOTCONFIGPATH'))"
Set-Location $rootConfig

# Other locations
$resourcesDir = "$($RmAPI.VariableStr('@'))"
$templatesDir = "$($resourcesDir)Templates"
$storageDir = "$($resourcesDir)Storage"
$tempDir = "$($resourcesDir)temp"
$barDir = ".\Bars"

# Known files
$mainFile = "$($resourcesDir)Main.inc"
$barMeasuresFile = "$($resourcesDir)Bands.inc"

# Known values
$bands = $RmAPI.Variable("Bands")
$SkipBands = $RmAPI.Variable("SkipBands")

function Update {
    $RmApi.Log("Updated Factory.ps1!")
    if ($RmApi.Variable("LoadBars", 0) -eq 1) { Load-Bars }
    return 1
}

function Combine {
    $RmApi.Log("Combining configs!")

    # Reset main file
    Reset-MainFile

    # Tell bars to export themselves
    Export-Bars

    # Append exported bars
    for ($i = 0; $i -lt $bands; $i++) {

        # Temporary file path
        $file = "$($tempDir)\$i.ini"
        
        # Get exported bar shape
        $content = Get-Content -Path $file

        # Remove temporary file
        Remove-Item -Path $file
        
        # Appended shape options start from 2
        "Shape$($i + 2)=$($content)" | Out-File -FilePath $mainFile -Append -Encoding oem
    }
    
    # Remove bar skins
    Remove-Item -Path "$barDir\*" -Recurse

    $RmApi.Bang("[!RefreshApp]")
}

function Make-BarDir {
    if (-Not (Test-Path $barDir)) { New-Item $barDir -ItemType Directory } 
}

function Separate {
    $RmAPI.Log("Separating configs!")
    Make-BarDir
    for ($i = 0; $i -lt $bands; $i++) {
        $directory = "$barDir\$i"
        if (-Not (Test-Path $directory)) { New-Item $directory -ItemType Directory } 

        # Load hashtable from Storage and use it to generate the editable skin
        $hash = Import-CliXml "$storageDir\$i.ps1xml"
        Meter-Bar -Index $i -FromHashtable $hash | Out-File -FilePath "$directory\$i.ini" -Force
    }
    # Reset mainfile
    Reset-MainFile
    # Tell Update to call Load-Bars and refresh rainmeter
    Refresh-LoadBars
}

function Clear-Measures { 
    # Clear measures
    Clear-Content -Path $barMeasuresFile
    # Generate bar measures
    for ($i = 0; $i -lt $bands; $i++) {
        Measure-Band -Index $i 
    }
    $RmApi.Log("Generated $bands measures!")
}

function Measure-Band {
    param (
        [Parameter()]
        [Int64]
        $Index
    )
    return &"$templatesDir\MeasureBar" -Index $Index -SkipBands $SkipBands | Out-File -FilePath $barMeasuresFile -Append
}

function Generate-Bars {
    Make-BarDir
    # Call template for each bar
    for ($i = 0; $i -lt $bands; $i++) {
        $directory = "$barDir\$i"
        if (-Not (Test-Path $directory)) { New-Item $directory -ItemType Directory } 
        Meter-Bar -Index $i | Out-File -FilePath "$directory\$i.ini" -Force
    }
    # Make new measures
    Clear-Measures
    # Tell Update to call Load-Bars and refresh rainmeter
    Refresh-LoadBars
}

function Meter-Bar {
    param (
        [Parameter()]
        [Int64]
        $Index,
        [Parameter()]
        [System.Collections.Hashtable]
        $FromHashtable
    )
    return &"$templatesDir\MeterBar" -Index $Index -FromHashtable $FromHashtable
}

function Export-Bars {
    # Command all configs to export themselves
    $exports = ""
    for ($i = 0; $i -lt $bands; $i++) {
        $exports += "[!CommandMeasure Export `"Export`" `"Amalgus\Bars\$i`"]"
    }
    $RmAPI.Bang($exports)
}

function Refresh-LoadBars {
    $RmApi.Bang("[!WriteKeyValue Variables LoadBars 1][!RefreshApp]")
}

function Load-Bars {
    # Tell Update that bars have been loaded
    $activate = "[!WriteKeyValue Variables LoadBars 0]"
    # Make activation bang for each bar
    for ($i = 0; $i -lt $bands; $i++) {
        $activate += "[!ActivateConfig `"Amalgus\Bars\$i`"]"
    }
    # Activate all of the configs
    $RmApi.Bang($activate)
}

function Reset-MainFile {
    &"$templatesDir\CompiledBars.ps1" | Set-Content -Path $mainFile
}