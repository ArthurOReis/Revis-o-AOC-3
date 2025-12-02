; Questão 1: GPIO
; Inicialize os GPIOs adequadamente.
; Cada vez que o botão INC/DEC for pressionado, incremente (de 0 até 15) uma vez o valor mostrado na porta B e decremente (de 15 até 0) uma vez o valor na porta C.
; Se o botão RST for pressionado, a contagem na porta B deve ser zerada e a porta C deve receber o valor 15.

; Pino,Função,Tipo,Configuração
; Porta B (0-3),Saída (Contagem),Output,DDRB → Saída.
; Porta C (0-3),Saída (Contagem),Output,DDRC → Saída.
; PD2 (INC/DEC),Entrada (INT0),Input,DDRD → Entrada. PORTD → Pull-up.
; PD3 (RST),Entrada (INT1),Input,DDRD → Entrada. PORTD → Pull-up.

; ==========================================
; Sua Tarefa (Parte A): Memória e Cabeçalho
; ==========================================

; 1. Defina o Botão INC/DEC (PD2) e RST (PD3).
; 2. Reserve 2 bytes na memória SRAM (Data Segment dseg) para as variáveis count_b e count_c.

.INCLUDE <m328Pdef.inc>
; REGISTRADORES
.def AUX = R16
.def TEMP = R17
; DEFINIÇÕES DE PINOS
.equ INC_DEC = PD2
.equ RST = PD3

; ===================================
; SEÇÃO DE MEMÓRIA (SRAM)
; ===================================
.dseg
count_b: .byte 1 ; 1 byte para contagem B
count_c: .byte 1 ; 1 byte para contagem C
.cseg
.ORG 0x0000
    RJMP setup

; ==========================================
; Sua Tarefa (Parte B): Configuração GPIO e Inicialização
; ==========================================

; Complete o setup para:

; 1. Configurar Port B (pinos 0-3) e Port C (pinos 0-3) como Saída. Dica: Use LDI AUX, 0b00001111 e depois OUT/STS DDRx, AUX.
; 2. Configurar PD2 e PD3 como Entrada com Pull-up.
; 3. Inicializar a SRAM: count_b = 0 e count_c = 15.

; O que adicionei e por quê:

; 1. Stack Pointer (SP): Essencial inicializar a pilha (SPH, SPL) sempre que vamos usar memória RAM ou sub-rotinas (rcall), senão o processador se perde.

; 2. Configuração de Portas: Defini B e C como saídas e D como entrada.

; 3. Estado Inicial: Zerei a contagem B e setei a contagem C para 15 (binário 0000 1111).

setup:
; --- Inicialização da Pilha (Obrigatório para usar SRAM/Sub-rotinas) ---
    ldi AUX, high(RAMEND)
    out SPH, AUX
    ldi AUX, low(RAMEND)
    out SPL, AUX

    ; 1. Configurar Port B e Port C como SAÍDA (4 bits inferiores)
    ldi AUX, 0b00001111       ; 0b00001111 (Pinos 0 a 3 como saída) - Pin7...Pin4 (0 = Entrada) | Pin3...Pin0 (1 = Saída)
    out DDRB, AUX       ; Configura DDRB
    out DDRC, AUX       ; Configura DDRC

    ; 2. Configurar PD2 e PD3 como ENTRADA
    ; No AVR, 0 é entrada. Como os pinos PD2/PD3 são bits 2 e 3,
    ; precisamos garantir que estejam em 0.
    cbi DDRD, INC_DEC   ; PD2 entrada
    cbi DDRD, RST       ; PD3 entrada

    ; 3. Habilitar PULL-UP (Escrever 1 no PORT de entrada)
    sbi PORTD, INC_DEC  ; Pull-up no PD2
    sbi PORTD, RST      ; Pull-up no PD3

    ; 4. Inicializar a SRAM e os LEDs
    ; --- Inicializa count_b com 0 ---
    ldi AUX, 0
    sts count_b, AUX    ; Salva 0 na memória RAM
    out PORTB, AUX      ; Mostra 0 nos LEDs B

    ; --- Inicializa count_c com 15 ---
    ldi AUX, 15
    sts count_c, AUX    ; Salva 15 na memória RAM
    out PORTC, AUX      ; Mostra 15 nos LEDs C

    rjmp main

main:
    ; --- Verifica Botão RST (PD3) ---
    sbis PIND, RST      ; Pula se o pino RST estiver SOLTO (1). Se for 0 (apertado), executa.
    rjmp rotina_rst     ; Vai para a rotina de reset

    ; --- Verifica Botão INC/DEC (PD2) ---
    sbis PIND, INC_DEC  ; Pula se o pino INC_DEC estiver SOLTO (1).
    rjmp rotina_inc_dec ; Vai para a rotina de incremento/decremento

    rjmp main           ; Volta para o início do loop

; ==========================================================
; ROTINA DE RESET
; ==========================================================
rotina_rst:
    ; 1. Zerar count_b
    ldi AUX, 0
    sts count_b, AUX
    out PORTB, AUX

    ; 2. Setar count_c para 15
    ldi AUX, 15
    sts count_c, AUX
    out PORTC, AUX

    ; 3. Trava de segurança: Espera soltar o botão RST
espera_soltar_rst:
    sbis PIND, RST      ; Se ainda estiver apertado (0), pula a próxima e volta pro loop
    rjmp espera_soltar_rst
    rjmp main           ; Botão solto, volta pro main

; ==========================================================
; ROTINA INC/DEC
; ==========================================================
rotina_inc_dec:
    ; --- Parte 1: Incrementar PORTB ---
    lds AUX, count_b    ; Carrega valor atual da RAM
    inc AUX             ; Incrementa (R16++)
    andi AUX, 0x0F      ; MASCARA: Mantém apenas os 4 bits (0-15). Se for 16 (10000), vira 0.
    sts count_b, AUX    ; Salva de volta na RAM
    out PORTB, AUX      ; Atualiza os LEDs

    ; --- Parte 2: Decrementar PORTC ---
    lds AUX, count_c    ; Carrega valor atual da RAM
    dec AUX             ; Decrementa (R16--)
    andi AUX, 0x0F      ; MASCARA: Garante que fique em 4 bits (se baixar de 0, vira 15 automaticamente em binário 4 bits)
    sts count_c, AUX    ; Salva na RAM
    out PORTC, AUX      ; Atualiza os LEDs

    ; 3. Trava de segurança: Espera soltar o botão INC/DEC
espera_soltar_inc:
    sbis PIND, INC_DEC  ; Se ainda estiver apertado (0), fica aqui
    rjmp espera_soltar_inc
    rjmp main           ; Botão solto, volta pro main