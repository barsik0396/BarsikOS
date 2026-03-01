; BarsikOS v0.3 - Stage 1 Bootloader
; Загружает Stage 2 и передаёт управление
[BITS 16]
[ORG 0x7C00]

start:
    cli
    xor ax, ax
    mov ds, ax
    mov es, ax
    mov ss, ax
    mov sp, 0x7C00
    sti
    
    ; Загружаем 36 секторов (простой способ - надеемся что BIOS поддерживает)
    mov ah, 0x02
    mov al, 36          ; Пробуем 36 секторов сразу
    mov ch, 0
    mov cl, 2
    mov dh, 0
    mov bx, 0x1000
    int 0x13
    jnc jump_stage2
    
    ; Если не получилось - пробуем по 18
    mov ah, 0x02
    mov al, 18
    mov ch, 0
    mov cl, 2
    mov dh, 0
    mov bx, 0x1000
    int 0x13
    jc error
    
    ; Загружаем вторую половину
    mov ah, 0x02
    mov al, 18
    mov ch, 0
    mov cl, 20          ; Следующие 18 секторов
    mov dh, 0
    mov bx, 0x3400      ; 0x1000 + 18*512
    int 0x13
    jc error

jump_stage2:
    jmp 0x0000:0x1000

error:
    mov si, msg
    call print
    cli
    hlt

print:
    lodsb
    or al, al
    jz .done
    mov ah, 0x0E
    int 0x10
    jmp print
.done:
    ret

msg db 'ERR', 0

times 510-($-$$) db 0
dw 0xAA55