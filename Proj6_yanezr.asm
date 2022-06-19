TITLE Program Template     (template.asm)

; Author: Ricardo Yanez
; Last Modified: 06/16/2022
; OSU email address: yanezr@oregonstate.edu
; Course number/section:   CS271 Section 404
; Project Number: 6        Due Date: 06/26/2022
; Description: This file is provided as a template from which you may work
;              when developing assembly projects in CS271.

INCLUDE Irvine32.inc

MAXNUM = 3

; A 32-bit sign integer has at most 10 decimal digits, add one 
; for the sign, add one for NULL termination of a string
MAXSIZE = 12

mGetString MACRO text, count, string
  LOCAL prompt
  .data
  prompt BYTE text, 0
  .code
  PUSH EDX
  PUSH ECX
  ; display prompt
  MOV EDX, OFFSET prompt
  CALL WriteString
  ; read user-supplied string
  MOV EDX, OFFSET string
  MOV ECX, SIZEOF string
  CALL ReadString
  MOV count, EAX
  POP ECX
  POP EDX
ENDM

mDisplayString MACRO string
  PUSH EDX
  ; display string
  MOV EDX, OFFSET string
  CALL WriteString
  POP EDX
ENDM

mDisplayText MACRO text
  LOCAL string
  .data
  string BYTE text, 0
  .code
  PUSH EDX
  ; display string
  MOV EDX, OFFSET string
  CALL WriteString
  POP EDX
ENDM

.data

  greeting		BYTE	"PROGRAMMING ASSIGNMENT 6: Designing low-level I/O procedures",10,13,
						"Written by: Ricardo Yanez",0
  prompt1		BYTE	"Please provide 10 signed decimal integers.",10,13,
						"Each number needs to be small enough to fit inside a 32 bit register. ",
						"After you have finished inputting the raw numbers I will display a list ",
						"of the integers, their sum, and their average value.",0

  buffer		BYTE	MAXSIZE DUP(0)
  numbers		SDWORD	MAXNUM DUP(?)

.code
main PROC

  PUSH OFFSET prompt1
  PUSH OFFSET greeting
  CALL introduction

  PUSH OFFSET numbers
  CALL ReadVal

  Invoke ExitProcess,0	; exit to operating system
main ENDP

introduction PROC
  PUSH EBP
  MOV EBP, ESP

  PUSH EDX

  MOV EDX, [EBP+8]
  CALL WriteString
  CALL CrLf
  CALL CrLf

  MOV EDX, [EBP+12]
  CALL WriteString
  CALL CrLf
  CALL CrLf

  POP EDX

  POP EBP
  RET 8
introduction ENDP

ReadVal PROC
  LOCAL byteCount:DWORD, pow:DWORD, num:SDWORD, numcnt:DWORD

  PUSH EAX						; preserve register
  PUSH EBX
  PUSH ECX
  PUSH EDX

  MOV EDI, [EBP+8]				; address of numbers array
  MOV numcnt, 0					; set number counter

_next_number:

  mGetString 'Please enter a signed number: ', byteCount, buffer

_start_over:

  ; pointer at the end of string and move backwards
  MOV ESI, OFFSET buffer
  MOV ECX, byteCount
  ADD ESI, ECX
  DEC ESI
  STD

  ; set the starting power of the last digit
  MOV pow, 1

  ; reset accumulator
  MOV num, 0

_parse:

  ; load byte
  LODSB

  ; compare digit to a '0'
  CMP AL, 30h
  JL _not_digit

  ; compare digit to a '9'
  CMP AL, 39h
  JG _not_digit

  ; here we have a valid digit
  ; subtract 30h to convert from ASCII to decimal
  SUB AL, 30h

  ; multiply digit by power of 10 and add to number
  MUL pow
  ADD num, EAX

  ; increase by one power of 10 for next digit
  MOV EAX, pow
  MOV EBX, 10
  MUL EBX
  MOV pow, EAX
  MOV EAX, 0

  LOOP _parse

  ; here we have a valid positive number
  JMP _continue

_not_digit:

  ; only the first element of the string can be a + or -
  CMP ECX, 1
  JNZ _not_number

  ; if a + character, do nothing
  CMP AL, 2Bh
  JZ _continue

  ; if a - character, flip the sign
  NEG num
  CMP AL, 2Dh
  JZ _continue

  ; if here, sting is not a number
_not_number:

  ; prompt error and enter a new value
  mDisplayText 'ERROR: You did not enter a signed number or your number was too big.'
  CALL CrLf
  mGetString 'Please try again: ', byteCount, buffer
  JMP _start_over

  ; if here, a number
_continue:

  ;----------------------------------
  ; check if number is too big
  ; divide by 1 and check the OV flag
  ;----------------------------------
  MOV EAX, num
  CDQ
  MOV EBX, 1
  IDIV EBX
  JO _not_number

  ; store number in array
  MOV [EDI], EAX
  ADD EDI, SIZEOF SDWORD

  ; increment number counter and loop to next number
  INC numcnt
  CMP numcnt, MAXNUM
  JNZ _next_number

  POP EDX						; restore registers
  POP ECX
  POP EBX
  POP EAX

  RET 4
ReadVal ENDP


END main
