/*	
    Archivo:		main_LAB.S
    Dispositivo:	PIC16F887
    Autor:		Javier Alejandro Pérez Marín 20183
    Compilador:		pic-as (v2.30), MPLABX V6.00

    Programa:		Contador binario de 4 bits que incrementa cada 100 ms (Prelab)
    Hardware:		LEDs en el puerto A (display contador prelab)

    Creado:			07/02/22
    Última modificación:	07/02/22	
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

 ; ---------------CONFIGURACIÓN--------------
 main:
; Configuración Inputs y Outputs
    CALL    config_pines
; Configuración deL Oscilador
    CALL    config_reloj
; Configuración Timer0
    CALL config_timer0
    
    BANKSEL PORTA	    ; Cambiamos a banco 0
    
LOOP:
    BTFSS   T0IF	    ; Se verifica la bandera de interrupción del TMR0 (De estarlo salta una instr)
    GOTO    LOOP	    ; De no haber pasado los 100 ms, evaluamos de nuevo T0IF
    
    ;Al pasar el delay de 100 ms se resetea el temporizador y se hace el incremento
    CALL    reset_timer0      ; Pasamos a resetear TMR0
    INCF    PORTA	      ; Se incrementa el valor del contador en Port A
    GOTO    LOOP
    
; ---------------CONFIGURACIÓN--------------
config_reloj:
    BANKSEL OSCCON	      ; Cambiamos a banco 1
    BSF	    OSCCON, 0	      ; Seteamos para utilizar reloj interno (SCS=1)
    
    ;Se modifican los bits 4 al 6 de OSCCON al valor de 100b para frecuencia de 1 MHz (IRCF=100b)
    BSF	    OSCCON, 6
    BCF	    OSCCON, 5
    BCF	    OSCCON, 4
    
    RETURN
    
config_timer0:
    BANKSEL OPTION_REG	    ; Cambiamos a Banco 1
    BCF	    OPTION_REG, 5   ; Seteamos TMR0 como temporizador(T0CS)
    BCF	    OPTION_REG, 3   ; Se asigna el prescaler a TMR0(PSA)
   ; Se setea el prescaler a 256 BSF <2:0>
    BSF	    OPTION_REG, 2   ; PS2
    BSF	    OPTION_REG, 1   ; PS1
    BSF	    OPTION_REG, 0   ; PS0		    
    
    BANKSEL TMR0	    ; Cambiamos a banco 0
    ;N=256-((100 ms)(1 MHz)/4*256) -> N=158 aprox
    MOVLW   158		    ; Se mueve N al registro W
    MOVWF   TMR0	    ; Se le dan los 100ms de delay a TMR0
    BCF	    T0IF	    ; limpiamos bandera de interrupción
    
    RETURN   

; Cuando se cumple el tiempo del TMR0 se reinicia
reset_timer0:
    BANKSEL TMR0	    ; Cambiamos al banco 1
    MOVLW   158              ; Se mueve N al registro W
    MOVWF   TMR0	    ; Se le dan los 100ms de delay a TMR0
    BCF	    T0IF	    ; Limpiamos la bandera de interrupción
    
    RETURN
    
config_pines:
    BANKSEL ANSEL	      ; Cambiamos a Banco 3
    CLRF    ANSEL	      ; Ra como I/O digital
    
    BANKSEL TRISA
    BCF    TRISA, 0	      ; Ra0 a Ra3 como salida
    BCF    TRISA, 1
    BCF    TRISA, 2
    BCF    TRISA, 3
    
    BANKSEL PORTA             ; Cambiamos a banco 00
    CLRF PORTA		      ; Se limpia PORTA para que inicie en 0
    
    RETURN
    
    
END
      


