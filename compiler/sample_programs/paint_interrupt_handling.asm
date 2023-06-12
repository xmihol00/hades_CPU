
&init_paint_interrupts:                 ; int init_paint_interrupts()
   MOV eax -1                           ; set bits 0-15 to 1
   SISA 1 console_interrupt_handler     ; set interrupt handler
   OUT eax 67                           ; enable interrupts from switches 1-8
   ENI                                  ; enable interrupts
   RET                                  ; return
EOF

&console_interrupt_handler:             ; int console_interrupt_handler()
   DEI                                  ; disable interrupts
   PUSH edx                             ; save return address
   PUSH ebp                             ; save base pointer
   IN ebp 68                            ; read switches
   
   SHR eax ebp 4                        ; shift switches to 5-8
   AND eax eax 31                       ; mask out all switches but 5-9
   LOAD edx @CURSOR_SPEED               ; load switches state (speed)
   XOR edx edx eax                      ; update switches state (speed)
   STORE @CURSOR_SPEED edx              ; store switches state (speed)

   AND eax ebp 15                       ; mask out all switches but 1-4
   LOAD edx @CURRENT_COLOR              ; load switches state (color)
   XOR edx edx eax                      ; update switches state (color)
   STORE @CURRENT_COLOR edx             ; store switches state (color)
   PUSH edx                             ; push color
   CALL draw_frame                      ; draw frame

   SHR eax ebp 13                       ; shift switches to 14-16
   AND edx eax 1                        ; mask out all switch 14
   STORE @MARK_POINT edx                ; store switches state (cursor on)
   AND edx eax 2                        ; mask out all switch 15
   STORE @DRAW edx                      ; store switches state (draw line)
   AND edx eax 4                        ; mask out all switch 16
   STORE @CLEAR edx                     ; store switches state (clear screen)

   MOV eax -1                           ; set bits 0-15 to 1
   OUT eax 68                           ; reset interrupts from all switches
   POP ebp                              ; restore base pointer
   POP edx                              ; restore return address
   ENI                                  ; enable interrupts
   RETI                                 ; return from interrupt
EOF
