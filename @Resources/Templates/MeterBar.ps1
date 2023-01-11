param (
    [Parameter()]
    [Int64]
    $Index,
    # Hashtable to get values from
    [Parameter()]
    [System.Collections.Hashtable]
    $FromHashtable
)

# Default values
$w = 10
$h = 100
$DefaultValues = @{
    X        = (($Index + 1) * ($w + 5))
    Y        = $h
    Width    = $w;
    Height   = $h;
    Rotation = 180;
}

# Use provided hashtable or defaults
$H = if ($FromHashtable -is [System.Collections.Hashtable]) { $FromHashtable } else { $DefaultValues }

# Helper functions that generate similar bangs that are reused
function New-Dimension {
    Param(
        [Parameter(Mandatory, Position = 0)]
        [string[]]
        $Dimension,
        [Parameter(Position = 1)]
        [string[]]
        $ifTrue,
        [Parameter(Position = 2)]
        [string[]]
        $ifFalse
    )

    return "(([#$Dimension] - [#Grow$Dimension]) < #Min$Dimension# ? $(if ($ifTrue.Length -eq 0) {"#Min$Dimension#"} else {$ifTrue}) : $(if($ifFalse.Length -eq 0) {"([#$Dimension] - [#Grow$Dimension])"} else {$ifFalse}))"

}

function If-Dimension {
    param(
        [Parameter(Mandatory, Position = 0)]
        [string[]]
        $Dimension
    )
    return "[!SetVariable Mouse$Dimension `"([#MouseIsEditing] = 0 ? `$mouse$Dimension`$ : [#Mouse$Dimension])`"]"
}

function Mouse-Actions {
    param(
        [Parameter(Mandatory, Position = 0)]
        [string[]]
        $Action
    )

    switch ($Action) {
        "Resize" { return "[!SetVariable GrowWidth `"(([#MouseX] - `$mouseX`$) * -1)`"][!SetVariable GrowHeight `"(([#MouseY] - `$mouseY`$) * -1)`"]" }
        "Move" { return "[!SetVariable MoveX `"([#MouseX] - `$mouseX`$)`"][!SetVariable MoveY `"([#MouseY] - `$mouseY`$)`"]" }
        Default { return "" }
    }

}

# Reused bangs
$ur = "[!UpdateMeter Bar][!Redraw]"

$enableEdit = "[!SetVariable MouseIsEditing 1]"
$disableEdit = "[!SetVariable MouseIsEditing 0]"
$writeRotation = "[!WriteKeyValue Variables Rotation `"([#Rotation])`"]"
$writeDimensions = "[!WriteKeyValue Variables Width `"[#Width]`"][!WriteKeyValue Variables Height `"[#Height]`"]"
$setWriteCordinates = "[!SetVariable X `"([#X] - [#MoveX])`"][!SetVariable Y `"([#Y] - [#MoveY])`"][!WriteKeyValue Variables X `"[#X]`"][!WriteKeyValue Variables Y `"[#Y]`"]"

$resetSize = "[!SetVariable GrowHeight 0][!SetVariable GrowWidth 0]"
$resetMove = "[!SetVariable MoveX 0][!SetVariable MoveY 0]"

return @"
[Rainmeter]
Update=16
MouseScrollDownAction=[!SetVariable Rotation "([#Rotation] - 5)"]$writeRotation$ur
MouseScrollUpAction=[!SetVariable Rotation "([#Rotation] + 5)"]$writeRotation$ur
MouseOverAction=[!SetVariable MouseOver 1]$ur
MouseLeaveAction=[!SetVariable MouseOver 0]$ur
RightMouseDownAction=$enableEdit$ur
RightMouseUpAction=$disableEdit[!SetVariable Width "$(New-Dimension "Width")"][!SetVariable Height "$(New-Dimension "Height")"]$writeDimensions$setWriteCordinates$resetMove$resetSize$ur
LeftMouseDownAction=$enableEdit$ur
LeftMouseUpAction=$disableEdit$setWriteCordinates$resetMove $ur
MiddleMouseUpAction=[!CommandMeasure Export "Export"]

[Variables]
@IncludeVariables=#@#Variables.inc
Index=$Index
Height=$($H.Height)
Width=$($H.Width)
Rotation=$($H.Rotation)
MouseIsEditing=0
X=$($H.X)
Y=$($H.Y)
MoveX=0
MoveY=0
GrowWidth=0
GrowHeight=0
MouseX=0
MouseY=0
MouseOver=0

[MeasureMouse]
Measure=Plugin
Plugin=Mouse
RelativeToSkin=0
MouseMoveAction=$(If-Dimension "X")$(If-Dimension "Y")
RightMouseDragAction=$(Mouse-Actions "Resize")[!Update]$ur
LeftMouseDragAction=$(Mouse-Actions "Move")[!Update]$ur

[Bar]
Meter=Shape
Shape=Rectangle 0,0,#SCREENAREAWIDTH#, #SCREENAREAHEIGHT# | Fill Color 0,0,0,(#MouseIsEditing# = 1 ? 25 : 0)
Shape2=Rectangle (#X# - #MoveX#), (#Y# - #MoveY#), $(New-Dimension "Width"), $(New-Dimension "Height") | Fill Color #FillColor# | StrokeWidth #StrokeWidth# | Stroke Color #StrokeColor# | Rotate #Rotation#,0,0
Shape3=Rectangle (#X# - #MoveX# - 4), (#Y# - #MoveY# - 4), 8, 8 | Rotate #Rotation#,4,4 | Extend Origin 
Shape4=Rectangle (#X# - #MoveX# - 2), (#Y# - #MoveY# - 2), 8, 8 | Rotate (#Rotation# + 45),2,2 | Extend Origin 
Origin=StrokeWidth 0 | Fill Color 255,0,0,(#MouseOver# = 1 ? 255 : 0)
DynamicVariables=1
UpdateDivider=-1

[Debug]
Meter=String
MeasureName=NewWidth
MeasureName2=NewHeight
Text=Bar $Index#CRLF#Rotation = #Rotation##CRLF#Width = (#Width# - #GrowWidth#)#CRLF#Height = (#Height# - #GrowHeight#)
Hidden=(1 - #MouseIsEditing#)
FontColor=255,255,255
X=48
Y=48
FontSize=18
AntiAlias=1
DynamicVariables=1

[Export]
Measure=Plugin
OnUpdateAction=[!SetOption #CURRENTSECTION# UpdateDivider -1]
Plugin=PowershellRM
ScriptFile=#@#Scripts\Export.ps1
Shape2=Rectangle #X#, #Y#, #Width#, (#Height# * [Band$Index])| Fill Color #FillColor#  | StrokeWidth #StrokeWidth# | Stroke Color #StrokeColor# | Rotate #Rotation#,0,0


"@
