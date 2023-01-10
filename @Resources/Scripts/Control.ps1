# Get skin root path and set script location to it
$rootConfig = "$($RmAPI.VariableStr('ROOTCONFIGPATH'))"
Set-Location $rootConfig

# Other locations
$resourcesDir = "$($RmAPI.VariableStr('@'))"
$tempDir = "$($resourcesDir)temp"
$barDir = ".\Bars"

# Known values
$nOfBands = $RmAPI.Variable("Bands")
$self = $RmAPI.VariableStr("ROOTCONFIG")
$EvalString = $RmAPI.VariableStr("EvalString")

function Update {
    $RmApi.Log("Updated Control.ps1!")
    return 1
}

function Control {

    Export-Hashtables

    $Bands = @()

    for ($i = 0; $i -lt $nOfBands; $i++) {
        $Bands += Import-Clixml "$tempDir\$i.ps1xml"
    }

    $index = 0
    $Bands | ForEach-Object {
        $i = $index
        $last = $Bands[$(if ($i -gt 0) { $i - 1 } else { 0 })]
        $first = $Bands[0]
        Invoke-Expression $EvalString
        $index++
    }

    for ($i = 0; $i -lt $nOfBands; $i++) {
        
        $bandHashtable = $Bands[$i]

        foreach ($Variable in $bandHashtable.Keys) {
            $config = "`"$self\Bars\$i`""
            $file = "`"$rootConfig\Bars\$i\$i.ini`""
            $bangs = "[!SetVariable `"$Variable`" `"$($bandHashtable[$Variable])`" $config][!WriteKeyValue Variables `"$Variable`" `"$($bandHashtable[$Variable])`" $file][!UpdateMeter Bar $config][!Redraw $config]"
            $RmAPI.Bang($bangs)
        }

    }

}

function Export-Hashtables {

    for ($i = 0; $i -lt $nOfBands; $i++) {

        $RmAPI.Bang("[!CommandMeasure Export Temp-Hashtable $self\Bars\$i]")

    }
    
}
