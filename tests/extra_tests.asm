; ========================================================================
; EXTRA TESTS FOR STABILITY
; ========================================================================

bits 16

; There were no memory/accumulator tests in listing 40,
; so these test putting data into the low byte of the accumulator
mov [15], al
mov al, [8]
mov [300], ax
mov ax, [400]