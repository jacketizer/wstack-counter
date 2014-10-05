; PICkit 2 Lesson 1 - 'Hello World'
;
#include <p16F690.inc>
	__config (_INTRC_OSC_NOCLKOUT & _WDT_OFF & _PWRTE_OFF & _MCLRE_OFF & _CP_OFF & _BOD_OFF & _IESO_OFF & _FCMEN_OFF)
	
	CBLOCK	0x20 ;start of general purpose registers
Delay1
Delay2
Level
Turner
	ENDC

; LED mappings
DSG	EQU	D'0'
DSF	EQU	D'1'
DSA	EQU	D'2'
DSB	EQU	D'3'
DSE	EQU	D'4'
DSD	EQU	D'5'
DSC	EQU	D'4'

; Hard coded turn point
NSTACK	EQU	D'4'

	org 0
	GOTO	Start
	
; +---------------+
; | DELAY ROUTINE |
; +---------------+
DELAY
	MOVLW	d'4'
	MOVWF	Delay1
	MOVWF	Delay2
Loop1	DECFSZ	Delay1,F
	GOTO	Loop2
	RETURN
Loop2	DECFSZ	Delay2,F
	GOTO	Loop2
	GOTO	Loop1
; - END DELAY -


Start	BCF	STATUS,RP0
	BCF	STATUS,RP1	; Bank 0
	CLRF	PORTA
	CLRF	PORTB
	CLRF	PORTC

	BANKSEL	ANSEL
	CLRF	ANSEL

	BSF	STATUS,RP0
	BCF	STATUS,RP1	; Bank 1

	MOVLW 	b'00000000'
	MOVWF	TRISC		; Set PortC all outputs
	MOVWF	TRISB		; Set PortB all outputs
   	MOVLW 	b'11111111'
	MOVWF	TRISA		; Set PortA all inputs

	BCF	STATUS,RP0	; Bank 0

	CLRF	Turner
	BSF	Turner,0
	SWAPF	Turner,1
	
	CLRF	Level
	GOTO	Check


Check	CALL	ShowLvl
	BTFSS	Turner,0
	GOTO	CheckU
	GOTO	CheckD

; Check up
; --------
CheckU	BTFSS	PORTA,4		; Wait for movement...
	GOTO	CheckU
	CALL	DELAY
	BTFSS	PORTA,4
	GOTO	CheckU
CheckU2	BTFSC	PORTA,4		; Wait for movement...
	GOTO	CheckU2
	CALL	DELAY
	BTFSC	PORTA,4
	GOTO	CheckU2
	GOTO	TickUp

; Check down
; ----------	
CheckD	BTFSC	PORTA,4		; Wait for movement...
	GOTO	CheckD
	CALL	DELAY
	BTFSC	PORTA,4
	GOTO	CheckD
CheckD2	BTFSS	PORTA,4		; Wait for movement...
	GOTO	CheckD2
	CALL	DELAY
	BTFSS	PORTA,4
	GOTO	CheckD2
	GOTO	TickDown

; Tick Up
; -------
TickUp	INCF	Level,1
	MOVF	Level,0		; Move Level to W
	XORLW	NSTACK
	BTFSC	STATUS,Z
	CALL	Turn
	GOTO	Check
	
; Tick Down
; ---------
TickDown
	DECFSZ	Level,1
	GOTO	Check
	CALL	Turn
	GOTO	Check

Turn	SWAPF	Turner,1
	RETURN

; Display the Level reg. 
; ----------------------
ShowLvl	CLRF	PORTC		; Clear display
	CLRF	PORTB
	MOVF	Level,0		; Test: 4
	XORLW	D'4'
	BTFSC	STATUS,Z
	GOTO	Show4
	MOVF	Level,0		; Test: 3
	XORLW	D'3'
	BTFSC	STATUS,Z
	GOTO	Show3
	MOVF	Level,0		; Test: 2
	XORLW	D'2'
	BTFSC	STATUS,Z
	GOTO	Show2
	MOVF	Level,0		; Test: 1
	XORLW	D'1'
	BTFSC	STATUS,Z
	GOTO	Show1
	GOTO	Show0		; Show 0
ShowLvlRet
	RETURN

; Show numbers
; ------------
ShowN	CLRF	PORTC
	GOTO	ShowLvlRet
Show0	MOVLW	b'11111111'
	MOVWF	PORTC
	BCF	PORTC,DSG
	BSF	PORTB,DSC
	GOTO	ShowLvlRet
Show1
	BSF	PORTC,DSB
	BSF	PORTB,DSC
	GOTO	ShowLvlRet
Show2
	BSF	PORTC,DSA
	BSF	PORTC,DSB
	BSF	PORTC,DSG
	BSF	PORTC,DSE
	BSF	PORTC,DSD
	GOTO	ShowLvlRet
Show3
	BSF	PORTC,DSA
	BSF	PORTC,DSB
	BSF	PORTB,DSC
	BSF	PORTC,DSG
	BSF	PORTC,DSD
	GOTO	ShowLvlRet
Show4
	BSF	PORTC,DSB
	BSF	PORTB,DSC
	BSF	PORTC,DSG
	BSF	PORTC,DSF
	GOTO	ShowLvlRet
Show7
	BSF	PORTC,DSA
	BSF	PORTC,DSB
	BSF	PORTC,DSC
	GOTO	ShowLvlRet

	end
