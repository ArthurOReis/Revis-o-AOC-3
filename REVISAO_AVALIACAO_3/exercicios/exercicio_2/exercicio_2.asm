; 📝 Questão Desafio: O "Gerador de Frequência Variável"
; Cenário: Você deve criar um sistema controlador de sinal para uma esteira industrial.

; O LED de Operação (PB5): Deve piscar continuamente comandado pelo Timer0.

; A Contagem de Ciclos (Porta C): Os 4 primeiros bits da Porta C (PC0 a PC3) devem exibir, em binário, quantas vezes o LED de Operação piscou (incrementa a cada ciclo acende-apaga).

; Botão MODO (PD2 / INT0): Alterna a velocidade do pisca-pisca.

; Modo Lento (Inicial): O LED inverte a cada 60 estouros do Timer (aprox. 1 segundo).

; Modo Rápido: O LED inverte a cada 15 estouros do Timer (aprox. 0,25 segundos).

; Botão RESET (PD3 / INT1): Quando pressionado, zera imediatamente o contador de ciclos mostrado na Porta C.

; --------------------------------------------------------------------

; 🧠 Análise Prévia (O "Rascunho Mental")
; Antes de codar, precisamos definir as variáveis. Vamos precisar de memória (SRAM ou Registradores) para:

; CONTADOR_ESTOUROS: Para saber se já deu o tempo de inverter o LED.

; LIMITE_ATUAL: Para saber se devemos comparar com 60 (Lento) ou 15 (Rápido).

; CONTAGEM_PC: Para guardar o valor que vai para a Porta C (0 a 15).

.INCLUDE <m328Pdef.inc>

.equ LED = PB5
.equ BTN_MODO = PD2
.equ BTN_RESET = PD3

.def AUX = R16
.def CONTA_ESTOURO = R17
.def LIM_VEL = R18

.dseg
count_b: .byte 1
count_c: .byte 1

.cseg
.ORG 0x0000
    RJMP setup

.ORG 0x0002
    RJMP isr_int0

.ORG 0x0004
    RJMP isr_int1

.ORG 0x0020
    RJMP isr_timer0

setup:
    ldi AUX, high(RAMEND)
    out SPH, AUX
    ldi AUX, low(RAMEND)
    out SPL, AUX; 
    
    ; ----------------------------------------------------
    ; 2. CONFIGURAÇÃO DE GPIO (Portas)
    ; ----------------------------------------------------
    ; A. LED (PB5) como SAÍDA
    sbi DDRB, LED
    
    ; B. Porta C (PC0 a PC3) como SAÍDA (Para mostrar a contagem)
    ldi AUX, 0x0F       ; 0000 1111 (4 bits inferiores)
    out DDRC, AUX

    ; C. Botões (PD2 e PD3) como ENTRADA
    cbi DDRD, BTN_MODO
    cbi DDRD, BTN_RESET

    ; D. Habilita PULL-UP nos Botões (Essencial!)
    sbi PORTD, BTN_MODO
    sbi PORTD, BTN_RESET

    ; ----------------------------------------------------
    ; 3. CONFIGURAÇÃO DAS INTERRUPÇÕES EXTERNAS (INT0 e INT1)
    ; ----------------------------------------------------
    ; Queremos Borda de Descida (Falling Edge) para AMBOS.
    ; INT1 (Bits 3,2) = 10 | INT0 (Bits 1,0) = 10
    ; Binário: 0000 10 10 -> Hex: 0x0A
    ldi AUX, 0x0A
    sts EICRA, AUX      ; Configura sensibilidade

    ; Habilita as duas interrupções na máscara
    ; Bit 0 (INT0) e Bit 1 (INT1) -> 0000 0011 -> Hex: 0x03
    ldi AUX, 0x03
    out EIMSK, AUX

    ; ----------------------------------------------------
    ; 4. CONFIGURAÇÃO DO TIMER0
    ; ----------------------------------------------------
    ; A. Zera o contador do hardware
    ldi AUX, 0
    out TCNT0, AUX

    ; B. Prescaler 1024 (O mais lento)
    ; Tabela TCCR0B: CS02=1, CS00=1 -> Hex: 0x05
    ldi AUX, 0x05
    out TCCR0B, AUX

    ; C. Habilita Interrupção de Overflow (TOIE0)
    ldi AUX, 0x01
    sts TIMSK0, AUX

    ; ----------------------------------------------------
    ; 5. INICIALIZAÇÃO DE VARIÁVEIS (O Estado Inicial)
    ; ----------------------------------------------------
    ; Começamos no Modo Lento (60 estouros = 1 seg)
    ldi LIM_VEL, 60     ; R18 = 60
    
    clr CONTA_ESTOURO   ; R17 = 0
    
    ; Zera a contagem da Porta C na memória RAM
    ldi AUX, 0
    sts count_c, AUX
    out PORTC, AUX      ; Apaga os LEDs da Porta C

    ; ----------------------------------------------------
    ; 6. HABILITAÇÃO GERAL
    ; ----------------------------------------------------
    sei                 ; Liga a chave geral
    rjmp main
; ==========================================================
; LOOP PRINCIPAL
; ==========================================================
main:
    rjmp main       ; O processador apenas espera aqui.

; ==========================================================
; ISR - BOTÃO MODO (INT0) - Alterna 60 <-> 15
; ==========================================================
isr_int0:
    push AUX
    in AUX, SREG
    push AUX

    ; Verifica qual a velocidade atual
    cpi LIM_VEL, 60     ; É lento (60)?
    breq muda_pra_rapido

    ; Se caiu aqui, é rápido. Então muda pra lento.
    ldi LIM_VEL, 60
    rjmp fim_int0

muda_pra_rapido:
    ldi LIM_VEL, 15     ; Define novo limite para 15

fim_int0:
    pop AUX
    out SREG, AUX
    pop AUX
    reti

; ==========================================================
; ISR - BOTÃO RESET (INT1) - Zera Porta C
; ==========================================================
isr_int1:
    push AUX
    in AUX, SREG
    push AUX

    ; Zera variável na RAM
    ldi AUX, 0
    sts count_c, AUX
    
    ; Zera saída física
    out PORTC, AUX

    pop AUX
    out SREG, AUX
    pop AUX
    reti

; ==========================================================
; ISR - TIMER0 (Overflow) - Controla o Pisca e Contagem
; ==========================================================
isr_timer0:
    push AUX
    in AUX, SREG
    push AUX

    ; 1. Incrementa contador de estouros
    inc CONTA_ESTOURO   ; R17++

    ; 2. Compara com o Limite Atual (pode ser 15 ou 60)
    cp CONTA_ESTOURO, LIM_VEL
    brne fim_timer      ; Se não chegou no limite, sai.

    ; --- CHEGOU NO TEMPO! ---
    
    ; A. Zera contagem de tempo
    clr CONTA_ESTOURO

    ; B. Inverte LED de Operação (PB5)
    sbi PINB, LED

    ; C. Incrementa Contagem de Ciclos (Porta C)
    lds AUX, count_c    ; Busca valor da RAM
    inc AUX             ; Incrementa
    andi AUX, 0x0F      ; Máscara (Mantém 0-15)
    sts count_c, AUX    ; Salva na RAM
    out PORTC, AUX      ; Mostra nos LEDs

fim_timer:
    pop AUX
    out SREG, AUX
    pop AUX
    reti