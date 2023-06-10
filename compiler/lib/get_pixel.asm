
&get_pixel:                             ; int get_pixel(int x, int y)
   PUSH edx                             ; save return address
   LOAD edx [esp+1]                     ; load y
   LOAD eax [esp+2]                     ; load x
   MUL eax eax 640                      ; compute offset to row x
   ADD eax eax edx                      ; add offset to colum y
   OUT eax 160                          ; set the VGA cursor
   LOAD eax [esp+1]                     ; load color
   IN eax 161                           ; get a color of the pixel
   POP edx                              ; restore return address
   ADD esp esp 2                        ; pop parameters
   RET                                  ; return
EOF
