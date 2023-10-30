#include "NomadMemory.au3"
#include <File.au3>
#include <Array.au3>
ToolTip("Running...", 0, 0, "Running", 1, 1)

$FilePath = FileOpenDialog("Open", @ScriptDir, "All (*.*)")
Local $offsets, $bytes
_FileReadToArray("offsets.txt", $offsets, 0)
_FileReadToArray("bytes.txt", $bytes, 0)

$file = FileOpen($FilePath, 16)
$data = FileRead($file)
FileClose($file)

$hwnd = ProcessList("test.exe")
$process = _MemoryOpen($hwnd[1][1])
$start = _MemoryPatternSearch($process, "CF FA ED FE")

For $i = 0 To UBound($bytes) - 1
	_MemoryWrite($start + $offsets[$i], $process, "0x" & $bytes[$i], 'byte[' & StringLen($bytes[$i]) / 2 & ']')
Next

$newFile = _MemoryRead($start, $process, 'byte[' & FileGetSize($FilePath) & ']')

FileMove($FilePath, $FilePath & "_old")
$file = FileOpen($FilePath, 2 + 16)
FileWrite($file, $newFile)
FileClose($file)

Func _MemoryPatternSearch($ProcessHandle, $Pattern, $StartAddress = 0x0, $StopAddress = 0x1FFFFFFF, $Step = 1024)
	If Not IsArray($ProcessHandle) Then
		SetError(1)
		Return -1
	EndIf
	$Pattern = StringRegExpReplace($Pattern, '[^0123456789ABCDEFabcdef?.]', '')
	$Pattern = StringRegExpReplace($Pattern, "\?", ".")

	If StringLen($Pattern) = 0 Then
		SetError(2)
		Return -2
	EndIf
	Local $BufferPattern, $FormatedPattern
	For $i = 0 To ((StringLen($Pattern) / 2) - 1)
		$BufferPattern = StringLeft($Pattern, 2)
		$Pattern = StringRight($Pattern, StringLen($Pattern) - 2)
		$FormatedPattern = $FormatedPattern & $BufferPattern
	Next
	$Pattern = $FormatedPattern
	For $Address = $StartAddress To $StopAddress Step $Step
		StringRegExp(_MemoryRead($Address, $ProcessHandle, 'byte[' & $Step & ']'), $Pattern, 1, 2)
		If Not @error Then
			Return Floor($Address + ((@extended - StringLen($Pattern) - 2) / 2) - $StartAddress)
		EndIf
	Next
	For $Address = $StartAddress To $StopAddress Step $Step * 1.5
		StringRegExp(_MemoryRead($Address, $ProcessHandle, 'byte[' & $Step * 1.5 & ']'), $Pattern, 1, 2)
		If Not @error Then
			Return Floor($Address + ((@extended - StringLen($Pattern) - 2) / 2) - $StartAddress)
		EndIf
	Next
	Return -3
EndFunc   ;==>_MemoryPatternSearch