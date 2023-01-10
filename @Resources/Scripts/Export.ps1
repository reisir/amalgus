# Locations
$resourcesDir = "$($RmAPI.VariableStr('@'))"
$tempDir = "$($resourcesDir)temp"
$storageDir = "$($resourcesDir)Storage"

# Known values
$index = $RmAPI.VariableStr("Index")
$currentPath = $($RmAPI.VariableStr("CURRENTPATH"))
$currentFileName = $($RmAPI.VariableStr("CURRENTFILE"))
$currentFile = "$currentPath$CurrentFileName"

function Update {
    return $currentFile
}

function Export {
    # Export shape option
    $RmApi.OptionStr("Shape2") | Out-File -FilePath "$($tempDir)\$currentFileName"
    $RmApi.Log("Exported shape $index!")

    Hashtable | Export-Clixml -Path "$($storageDir)\$index.ps1xml"
    $RmApi.Log("Exported bar $index as hashtable!")

    $RmApi.Bang("!DeactivateConfig")
}

function Hashtable { 
    
    # https://stackoverflow.com/questions/60621582/does-powershell-support-hashtable-serialization
    # Import-CliXml hashtable.ps1xml

    return @{
        X        = $RmApi.Variable("X");
        Y        = $RmApi.Variable("Y");
        Width    = $RmApi.Variable("Width");
        Height   = $RmApi.Variable("Height");
        Rotation = $RmApi.Variable("Rotation");
    }
}

function Temp-Hashtable {
    Hashtable | Export-Clixml -Path "$tempDir\$index.ps1xml"
}
