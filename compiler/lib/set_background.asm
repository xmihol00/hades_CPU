
&set_background:                        ; int set_background(int color)
   OUT r0 160                           ; reset the VGA cursor
   POP eax                              ; get the color from the stack
   AND eax eax 15                       ; mask the color
   PUSH edx                             ; save return address
   MOV edx eax                          ; copy the color to edx
   SHL eax eax 4                        ; shift the color to the next nibble
   OR edx edx eax                       ; combine the color
   SHL eax eax 4                        ; shift the color to the next nibble
   OR edx edx eax                       ; combine the color
   SHL eax eax 4                        ; shift the color to the next nibble
   OR edx edx eax                       ; combine the color
   MOV eax 75
   SHL eax eax 10                       ; init counter to 76800 (640 * 480 / 4)
set_background.loop:                    ; loop over all pixels
   OUT edx 162                          ; write the color to the VGA
   SUB eax eax 1                        ; decrement counter
   JNZ eax set_background.loop          ; loop if counter is not zero
   POP edx                              ; restore return address
   RET                                  ; return
EOF
