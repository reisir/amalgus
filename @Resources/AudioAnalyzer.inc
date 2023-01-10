[Variables]
BinWidth=8
OverlapBoost=10
CascadesCount=2
; None | Hann | Hamming | Kaiser | Exponential | Chebyshev 
WindowFunction=Kaiser 

FreqMin=20
FreqMax=20000
; true | false
CubicInterpolation=true

; Average | Product
MixFunction=Average
MinWeight=0.01
TargetWeight=2

Attack=([#UpdateRate] * 1)
Decay=([#UpdateRate] * 2)
MaxSensitivity=43
MinSensitivity=5

BlurRadius=2

[MeasureAudioAnalyzer]
Measure=Plugin
Plugin=AudioAnalyzer
Type=Parent
; AudioAnalyzer settings
; MagicNumber=104
Threading=Policy SeparateThread | UpdateRate [#PollingRate] | WarnTime -1
Source=DefaultOutput
; Units
ProcessingUnits=Main
Unit-Main=Channels Auto | Handlers MainFFT, MainBR(MainFFT), MainBCT(MainBR), MainTR(MainBCT), MainFinalOutput(MainTR)
Handler-MainFFT=Type FFT | BinWidth [#BinWidth] | OverlapBoost [#OverlapBoost] | CascadesCount [#CascadesCount] | WindowFunction [#WindowFunction]
Handler-MainBR=Type BandResampler | Bands Log(Count ([#Bands] + [#SkipBands]), FreqMin [#FreqMin], FreqMax [#FreqMax]) | CubicInterpolation [#CubicInterpolation]
Handler-MainBCT=Type BandCascadeTransformer | MixFunction [#MixFunction] | MinWeight [#MinWeight] | TargetWeight [#TargetWeight]
Handler-MainTR=Type TimeResampler | Attack [#Attack] | Decay [#Decay] | Transform dB, Map(From -[#MaxSensitivity] : -[#MinSensitivity]), Clamp
Handler-MainFinalOutput=Type UniformBlur | Radius [#BlurRadius]
