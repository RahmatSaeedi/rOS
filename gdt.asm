; GDT   - Made up of segment descriptors
;       - Describes a segment, its location, virtual address space, size, protection characteristics, ...
;       - Descriptors
;           - null descriptor
;           - code descriptor
;           - data descriptor
;
; INFO: Page 146 of amd.com/system/files/TechDocs/24593.pdf
GDT:
GDT_NULL: equ $ - GDT
        dw 0    ; Segment limit
        dw 0    ; Base address [15:0]
        db 0    ; Base address [23:16]
        db 0    ; {P, DPL[0:1] , 1,1, C,R,A}
        db 0    ; {G, D, L, AVL, Segment Limit[19:16]}
        db 0    ; Base address [31:24]
GDT_Code:   equ $ - GDT
        dw 0    ; Segment limit
        dw 0    ; Base address [15:0]
        db 0    ; Base address [23:16]
        db 10011010b    ; {P, DPL[0:1] , 1, 1, C,R,A}           Perivilage level 00 = kernel = most priviliged, readable, present,
        db 00100000b    ; {G, D, L, AVL, Segment Limit[19:16]}  "L = long mode = 1", D = Default Size = 0
        db 0    ; Base address [31:24]
GDL_Data:
        dw 0    ; Segment limit
        dw 0    ; Base address [15:0]
        db 0    ; Base address [23:16]
        db 10000000b    ; {P, DPL[0:1] , 1,0, E,W,A}            P = Present
        db 0    ; {G, D/B, , AVL, Segment Limit[19:16]}
        db 0    ; Base address [31:24]
GDL_Pointer:
        dw $ - GDT - 1      ; Size of GDT
        dq GDT              ; Location of GDT in memory



