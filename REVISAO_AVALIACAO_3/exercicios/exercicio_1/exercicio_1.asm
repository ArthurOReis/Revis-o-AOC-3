; 📝 O Desafio: Pisca-Pisca com "Pause"

; Objetivo:

; 1. Um LED (PB5) deve piscar a cada 0,5 segundos (aproximadamente), controlado pelo Timer0.

; 2. Um Botão (PD2/INT0) deve funcionar como Pause/Play.
    ; Se apertar: O LED para de piscar (congela).
    ; Se apertar de novo: O LED volta a piscar.

.INCLUDE <m328Pdef.inc>

; --- Definições de Pinos ---
.equ LED = PB5          ; LED no pino 13
.equ BOTAO = PD2        ; Botão no pino 2 (INT0)

; --- Registradores ---
.def AUX = R16
.def CONTADOR_TEMPO = R17
.def FLAG_PAUSA = R18

.ORG 0x0000          ; Reset
    RJMP setup

.ORG 0x0002             ; VETOR INT0 (Botão) <--- Faltava este!
    RJMP isr_botao

.ORG 0x0020
    RJMP isr_timer0

setup:
    ; --- 1. Inicializa a Pilha (Stack Pointer) ---
    ; Obrigatório para interrupções funcionarem
    LDI AUX, HIGH(RAMEND)
    OUT SPH, AUX
    LDI AUX, LOW(RAMEND)
    OUT SPL, AUX

    ; --- 2. Configura GPIO (Pinos) ---
    SBI DDRB, LED    ; LED como saída
    CBI DDRD, BOTAO  ; Botão como ENTRADA
    SBI PORTD, BOTAO ; Liga PULL-UP no Botão

    ; --- 3. Configura Interrupção do Botão (INT0) ---
    ; Queremos detectar quando aperta (Borda de Descida)
    ; Tabela EICRA: ISC01=1, ISC00=0 -> Valor 0x02
    LDI AUX, 0x02
    STS EICRA, AUX      ; Configura sensibilidade

    SBI EIMSK, INT0     ; Liga a chave da INT0

    ; --- 4. Configura o Timer0 (O Despertador) ---
    ; A. Zera o contador
    LDI AUX, 0
    OUT TCNT0, AUX

    ; B. Define a velocidade (Prescaler 1024)
    ; Tabela TCCR0B: CS02=1, CS00=1 -> Valor 0x05
    LDI AUX, 0x05
    OUT TCCR0B, AUX

    ; C. Habilita o aviso de estouro (Interrupção)
    LDI AUX, 0x01       ; Bit TOIE0
    STS TIMSK0, AUX

    ; --- 5. Inicializa Variáveis ---
    CLR CONTADOR_TEMPO  ; Zera contador de tempo
    CLR FLAG_PAUSA      ; Começa "despausado"

    ; --- 6. Habilita Geral ---
    SEI                 ; Liga a chave geral das interrupções

    RJMP main           ; Vai para o loop vazio

main:
    RJMP main       ; Loop infinito. Fica aqui "dormindo".
                    ; O processador só sai daqui quando uma Interrupção ocorre.

isr_botao:
    ; 1. Salvar Contexto (Padrão Ouro)
    PUSH AUX
    IN AUX, SREG
    PUSH AUX

    ; 2. Lógica de Alternar (Toggle) a Flag
    CPI FLAG_PAUSA, 1       ; A pausa está ligada?
    BREQ desligar_pausa     ; Se sim, vai para desligar

ligar_pausa:
    LDI FLAG_PAUSA, 1       ; Seta flag para 1
    RJMP fim_botao

desligar_pausa:
    CLR FLAG_PAUSA          ; Seta flag para 0 (Limpa registrador)

fim_botao:
    ; 3. Restaurar Contexto
    POP AUX
    OUT SREG, AUX
    POP AUX
    RETI                    ; Retorna

isr_timer0:
    PUSH AUX
    IN AUX, SREG
    PUSH AUX

    ; 1. Verificar Pausa
    CPI FLAG_PAUSA, 1       ; Está pausado?
    BREQ fim_timer          ; Se sim, sai sem fazer nada (congela o tempo)

    ; 2. Contar Tempo
    INC CONTADOR_TEMPO      ; R17 = R17 + 1
    
    ; 3. Verificar se deu 0,5 segundos (31 estouros)
    CPI CONTADOR_TEMPO, 31
    BRNE fim_timer          ; Se não chegou em 31, sai.

    ; --- Chegou em 0,5s! ---
    ; A. Zera o contador para recomeçar
    CLR CONTADOR_TEMPO

    ; B. Inverte o LED (Toggle)
    SBI PINB, LED           ; Escrever no PINB inverte o PORTB

fim_timer:
    POP AUX
    OUT SREG, AUX
    POP AUX
    RETI