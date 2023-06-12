
&putchar:                               ; int putchar(int value), returns the passed value
putchar.buffer_full:                    ; while transmit buffer is full
   IN eax 97                            ; load the status of the UART
   AND eax eax 2                        ; check if transmit buffer is full
   JZ eax putchar.buffer_full           ; loop if transmit buffer is full
   POP eax                              ; pop the value from stack
   OUT eax 96                           ; write the value to the UART
   RET                                  ; return
EOF

&getchar:                               ; int putchar()
getchar.no_data:                        ; while data are not available
   IN eax 97                            ; load the status of the UART
   AND eax eax 1                        ; check if any data are available
   JZ eax getchar.no_data               ; loop if data are not available
   IN eax 96                            ; read a value from the UART
   RET                                  ; return
EOF
