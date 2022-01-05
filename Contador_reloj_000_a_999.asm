;*************************************************************
; RELOJ DE 9.99
;*************************************************************
; Frecuencia de reloj: 4 MHz
; Instrucción: 1Mz = 1 us
; Perro Guardián: OFF
; Tipo de Reloj: XT
; Protección de código: OFF
; POR: ON
;
;*************************************************************
; DESCRIPCIÓN DEL PROGRAMA
;*************************************************************
;
; Este programa funciona en un PIC16F84A y se trata de un reloj/contador 
; desde 0 hasta 9.99 muestra hasta 9 minutos y 99 segundos.
; Dispone de dos displays LED para los minutos y otros dos para los
; segundos. La decena de minuto se inhabilita, ya que no se necesita. Se puede 
;modificar el programa para tener dos displays para las horas y otros dos para los minutos. 
;  
; DESCRIPCIÓN DEL HARDWARE
;  
; VISUALIZACIÓN:  
;
; Los minutos se muestran mediante cuatro displays de 7 segmentos de cátodo
; común multiplexados. Los segmentos de cada display se unen y están
; controlados a través de resistencias por salidas del PIC. Cada cátodo
; común de cada display es controlado por el PIC a través de un transistor.
; El reloj/contador separa los minutos y segundos por el punto de la unidad de minutos (88.88.). Los
; segmentos se asignan al puerto B.
; Los dos puntos se realizan en serie con una resistencia
; y se conectan a RB0 y al punto de unidad de minutos y al punto de unidad de segundos.
; Los segmentos de los displays, de "a" hasta "f" se asignan a las salidas
; de RB1 a RB7.  
; Los cuatro cátodos comunes se controlan mediante el puerto A a través de
; los transistores.  
; RA0 controla la decena de minuto, RA1 la unidad de minuto; RA2 la decena de
; segundo y RA3 la unidad de segundo.  
;*************************************************************
; PINES: En proteus está el circuito con la organización de cada uno de los pines
;*************************************************************
 
; PORTA, control displays 7 segmentos de cátodo común
; PORTB, segmetos de los displays, led separadores.

;*************************************************************
	LIST P=PIC16F84A		; Pic a usar
#INCLUDE <P16F84A.INC>		; Lista de etiquetas de microchip
;
;*************************************************************
; Configuración opciones de hardware para la programación
		__CONFIG    _CP_OFF & _PWRTE_ON & _WDT_OFF & _XT_OSC       
;
;**************************************************************
; Lista de constantes y variables para el uso del programa
;**************************************************************
;
; Valores de constantes ***************************************
;
FRAC_INI	equ		D'12'	; Constante para inicio cuenta de fracciones de segundo(Ya que TMR0 funciona con ciclos de reloj)
SEGS_INI	equ		D'156'	; Constante para inicio cuenta de segundos (255-156=99)
MINS_INI	equ		D'246'	; Constante para inicio cuenta de minutos  (255-246=9)
HORS_INI	equ		D'247'	; Constante para cuenta de horas  (Se puede modificar el programa para conteo de horas y minutos)
HORS_9H		equ		D'246'	; Constante para cuenta de horas
;Se tiene en cuenta los desbordamientos para reiniciar el conteo de los segundos, minutos y horas
;Cuando segundos sea igual a 255: segundos - SEGS_INI = 255 - 156 = 99 que es el máximo valor de segundos
;Ya que al llegar a 256 se desborda y vuelve a tomar el valor de cero
;Cuando minutos = 255: minutos - MINS_INI = 246 - 255 = 9 que es el máximo valor para minutos.
; El ejercicio se puede modificar para que minutos llegue a 99
; Si se requiere un conteo más lento se puede mostrar en pantalla las horas y minutos, haciendo algunas modificaciones 
;o modificar el oscilador.

ADJMIN		equ		D'9'	; Número de "frac_sec" que se necesita sumar cada minuto
							; para ajustar el tiempo
ADJHOR		equ		D'34'	; Número de "frac_sec" que se necesita restar cada hora
							; para ajustar el tiempo
ADJDIA		equ		D'3'	; Número de "frac_sec" que se necesita sumar cada 12 horas
							; para ajustar el tiempo
