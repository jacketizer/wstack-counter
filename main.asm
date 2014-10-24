; Weight Stack Counter
#include <p16F690.inc>
	__config (_INTRC_OSC_NOCLKOUT & _WDT_OFF & _PWRTE_OFF & _MCLRE_OFF & _CP_OFF & _BOD_OFF & _IESO_OFF & _FCMEN_OFF)
;	__config (_FOSC_HS & _WDT_OFF & _PWRTE_OFF & _MCLRE_OFF & _CP_OFF & _BOD_OFF & _IESO_OFF & _FCMEN_OFF)

	CBLOCK	0x20	; Start of general purpose registers
Delay1
Delay2
Level			; Weight counter
LevelSPI		; To be sent via SPI
Turner			; What direction
WaitFor			; What to wait for
CalStatus		; Which sensor to calibrate
	ENDC

; Optic Sensor Mappings
#define	OPTIC1	PORTC,4
#define	OPTIC2	PORTC,5
#define	OPTICT1	TRISC,4
#define	OPTICT2	TRISC,5

; Magnetic Sensor Mappings
#define	MAGN1	PORTC,1
#define	MAGNT1	TRISC,1

; SPI TRIS Mappings
#define SPI_SCK	TRISB,6
#define SPI_SDI	TRISB,4
#define SPI_SDO	TRISC,7
#define SPI_SS	TRISC,6

; Status LED
#define ST_LED	PORTC,0
#define ST_LEDT	TRISC,0

; Button
#define BUTTON	PORTB,7
#define BUTTONT	TRISB,7

	org 0
	goto	Start

; Delay Functions
; ---------------
Delay
	MOVLW	d'6'		; 4 MHz: 4
	MOVWF	Delay1
	MOVWF	Delay2
Loop1	DECFSZ	Delay1,F
	GOTO	Loop2
	RETURN
Loop2	DECFSZ	Delay2,F
	GOTO	Loop2
	GOTO	Loop1

SensorDelay
	MOVLW	d'35'		; 4 MHz: 25
	MOVWF	Delay1
	MOVWF	Delay2
LLoop1	DECFSZ	Delay1,F
	GOTO	LLoop2
	RETURN
LLoop2	DECFSZ	Delay2,F
	GOTO	LLoop2
	GOTO	LLoop1
LongDelay
	MOVLW	d'150'
	MOVWF	Delay1
	MOVWF	Delay2
BLoop1	DECFSZ	Delay1,F
	GOTO	BLoop2
	RETURN
BLoop2	DECFSZ	Delay2,F
	GOTO	BLoop2
	GOTO	BLoop1
; End Delay

Start	BCF	STATUS,RP0
	BCF	STATUS,RP1	; Bank 0
	CLRF	PORTA
	CLRF	PORTB
	CLRF	PORTC

	BANKSEL	ANSEL		; Do not use AD converter
	CLRF	ANSEL

	BSF	STATUS,RP0
	BCF	STATUS,RP1	; Bank 1

	; Sensor Pin Setup
	BSF	OPTICT1		; Optic sensor 1 input
	BSF	OPTICT2		; Optic sensor 2 input
	BSF	MAGNT1		; Magnetic sensor 1 input

	; SPI Pin Setup
	BSF	SPI_SCK		; SPI Clock: Input (as slave)
	BSF	SPI_SDI		; SPI Digital Input
	BCF	SPI_SDO		; SPI Digital Output
	BSF	SPI_SS		; SPI Slave Select: Input
	
	; Status LED Setup
	BCF	ST_LEDT		; Status LED: output

	; Button Setup
	BSF	BUTTONT		; Button: input

	BANKSEL	SSPSTAT
	BCF	SSPSTAT,SMP
	BCF	SSPSTAT,CKE

	BANKSEL	SSPCON
	BCF	SSPCON,CKP	; Clock Polarity, idle low
	BSF	SSPCON,2	; SPI Slave Mode, SS Enabled
	BSF	SSPCON,SSPEN

	BCF	STATUS,RP0	; Bank 1
	BCF	STATUS,RP1
	CLRF	Turner
	CLRF	WaitFor
	CLRF	Level
	CLRF	LevelSPI
	clrf	CalStatus

	BSF	Turner,0
	SWAPF	Turner,1

Check	call	SPI_Test
	call	Cal_Test
	BTFSS	Turner,0
	GOTO	Upp
	GOTO	Ner

