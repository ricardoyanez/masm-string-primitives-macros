TITLE Sring Primitives and Macros     (Proj6_yanezr.asm)

; Author: Ricardo Yanez
; Last Modified: 06/19/2022
; OSU email address: yanezr@oregonstate.edu
; Course number/section: CS271 Section 404
; Project Number: 6    Due Date: 06/26/2022
; Description: Designing low-level procedures to read a string containing digits,
;              validate, convert to signed integer and display.

INCLUDE Irvine32.inc

MAXNUM = 3

; A 32-bit sign integer has at most 10 decimal digits, add one
; for the sign, add one for NULL termination of a string
MAXSIZE = 12

;---------------------------------------------------;
; Name: mGetString                                  ;
;                                                   ;
; Display a prompt and get a user-supplied string   ;
;                                                   ;
; Preconditions: do not use ECX, EDX as arguments   ;
;                                                   ;
; Postconditions: all used registers restored       ;
;                                                   ;
; Receives: text      prompt text                   ;
;           string    string variable               ;
;           count     size of string                ;
;                                                   ;
; Returns: string, size of string                   ;
;---------------------------------------------------;
mGetString MACRO text, string, count
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

;---------------------------------------------------;
; Name: mDisplayString                              ;
;                                                   ;
; Display a string                                  ;
;                                                   ;
; Preconditions: do not use EDX as argument         ;
;                                                   ;
; Postconditions: all used registers restored       ;
;                                                   ;
; Receives: string    string variable               ;
;                                                   ;
; Returns: none                                     ;
;---------------------------------------------------;
mDisplayString MACRO string
  PUSH EDX
  ; display string
  MOV EDX, OFFSET string
  CALL WriteString
  POP EDX
ENDM

;---------------------------------------------------;
; Name: mDisplayText                                ;
;                                                   ;
; Display a text                                    ;
;                                                   ;
; Preconditions: do not use EDX as argument         ;
;                                                   ;
; Postconditions: all used registers restored       ;
;                                                   ;
; Receives: text      text string                   ;
;                                                   ;
; Returns: none                                     ;
;---------------------------------------------------;
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
  instruction	BYTE	"Please provide 10 signed decimal integers.",10,13,
						"Each number needs to be small enough to fit inside a 32 bit register. ",
						"After you have finished inputting the raw numbers I will display a list ",
						"of the integers, their sum, and their average value.",0
  buffer		BYTE	MAXSIZE DUP(0)
  number		SDWORD	?
  numbers		SDWORD	MAXNUM DUP(?)
  sum			SDWORD	?
  ave			SDWORD	?


.code
main PROC

  PUSH OFFSET instruction
  PUSH OFFSET greeting
  CALL introduction

  ;------------------------------------------
  ; as per instruction, ReadVal is called in
  ; a loop within main, and the numeric value
  ; is save in array (numbers)
  ;------------------------------------------
  MOV EDI, OFFSET numbers
  MOV ECX, MAXNUM
_loop:
  PUSH OFFSET number
  CALL ReadVal
  MOV EAX, number
  MOV [EDI], EAX
  ADD EDI, SIZEOF SDWORD
  LOOP _loop

  PUSH OFFSET numbers
  CALL WriteVal

  PUSH OFFSET sum
  PUSH OFFSET numbers
  CALL SumVal

  PUSH OFFSET ave
  PUSH OFFSET sum
  CALL AveVal

  CALL endCredits

  Invoke ExitProcess,0	; exit to operating system
main ENDP


;---------------------------------------------------;
; Name: introduction                                ;
;                                                   ;
; Display program title and instructions.           ;
;                                                   ;
; Preconditions: none                               ;
;                                                   ;
; Postconditions: all used registers restored       ;
;                                                   ;
; Receives: [EBP+8]   program greeting              ;
;           [EBP+12]  program introductions         ;
;                                                   ;
; Returns: none                                     ;
;---------------------------------------------------;
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

;---------------------------------------------------;
; Name: ReadVal                                     ;
;                                                   ;
; Reads a string of digits and converts to a        ;
; numeric value.                                    ;
;                                                   ;
; Preconditions: none                               ;
;                                                   ;
; Postconditions: all used registers restored       ;
;                                                   ;
; Receives: buffer is a global variable             ;
;                                                   ;
; Returns: number     the converted number          ;
;---------------------------------------------------;
ReadVal PROC
  LOCAL byteCount:DWORD, pow:DWORD, num:SDWORD

  PUSH EAX						; preserve register
  PUSH EBX
  PUSH ECX
  PUSH EDX
  PUSH EDI

  MOV EDI, [EBP+8]				; address of number

  mGetString "Please enter a signed number: ", buffer, byteCount

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

  ;------------------------------------------
  ; parse the string byte by byte, check that
  ; byte is a digit and convert to ASCII
  ;------------------------------------------
