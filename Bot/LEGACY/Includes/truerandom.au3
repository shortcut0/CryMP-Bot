; -------------------------------
; !! SOURCES OF truerandom.exe !!
; -------------------------------

#Region ;**** Directives created by AutoIt3Wrapper_GUI ****
#AutoIt3Wrapper_Change2CUI=y
#EndRegion ;**** Directives created by AutoIt3Wrapper_GUI ****

; Get mem load for seed randomization
Local $aMemInfo = MemGetStats()

; Create seed by adding used mem in bytes + available virtual ram in bytes + truerandom.exe PID + current second + 5 numbers from the right of TimerInit()
Local $iSeed = $aMemInfo[2] + $aMemInfo[6] + @AutoItPID + @MSEC + StringRight(TimerInit(), 5)

; Set Random Number Generator Seed
SRandom(Random(0, 10000, 1) + $iSeed)

Local $iCmd = $CmdLine[0]
Local $iLen = 20
Local $sRandom = Random(1, 100, 1)
If ($iCmd >= 1) Then
	Local $iLen = Number($CmdLine[1])
	$sRandom = ""
	For $i = 1 To $iLen
		$sRandom &= Random(1, 9, 1)
	Next
EndIF
ConsoleWrite(String($sRandom) & @CRLF)