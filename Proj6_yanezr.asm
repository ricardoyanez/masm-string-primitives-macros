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

.data

  greeting		BYTE	"PROGRAMMING ASSIGNMENT 6: Designing low-level I/O procedures",10,13,
						"Written by: Ricardo Yanez",0
  prompt1		BYTE	"Please provide 10 signed decimal integers.",10,13,
						"Each number needs to be small enough to fit inside a 32 bit register. ",
						"After you have finished inputting the raw numbers I will display a list ",
						"of the integers, their sum, and their average value.",0

.code
main PROC

  PUSH OFFSET prompt1
  PUSH OFFSET greeting
  CALL introduction

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

END main