;Ajustes
; Un "frac_sec" es aproximadamente 1 / 244 s
; 1 MHz / 16 = 62.500 Hz ; 62.500 Hz / 256 = 244,140625 Hz ; T = 0,004096 s
; 0,004096 s * 244 = 0,999424 s; dif 1 segundo = -0,000576 s
; 1 "minuto" = 0,999424 s * 60 = 59,96544 s
; 60 s - 59,96544 s = 0,03456 s ; 0,03456 s / 0,004096 s = 8,4375
; 1 "minutoadj" = 59,96544 s + (0,004096 s * 9) = 59,96544 s + 0,036864 s = 60,002304 s
; 1 "hora" = 60,002304 s * 60 = 3600,13824 s
; 3600 s - 3600,13824 s = -0,13824 s ; -0,13824 s / 0,004096 s = -33,75 s
; 1 "horaadj" = 3600,13824 s - (0,004096 s * 34) = 3600,13824 s - 0,139264 s = 3599,998976 s
; 12 "horas" = 3599,998976 s * 12 = 43199,987712 s
; 43200 s - 43199,987712 s = 0,012288 s ; 0,012288 s /  0,004096 s = 3
; 12 "horasadj" = 43199,987712 s + 0,004096 s * 3 = 43199,987712 s + 0,012288 s = 43200 s
;
CHG			equ		H'03'	; Indica que es necesario actualizar los valores de los minutos (hora) que tienen 
							; que mostrarse en los displays
DSPOFF		equ		B'11111111'	; Displays apagados (PORTA)
;
; Mapa de activación de segmentos para los displays (PORTB)
;    
							; gfedcbap
CERO		equ		H'7E'	; 01111110
UNO			equ		H'0C'	; 00001100
DOS			equ		H'B6'	; 10110110
TRES		equ		H'9E'	; 10011110
CUATRO		equ		H'CC'	; 11001100
CINCO		equ		H'DA'	; 11011010
SEIS		equ		H'FA'	; 11111010
SIETE		equ		H'0E'	; 00001110
OCHO		equ		H'FE'	; 11111110
NUEVE		equ		H'DE'	; 11011110
SEGM_OFF	equ		H'00'	; Todos los segmentos apagados. Separador entre horas
							; y minutos apagado (RB0).
;
; Posición de memoria de variables ************************************
; Las variables de tiempo comienzan con un número que permite contar y ajustar el tiempo  
; Por ejemplo la variable "segundos" se inicia con 196 decimal, para que después de 100
; incrementos de 1 segundo se produzca un 0 (156 + 100 = 256 -> 0)
frac_sec	equ		H'0C'	; Fracciones de segundo (1/244)
segundos	equ		H'0D'	; Segundos
minutos		equ		H'0E'   ; Minutos  (246 + 10 = 256 -> 0)
horas		equ		H'0F'   ; Horas    (246 + 10 = 256 -> 0)
conta1		equ		H'10'	; Variable 1 para bucle contador
;
display		equ     H'11'	; Indicador de display que debe actualizarse
digito1		equ		H'12'	; Display unidad de segundo (minuto) 
digito2		equ		H'13'	; Display decena de segundo (minuto)
digito3		equ		H'14'	; Display unidad de minuto   (Hora)
digito4		equ		H'15'	; Display decena de minuto (Hora)
banderas	equ     H'16'	; Banderas; 3-CHG
;
;**************************************************************
	ORG 0x00		;Vector de Reset
	goto	INICIO
	org	0x05		;Salva el vector de interrupción
;**************************************************************
; SUBRUTINAS
;**************************************************************
CODIGO_7S	; Devuelve el código 7 segmentos
	addwf	PCL,F
	retlw	CERO
	retlw	UNO
	retlw	DOS
	retlw	TRES
	retlw	CUATRO
	retlw	CINCO
	retlw	SEIS
	retlw	SIETE
	retlw	OCHO
	retlw	NUEVE
