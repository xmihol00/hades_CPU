
&putchar:                               ; int putchar(int value), returns the passed value
putchar.buffer_full:                    ; while transmit buffer is full
   IN eax 97                            ; load the status of the UART
   AND eax eax 2                        ; check if transmit buffer is full
   JZ eax putchar.buffer_full           ; loop if transmit buffer is full
   POP eax                              ; pop the value from stack
   OUT eax 96                           ; write the value to the UART
   RET                                  ; return
