param (
    [Parameter()]
    [Int64]
    $Index,
    [Parameter()]
    [Int64]
    $SkipBands = 0
)

return @"
[Band$Index]
Measure=Plugin
Plugin=AudioAnalyzer
Parent=MeasureAudioAnalyzer
Type=Child
Index=$($Index + $SkipBands)
Channel=Auto
HandlerName=MainFinalOutput

"@
