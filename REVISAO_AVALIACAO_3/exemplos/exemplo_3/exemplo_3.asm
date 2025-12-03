; Exemplo 2: O Timer como CONTADOR (Contar Peças/Pessoas) 🏭
; O nome do periférico é Temporizador/Contador.

; Temporizador: Conta pulsos do relógio interno (16MHz).

; Contador: Conta pulsos de um pino externo (T0 no pino PD4).

; Cenário da Prova: Um sensor de passagem está ligado no pino PD4 (T0). Acenda o LED (PB5) toda vez que 5 objetos passarem pelo sensor.

; O que muda? Olhe a tabela na página 11 do seu PDF. As últimas linhas mostram "Clock externo no pino T0".

; Borda de Descida (Falling Edge): CS02=1, CS01=1, CS00=0 => 0x06.

; Neste modo, o Timer não corre sozinho. Ele só incrementa (TCNT0++) quando o sinal no pino PD4 muda.

.INCLUDE <m328Pdef.inc>
.equ LED = PB5
.equ SENSOR = PD4      ; Pino T0 físico do ATmega328p
.def AUX = R16

.ORG 0x0000
    RJMP setup

setup:
    ; 1. GPIO
    sbi DDRB, LED      ; LED Saída
    cbi DDRD, SENSOR   ; Sensor (PD4) Entrada
    sbi PORTD, SENSOR  ; Pull-up no sensor

    ; 2. Configura Timer como CONTADOR DE EVENTOS
    ; Não usamos Prescaler de tempo. Usamos Clock Externo.
    ; TCNT0 começa zerado
    ldi AUX, 0
    out TCNT0, AUX

    ; Configura TCCR0B para Clock Externo (Borda de Descida no T0)
    ; Valor 0x06 (Binário 110 na tabela do PDF)
    ldi AUX, 0x06
    out TCCR0B, AUX

    ; Nota: NÃO habilitamos interrupção aqui. Vamos ler o valor na main.
    ; (Também poderíamos usar interrupção se a conta fosse 256)

    rjmp main

main:
    ; --- Leitura do Contador ---
    in AUX, TCNT0      ; Lê quantos pulsos o Timer já contou
    
    cpi AUX, 5         ; Já passaram 5 objetos?
    brlo main          ; Se for menor (Lower) que 5, volta pro início.

    ; --- Chegou em 5! ---
    sbi PORTB, LED     ; Liga o LED

    ; Opcional: Resetar a contagem para começar de novo
    clr AUX
    out TCNT0, AUX
    
    ; Espera um pouco para não piscar rápido demais (delay simples)
    ; ... (aqui entraria um delay) ...
    cbi PORTB, LED     ; Desliga
    
    rjmp main