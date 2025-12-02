.INCLUDE <m328Pdef.inc>

; --- REGISTRADORES ---
.def AUX = R16
.def TEMP = R17

; --- DEFINIÇÕES DE PINOS ---
.equ INC_DEC = PD2  ; INT0
.equ RST = PD3      ; INT1

; --- MEMÓRIA ---
.dseg
count_b: .byte 1
count_c: .byte 1

.cseg
; ==========================================================
; 1. TABELA DE VETORES (Obrigatório vir primeiro)
; ==========================================================
.ORG 0x0000             ; Reset
    RJMP setup

.ORG 0x0002             ; INT0 (Botão INC/DEC)
    RJMP isr_inc_dec

.ORG 0x0004             ; INT1 (Botão RST)
    RJMP isr_rst

.ORG 0x0034             ; Área segura
setup:
    ; --- Inicialização da Pilha (SP) ---
    ldi AUX, high(RAMEND)
    out SPH, AUX
    ldi AUX, low(RAMEND)
    out SPL, AUX

    ; --- Configuração GPIO (Igual à Questão 1) ---
    ldi AUX, 0x0F
    out DDRB, AUX       ; Port B Saída
    out DDRC, AUX       ; Port C Saída

    cbi DDRD, INC_DEC   ; PD2 Entrada
    cbi DDRD, RST       ; PD3 Entrada
    sbi PORTD, INC_DEC  ; Pull-up PD2
    sbi PORTD, RST      ; Pull-up PD3

    ; --- Inicialização Variáveis ---
    ldi AUX, 0
    sts count_b, AUX
    out PORTB, AUX      ; B começa em 0

    ldi AUX, 15
    sts count_c, AUX
    out PORTC, AUX      ; C começa em 15

    ; ======================================================
    ; CONFIGURAÇÃO DAS INTERRUPÇÕES (A NOVIDADE)
    ; ======================================================
    
    ; 1. Configurar EICRA
    ; INT1 (RST) -> Borda Descida (10)
    ; INT0 (INC/DEC) -> Qualquer Mudança (01)
    ; Binário: 0000 10 01 -> Hex: 0x09
    ldi AUX, 0x09
    sts EICRA, AUX

    ; 2. Habilitar INT0 e INT1 no EIMSK
    ; Bit 0 (INT0) e Bit 1 (INT1) -> 0000 0011 -> 0x03
    ldi AUX, 0x03
    out EIMSK, AUX

    ; 3. Chave Geral
    sei

    rjmp main

; ==========================================================
; LAÇO PRINCIPAL
; ==========================================================
main:
    rjmp main           ; Loop vazio (faz nada, só espera)

; ==========================================================
; ISR - INC/DEC (INT0) - Dispara na Ida e na Volta
; ==========================================================
isr_inc_dec:
    ; 1. Salvar Contexto
    push AUX
    in AUX, SREG
    push AUX

    ; 2. Decidir: Foi Aperto (0) ou Soltura (1)?
    sbic PIND, INC_DEC  ; Se pino for 0 (Apertado), pula a instrução
    rjmp foi_soltura    ; Se não pulou, é 1 (Solto)

foi_aperto:
    ; --- INCREMENTA PORT B ---
    lds AUX, count_b
    inc AUX
    andi AUX, 0x0F      ; Máscara 0-15
    sts count_b, AUX
    out PORTB, AUX
    rjmp fim_isr_inc

foi_soltura:
    ; --- DECREMENTA PORT C ---
    lds AUX, count_c
    dec AUX
    andi AUX, 0x0F      ; Máscara 0-15
    sts count_c, AUX
    out PORTC, AUX

fim_isr_inc:
    ; 3. Restaurar Contexto
    pop AUX
    out SREG, AUX
    pop AUX
    reti

; ==========================================================
; ISR - RESET (INT1) - Dispara só na Descida
; ==========================================================
isr_rst:
    push AUX
    in AUX, SREG
    push AUX

    ; --- RESETAR VARIÁVEIS ---
    ldi AUX, 0
    sts count_b, AUX
    out PORTB, AUX

    ldi AUX, 15
    sts count_c, AUX
    out PORTC, AUX

    pop AUX
    out SREG, AUX
    pop AUX
    reti