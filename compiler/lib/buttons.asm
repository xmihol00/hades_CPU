
&buttons_status:                        ; int buttons_status()
   PUSH edx                             ; save return value
   MOV edx 15                           ; set bits 0-3 to 1
   IN eax 66                            ; read buttons status
   OUT edx 66                           ; reset buttons
   POP edx                              ; restore return value
   RET                                  ; return
EOF
