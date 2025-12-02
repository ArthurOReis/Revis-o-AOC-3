; 📝 O Desafio: Pisca-Pisca com "Pause"

; Objetivo:

; 1. Um LED (PB5) deve piscar a cada 0,5 segundos (aproximadamente), controlado pelo Timer0.

; 2. Um Botão (PD2/INT0) deve funcionar como Pause/Play.
    ; Se apertar: O LED para de piscar (congela).
    ; Se apertar de novo: O LED volta a piscar.

.INCLUDE <m328Pdef.inc>

.def AUX = R16
.def CONTADOR_TEMPO = R17
.def PAUSA = R18

.ORG 0x0000          ; Reset
    RJMP setup

.ORG 0x0020
    RJMP isr_timer0

setup:

isr_timer0: