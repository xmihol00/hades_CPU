
&init_paint_console:                    ; int init_paint_console()
   MOV eax 255                           ; set bits 0-7 to 1
   SISA 1 paint_interrupt_handler       ; set interrupt handler
   OUT eax 67                           ; enable interrupts from switches 1-8
   ENI                                  ; enable interrupts
   RET                                  ; return
EOF

&paint_interrupt_handler:               ; int paint_interrupt_handler()
   PUSH edx                             ; save return address
   PUSH ebp                             ; save base pointer
   IN ebp 68                            ; read switches
   
   SHR eax ebp 4                        ; shift switches to bits 5-8
   AND eax eax 15                       ; mask out all but bits 5-8
   LOAD edx @CURSOR_SPEED               ; load switches state (speed)
   XOR edx edx eax                      ; update switches state (speed)
   STORE @CURSOR_SPEED edx              ; store switches state (speed)

   AND eax ebp 15                       ; mask out all but bits 0-3
   LOAD edx @CURRENT_COLOR              ; load switches state (color)
   XOR edx edx eax                      ; update switches state (color)
   STORE @CURRENT_COLOR edx             ; store switches state (color)
   PUSH edx                             ; push color
   CALL draw_frame                      ; draw frame

   MOV eax 255                          ; set bits 0-7 to 1
   OUT eax 68                           ; reset interrupts from switches 1-8
   POP ebp                              ; restore base pointer
   POP edx                              ; restore return address
   RETI                                 ; return from interrupt
EOF