;**************************************************************
;
;
;**************************************************************
; Comienzo del programa
;**************************************************************
;
INICIO
;  Configurar puertos como salidas, blanquear display
	bsf		STATUS,RP0	; Activa el banco de memoria 1.
	movlw	B'10000011' ; Configuración del registro Option
	movwf	OPTION_REG	; TMR0 en modo temporizador (uso de pulsos de reloj internos, Fosc/4)
						; prescaler TMR0 a 1:16 
	movlw	B'00000000'
	movwf	TRISA		; Pone todas las patillas del puerto A como salidas
	movwf	TRISB		; Pone todas las patillas del puerto B como salidas
	bcf		STATUS,RP0	; Activa el banco de memoria 0.
;
; Establecer estados iniciales de las salidas
	movlw	DSPOFF
	movwf	PORTA		; Apaga los displays
	movlw	B'00000001'	; Todos los segmentos apagados. Separador 
	movwf	PORTB		; entre horas y minutos encendido (RB0).
;
; Inicialización de variables:
	movlw	H'01';
	movwf	TMR0		; Pone 01h en TMR0
	movlw	B'11111110'	
	movwf	display		; Inicia display seleccionando decena de minuto
	movlw	NUEVE
	movwf	digito1		; Aparecerá un "9" en el display unidad de segundos
	movwf	digito2		; Aparecerá un "9" en el display decena de segundos
	movwf	digito3		; Aparecerá un "9" en el display unidad de minuto
	movwf	digito4		; Aparecerá un "9" en el display decena de minuto (Luego se queda apagado, ya que no se necesita para el conteo)
	movlw	B'00000000'
	movwf	banderas	; Coloca todas las banderas a 0
;
; Inicia las variables de tiempo
	movlw	FRAC_INI    ; Valor constante de 12
	movwf	frac_sec	; 12
	movlw	SEGS_INI    ; Valor constante de 156
	movwf	segundos	; 156
	movlw	MINS_INI    ; Valor constante de 246
	movwf	minutos		; 246 Los minutos comienzan con 0 por lo que "minutos" ha de ser 255-246=9
	movlw	D'246'      ; 
	movwf	horas		; Se puede modificar el programa para que muestre horas y minutos
;
;**************************************************************
PRINCIPAL ; Rutina principal cíclica
;**************************************************************
;
;  Esperar al desbordamiento de TMR0
TMR0_LLENO ; TMR0 Cuenta los ciclos de reloj
;	4 MHz -> 1 MHz
;   1.000.000 Hz / 16 = 62.500 Hz
;   62.500 Hz / 256 = 244,140625 Hz -> 4,096 ms
	movf	TMR0,W
	
	btfss	STATUS,Z	; TMR0 cuenta libremente para no perder ciclos del reloj
						; escribiendo valores
	goto	TMR0_LLENO
	
;
; Se ha desbordado TMR0 y se han contado 256.
; Tarda en desbordarse 4.096 ciclos de reloj, 4,096 ms
	incfsz	frac_sec,F		; Se añade 1 a frac_sec
	goto	COMPROBAR_CHG	; Si no se ha desbordado fracciones de segundo, se comprueba el estado de “CHG” por si 
							; es necesario actualizar los valores
							; de la hora que tienen que mostrarse en los displays
;
; Se ha desbordado frac_sec y se han contado 244 "frac_sec", 1 segundo.
; Tarda en desbordarse 4.096 ciclos de reloj, 4,096 ms * 244 = 999,424 ms
; Al no consegirse exactamente 1 segundo sino 0,999424 s, luego se necesitan ajustes
	bsf		PORTB,0		; Se activa separador minutos segundos (horas-minutos)
	movlw	FRAC_INI
	movwf	frac_sec  ; Restaura la variable frac_sec para la próxima vuelta
;
		
INC_HORA	; Verifica si se debe Incrementar segundos, minutos y horas
			; Ajustes cada minuto, hora y 12 horas
	bsf		banderas,CHG	; Se especifica que se ha producido un cambio en segundos, minutos u horas
;						     o en segundos y minutos o sólo en segundos
	incfsz	segundos,F 		; Como ha pasado un segundo se incrementa "segundos". Si se desborda segundos se ignora instrucción goto
	goto	COMPROBAR_CHG   ; Si segundos no se desborda salta
	movlw	SEGS_INI   		; Se ha desbordado "segundos" y se reestablece el valor inicial
	movwf	segundos		; de "segundos" para la próxima vuelta. Debe aumentar los minutos.
