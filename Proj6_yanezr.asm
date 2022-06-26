TITLE Sring Primitives and Macros     (Proj6_yanezr.asm)

; Author: Ricardo Yanez
; Last Modified: 06/20/2022
; OSU email address: yanezr@oregonstate.edu
; Course number/section: CS271 Section 404
; Project Number: 6    Due Date: 06/26/2022
; Description: Designing low-level procedures to read a string containing digits,
;              validate, convert to signed integer and display.

INCLUDE Irvine32.inc

MAXNUM = 10
MAXSIZE = 25

;---------------------------------------------------;
; Name: mGetString                                  ;
;                                                   ;
; Display a prompt and get a user-supplied string   ;
;                                                   ;
; Preconditions: do not use ECX, EDX or EAX as      ;
;                arguments                          ;
;                                                   ;
; Postconditions: all used registers restored       ;
;                                                   ;
; Receives: prompt    prompt text                   ;
;           buffer    address of string             ;
;           size      size of string                ;
;           count     count of characters           ;
;                                                   ;
; Returns: buffer, count                            ;
;---------------------------------------------------;
mGetString MACRO prompt, buffer, size, count
  PUSH EDX
  PUSH ECX
  ; display prompt
  mDisplayString prompt
  ; read user-supplied string
  MOV EDX, buffer
  MOV ECX, size
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
; Receives: buffer    address of string             ;
;                                                   ;
; Returns: none                                     ;
;---------------------------------------------------;
mDisplayString MACRO buffer
  PUSH EDX
  ; display string
  MOV EDX, buffer
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
  prompt1		BYTE	"Please enter a signed number: ",0
  prompt2		BYTE	"Please try again: ",0
  prompt3		BYTE	"You entered the following numbers:",0
  prompt4		BYTE	"The sum of these numbers is: ",0
  prompt5		BYTE	"The truncated average is: ",0
  error			BYTE	"ERROR: You did not enter a signed number or your number was too big.",0
  credits		BYTE	"Thanks for playing!",0
  separator		BYTE	", ",0
  buffer		BYTE	MAXSIZE DUP(0)
  bufSize		DWORD	SIZEOF buffer
  byteCount		DWORD	?
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
  ; is saved in array (numbers)
  ;------------------------------------------
  MOV EDI, OFFSET numbers
  MOV ECX, MAXNUM
_loop:
  PUSH OFFSET error
  PUSH OFFSET prompt2
  PUSH OFFSET prompt1
  PUSH OFFSET byteCount
  PUSH bufSize
  PUSH OFFSET buffer
  PUSH OFFSET number
  CALL ReadVal
  MOV EAX, number
  MOV [EDI], EAX
  ADD EDI, SIZEOF SDWORD
  LOOP _loop

  PUSH OFFSET separator
  PUSH OFFSET prompt3
  PUSH OFFSET buffer
  PUSH OFFSET numbers
  CALL WriteVal

  PUSH OFFSET prompt4
  PUSH OFFSET sum
  PUSH OFFSET numbers
  CALL SumVal

  PUSH OFFSET prompt5
  PUSH OFFSET ave
  PUSH OFFSET sum
  CALL AveVal

  PUSH OFFSET credits
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

  PUSH EDX						; preserve registers

  MOV EDX, [EBP+8]
  CALL WriteString
  CALL CrLf
  CALL CrLf

  MOV EDX, [EBP+12]
  CALL WriteString
  CALL CrLf
  CALL CrLf

  POP EDX						; restore registers

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
; Receives: [EBP+8]     address of number           ;
;           [EBP+12]    address of buffer           ;
;           [EBP+16]    bufSize                     ;
;           [EBP+20]    address of byteCount        ;
;           [EBP+24]    address of prompt1          ;
;           [EBP+28]    address of prompt2          ;
;           [EBP+32]    address of error            ;
;                                                   ;
; Returns: [EBP+8]      number                      ;
;---------------------------------------------------;
ReadVal PROC
  LOCAL pow:DWORD, num:SDWORD

  PUSH EAX						; preserve registers
  PUSH EBX
  PUSH ECX
  PUSH EDX
  PUSH EDI

  MOV EDI, [EBP+20]

  mGetString [EBP+24], [EBP+12], [EBP+16], [EDI]

