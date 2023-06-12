
&init_7segment:                         ; int init_7segment()
   MOV eax 1                            ; set eax to 1
   SHL eax eax 31                       ; set bit 31 to 1
   OUT eax 224                          ; initialize 7-segment display
   RET                                  ; return
EOF

&display_7segment:                      ; int display_7segment(int value)
   POP eax                              ; get value
   OUT eax 224                          ; display value
   RET                                  ; return
EOF
