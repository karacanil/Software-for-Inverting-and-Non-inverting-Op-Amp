;########################################################################
;# Project Name: Design Software for Inverting and Non-inverting Op-Amp #                                           #
;# Author: Anýl Karaca                                                  #                                                  #
;########################################################################

org 100h
JMP start

;Define messages
welcome1: DB "%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%",0Dh,0Ah,'$'
welcome2: DB "%%%%%%%%%%%%%%%%%%  WELCOME  %%%%%%%%%%%%%%%%%%%%",0Dh,0Ah,'$'

input: DB 0Dh,0Ah,"Please select one of the calculations above:",0Dh,0Ah,'$'

aMsg: DB 0Dh,0Ah,"(a/A)Calculate R1/R2 ratio using the gain of the non-inverting Op-Amp",0Dh,0Ah,'$'
bMsg: DB "(b/B)Calculate R1/R2 ratio using the gain of the inverting Op-Amp",0Dh,0Ah,'$'
cMsg: DB "(c/C)Calculate Gain using the R1, R2 values of the non-inverting Op-Amp",0Dh,0Ah,'$'
dMsg: DB "(d/D)Calculate Gain using the R1, R2 values of the inverting Op-Amp",0Dh,0Ah,'$'

promptR1: DB 0Dh,0Ah,"Please enter the value of R1(kOhms)(Max=65535):",0Dh,0Ah,'$'
promptR2: DB 0Dh,0Ah,"Please enter the value of R2(kOhms)(Max=65535):",0Dh,0Ah,'$'

promptGain: DB 0Dh,0Ah,"Please enter the value of the A(Gain)(Max=65535):",0Dh,0Ah,'$'
promptKey: DB 0Dh,0Ah,"(Press any key to plot the circuit)",'$' 

resultRatio: DB 0Dh,0Ah,"The R1/R2 ratio for non-inverting op-amp is:",0Dh,0Ah,'$'
resultGain: DB 0Dh,0Ah,"The gain value(A) for non-inverting op-amp is:",0Dh,0Ah,'$'

resultRatioInv: DB 0Dh,0Ah,"The R1/R2 ratio for inverting op-amp is:",0Dh,0Ah,'$'
resultGainInv: DB 0Dh,0Ah,"The gain value(A) for inverting op-amp is:",0Dh,0Ah,'$'

resultR1: DB 0Dh,0Ah,"So you can select R1 to be:1kOhms",0Dh,0Ah,'$'
resultR2: DB "So you can select R2 to be:",'$'
kohms: DB "kOhms",'$'

esc: DB 0Dh,0Ah,"'ESC' key is pressed, terminating...",0Dh,0Ah,'$' 

;Variables to store the values
R1 DB 5 DUP(?)
R2 DB 5 DUP(?)
Gain DB 5 DUP(?)
GainMinusOne DB 5 DUP(?)

;Variables to store length
lenR1 DW ?
lenR2 DW ?
lenA DW ?

;Flags
dotFlag DB 0 ;1 if dot is present and 0 if not
invGainFlag DB 0 ;1 for gain calculations for inverting and 0 for non-inverting
escFlag DB 0 ;1 if "ESC" key is pressed

;Variables for division
result DW ?
remainder DW ?
afterPoint DB ?
afterPoint2 DB ?

;Ten
ten DW 10

;######################### MACROS ###########################
;Prints the given message on the screen
print MACRO msg
    MOV DX, msg
    MOV AH, 9h
    INT 21h
ENDM

printVideo MACRO char
    MOV AL, char
    MOV AH, 09h
    INT 10h
ENDM

;Print the given character on the screen
PUTC MACRO char
    MOV AL, char
    MOV AH, 0Eh
    INT 10h
ENDM

;This macro prints the char1 and char2
;on the given x, y coordinates of the screen
label MACRO x, y, char1, char2
    MOV BL, 10 ;Set the color
    MOV AH, 02h    
    ;Assign position
    MOV DL, x
    MOV DH, y
    INT 10h
    
    ;Print char1
    MOV AL, char1
    MOV AH, 09h
    MOV CX, 1
    INT 10h
    
    MOV AH, 02h
    INC DL
    INT 10h
    
    ;Print char2
    MOV AL, char2
    MOV AH, 09h
    INT 10h
ENDM

;Labels R1 and R2 on the plotted circuitry for option a/A
labelA MACRO x1, y1, x2, y2
    LOCAL printR2_A, skipAdd_A, printDoneR2_A
    ;#####################   R1   #####################
    MOV BL, 10 ;Set the color
    MOV AH, 02h    
    ;Assign position
    MOV DL, x1
    MOV DH, y1
    INT 10h
    
    MOV CX, 1d
    ;Print "="
    printVideo "="
    
    MOV AH, 02h
    INC DL
    INT 10h
    
    ;Print "1"
    printVideo "1"
    
    MOV AH, 02h
    INC DL
    INT 10h
    
    ;Print "k"
    printVideo "k"
    ;#####################   R2   #####################
    MOV AH, 02h
    MOV DL, x2
    MOV DH, y2
    INT 10h
    
    MOV CX, 1d
    ;Print "="
    printVideo "="
    
    MOV AH, 02h
    INC DL
    INT 10h
    
    MOV SI, 0
    printR2_A: ;Keep printing until either when SI=5 or when we encounter '$'
    CMP SI, 5d
    JZ printDoneR2_A
    CMP b.GainMinusOne[SI], 0
    JZ skipPrint_A
    CMP b.GainMinusOne[SI], "$"
    JZ printDoneR2_A
    CMP b.GainMinusOne[SI], "."
    JZ skipAdd_A
    ADD b.GainMinusOne[SI], 30h
    skipAdd_A:
    printVideo b.GainMinusOne[SI]
    
    MOV AH, 02h
    INC DL
    INT 10h
    INC SI
    JMP printR2_A 
    
    skipPrint_A:
    INC SI
    JMP printR2_A 
    
    printDoneR2_A:
    ;Print "k"
    printVideo "k"    
