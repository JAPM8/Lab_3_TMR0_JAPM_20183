/*	
    Archivo:		main_postLAB.S
    Dispositivo:	PIC16F887
    Autor:		Javier Alejandro Pérez Marín 20183
    Compilador:		pic-as (v2.30), MPLABX V6.00

    Programa:		Contador binario de 4 bits que incrementa cada 100 ms
			en PORTA, contador de 2 bytes en display de 7 segmentos
			en PORTC con botones de inc y dec en PORTB, como un
			contador de segundos en PORTD y un comparador de
			PORTC con PORTD
    Hardware:		LEDs en el puerto A, D y E, 2 pb en puerto b, 7 segmentos 
			puerto C

    Creado:			12/02/22
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

  
; ----------------Variables----------------
PSECT udata_bank0	      ; Common memory, vars de 1 byte
    CONT_7D:	DS 1
    
; CONFIG Vector RESET    
PSECT resVect, class=CODE, abs, delta=2
ORG 00h                       ; posición 0000h para el reset
    
; ---------------vector reset--------------
resetVec:
    PAGESEL MAIN
    GOTO    MAIN

; CONFIG uCS
PSECT code, delta=2, abs
ORG 100h                      ; posición para el código

 ; ---------------CONFIGURACIÓN--------------
 MAIN:
; Configuración Inputs y Outputs
    CALL    CONFIG_PINES
; Configuración deL Oscilador
    CALL    CONFIG_RELOJ
; Configuración Timer0
    CALL    CONFIG_TIMER0
    
    MOVLW   00111111B	      ; Mover la literal a W
    MOVWF   PORTC	      ; Asignar valor de W (0) al display
    
    CLRF    CONT_7D	    
    
    
    BANKSEL PORTB
    
LOOP:
        
    BTFSC PORTB, 0            ; Se evalúa estado de RB0 (si NO está presionado salta una línea)
    CALL  INC_CONT	      ; Mientras se presione RB0 pasa al antirebote de Incremento
    BTFSC PORTB, 1            ; Se evalúa estado de RB1 (si NO está presionado salta una línea)
    CALL  DEC_CONT	      ; Mientras se presione RB1 pasa al antirebote de Decremento
    CALL  CONT_TMR0	      ; Subrutina para contador en PORTA
    CALL  EST_DISP7	      ; Subrutina para limitar contador en PORTD
    
    GOTO LOOP

CONFIG_PINES:
    BANKSEL ANSEL	      ; Cambiamos de banco
    CLRF    ANSEL
    CLRF    ANSELH	      ; Rb como I/O digital
    
    BANKSEL TRISA
    BCF    TRISA, 0	      ; Ra0 a Ra3 como salida
    BCF    TRISA, 1
    BCF    TRISA, 2
    BCF    TRISA, 3
            
    BANKSEL TRISB
    BSF     TRISB, 0	       ; Rb0 a Rb1 como input
    BSF     TRISB, 1          
    
    BANKSEL TRISC
    CLRF    TRISC	       ; Pines Rc como output
    
    BANKSEL TRISD
    BCF    TRISD, 0	       ; Pines Rd como output
    BCF    TRISD, 1
    BCF    TRISD, 2
    BCF    TRISD, 3
    
    BANKSEL TRISE	        ; Cambiamos de banco
    BCF     TRISE, 0
    
    BANKSEL PORTA               ; Cambiamos de banco
    CLRF    PORTA	        ; Se limpia PORTA para que inicie en 0
    CLRF    PORTB	        ; Se limpia PORTB para que inicie en 0
    CLRF    PORTC	        ; Se limpia PORTC para que inicie en 0
    CLRF    PORTD	        ; Se limpia PORTD para que inicie en 0
    CLRF    PORTE	        ; Se limpia PORTE para que inicie en 0
        
    RETURN
    
CONFIG_RELOJ:
    BANKSEL OSCCON	        ; Cambiamos de banco
    BSF	    OSCCON, 0	        ; Seteamos para utilizar reloj interno (SCS=1)
    
    ;Se modifican los bits 4 al 6 de OSCCON al valor de 100b para frecuencia de 1 MHz (IRCF=100b)
    BSF	    OSCCON, 6
    BCF	    OSCCON, 5
    BCF	    OSCCON, 4
    
    RETURN
    
CONFIG_TIMER0:
    BANKSEL OPTION_REG	        ; Cambiamos de banco
    BCF	    T0CS	        ; Seteamos TMR0 como temporizador(T0CS)
    BCF	    PSA		        ; Se asigna el prescaler a TMR0(PSA)
   ; Se setea el prescaler a 256 BSF <2:0>
    BSF	    PS2		        ; PS2
    BSF	    PS1		        ; PS1
    BSF	    PS0		        ; PS0		    
    
    BANKSEL TMR0	        ; Cambiamos a banco 0
    ;N=256-((100 ms)(1 MHz)/4*256) -> N=158 aprox
    MOVLW   158		        ; Se mueve N al registro W
    MOVWF   TMR0	        ; Se le dan los 100ms de delay a TMR0
    BCF	    T0IF	        ; limpiamos bandera de interrupción
    
    RETURN 
    
INC_CONT:
    BTFSC PORTB, 0	        ; Se evalúa estado de RB0 (si NO está presionado salta una línea)
    GOTO $-1		        ; Mientras se presione RB0 se continúa revisando hasta que deje de estarlo
    
    INCF    CONT_7D	        ; Se incrementa el valor de la variable CONT_7D
    MOVF    CONT_7D, W	        ; Movemos la variable a W
    CALL    TABLA	        ; Llamamos nuestra tabla para 7 segmentos
    MOVWF    PORTC	        ; Movemos valor de 7 segmentos a PORTC
            
    RETURN    
    
DEC_CONT:
    BTFSC PORTB, 1	        ; Se evalúa estado de RB1 (si NO está presionado salta una línea)
    GOTO $-1		        ; Mientas se presione RB1 se continua revisando hasta que deje de estarlo
    
    DECF    CONT_7D	        ; Se reduce el valor de la variable CONT_7D
    MOVF    CONT_7D, W	        ; Movemos la variable a W
    CALL    TABLA	        ; Llamamos nuestra tabla para 7 segmentos
    MOVWF    PORTC	        ; Movemos valor de 7 segmentos a PORTC
    
    RETURN
    
CONT_TMR0:
    BTFSS   T0IF	        ; Verificación de interrupcion del TMR0
    GOTO    $-1		        ; Si está en 0 se mantiene en loop hasta que se prenda.
    CALL    RESET_TMR0	        ; Llamamos la subrutina de reinicio de TMR0
    INCF    PORTA	        ; Incrementamos contador en PORTA
    MOVF    PORTA, 0	        ; PORTA a W
    SUBLW   10		        ; w-10 -> Buscando bandera de Zero para hacer incremento
    BTFSC   ZERO	        ; Si la bandera está activa se hace el incremento de PORTD
    INCF    PORTD
    
    RETURN

RESET_TMR0:
    BANKSEL TMR0	        ; Cambiamos al banco 1
    MOVLW   158                 ; Se mueve N al registro W
    MOVWF   TMR0	        ; Se le dan los 100ms de delay a TMR0
    BCF	    T0IF	        ; Limpiamos la bandera de interrupción
    
    RETURN
  
EST_DISP7:
    MOVF    CONT_7D, 0	        ; Movemos variable CONT_7D a W (Valor 7 segmentos)
    SUBWF   PORTD, 0	        ; PORTD - W (Comparación contadores) 
    BTFSC   ZERO	        ; Si son iguales los contadores pasamos a una subrutina
    CALL    BANDERA_IGUAL     
        
    RETURN  
    
BANDERA_IGUAL:
    CLRF    PORTD		; Reinicio de PORTD
    INCF    PORTE		; On/Off led 
    
    RETURN
    
ORG 200h
TABLA:
    CLRF    PCLATH		; Limpiamos registro PCLATH
    BSF	    PCLATH, 1		; Posicionamos el PC en dirección 02xxh
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

END