;
	movlw	ADJMIN			; Se resta 9 a "frac_sec" cada minuto para los ajustes de tiempo 
	subwf	frac_sec,F 		; El minuto será 9 "frac_sec" más largo
;
	incfsz	minutos,F  		; Se añade 1 minuto
	goto	COMPROBAR_CHG   ; Si minutos no se desborda salta
	movlw	MINS_INI		; Se ha desbordado "minutos" y Se reestablece el valor inicial
	movwf	minutos	  		; de "minutos" para la próxima vuelta. Se debe aumentar la hora.
;
	movlw	ADJHOR			; Se suma 34 a "frac_sec" cada hora para los ajustes de tiempo 
	addwf	frac_sec,F		; La hora será 34 "frac_sec" más corta
;
	incfsz	horas,F	  		; Se añade 1 hora
	goto	COMPROBAR_CHG   ; Si horas no se desborda salta
	movlw	HORS_INI			; Se ha desbordado "horas" y se reestablece el valor inicial
	movwf	horas	  		; de "horas" para la próxima vuelta
	movlw	ADJDIA			; Se resta 3 a "frac_sec" cada 12 horas para los ajustes de tiempo
	subwf	frac_sec,F 		; Cada 12 horas se añadirán 3 "frac_sec"
;
; Se comprueba el estado de “CHG” por si 
; es necesario actualizar los valores
; de la hora que tienen que mostrarse en los displays
; Se actualiza hora y los displays cada 4,096 ms (244 veces por segundo)
COMPROBAR_CHG 	
	btfss	banderas,CHG	; Si no se ha cambiado la hora
 	goto	DISPLAY_PUL		; se salta a DISPLAY_PUL, que principalmente refresca uno de los
							; displays cada vez que se accede a ella.
;
	
OBTENER_H_M;/////////////////////////////////////////////////////////////////////////////////
    movlw	MINS_INI  ; MINS_INI = d246. Se transfiere a W el valor de MINS_INI
    subwf	minutos,W ; W = d246. minutos - W. El valor de minutos va de 246 a 255
    movwf	digito3     ; La variable digito3 almacena temporalmente el valor para los minutos. (Entre 0 y 9)
    movlw	SEGS_INI    ; SEGS_INI = d146
	subwf	segundos,W  ; Segundos va cambiando entre 146 y 255
	movwf	digito1			; Se guarda temporalmente el número de segundos en “digito1”. (Entre 0 y 99)
;
DIV_DIGITOS		; Divide los segundos o los minutos y las horas en dígitos independientes
				; ejemplo, [14] lo pasa a [1]-[4]
	movlw	H'00'
	movwf	digito4		; Se ponen a cero las posiciones de las decenas
	movwf	digito2		; para el caso de que no se incrementen
	movlw	H'02'
	movwf	conta1		; Bucle para convertir cada número (segundos o minutos y horas)
	movlw	digito1		; Se recupera el valor de los segundos guardados en digito1
	movwf	FSR			; La primera vez, FSR = digito1 (segundos) y la segunda vez FSR = digito3 (minutos)
	goto	LOOP		
;
LOOP2	; Este LOOP se utiliza para los minutos 
	movlw	digito3
	movwf	FSR			
;
LOOP	; Este LOOP se utiliza primero para los segundos y después para los minutos
	movlw	D'10'			; Averiguar cuantas "decenas" hay en el número
	subwf	INDF,F			; En cada LOOP restar 10 al número
	btfsc	STATUS,C        ; Se comprueba "C", que se pone a 1 si en la resta no se ha
							; producido llevada
	goto	INC_DECENAS   	; C = 1 por lo que se añade 1 a la posición de las decenas
	addwf	INDF,F			; C = 0, no se incrementan las decenas y se suma 10 para restaurar
							; las unidades
	goto	PROX_NUM
;
INC_DECENAS
	incf	FSR,F		; El puntero apunta a la primera posición de las decenas
	incf	INDF,F		; Se añade 1 a las decenas
	decf	FSR,F	  	; Se restaura el valor de INDF para apuntar al número
	goto    LOOP		; para la próxima resta hasta que se termine
						; Con "goto LOOP" se vuelve a comprobar si es necesario
						; sumar uno a la decena cada vez que esta se ha incrementado