ENDM

;Labels R1 and R2 on the plotted circuitry for option b/B
labelB MACRO x1, y1, x2, y2
    LOCAL printR2_B, skipAdd_B, printDoneR2_B   
    ;#####################   R1   #####################
    MOV BL, 10 ;Set the color
    MOV AH, 02h    
    ;Assign position
    MOV DL, x1
    MOV DH, y1
    INT 10h
    
    MOV CX, 1d
    ;Print "="
    printVideo "="
    
    MOV AH, 02h
    INC DL
    INT 10h
    
    ;Print "1"
    printVideo "1"
    
    MOV AH, 02h
    INC DL
    INT 10h
    
    ;Print "k"
    printVideo "k"    
    ;#####################   R2   #####################
    MOV AH, 02h
    MOV DL, x2
    MOV DH, y2
    INT 10h
    
    MOV CX, 1d
    ;Print "="
    printVideo "="
    
    MOV AH, 02h
    INC DL
    INT 10h
    
    MOV SI, 0
    printR2_B: ;Keep printing until either when SI=5 or when we encounter '$'
    CMP SI, 5d
    JZ printDoneR2_B
    CMP b.Gain[SI], "$"
    JZ printDoneR2_B
    CMP b.Gain[SI], "."
    JZ skipAdd_B
    ADD b.Gain[SI], 30h
    skipAdd_B:
    printVideo b.Gain[SI]
    
    MOV AH, 02h
    INC DL
    INT 10h
    INC SI
    JMP printR2_B 
   
    printDoneR2_B:
    ;Print "k"
    printVideo "k"
ENDM

;Labels R1 and R2 on the plotted circuitry for option c/C and d/D
labelCD MACRO x1, y1, x2, y2
    LOCAL printR1_CD, skipAddR1_CD, printDoneR1_CD, printR2_CD, skipAddR2_CD, printDoneR2_CD
    ;#####################   R1   #####################
    MOV BL, 10 ;Set the color
    MOV AH, 02h
    ;Assign position
    MOV DL, x1
    MOV DH, y1
    INT 10h
    
    MOV CX, 1d
    ;Print "="
    printVideo "="
    
    MOV AH, 02h
    INC DL
    INT 10h
    
    MOV SI, 0
    printR1_CD: ;Keep printing until either when SI=5 or when we encounter '$'
    CMP SI, 5d
    JZ printDoneR1_CD
    CMP b.R1[SI], "$"
    JZ printDoneR1_CD
    CMP b.R1[SI], "."
    JZ skipAddR1_CD
    ADD b.R1[SI], 30h
    skipAddR1_CD:
    printVideo b.R1[SI]
    
    MOV AH, 02h
    INC DL
    INT 10h
    INC SI
    JMP printR1_CD 
   
    printDoneR1_CD:
    ;Print "k"
    printVideo "k"    
    ;#####################   R2   #####################
    MOV AH, 02h
    MOV DL, x2
    MOV DH, y2
    INT 10h
    
    MOV CX, 1d
    ;Print "="
    printVideo "="
    
    MOV AH, 02h
    INC DL
    INT 10h
    
    MOV SI, 0
    printR2_CD: ;Keep printing until either when SI=5 or when we encounter '$'
    CMP SI, 5d
    JZ printDoneR2_CD
    CMP b.R2[SI], "$"
    JZ printDoneR2_CD
    CMP b.R2[SI], "."
    JZ skipAddR2_CD
    ADD b.R2[SI], 30h
    skipAddR2_CD:
    printVideo b.R2[SI]
    
    MOV AH, 02h
    INC DL
    INT 10h
    INC SI
    JMP printR2_CD 
   
    printDoneR2_CD:
    ;Print "k"
    printVideo "k"
ENDM

;######################### PROCEDURES #######################
;a/A
resistanceNonInverting PROC
    CALL getInputGain
    
    CMP escFlag, 1d ;Check if 'ESC' was pressed in 'getInputGain'
    JZ escA
    
    CALL formatGain
    DEC SI ;Decrement gain A by 1
    
    ;Call a procedure to store A-1 in an array
    ;so I can use it for printing purposes later on
    CALL formatResult
    
    CALL calculateRatio ;Calculate R1/R2 ratio
    
    print resultRatio
    
    MOV AX, result
    CALL printResult ;Print the integer part of the result
    
    ;Print dot to separte the integer and the floating part
    PUTC '.'
    
    ;Print the floating part of the result
    MOV AL, afterPoint
    ADD AL, 30h
    PUTC AL
    
    MOV AL, afterPoint2
    ADD AL, 30h
    PUTC AL
    
    print resultR1
    print resultR2
    MOV AX, SI
    CALL printResult
    print kohms
    
    print promptKey ;Press any key
    
    ;Check press any key
    MOV AH, 00h
    INT 16h
    
    CMP AL, 01Bh ;Check if 'ESC' is pressed
    JZ escA
    
    ;Open a new screen to plot the circuit
    MOV CX, 0d
    MOV AH, 00
    MOV AL, 12h
    INT 10h    
    INT 10h
    
    ;Label the circuitry
    MOV BH, 0
    label 23, 29, "V", "i"
    label 29, 40, "R", "1"
    label 35, 21, "R", "2"
    label 52, 31, "V", "o"
    label 35, 28, "U", "1"
    labelA 31, 40, 37, 21
    
    ;Draw non-inverting op-amp circuitry on the screen
    CALL drawNonInverting
    JMP terminateA
    
    escA:
    MOV escFlag, 1d ;Set the escFlag

terminateA:        
RET
resistanceNonInverting ENDP