_parse:

  ; load a byte
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

  ;-------------------------------------
  ; if a non-digit is found, chech if it
  ; is a + or - sign
  ;-------------------------------------
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

  ;-----------------------------------
  ; if here, sting is not a number
  ; display error and get a new string
  ;-----------------------------------
_not_number:
  mDisplayText "ERROR: You did not enter a signed number or your number was too big."
  CALL CrLf
  mGetString "Please try again: ", buffer, byteCount
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

  ; store number in variable
  MOV [EDI], EAX
  ADD EDI, SIZEOF SDWORD

  POP EDI					; restore registers
  POP EDX
  POP ECX
  POP EBX
  POP EAX

  RET 4
ReadVal ENDP

WriteVal PROC
  LOCAL numcnt:DWORD

  PUSH EAX						; preserve register
  PUSH EBX
  PUSH ECX
  PUSH EDX

  MOV ESI, [EBP+8]				; address to numbers array
  MOV numcnt, 0					; set number counter

  CALL CrLf
  mDisplayText "You entered the following numbers:"
  CALL CrLf

_next_number:

  MOV EDI, OFFSET buffer

  ;--------------------------------------
  ; if negative, flip the sign and insert
  ; a - character at the beginning
  ;--------------------------------------
  MOV EAX, [ESI]
  MOV ECX, 0
  CMP EAX, 0
  JNS _non_negative
  NEG EAX
  PUSH EAX
  MOV EAX, 2Dh
  STOSB
  POP EAX

_non_negative:
  PUSH EAX
  ;-----------------------------
  ; get the length of the number
  ; by counting powers of 10
  ;-----------------------------
_get_len:
  MOV EDX, 0
  MOV EBX, 10
  CDQ
  IDIV EBX
  INC ECX
  CMP EAX, 0
  JNZ _get_len

  ; when here, ECX holds the length
  POP EAX

  ;-------------------------------------------
  ; store digits in string backwards
  ; starting from position given by the length
  ;-------------------------------------------
  ADD EDI, ECX
  STD

  ; add NULL termination
  PUSH EAX
  MOV EAX, 0
  STOSB
  POP EAX

  ;----------------------------------
  ; parse the number by powers of 10,
  ; convert digit to ASCII and store
  ;----------------------------------
_parse:

  ; divide number by 10
  MOV EDX, 0
  MOV EBX, 10
  CDQ
  IDIV EBX

  ; the remainder is the digit
  ; convert to ASCII
  ADD EDX, 30h

  ; store ASCII value to string
  PUSH EAX
  MOV EAX, EDX
  STOSB
  POP EAX

  CMP EAX, 0
  JNZ _parse

  mDisplayString buffer

  ; point to next element
  ADD ESI, SIZEOF SDWORD

  ; increment number counter
  INC numcnt
  CMP numcnt, MAXNUM

  ;---------------------
  ; print separator, and
  ; skip the last one
  ;---------------------
  JZ _skip
  mDisplayText ", "
_skip:

  JNZ _next_number

  POP EDX						; restore registers
  POP ECX
  POP EBX
  POP EAX

  RET 4
WriteVal ENDP


SumVal PROC
  PUSH EBP
  MOV EBP, ESP

  PUSH EAX						; preserve register
  PUSH ECX

  MOV ESI, [EBP+8]				; address of numbers array
  MOV ECX, MAXNUM				; size of array
  MOV EAX, 0					; reset accumulator

  ;---------------
  ; sum all values
  ;---------------
_loop:
  ADD EAX, [ESI]
  ADD ESI, SIZEOF SDWORD
  LOOP _loop

  ;-----------------------------
  ; store sum in return variable
  ;-----------------------------
  MOV EDI, [EBP+12]
  MOV [EDI], EAX

  ;------------
  ; display sum
  ;------------
  CALL CrLf
  mDisplayText "The sum of these numbers is: "
  CALL WriteInt

  POP ECX						; restore registers
  POP EAX

  POP EBP

  RET 8
SumVal ENDP

AveVal PROC
  PUSH EBP
  MOV EBP, ESP

  PUSH EAX						; preserve register
  PUSH EBX
  PUSH EDX

  MOV ESI, [EBP+8]				; address of sum
  MOV EAX, [ESI]

  ;----------------------------
  ; calculate truncated average
  ;----------------------------
  MOV EDX, 0
  MOV EBX, MAXNUM
  CDQ
  IDIV EBX

  ;---------------------------------
  ; store average in return variable
  ;---------------------------------
  MOV EDI, [EBP+12]
  MOV [EDI], EAX

  ;----------------
  ; display average
  ;----------------
  CALL CrLf
  mDisplayText "The truncated average is: "
  CALL WriteInt
  CALL CrLf

  POP EDX						; restore registers
  POP EBX
  POP EAX

  POP EBP

  RET 8
AveVal ENDP


endCredits PROC
  CALL CrLf
  mDisplayText "Thanks for playing!"
  CALL CrLf
  RET
endCredits ENDP

END main
