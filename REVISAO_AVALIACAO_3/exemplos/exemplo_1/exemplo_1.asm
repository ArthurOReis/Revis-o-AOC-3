.INCLUDE <m328Pdef.inc>
; Definições
.def AUX = R16
.def CONTADOR_SOFTWARE = R17  ; Vai contar os estouros (ex: contar até 61)

.ORG 0x0000          ; Reset
    RJMP setup

.ORG 0x0020          ; VETOR DO TIMER0 (Endereço 0x0020 no PDF)
    RJMP isr_timer0

.ORG 0x0034
setup:
    ; ... Configurações de Pilha e GPIO (LEDs) igual antes ...

    ; --- CONFIGURAÇÃO DO TIMER0 ---
    ; 1. Valor Inicial (TCNT0)
    ldi AUX, 0
    out TCNT0, AUX      ; Começa do 0

    ; 2. Configura Prescaler 1024 (TCCR0B)
    ; Olhando tabela no PDF: CS02=1, CS00=1 -> 0x05
    ldi AUX, 0x05
    out TCCR0B, AUX

    ; 3. Habilita Interrupção (TIMSK0)
    ldi AUX, 0x01       ; Bit TOIE0
    sts TIMSK0, AUX     ; (TIMSK0 geralmente usa STS, não OUT)

    ; 4. Zera contador de software
    clr CONTADOR_SOFTWARE

    sei                 ; Habilita Global
    rjmp main

main:
    rjmp main           ; Loop vazio! O Timer trabalha sozinho.

; --- ISR DO TIMER (Roda a cada 16ms) ---
isr_timer0:
    push AUX            ; Salva contexto
    in AUX, SREG
    push AUX

    ; Lógica:
    inc CONTADOR_SOFTWARE   ; Mais um estouro aconteceu...
    
    ; Verifica se já deu o tempo (ex: 61 estouros = 1 segundo)
    cpi CONTADOR_SOFTWARE, 61
    brne fim_isr            ; Se não chegou em 61, sai.

    ; Se chegou em 61:
    ; 1. Reseta o contador
    clr CONTADOR_SOFTWARE
    ; 2. Inverte o LED (Seu código de piscar aqui)
    sbi PINB, PB5

fim_isr:
    pop AUX             ; Restaura contexto
    out SREG, AUX
    pop AUX
    reti