;b/B
resistanceInverting PROC
    MOV invGainFlag, 1d
    CALL getInputGain
    
    CMP escFlag, 1d ;Check if 'ESC' was pressed in 'getInputGain'
    JZ escB
    
    CALL formatGain    
    CALL calculateRatio ;Calculate R1/R2 ratio
    
    print resultRatioInv
    
    MOV AX, result
    CALL printResult ;Print the integer part of the result
    
    ;Print dot to separte the integer and the floating part
    PUTC '.'
    
    ;Print the floating part of the result
    MOV AL, afterPoint
    ADD AL, 30h
    PUTC AL
    
    MOV AL, afterPoint2
    ADD AL, 30h
    PUTC AL
    
    print resultR1
    print resultR2
    MOV AX, SI
    CALL printResult
    print kohms
    
    print promptKey ;Press any key
    
    ;Check press any key
    MOV AH, 00h
    INT 16h
    
    CMP AL, 01Bh ;Check if 'ESC' is pressed
    JZ escB
    
    ;Open a new screen to plot the circuit
    MOV CX, 0d
    MOV AH, 00
    MOV AL, 12h
    INT 10h    
    INT 10h
    
    ;Label the circuitry
    MOV BH, 0
    label 18, 29, "V", "i"
    label 23, 28, "R", "1"
    label 37, 18, "R", "2"
    label 54, 28, "V", "o"
    label 31, 36, "R", "C"
    label 36, 26, "U", "1"
    labelB 25, 28, 39, 18
    
    ;Draw inverting op-amp circuitry on the screen
    CALL drawInverting
    JMP terminateB
    
    escB:
    print esc
    MOV escFlag, 1d ;Set the escFlag

terminateB: 
RET
resistanceInverting ENDP
    
;c/C
gainNonInverting PROC
    CALL getInputResistor
    
    CMP escFlag, 1d ;Check if 'ESC' was pressed in 'getInputResistor'
    JZ escC
    
    CALL formatResistor
    CALL calculateGain ;Calculate A
    INC result ;Add 1 to the R2/R1 ratio
    
    print resultGain
    
    MOV AX, result
    CALL printResult ;Print the integer part of the result
    
    ;Print dot to separte the integer and the floating part
    PUTC '.'
    
    ;Print the floating part of the result
    MOV AL, afterPoint
    ADD AL, 30h
    PUTC AL
    
    MOV AL, afterPoint2
    ADD AL, 30h
    PUTC AL
    
    print promptKey ;Press any key
    
    ;Check press any key
    MOV AH, 00h
    INT 16h
    
    CMP AL, 01Bh ;Check if 'ESC' is pressed
    JZ escC
    
    ;Open a new screen to plot the circuit
    MOV CX, 0d
    MOV AH, 00
    MOV AL, 12h
    INT 10h    
    INT 10h
    
    ;Label the circuitry
    MOV BH, 0
    label 23, 29, "V", "i"
    label 29, 40, "R", "1"
    label 35, 21, "R", "2"
    label 52, 31, "V", "o"
    label 35, 28, "U", "1"
    labelCD 31, 40, 37, 21
    
    ;Draw non-inverting op-amp circuitry on the screen
    CALL drawNonInverting
    JMP terminateC    
    
    escC:
    print esc
    MOV escFlag, 1d ;Set the escFlag

terminateC:
RET
gainNonInverting ENDP

;d/D
gainInverting PROC
    CALL getInputResistor
    
    CMP escFlag, 1d ;Check if 'ESC' was pressed in 'getInputResistor'
    JZ escD
    
    CALL formatResistor    
    CALL calculateGain ;Calculate A
    
    print resultGainInv
     
    ;Print minus sign since we are dealing with inverting op-amp
    PUTC '-'
    MOV AX, result
    CALL printResult ;Print the integer part of the result
    
    ;Print dot to separte the integer and the floating part
    PUTC '.'
    
    ;Print the floating part of the result
    MOV AL, afterPoint
    ADD AL, 30h
    PUTC AL
    
    MOV AL, afterPoint2
    ADD AL, 30h
    PUTC AL
    
    print promptKey ;Press any key
    
    ;Check press any key
    MOV AH, 00h
    INT 16h
    
    CMP AL, 01Bh ;Check if 'ESC' is pressed
    JZ escD
    
    ;Open a new screen to plot the circuit
    MOV CX, 0d
    MOV AH, 00
    MOV AL, 12h
    INT 10h    
    INT 10h
    
    ;Label the circuitry
    MOV BH, 0
    label 18, 29, "V", "i"
    label 23, 31, "R", "1"
    label 37, 18, "R", "2"
    label 54, 28, "V", "o"
    label 31, 36, "R", "C"
    label 36, 26, "U", "1"
    labelCD 25, 31, 39, 18
    
    ;Draw inverting op-amp circuitry on the screen
    CALL drawInverting
    JMP terminateD    
    
    escD:
    print esc
    MOV escFlag, 1d ;Set the escFlag

terminateD:         
RET
gainInverting ENDP

;###########################################
;Procedures for making calculations

;Calculates gain(A) by using R1 and R2 values
;in "result.afterPoint afterPoint2" format
calculateGain PROC
    ;################# result and afterPoint ####################
    MOV DX, 0 ;Reset DX
    MOV AX, DI ;Assign R2 to AX    
    DIV SI ;Remainder->DX, Result->AX
    
    MOV result, AX ;Store the result(Integer part)
    MOV remainder, DX
    
    MOV DX, 0
    MOV BX, ten
    
    MOV AX, remainder
    MUL BX ;Result->AX
    
    DIV SI ;Remainder->DX, Result->AX
    MOV afterPoint, AL 
    
    ;####################### afterPoint2 ########################
    MOV AX, DX
    MUL BX ;Result->AX
    
    DIV SI
    MOV afterPoint2, AL            
RET
calculateGain ENDP

