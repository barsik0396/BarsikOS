; BarsikOS v0.3 - Stage 2 Bootloader
; Показывает логотип и загружает систему
[BITS 16]
[ORG 0x1000]

start:
    ; Сообщение что мы в Stage 2
    mov si, msg_stage2
    call print
    
    ; Очистка экрана
    mov ax, 0x0003
    int 0x10
    
    ; Рисуем UI загрузки
    call draw_logo
    
    mov si, msg_loading
    call print
    
    call show_progress
    
    ; Прыгаем на установщик (он идёт сразу после stage2)
    jmp installer_start

error:
    mov si, msg_err
    call print
    cli
    hlt

draw_logo:
    ; Переходим на строку 7
    mov ah, 0x02
    mov bh, 0
    mov dh, 7
    mov dl, 32
    int 0x10
    
    mov si, msg_logo
    call print
    ret

show_progress:
    ; Переходим на строку 15
    mov ah, 0x02
    mov bh, 0
    mov dh, 15
    mov dl, 0
    int 0x10
    
    mov si, progress_empty
    call print
    
    ; Анимация прогресс-бара
    mov cx, 30          ; 30 шагов
.loop:
    push cx
    
    ; Задержка
    mov cx, 0xFFFF
.delay:
    loop .delay
    
    ; Добавляем #
    mov ah, 0x0E
    mov al, '#'
    int 0x10
    
    pop cx
    loop .loop
    
    ret

print:
    lodsb
    or al, al
    jz .done
    mov ah, 0x0E
    int 0x10
    jmp print
.done:
    ret

msg_stage2 db 'Stage 2 started!', 0x0D, 0x0A, 0
msg_loading db 'Loading...', 0x0D, 0x0A, 0
msg_kernel db 'Loading kernel...', 0x0D, 0x0A, 0
msg_jump db 'Jumping to kernel...', 0x0D, 0x0A, 0
msg_logo db 'BarsikOS', 0
progress_empty db '------', 0
msg_err db 'Kernel Load Error!', 0

times 9216-($-$$) db 0  ; Заполняем до 9KB (18 секторов)