;
PROX_NUM	; Próximo número, primero ha sido segundos y luego minutos
	decfsz	conta1,F
	goto	LOOP2
;
CONVER_COD_7S	; Convierte cada dígito a código 7 segmentos para los displays
	movlw	digito1	
	movwf	FSR		; Coloca la dirección del primer digito (digito1) en FSR
	movlw	H'04'
	movwf	conta1	; Prepara la variable conta1 para el bucle de los 4 displays
;
PROX_DIGITO
	movf	INDF,W		; Obtener el valor de la variable "digito" actual
	call	CODIGO_7S	; LLamar a la rutina de conversión a código 7 segmentos
	movwf	INDF		; Colocar en la variable "digito" el código 7 segmentos devuelto
	incf	FSR,F		; Incremente INDF para el próximo "digito"
	decfsz	conta1,F	; Permitir que conta1 de sólo 4 vueltas
	goto	PROX_DIGITO
;
BORRAR_CERO		; Como el  el display de las decenas de minuto (hora) no se requiere
				; no se muestra (borrado de los ceros a la izquierda)
	movlw	SEGM_OFF
	movwf	digito4

;
DISPLAY_PUL		; Se borran los bits de flag para actualizar su estado
				; Muestra los dígitos correspondientes a los segundos o a
				; los minutos y horas en el display que corresponda.
;
	movlw	B'00000000'
	movwf	banderas	; Se borran los bits de flag para actualizar su estado
;
	; Apagar los displays
	movlw	DSPOFF
	movwf	PORTA		
;
	; Apagar los segmentos respetando separador -minutos-segundos
	movlw	SEGM_OFF	; Respeta valor RB0
	xorwf	PORTB, w
	andlw	B'11111110'	;  Poner "1" en la posición del bit a copiar
	xorwf	PORTB, f
;
	nop		; Las instrucciones "nop" pueden no ser necesarias.
	nop		; En principio proporcionan el tiempo suficiente para que los
	nop		; estados anteriores de las salidas se actualicen 
	nop		; 
	nop		; 
	nop

;
ACTIVAR_SEGM	; Se coloca en PORTB el valor para los segmentos del display actual

	; Se determina que display debe actualizarse, es decir, que dato debe
	; presentarse en el puerto B y se establece el siguiente display
	btfss	display,0	; Si es el primer display (decena de minuto) tomar digito4
	movf	digito4,W
	btfss	display,1	; Si es el segundo display (unidad de minuto) tomar valor digito3
	movf	digito3,W
	btfss	display,2	; Si es el tercer display (decena de seg) tomar valor digito2
	movf	digito2,W
	btfss	display,3	; Si es el cuarto display (unidad de seg) tomar valor digito1
	movf	digito1,W
;
	; Entregar el valor en puerto B y respetar valor RB0
	xorwf	PORTB, w
	andlw	B'11111110'	;  Poner "1" el la posición del bit a copiar
	xorwf	PORTB, f
;
	btfsc	frac_sec,7	; Establecer el separador de minutos y segundos a un 50% 
	bcf		PORTB,0		; del ciclo (1/2 segundo encendido, 1/2 segundo apagado)
;
	movf	display,W	; Tomar el valor del display que debe habilitarse
	movwf	PORTA		; Cada display se “enciende” con una cadencia de 244 Hz / 4 = 61 Hz   
		; En este momento están encendidos los segmentos correspondientes
;
	rlf		display,F	; Rota display 1 bit a la próxima posición
	bsf		display,0	; Asegura un 1 en la posición más baja de display (luego se hará 0 si es necesario)
	btfss	display,4	; Comprueba si el último display fue actualizado
	bcf		display,0	; Si lo fue, se vuelve a habilitar el primer display
						; La variable display va cambiando:
						;	1111 1101
						;	1111 1011
						;	1111 0111
						;	1110 1110
						;	1101 1101
						;	1011 1011
						;	0111 0111
						;	1110 1110
						; Sólo valen los 4 bits menos significativos

	
;
	goto    PRINCIPAL	; Volver a realizar todo el proceso
;
    END