;Calculates R1/R2 ratio by using the given gain(A) value
;in "result.afterPoint afterPoint2" format
calculateRatio PROC
    ;################# result and afterPoint ####################
    MOV DX, 0 ;Reset DX
    MOV AX, 1d ;Assign 1 to AX    
    DIV SI ;Remainder->DX, Result->AX
    
    MOV result, AX ;Store the result(Integer part)
    MOV remainder, DX
    
    MOV DX, 0
    MOV BX, ten
    
    MOV AX, remainder
    MUL BX ;Result->AX
    
    DIV SI ;Remainder->DX, Result->AX
    MOV afterPoint, AL 
    
    ;####################### afterPoint2 ########################
    MOV AX, DX
    MUL BX ;Result->AX
    
    DIV SI
    MOV afterPoint2, AL            
RET
calculateRatio ENDP

;###############################################################
;Procedures for printing the resulting numbers on the screen
;Prints the number in AX
;Allowed values are from 0 to 65535(FFFF)
printResult PROC NEAR
        ;Flag to prevent printing zeros before number
        MOV CX, 1d
        ;(result of "/ 10000" is always less or equal to 9)
        MOV BX, 10000d ;2710h - divider

        CMP AX, 0 ;Check if AX is zero
        JZ print_zero
        begin_print:
        ;Check divider
        CMP BX,0
        JZ end_print

        ;Avoid printing zeros before number
        CMP CX, 0
        JE calc
        
        ;If AX<BX then result of DIV will be zero
        CMP AX, BX
        JB skip
        calc:
        MOV CX, 0 ;Set flag
        MOV DX, 0
        DIV BX ;Remainder->DX, Result->AX

        ;Print last digit
        ;AH is always zero, ignore it
        ADD AL, 30h ;Convert to ASCII code
        PUTC AL
        MOV AX, DX ;Get remainder from last div
        skip:
        ;Calculate BX=BX/10
        PUSH AX
        MOV DX, 0
        MOV AX, BX
        DIV ten  ;Remainder->DX, Result->AX
        MOV BX, AX
        POP AX
        JMP begin_print
        print_zero:
        PUTC    '0'
end_print:
RET
printResult ENDP

;#####################################
;Procedures for getting inputs
;Gets the menu input form the user
getInputMenu PROC
    ;########################## MENU ############################
    inputMenu:
    MOV AH, 00h ;Get input from keyboard
    INT 16h
    
    CMP AL, 01Bh ;Check if 'ESC' was pressed
    JZ escMenu
    
    ;Check if the entered character is valid
    CMP AL, 'A'
    JB inputMenu
    
    CMP AL, 'D'
    JBE valid
    
    CMP AL, 'd'
    JA inputMenu
    
    CMP AL, 'a'
    JAE valid
    
    JMP inputMenu
     
    valid:
    MOV AH, 0Eh ;Print input on the screen 
    INT 10h
    
    MOV BL, AL ;Store the input
    
    waitEnter:
    MOV AH, 00h ;Get input from keyboard
    INT 16h
    
    CMP AL, 01Bh ;Check if 'ESC' was pressed
    JZ escMenu 
    
    CMP AL, 08h ;Check backspace
    JZ delInput
    
    CMP AL, 0Dh ;Check enter
    JZ endInput
    
    JMP waitEnter
    
    delInput: ;Delete input
    PUTC 8
    PUTC ' '
    PUTC 8
    MOV BL, 0
    JMP inputMenu
    
    escMenu:
    print esc
    MOV escFlag, 1d ;Set the escFlag
    
endInput:
RET
getInputMenu ENDP

