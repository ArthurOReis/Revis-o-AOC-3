; Cenário: Gere uma onda quadrada de 1 kHz no pino PB5.

; 1 kHz significa um período de 1ms.

; O pino deve ficar 0,5ms ligado e 0,5ms desligado.

; O Problema: O Timer0 com Prescaler 64 estoura a cada 1,024ms (aproximadamente). Se usarmos o estouro completo (0 a 256), nunca teremos exatos 0,5ms.

; A Solução (Recarga): Não deixamos o balde começar do 0. Enchemos ele até a metade já no início, para ele transbordar mais rápido.

.INCLUDE <m328Pdef.inc>
.equ LED = PB5
.def AUX = R16
.equ VALOR_INICIAL = 131   ; 256 - 125

.ORG 0x0000
    RJMP setup

.ORG 0x0020                ; Vetor do Timer0 Overflow
    RJMP isr_timer0

.ORG 0x0034
setup:
    ; 1. GPIO
    sbi DDRB, LED          ; PB5 como Saída

    ; 2. Configura Timer
    ldi AUX, VALOR_INICIAL
    out TCNT0, AUX         ; Começa já em 131 (não em 0)

    ; 3. Configura Prescaler 64 (0x03)
    ldi AUX, 0x03
    out TCCR0B, AUX

    ; 4. Habilita Interrupção
    ldi AUX, 0x01
    sts TIMSK0, AUX

    sei
    rjmp main

main:
    rjmp main              ; Loop vazio

isr_timer0:
    push AUX
    in AUX, SREG
    push AUX

    ; --- O SEGREDO DA PRECISÃO ---
    ; Recarrega o Timer imediatamente para 131
    ldi AUX, VALOR_INICIAL
    out TCNT0, AUX
    
    ; Inverte o LED (Toggle)
    sbi PINB, LED

    pop AUX
    out SREG, AUX
    pop AUX
    reti

; Dica de Prova: Se o professor pedir uma frequência exata, você tem que recarregar o TCNT0 dentro da ISR (logo no começo).