Upp	CALL	CheckEnd
	CALL	CheckU
	GOTO	Check

Ner	CALL	CheckStart
	CALL	CheckD
	GOTO	Check

CheckStart
	BTFSS	OPTIC1
	return
	BTFSC	OPTIC2
	return
	CALL	SensorDelay
	BTFSS	OPTIC1
	return
	BTFSC	OPTIC2
	return
	CALL	Turn
	call	StatusLEDOn
	return
	
CheckEnd
	BTFSS	OPTIC2
	return
	BTFSC	OPTIC1
	return
	CALL	SensorDelay
	BTFSS	OPTIC2
	return
	BTFSC	OPTIC1
	return
	CALL	Turn
	call	StatusLEDOff
	return

; SPI Transfer
; ------------
SPI_Test
	movlw	SSPSTAT
	movwf	FSR
	btfss	INDF,BF
	return
	
	BANKSEL	SSPBUF
	movf	SSPBUF,W
	movf	LevelSPI,W  ; should be levelSPI
	movwf	SSPBUF
	clrf	LevelSPI
	return
	
; Check Calibration Button
; ------------------------
Cal_Test
	btfss	BUTTON
	return
	call	SensorDelay
	btfss	BUTTON
	return
	call	SensorDelay
	btfss	BUTTON
	return
	btfsc	BUTTON		; Wait for release...
	goto	$-1
	call	SensorDelay
	btfsc	BUTTON
	return

	btfsc	CalStatus,1
	goto	Cal_Stop

	btfsc	CalStatus,0
	goto	Calibrate2

	goto	Calibrate1

Cal_Stop
	bsf	CalStatus,2	; Next: Exit to normal...
	return

Cal_Exit
	clrf	CalStatus
	call	StatusLEDOff
	return

Calibrate1
	bsf	CalStatus,0	; Next: cal2
	call	Cal_Test	; Check button again
	btfsc	CalStatus,2	; Exit?
	goto	Cal_Exit	; Yes!

	call	StatusLEDOn
	btfss	OPTIC1
	goto	Calibrate1
	btfsc	OPTIC2
	goto	Calibrate1
	call	SensorDelay
	btfss	OPTIC1
	goto	Calibrate1
	btfsc	OPTIC2
	goto	Calibrate1
	call	StatusLEDOff
	call	LongDelay
	goto	Calibrate1

Calibrate2
	bsf	CalStatus,1	; Next: exit
	call	Cal_Test	; Check button again
	btfsc	CalStatus,2	; Exit?
	goto	Cal_Stop	; Yes!

	call	StatusLEDOn
	btfss	OPTIC2
	goto	Calibrate2
	btfsc	OPTIC1
	goto	Calibrate2
	call	SensorDelay
	btfss	OPTIC2
	goto	Calibrate2
	btfsc	OPTIC1
	goto	Calibrate2
	call	StatusLEDOff
	call	LongDelay
	goto	Calibrate2

; Check up
; --------
CheckU	BTFSC	WaitFor,0	; What to wait for
	GOTO	CheckU2
	BTFSS	MAGN1
	return
	CALL	Delay
	BTFSS	MAGN1
	return
	BSF	WaitFor,0	; Change WaitFor
	return
CheckU2	BTFSC	MAGN1
	return
	CALL	Delay
	BTFSC	MAGN1
	return
	BCF	WaitFor,0	; Change WaitFor
	CALL	TickUp
	return

; Check down
; ----------	
CheckD	BTFSC	WaitFor,0	; What to wait for
	GOTO	CheckD2
	BTFSC	MAGN1
	return
	CALL	Delay
	BTFSC	MAGN1
	return
	BSF	WaitFor,0	; Change WaitFor
	return
CheckD2	BTFSS	MAGN1
	return
	CALL	Delay
	BTFSS	MAGN1
	return
	BCF	WaitFor,0	; Change WaitFor
	CALL	TickUp
	return

; Tick Up
; -------
TickUp	incf	Level,1
	return

; Turn
; ----
Turn	swapf	Turner,1
	movf	LevelSPI,1
	btfss	STATUS,Z
	return
	movf	Level,0
	movwf	LevelSPI	; Only move if LevelSPI is zero? (todo)
	clrf	Level
	return
	
; Status LED Operations
; ---------------------
StatusLEDOn
	bsf	ST_LED
	return
	
StatusLEDOff
	bcf	ST_LED
	return

	end