getInputResistor PROC
    ;########################## R1 ##############################
    MOV dotFlag, 0
    MOV SI, 0 ;Initialize digit counter    
    print promptR1
    inputR1:
    MOV AH, 00h ;Get input from keyboard
    INT 16h
    
    CMP SI, 5d ;Check if SI is 5 and storage is full
    JZ full1
    
    CMP AL, '0' ;Check if the input is '0'
    JZ firstDigitR1 
    
    CMP AL, 01Bh ;Check if 'ESC' key was pressed
    JZ escResistor
    
    CMP AL, 08h ;Check backspace
    JZ delInput1
    
    CMP AL, 0Dh ;Check enter
    JZ endInputR1
        
    CMP AL, '.' ;Check dot "."
    JZ dotFlag1
    
    ;Check if it is a valid digit
    CMP AL, '0'
    JB inputR1
    
    CMP AL, '9'
    JA inputR1   
    
    continue1:    
    MOV AH, 0Eh ;Print input on the screen 
    INT 10h
        
    ;Store the digit in a variable
    CMP AL, '.'
    JZ dot1
    SUB AL, 30h
    dot1:
    MOV b.R1[SI], AL
    INC SI    
    JMP inputR1
    
    ;Delete the last character on the screen
    delInput1:
    CMP SI, 0d ;Check if there is anything to delete
    JZ inputR1
    PUTC 8
    PUTC ' '
    PUTC 8
    DEC SI
    CMP R1[SI], '.'
    JZ resetFlag1
    resetFlagDone1:
    MOV b.R1[SI], 0
    JMP inputR1
    
    endInputR1: ;End input process
    CMP SI, 0d
    JZ inputR1
    JMP checkEnterR1
    checkedEnterR1: 
    CMP dotFlag, 1 ;Check if we have already stored the length
    JZ skip1
    MOV lenR1, SI ;Store the length if there is no dot
    skip1:
    CMP SI, 5d
    JZ doneR1 
    MOV b.R1[SI], '$'
    JMP doneR1
    
    checkEnterR1: ;Check "enter" key
    CMP SI, 1d
    JZ checkDotR1
    JMP checkedEnterR1
    checkDotR1:
    CMP b.R1[0], '.'
    JZ inputR1
    JMP checkedEnterR1 
    
    dotFlag1: ;Set the dotFlag
    CMP SI, 0d ;If the first input char is '.' don't allow it
    JZ inputR1 
    CMP dotFlag, 1
    JZ inputR1
    MOV dotFlag, 1
    ;Store the length before the dot in BL
    MOV lenR1, SI
    JMP continue1
    
    resetFlag1: ;Reset the dotFlag
    MOV dotFlag, 0
    MOV lenR1, 0
    JMP resetFlagDone1
    
    full1: ;If variables are full
    CMP AL, 0Dh ;Check enter
    JZ endInputR1
    CMP AL, 08h ;Check backspace
    JZ delInput1
    MOV AH, 00h ;Get input from keyboard
    INT 16h
    
    CMP AL, 01Bh ;Check if 'ESC' was pressed
    JZ escResistor
    
    CMP SI, 5d ;Check if the storage is still full
    JZ full1 
    JMP inputR1
    
    firstDigitR1: ;Check if the first input character was '0'
    CMP SI, 0d ;If the first input char is '0' don't allow it
    JZ inputR1
    JMP continue1  
        
    doneR1:    
    ;########################## R2 ##############################
    MOV dotFlag, 0
    MOV SI, 0 ;Initialize digit counter    
    print promptR2
    inputR2:
    MOV AH, 00h ;Get input from keyboard
    INT 16h
    
    CMP SI, 5d ;Check if SI is 5 and storage is full
    JZ full2
    
    CMP AL, '0' ;Check if the input is '0'
    JZ firstDigitR2
    
    CMP AL, 01Bh ;Check if 'ESC' key was pressed
    JZ escResistor
    
    CMP AL, 08h ;Check backspace
    JZ delInput2
    
    CMP AL, 0Dh ;Check enter
    JZ endInputR2
        
    CMP AL, '.' ;Check dot "."
    JZ dotFlag2
    
    ;Check if it is a valid digit
    CMP AL, '0'
    JB inputR2
    
    CMP AL, '9'
    JA inputR2   
    
    continue2:    
    MOV AH, 0Eh ;Print input on the screen 
    INT 10h
        
    ;Store the digit in a variable
    CMP AL, '.'
    JZ dot2
    SUB AL, 30h
    dot2:
    MOV b.R2[SI], AL
    INC SI    
    JMP inputR2
    
    ;Delete the last character on the screen
    delInput2:
    CMP SI, 0d ;Check if there is anything to delete
    JZ inputR2
    PUTC 8
    PUTC ' '
    PUTC 8
    DEC SI
    CMP R2[SI], '.'
    JZ resetFlag2
    resetFlagDone2:
    MOV b.R2[SI], 0
    JMP inputR2
    
    endInputR2: ;End input process
    CMP SI, 0d
    JZ inputR2
    JMP checkEnterR2
    checkedEnterR2:
    CMP dotFlag, 1 ;Check if we have already stored the length
    JZ skip2
    MOV lenR2, SI ;Store the length if there is no dot
    skip2:
    CMP SI, 5d
    JZ doneR2 
    MOV b.R2[SI], '$'
    JMP doneR2
    
    checkEnterR2: ;Check "enter" key
    CMP SI, 1d
    JZ checkDotR2
    JMP checkedEnterR2
    checkDotR2:
    CMP b.R2[0], '.'
    JZ inputR2
    JMP checkedEnterR2
    
    dotFlag2: ;Set the dotFlag
    CMP SI, 0d ;If the first input char is '.' don't allow it
    JZ inputR2
    CMP dotFlag, 1
    JZ inputR2
    MOV dotFlag, 1
    ;Store the length before the dot in BL
    MOV lenR2, SI
    JMP continue2
    
    resetFlag2: ;Reset the dotFlag
    MOV dotFlag, 0
    MOV lenR2, 0
    JMP resetFlagDone2
    
    full2: ;If variables are full
    CMP AL, 0Dh ;Check enter
    JZ endInputR2
    CMP AL, 08h ;Check backspace
    JZ delInput2
    MOV AH, 00h ;Get input from keyboard
    INT 16h
    
    CMP AL, 01Bh ;Check if 'ESC' was pressed
    JZ escResistor
    
    CMP SI, 5d ;Check if the storage is still full
    JZ full2 
    JMP inputR2
    
    firstDigitR2: ;Check if the first input character was '0'
    CMP SI, 0d ;If the first input char is '0' don't allow it
    JZ inputR2
    JMP continue2
        
    escResistor:
    MOV escFlag, 1d ;Set the escFlag
        
doneR2:        
RET
getInputResistor ENDP