_start_over:

  ;------------------------------------------------
  ; pointer at the end of string and move backwards
  ;------------------------------------------------
  MOV ESI, [EBP+12]				; address of buffer
  MOV ECX, [EDI]                ; address of byteCount
  ADD ESI, ECX
  DEC ESI
  STD

  ; set the starting power of the last digit
  MOV pow, 1

  ; reset accumulator
  MOV num, 0

  ; address of number
  MOV EDI, [EBP+8]

  ;-------------------------------------------
  ; parse the string byte by byte, check that
  ; byte is a digit and convert to ASCII if so
  ;-------------------------------------------
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

  ;------------------------------
  ; check if number is too big
  ; by checking the overflow flag
  ;------------------------------
  JO _not_number

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
  mDisplayString [EBP+32]
  CALL CrLf
  MOV EDI, [EBP+20]
  mGetString [EBP+28], [EBP+12], [EBP+16], [EDI]
  JMP _start_over

  ; if here, a number
_continue:

  ;-------------------------
  ; store number in variable
  ;-------------------------
  MOV EAX, num
  MOV [EDI], EAX
  ADD EDI, SIZEOF SDWORD

  POP EDI					; restore registers
  POP EDX
  POP ECX
  POP EBX
  POP EAX

  RET 28
ReadVal ENDP

;---------------------------------------------------;
; Name: WriteVal                                    ;
;                                                   ;
; Converts numeric values to a string and prints    ;
;                                                   ;
; Preconditions: none                               ;
;                                                   ;
; Postconditions: all used registers restored       ;
;                                                   ;
; Receives: [EBP+8]     address of numbers          ;
; Receives: [EBP+12]    address of buffer           ;
; Receives: [EBP+16]    address of prompt3          ;
; Receives: [EBP+20]    address of separator        ;
;                                                   ;
; Returns: none                                     ;
;---------------------------------------------------;
WriteVal PROC
  LOCAL numcnt:DWORD

  PUSH EAX						; preserve registers
  PUSH EBX
  PUSH ECX
  PUSH EDX
  PUSH ESI

  MOV ESI, [EBP+8]				; address to numbers array
  MOV numcnt, 0					; set number counter

  CALL CrLf
  mDisplayString [EBP+16]
  CALL CrLf

_next_number:

  MOV EDI, [EBP+12]				; address of buffer

  ;----------------------------------------
  ; if negative, flip the sign and insert a
  ; - character at the beginning of string
  ;----------------------------------------
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

  mDisplayString [EBP+12]

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
  mDisplayString [EBP+20]
_skip:

  JNZ _next_number

  POP ESI						; restore registers
  POP EDX
  POP ECX
  POP EBX
  POP EAX

  RET 16
WriteVal ENDP

;---------------------------------------------------;
; Name: SumVal                                      ;
;                                                   ;
; Sum the values of an array of numbers and display ;
;                                                   ;
; Preconditions: none                               ;
;                                                   ;
; Postconditions: all used registers restored       ;
;                                                   ;
; Receives: [EBP+8]     address of numbers          ;
;           [EBP+12]    address of sum              ;
;           [EBP+16]    address of prompt4          ;
;                                                   ;
; Returns: [EBP+12]     sum                         ;
;---------------------------------------------------;
SumVal PROC
  PUSH EBP
  MOV EBP, ESP
  PUSH ESI
  PUSH EDI

  PUSH EAX						; preserve registers
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
  mDisplayString [EBP+16]
  CALL WriteInt

  POP ECX						; restore registers
  POP EAX

  POP EDI
  POP ESI
  POP EBP

  RET 12
SumVal ENDP

;---------------------------------------------------;
; Name: AveVal                                      ;
;                                                   ;
; Calculate and display the average                 ;
;                                                   ;
; Preconditions: none                               ;
;                                                   ;
; Postconditions: all used registers restored       ;
;                                                   ;
; Receives: [EBP+8]     address of sum              ;
;           [EBP+12]    address of ave              ;
;           [EBP+16]    address of prompt5          ;
;                                                   ;
; Returns: [EBP+12]     ave                         ;
;---------------------------------------------------;
AveVal PROC
  PUSH EBP
  MOV EBP, ESP
  PUSH ESI
  PUSH EDI

  PUSH EAX						; preserve registers
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
  mDisplayString [EBP+16]
  CALL WriteInt
  CALL CrLf

  POP EDX						; restore registers
  POP EBX
  POP EAX

  POP EDI
  POP ESI
  POP EBP

  RET 12
AveVal ENDP

;---------------------------------------------------;
; Name: EndCredits                                  ;
;                                                   ;
; Display the end credits                           ;
;                                                   ;
; Preconditions: none                               ;
;                                                   ;
; Postconditions: none                              ;
;                                                   ;
; Receives: [EBP+8]     address of credits          ;
;                                                   ;
; Returns: none                                     ;
;---------------------------------------------------;
endCredits PROC
  PUSH EBP
  MOV EBP, ESP

  CALL CrLf
  mDisplayString [EBP+8]
  CALL CrLf

  POP EBP

  RET 4
endCredits ENDP

END main
