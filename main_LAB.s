/*	
    Archivo:		main_preLAB.S
    Dispositivo:	PIC16F887
    Autor:		Javier Alejandro Pérez Marín 20183
    Compilador:		pic-as (v2.30), MPLABX V6.00

    Programa:		Contador binario de 8 bits con botón de incremento y decremento portD
    Hardware:		Display de 7 segmentos en puerto C

    Creado:			09/02/22
    Última modificación:	12/02/22	
*/
    
PROCESSOR 16F887
// config statements should precede project file includes.
#include <xc.inc>
 
; CONFIG1
CONFIG  FOSC = INTRC_NOCLKOUT ; Oscillator Selection bits (INTOSCIO oscillator: I/O function on RA6/OSC2/CLKOUT pin, I/O function on RA7/OSC1/CLKIN)
CONFIG  WDTE = OFF            ; Watchdog Timer Enable bit (WDT disabled and can be enabled by SWDTEN bit of the WDTCON register)
CONFIG  PWRTE = ON            ; Power-up Timer Enable bit (PWRT enabled)
CONFIG  MCLRE = OFF           ; RE3/MCLR pin function select bit (RE3/MCLR pin function is digital input, MCLR internally tied to VDD)
CONFIG  CP = OFF              ; Code Protection bit (Program memory code protection is disabled)
CONFIG  CPD = OFF             ; Data Code Protection bit (Data memory code protection is disabled)

CONFIG  BOREN = OFF           ; Brown Out Reset Selection bits (BOR disabled)
CONFIG  IESO = OFF            ; Internal External Switchover bit (Internal/External Switchover mode is disabled)
CONFIG  FCMEN = OFF           ; Fail-Safe Clock Monitor Enabled bit (Fail-Safe Clock Monitor is disabled)
CONFIG  LVP = ON              ; Low Voltage Programming Enable bit (RB3/PGM pin has PGM function, low voltage programming enabled)

; CONFIG2
CONFIG  BOR4V = BOR40V        ; Brown-out Reset Selection bit (Brown-out Reset set to 4.0V)
CONFIG  WRT = OFF             ; Flash Program Memory Self Write Enable bits (Write protection off)

; CONFIG Vector RESET
    
    
PSECT resVect, class=CODE, abs, delta=2
ORG 00h                       ; posición 0000h para el reset
    
; ---------------vector reset--------------
resetVec:
    PAGESEL main
    GOTO    main

; CONFIG uCS
PSECT code, delta=2, abs
ORG 100h                      ; posición para el código
TABLA:
    CLRF    PCLATH		; Limpiamos registro PCLATH
    BSF	    PCLATH, 0		; Posicionamos el PC en dirección 01xxh
    ANDLW   0x0F		; no saltar más del tamaño de la tabla
    ADDWF   PCL			; Apuntamos el PC a PCLATH + PCL + W
    retlw 00111111B ;0
    retlw 00000110B ;1
    retlw 01011011B ;2
    retlw 01001111B ;3
    retlw 01100110B ;4
    retlw 01101101B ;5
    retlw 01111101B ;6
    retlw 00000111B ;7
    retlw 01111111B ;8
    retlw 01101111B ;9
    retlw 01110111B ;10 (A)
    retlw 01111100B ;11 (b)
    retlw 00111001B ;12 (C)
    retlw 01011110B ;13 (d)
    retlw 01111001B ;14 (E)
    retlw 01110001B ;15 (F)
 ; ---------------CONFIGURACIÓN--------------
 main:
; Configuración Inputs y Outputs
    CALL    config_pines
          
    BANKSEL PORTA	    ; Cambiamos de banco

; ---------------sub-rutinas--------------
    
checkbotones:                 ; Todos los botones se encuentran en config Pull Down
    BTFSC PORTB, 0            ; Se evalúa estado de RB0 (si NO está presionado salta una línea)
    CALL inc_cont	      ; Mientras se presione RB0 pasa al antirebote de Incremento
    BTFSC PORTB, 1            ; Se evalúa estado de RB1 (si NO está presionado salta una línea)
    CALL dec_cont	      ; Mientras se presione RB1 pasa al antirebote de Decremento	      
 
    GOTO checkbotones         ; Mientras no estén presionados continua revisando el estado
    
config_pines:
    BANKSEL ANSELH	    ; Cambiamos de banco
    CLRF    ANSELH	    ; Rb como I/O digital
            
    BANKSEL TRISB
    BSF     TRISB, 0	    ; Rb0 a Rb1 como input
    BSF     TRISB, 1          
    
    BANKSEL TRISC
    CLRF    TRISC	    ; Pines Rc como output
    
    BANKSEL TRISD
    BCF	    TRISD, 0	    ; Pines Rd como output
    BCF	    TRISD, 1
    BCF	    TRISD, 2
    BCF	    TRISD, 3
    
    BANKSEL PORTA           ; Cambiamos de banco
    CLRF    PORTB	    ; Se limpia PORTB para que inicie en 0
    CLRF    PORTC	    ; Se limpia PORTC para que inicie en 0
    CLRF    PORTD	    ; Se limpia PORTD para que inicie en 0
    
    RETURN
    
inc_cont:
    BTFSC PORTB, 0	      ; Se evalúa estado de RB0 (si NO está presionado salta una línea)
    GOTO $-1		      ; Mientras se presione RB0 se continúa revisando hasta que deje de estarlo
    
    INCF    PORTD
    MOVF    PORTD, W		; Valor de contador a W para buscarlo en la tabla
    CALL    TABLA		; Buscamos caracter de CONT en la tabla
    MOVWF   PORTC		; Guardamos caracter de CONT
       
    GOTO    checkbotones    
    
  
dec_cont:
    BTFSC PORTB, 1	      ; Se evalúa estado de RB1 (si NO está presionado salta una línea)
    GOTO $-1		      ; Mientas se presione RB1 se continua revisando hasta que deje de estarlo
    
    DECF    PORTD
    MOVF    PORTD, W		; Valor de contador a W para buscarlo en la tabla
    CALL    TABLA		; Buscamos caracter de CONT en la tabla
    MOVWF   PORTC		; Pasamos el valor en bin para encender 7 seg
    
    GOTO    checkbotones  
        
END