getInputGain PROC
    ;##########################  A  #############################       
    MOV dotFlag, 0
    MOV SI, 0 ;Initialize digit counter    
    print promptGain
    
    CMP invGainFlag, 1d
    JNZ inputA
    MOV AL, "-"
    MOV AH, 0Eh ;Print "-" on the screen 
    INT 10h
    
    inputA:
    MOV AH, 00h ;Get input from keyboard
    INT 16h
    
    CMP SI, 5d ;Check if SI is 5 and storage is full
    JZ full3
    
    CMP AL, '0' ;Check if the input is '0'
    JZ firstDigitA
    
    CMP AL, 01Bh ;Check if 'ESC' key was pressed
    JZ escGain
    
    CMP AL, 08h ;Check backspace
    JZ delInput3
    
    CMP AL, 0Dh ;Check enter
    JZ endInputA
    
    CMP AL, '.' ;Check dot "."
    JZ dotFlag3
    
    ;Check if it is a valid digit
    CMP AL, '0'
    JB inputA
    
    CMP AL, '9'
    JA inputA   
    
    continue3:    
    MOV AH, 0Eh ;Print input on the screen 
    INT 10h
        
    ;Store the digit in a variable
    CMP AL, '.'
    JZ dot3
    SUB AL, 30h
    dot3:
    MOV b.Gain[SI], AL
    INC SI    
    JMP inputA
    
    ;Delete the last character on the screen
    delInput3:
    CMP SI, 0d ;Check if there is anything to delete
    JZ inputA 
    PUTC 8
    PUTC ' '
    PUTC 8
    DEC SI
    CMP Gain[SI], '.'
    JZ resetFlag3
    resetFlagDone3:
    MOV b.Gain[SI], 0
    JMP inputA
    
    endInputA: ;End input process
    CMP SI, 0d
    JZ inputA
    JMP checkEnterA
    checkedEnterA:
    CMP SI, 0d
    JZ inputA
    CMP dotFlag, 1 ;Check if we have already stored the length
    JZ skip3
    MOV lenA, SI ;Store the length if there is no dot
    skip3:
    CMP SI, 5d
    JZ doneA 
    MOV b.Gain[SI], '$'
    JMP doneA
    
    checkEnterA: ;Check "enter" key
    CMP SI, 1d
    JZ checkDotA
    JMP checkedEnterA
    checkDotA:
    CMP b.Gain[0], '.'
    JZ inputA
    JMP checkedEnterA
    
    dotFlag3: ;Set the dotFlag
    CMP SI, 0d ;If the first input char is '.' don't allow it
    JZ inputA
    CMP dotFlag, 1
    JZ inputA
    MOV dotFlag, 1
    ;Store the length before the dot in BL
    MOV lenA, SI
    JMP continue3
    
    resetFlag3: ;Reset the dotFlag
    MOV dotFlag, 0
    MOV lenA, 0
    JMP resetFlagDone3
    
    full3: ;If variables are full
    CMP AL, 0Dh ;Check enter
    JZ endInputA
    CMP AL, 08h ;Check backspace
    JZ delInput3
    MOV AH, 00h ;Get input from keyboard
    INT 16h
    
    CMP AL, 01Bh ;Check if 'ESC' was pressed
    JZ escGain
    
    CMP SI, 5d ;Check if the storage is still full
    JZ full3 
    JMP inputA 
    
    firstDigitA: ;Check if the first input character was '0'
    CMP SI, 0d ;If the first input char is '0' don't allow it
    JZ inputA
    JMP continue3
    
    escGain:
    print esc
    MOV escFlag, 1d ;Set the escFlag        
doneA:   
RET
getInputGain ENDP

;#####################################
;Procedures for formating inputs

;#########
;#R2<->DI#
;#R1<->SI#
;#########

;########
;#A<->SI#
;########

;Procedure for formating resistor inputs
formatResistor PROC
    ;########################## R1 ##############################
    MOV BP, 0 ;Initialize BP which I'll use the arrays R1,R2 and A
    MOV DX, 0 ;DX will hold the value temporarily
    formatR1:
    CMP BP, lenR1 ;Check if we are done formatting
    JZ doneFormatR1
    
    ;CX will control the loop to calculate 10^x
    ;Initialize CX
    MOV CX, lenR1 
    SUB CX, BP
    DEC CX
    
    CMP CX, 0
    JZ doneFormatR1
    
    ;Calculate 10^x
    MOV AX, 1d
    MOV BX, ten
    multiplyR1:
    PUSH DX
    MUL BX
    POP DX
    LOOP multiplyR1
    
    PUSH DX
    ;MUL R1[BP] ;AX = AX * R1[BP]
    MOV BX, 0
    MOV BL, R1[BP]
    MUL BX
    POP DX
    ADD DX, AX
    
    INC BP
    JMP formatR1
           
    doneFormatR1: ;End formatting R1
    MOV AX, 0
    MOV AL, R1[BP]
    ADD DX, AX
    MOV SI, DX

    ;########################## R2 ##############################
    MOV BP, 0 ;Initialize BP which I'll use the arrays R1,R2 and A
    MOV DX, 0 ;DX will hold the value temporarily
    formatR2:
    CMP BP, lenR2 ;Check if we are done formatting
    JZ doneFormatR2
    
    ;CX will control the loop to calculate 10^x
    ;Initialize CX
    MOV CX, lenR2 
    SUB CX, BP
    DEC CX
    
    CMP CX, 0
    JZ doneFormatR2
    
    ;Calculate 10^x
    MOV AX, 1d
    MOV BX, ten
    multiplyR2:
    PUSH DX
    MUL BX
    POP DX
    LOOP multiplyR2
    
    PUSH DX
    ;MUL R1[BP] ;AX = AX * R1[BP]
    MOV BX, 0
    MOV BL, R2[BP]
    MUL BX
    POP DX
    ADD DX, AX
    
    INC BP
    JMP formatR2
           
    doneFormatR2: ;End formatting R2
    MOV AX, 0
    MOV AL, R2[BP]
    ADD DX, AX
    MOV DI, DX    
RET
formatResistor ENDP

;Procedure for formating gain inputs
formatGain PROC
    ;##########################  A  #############################
    MOV BP, 0 ;Initialize BP which I'll use the arrays R1,R2 and A
    MOV DX, 0 ;DX will hold the value temporarily
    formatA:
    CMP BP, lenA ;Check if we are done formatting
    JZ doneFormatA
    
    ;CX will control the loop to calculate 10^x
    ;Initialize CX
    MOV CX, lenA 
    SUB CX, BP
    DEC CX
    
    CMP CX, 0
    JZ doneFormatA
    
    ;Calculate 10^x
    MOV AX, 1d
    MOV BX, ten
    multiplyA:
    PUSH DX
    MUL BX
    POP DX
    LOOP multiplyA
    
    PUSH DX
    ;MUL R1[BP] ;AX = AX * R1[BP]
    MOV BX, 0
    MOV BL, Gain[BP]
    MUL BX
    POP DX
    ADD DX, AX
    
    INC BP
    JMP formatA
           
    doneFormatA: ;End formatting A
    MOV AX, 0
    MOV AL, Gain[BP]
    ADD DX, AX
    MOV SI, DX     
RET
formatGain ENDP

