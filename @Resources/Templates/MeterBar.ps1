param (
    [Parameter()]
    [Int64]
    $Index,
    # Hashtable to get values from
    [Parameter()]
    [System.Collections.Hashtable]
    $FromHashtable
)

$w = 10
$h = 100
$DefaultValues = @{
    X        = (($Index + 1) * ($w + 5))
    Y        = $h
    Width    = $w;
    Height   = $h;
    Rotation = 180;
}

$H = if ($FromHashtable -is [System.Collections.Hashtable]) { $FromHashtable } else { $DefaultValues }

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

return @"
[Rainmeter]
Update=16
MouseScrollDownAction=[!SetVariable Rotation "([#Rotation] - 5)"][!WriteKeyValue Variables Rotation "([#Rotation])"]#UR#
MouseScrollUpAction=[!SetVariable Rotation "([#Rotation] + 5)"][!WriteKeyValue Variables Rotation "([#Rotation])"]#UR#
MouseOverAction=[!SetVariable MouseOver 1]#UR#
MouseLeaveAction=[!SetVariable MouseOver 0]#UR#
RightMouseDownAction=[!SetVariable MouseIsEditing 1]#UR#
RightMouseUpAction=[!SetVariable MouseIsEditing 0][!SetVariable Width "(([#Width] - [#GrowWidth]) < #MinWidth# ? #MinWidth# : ([#Width] - [#GrowWidth]))"][!SetVariable Height "(([#Height] - [#GrowHeight]) < #MinHeight# ? #MinHeight# : ([#Height] - [#GrowHeight]))"][!WriteKeyValue Variables Width "[#Width]"][!WriteKeyValue Variables Height "[#Height]"][!SetVariable X "([#X] - [#MoveX])"][!SetVariable Y "([#Y] - [#MoveY])"][!WriteKeyValue Variables X "[#X]"][!WriteKeyValue Variables Y "[#Y]"]#ResetMove# #ResetSize# #UR#
LeftMouseDownAction=[!SetVariable MouseIsEditing 1]#UR#
LeftMouseUpAction=[!SetVariable MouseIsEditing 0][!SetVariable X "([#X] - [#MoveX])"][!SetVariable Y "([#Y] - [#MoveY])"][!WriteKeyValue Variables X "[#X]"][!WriteKeyValue Variables Y "[#Y]"]#ResetMove# #UR#
MiddleMouseUpAction=#Export#

[Variables]
@IncludeVariables=#@#Variables.inc
UR=[!UpdateMeter Bar][!Redraw]
Export=[!CommandMeasure Export "Export"]
ResetMove=[!SetVariable MoveX 0][!SetVariable MoveY 0]
ResetSize=[!SetVariable GrowHeight 0][!SetVariable GrowWidth 0]
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
MouseMoveAction=[!SetVariable MouseX "([#MouseIsEditing] = 0 ? `$mouseX$ : [#MouseX])"][!SetVariable MouseY "([#MouseIsEditing] = 0 ? `$mouseY$ : [#MouseY])"]
RightMouseDragAction=[!SetVariable GrowWidth "(([#MouseX] - `$mouseX$) * -1)"][!SetVariable GrowHeight "(([#MouseY] - `$mouseY$) * -1)"][!Update]#UR#
LeftMouseDragAction=[!SetVariable MoveX "([#MouseX] - `$mouseX$)"][!SetVariable MoveY "([#MouseY] - `$mouseY$)"][!Update]#UR#

[Bar]
Meter=Shape
Shape=Rectangle 0,0,#SCREENAREAWIDTH#, #SCREENAREAHEIGHT# | Fill Color 0,0,0,(#MouseIsEditing# = 1 ? 25 : 0)
Shape2=Rectangle (#X# - #MoveX#), (#Y# - #MoveY#), $(New-Dimension "Width"), $(New-Dimension "Height") | Fill Color #FillColor# | StrokeWidth #StrokeWidth# | Stroke Color #StrokeColor# | Rotate #Rotation#,0,0
Shape3=Rectangle (#X# - #MoveX# - 4), (#Y# - #MoveY# - 4), 8, 8 | Rotate #Rotation#,4,4 | Extend Origin 
Shape4=Rectangle (#X# - #MoveX# - 2), (#Y# - #MoveY# - 2), 8, 8 | Rotate (#Rotation# + 45),2,2 | Extend Origin 
Origin=StrokeWidth 0 | Fill Color 255,0,0,(#MouseOver# = 1 ? 255 : 0)
DynamicVariables=1
UpdateDivider=-1

[NewWidth]
Measure=Calc
Formula=$(New-Dimension "Width")
DynamicVariables=1
[NewHeight]
Measure=Calc
Formula=$(New-Dimension "Height")
DynamicVariables=1

[Debug]
Meter=String
MeasureName=NewWidth
MeasureName2=NewHeight
Text=Bar $Index#CRLF#Rotation = #Rotation##CRLF#Width = %1#CRLF#Height = %2
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
