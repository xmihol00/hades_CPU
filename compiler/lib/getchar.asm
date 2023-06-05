
&getchar:                               ; int putchar()
getchar.no_data:                        ; while data are not available
   IN eax 97                            ; load the status of the UART
   AND eax eax 1                        ; check if any data are available
   JZ eax getchar.no_data               ; loop if data are not available
   IN eax 96                            ; read a value from the UART
   RET                                  ; return