;This procedure stores the result of the operation a/A
;in an array so I can use it later to print it on the
;screen in video mode
formatResult PROC
    MOV DX, 0 ;Reset DX so it won't effect division
    MOV BX, 4d ;BX will hold the index of the array
    MOV AX, SI
    
    CMP lenA, 1d ;Check if the number is single digit
    JZ oneDigit
    
    MOV CX, lenA
    DEC CX ;CX=Number of times to divide    
        
    keepDividing:
    DIV ten ;Remainder is the right most digit of the number 
    MOV GainMinusOne[BX], DL
    DEC BX
    MOV DX, 0 ;;Reset DX so it won't effect division
    LOOP keepDividing
    MOV GainMinusOne[BX], AL
    JMP terminateFormat 
    
    oneDigit:
    MOV GainMinusOne[BX], AL    
terminateFormat:
RET
formatResult ENDP

;####################################################
;Procedures for changing the colors of the pixels
;in different directions

;This procedures keep looping until
;the end point SI is reached     
right PROC
    loop1:
    ;Change the color of the pixel
    ;(CX,DX)
    MOV AH, 0Ch 
    INT 10h
    
    INC CX
    CMP CX, SI ;Check if we are done
    JNZ loop1
RET
right ENDP

left PROC
    loop2:
    ;Change the color of the pixel
    ;(CX,DX)
    MOV AH, 0Ch 
    INT 10h
    
    DEC CX
    CMP CX, SI ;Check if we are done
    JNZ loop2
RET
left ENDP

up PROC
    loop3:
    ;Change the color of the pixel
    ;(CX,DX)
    MOV AH, 0Ch 
    INT 10h
    
    DEC DX
    CMP DX, SI ;Check if we are done
    JNZ loop3
RET
up ENDP

down PROC
    loop4:
    ;Change the color of the pixel
    ;(CX,DX)
    MOV AH, 0Ch 
    INT 10h
    
    INC DX
    CMP DX, SI ;Check if we are done
    JNZ loop4
RET
down ENDP

upRight PROC
    loop5:
    ;Change the color of the pixel
    ;(CX,DX)
    MOV AH, 0Ch
    INT 10h
    
    INC CX
    DEC DX
    CMP DX, SI ;Check if we are done
    JNZ loop5
RET
upRight ENDP

downRight PROC
    loop6:
    ;Change the color of the pixel
    ;(CX,DX)
    MOV AH, 0Ch
    INT 10h
    
    INC CX
    INC DX
    CMP DX, SI ;Check if we are done
    JNZ loop6
RET
downRight ENDP

upLeft PROC
    loop7:
    ;Change the color of the pixel
    ;(CX,DX)
    MOV AH, 0Ch 
    INT 10h
    
    DEC CX
    DEC DX
    CMP CX, SI ;Check if we are done
    JNZ loop7
RET
upLeft ENDP

downLeft PROC
    loop8:
    ;Change the color of the pixel
    ;(CX,DX)
    MOV AH, 0Ch
    INT 10h
    
    DEC CX
    INC DX
    CMP DX, SI ;Check if we are done
    JNZ loop8
RET
downLeft ENDP

;###########################################
;Procedures for drawing circuits

;This procedure creates a ground
;consisting of 3 lines which are
;aligned vertically
ground PROC
    MOV SI, CX
    SUB SI, 10d    
    CALL left
    
    ADD CX, 10d
    MOV SI, CX
    ADD SI, 10d    
    CALL right
    
    SUB CX, 10d
    ADD DX, 3d    
    MOV SI, CX
    SUB SI, 7d    
    CALL left
    
    ADD CX, 7d
    MOV SI, CX
    ADD SI, 7d    
    CALL right
    
    SUB CX, 7d
    ADD DX, 3d    
    MOV SI, CX
    SUB SI, 4d    
    CALL left
    
    ADD CX, 4d
    MOV SI, CX
    ADD SI, 4d    
    CALL right
RET
ground ENDP

;This procedure creates an op-amp
;without "+" and "-" signs
opamp PROC    
    ;Print the upper edge of the op-amp
    MOV SI, CX
    SUB SI, 40d ;Length of the upper edge    
    CALL upLeft
    
    ;Print the left edge of the op-amp
    MOV SI, DX
    ADD SI, 80d ;Length of the left edge    
    CALL down
    
    ;Print the bottom edge of the op-amp
    MOV SI, DX
    SUB SI, 40d ;Length of the bottom edge    
    CALL upRight        
RET
opamp ENDP

;This procedure creates a resistor
resistor PROC
    ;If BL is equal to 1 then print the resistor in a vertically
    ;Otherwise print it horizontally
    CMP BL, 1d
    JZ vertical    
        
    MOV SI, DX ;Set the ending point
    SUB SI, 4d ;4=length of the short edge of the resistor     
    CALL upRight
    
    MOV SI, DX ;Set the ending point
    ADD SI, 8d ;8=length of the long edge of the resistor          
    CALL downRight
    
    MOV SI, DX ;Set the ending point
    SUB SI, 8d    
    CALL upRight
    
    MOV SI, DX ;Set the ending point
    ADD SI, 8d    
    CALL downRight
    
    MOV SI, DX ;Set the ending point
    SUB SI, 4d    
    CALL upRight 
    
    JMP exit
    
    ;################## vertical ###################
    vertical:    
    MOV SI, DX ;Set the ending point
    ADD SI, 4d ;4=length of the short edge of the resistor     
    CALL downRight
    
    MOV SI, DX ;Set the ending point
    ADD SI, 8d ;8=length of the long edge of the resistor          
    CALL downLeft
    
    MOV SI, DX ;Set the ending point
    ADD SI, 8d    
    CALL downRight
    
    MOV SI, DX ;Set the ending point
    ADD SI, 8d    
    CALL downLeft
    
    MOV SI, DX ;Set the ending point
    ADD SI, 4d    
    CALL downRight    
    exit:
