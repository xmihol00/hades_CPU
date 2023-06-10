@__switches_state: 0

&init_frame_interrupts:                 ; int init_frame_interrupts()
   MOV eax 15                           ; set bits 0-3 to 1
   SISA 1 frame_interrupt_handler       ; set interrupt handler
   OUT eax 67                           ; enable interrupts from switches 0-3
   ENI                                  ; enable interrupts
   RET                                  ; return
EOF

&frame_interrupt_handler:               ; int frame_interrupt_handler()
   PUSH edx                             ; save edx
   IN eax 68                            ; read switches
   AND eax eax 15                       ; mask out all but bits 0-3
   LOAD edx @__switches_state           ; load switches state
   XOR edx edx eax                      ; update switches state
   STORE @__switches_state edx          ; store switches state
   MOV eax 15                           ; set bits 0-3 to 1
   OUT eax 68                           ; reset interrupts from switches 0-3
   PUSH edx                             ; push color
   CALL draw_frame                      ; draw frame
   POP edx                              ; restore edx
   RETI                                 ; return from interrupt
EOF