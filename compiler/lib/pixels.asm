
&draw_pixel:                            ; int draw_pixel(int x, int y, int color)
   PUSH edx                             ; save return address
   LOAD edx [esp+3]                     ; load x
   LOAD eax [esp+2]                     ; load y
   MUL eax eax 640                      ; compute offset to row y
   ADD eax eax edx                      ; add offset to colum x
   OUT eax 160                          ; set the VGA cursor
   LOAD eax [esp+1]                     ; load color
   OUT eax 161                          ; write the color to the VGA
   POP edx                              ; restore return address
   ADD esp esp 3                        ; pop parameters
   RET                                  ; return
EOF


&draw_quad_pixel:                       ; int draw_quad_pixel(int x, int y, int color)
   PUSH edx                             ; save return address
   LOAD edx [esp+2]                     ; load y
   LOAD eax [esp+3]                     ; load x
   MUL eax eax 640                      ; compute offset to row x
   ADD eax eax edx                      ; add offset to colum y
   OUT eax 160                          ; set the VGA cursor
   LOAD eax [esp+1]                     ; load color
   OUT eax 162                          ; write the color to the VGA
   POP edx                              ; restore return address
   ADD esp esp 3                        ; pop parameters
   RET                                  ; return
EOF

&get_pixel:                             ; int get_pixel(int x, int y)
   PUSH edx                             ; save return address
   LOAD edx [esp+2]                     ; load x
   LOAD eax [esp+1]                     ; load y
   MUL eax eax 640                      ; compute offset to row y
   ADD eax eax edx                      ; add offset to colum x
   OUT eax 160                          ; set the VGA cursor
   LOAD eax [esp+1]                     ; load color
   IN eax 161                           ; get a color of the pixel
   POP edx                              ; restore return address
   ADD esp esp 2                        ; pop parameters
   RET                                  ; return
EOF

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