RET
resistor ENDP

;This procedure draws an inverting op-amp circuit
drawInverting PROC
    MOV AL, 14d ;Set color to yellow    
    ;Set the starting point
    MOV CX, 160d
    MOV DX, 240d
    ;Set the ending point
    MOV SI, CX
    ADD SI, 20d    
    CALL right
    
    ;Print the R1 resistor
    CALL resistor
    
    ;Set the ending point
    MOV SI, CX
    ADD SI, 20d    
    CALL right
    
    ;Set the ending point
    MOV SI, DX
    SUB SI, 80d    
    CALL up
    
    ;Set the ending point
    MOV SI, CX
    ADD SI, 60d    
    CALL right
    
    ;Print the R2 resistor
    CALL resistor
    
    ;Set the ending point
    MOV SI, CX
    ADD SI, 60d    
    CALL right
    
    ;Set the ending point
    MOV SI, DX
    ADD SI, 70d    
    CALL down
    
    ;Set the ending point
    MOV SI, CX
    ADD SI, 40d    
    CALL right
    
    MOV CX, 384d
    ;Set the ending point
    MOV SI, CX
    SUB SI, 30d    
    CALL left
    ;Print the op-amp on the screen
    CALL opamp
    
    MOV CX, 232d
    MOV DX, 240d
    ;Set the ending point
    MOV SI, 314d   
    CALL right
    ;###########################
    ;Print the "-" of the op-amp
    ADD CX, 4d
    ;Set the ending point
    MOV SI, CX
    ADD SI, 7d
    CALL right
    
    DEC CX
    MOV DX, 220d
    ;###########################
    ;Print the "+" of the op-amp
    ;Set the ending point
    MOV SI, CX
    SUB SI, 7d
    CALL left
    
    ADD CX, 4d
    SUB DX, 3d
    ;Set the ending point
    MOV SI, DX
    ADD SI, 7d
    CALL down
    ;###########################
    SUB DX, 3d
    SUB CX, 8d
    ;Set the ending point
    MOV SI, CX
    SUB SI, 40d
    CALL left
    
    ;Set the ending point
    MOV SI, DX
    ADD SI, 60d
    CALL down
    
    MOV BL, 1d ;BL==1 means print resistor vertically    
    ;Print the RC resistor
    CALL resistor
    
    ;Set the ending point
    MOV SI, DX
    ADD SI, 20d
    CALL down
    ;Print the ground terminal on the screen
    CALL ground        
RET
drawInverting ENDP

;This procedure draws a non-inveting op-amp circuit
drawNonInverting PROC
    MOV AL, 14d ;Set color to yellow    
    ;Set the starting point
    MOV CX, 200d
    MOV DX, 240d
    
    ;Set the ending point
    MOV SI, CX
    ADD SI, 20d
    CALL right
    
    ;Set the ending point
    MOV SI, DX
    ADD SI, 21d
    CALL down
    
    ;Set the ending point
    MOV DX, 240d
    MOV SI, DX
    SUB SI, 50d
    CALL up
    
    ;Set the ending point
    MOV SI, CX
    ADD SI, 60d
    CALL right
    
    ;Print the R2 resistor
    CALL resistor
    
    ;Set the ending point
    MOV SI, CX
    ADD SI, 60d
    CALL right
    
    ;Set the ending point
    MOV SI, DX
    ADD SI, 60d
    CALL down
    
    ;Set the ending point
    MOV SI, CX
    ADD SI, 40d
    CALL right
    
    MOV CX, 372d   
    ;Set the ending point
    MOV SI, CX
    SUB SI, 30d
    CALL left
    
    ;Print the op-amp on the screen
    CALL opamp
    
    MOV CX, 220d
    MOV DX, 240d
    ;Set the ending point
    MOV SI, 302d
    CALL right
    
    ;###########################
    ;Print the "+" of the op-amp
    ADD CX, 4d
    MOV SI, CX
    ADD SI, 7d
    CALL right
    
    SUB CX, 4d
    SUB DX, 3d
    ;Set the ending point
    MOV SI, DX
    ADD SI, 7d
    CALL down
    ;###########################
    ;Print the "-" of the op-amp
    ADD DX, 17d
    SUB CX, 3d
    ;Set the ending point
    MOV SI, CX
    ADD SI, 7d
    CALL right
    ;###########################
    
    SUB CX, 11d
    ;Set the ending point
    MOV SI, 220d
    CALL left
    
    ;Set the ending point
    MOV SI, DX
    ADD SI, 40d
    CALL down
    
    MOV BL, 1d
    
    ;Print the R2 resistor
    CALL resistor
    
    ;Set the ending point
    MOV SI, DX
    ADD SI, 40d
    CALL down
    
    ;Print ground terminal on the screen
    CALL ground    
RET
drawNonInverting ENDP
    
start:
;Print welcome message on the screen
MOV DX, welcome1
MOV AH, 9h
INT 21h
MOV DX, welcome2
INT 21h
MOV DX, welcome1
INT 21h

;Propmpt user to select the operation
print aMsg
print bMsg
print cMsg
print dMsg
print input

err:
CALL getInputMenu

CMP escFlag, 1d ;Check if 'ESC' key was pressed in 'getInputMenu'
JZ terminate

;Analyze the input
CMP BL, 'a'
JZ a    
CMP BL, 'b'
JZ b 
CMP BL, 'c'
JZ c 
CMP BL, 'd'
JZ d

CMP BL, 'A'
JZ a   
CMP BL, 'B'
JZ b 
CMP BL, 'C'
JZ c 
CMP BL, 'D'
JZ d

JMP err

a:
CALL resistanceNonInverting
RET
b:
CALL resistanceInverting
RET
c:
CALL gainNonInverting
RET
d:
CALL gainInverting
RET    

terminate:
ret