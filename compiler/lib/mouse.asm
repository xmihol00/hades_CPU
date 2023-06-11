
&init_mouse:                            ; int init_mouse(), returns 0 on success
   PUSH edx                             ; save return address
init_mouse.init_loop:                   ; while mouse is not initialized
   IN eax 129                           ; load the status register
   AND edx eax 4                        ; check if mouse is initialized
   JZ edx init_mouse.init_loop          ; loop if not initialized
   
   AND eax eax 24                       ; mask bits 4 and 5
   NEQ eax eax 8                        ; ensure only bit 4 is not set
   JNZ eax init_mouse.return            ; return if bit 4 is not set

   MOV edx 244                          ; set init command
   OUT edx 128                          ; send init command 

init_mouse.ack_wait:
   IN eax 129                           ; load the status register
   AND eax eax 1                        ; check if ack bit is set
   JZ eax init_mouse.ack_wait           ; loop if ack bit is not set
   IN r0 128                            ; discard the ack byte
   MOV eax 0                            ; return 0
   
init_mouse.return:                      
   POP edx                              ; restore return address
   RET                                  ; return
EOF

&mouse_status:                          ; int mouse_status(), returns byte 1 of mouse events or 0 if no events
   PUSH edx                             ; save return address
   IN eax 129                           ; load the status register
   AND eax eax 1                        ; check if data is available
   JZ eax mouse_status.no_events        ; return 0 if no events

   IN eax 128                           ; load byte 1
   
mouse_status.discard1:
   IN edx 129                           ; load the status register
   AND edx edx 1                        ; check if data is available
   JZ edx mouse_status.discard1         ; loop if no data available
   IN r0 128                            ; load discard byte 2

mouse_status.discard2:
   IN edx 129                           ; load the status register
   AND edx edx 1                        ; check if data is available
   JZ edx mouse_status.discard2         ; loop if no data available
   IN r0 128                            ; load discard byte 3

mouse_status.no_events:
   POP edx                              ; restore return address
   RET                                  ; return
EOF
