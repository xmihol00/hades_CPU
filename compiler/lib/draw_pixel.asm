
&draw_pixel:                            ; int draw_pixel(int x, int y, int color)
   PUSH edx                             ; save return address
   LOAD edx [esp+2]                     ; load y
   LOAD eax [esp+3]                     ; load x
   MUL eax eax 640                      ; compute offset to row x
   ADD eax eax edx                      ; add offset to colum y
   OUT eax 160                          ; set the VGA cursor
   LOAD eax [esp+1]                     ; load color
   OUT eax 161                          ; write the color to the VGA
   POP edx                              ; restore return address
   ADD esp esp 3                        ; pop parameters
   RET                                  ; return
EOF
