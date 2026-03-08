; BarsikOS v0.3 - Stage 2 Bootloader
[BITS 16]
[ORG 0x1000]

start:
    mov ax, 0x0003
    int 0x10

    ; Показываем курсор пока грузимся
    mov ah, 0x01
    mov cx, 0x0607
    int 0x10

    mov ah, 0x05
    mov al, 0
    int 0x10

    call s2_draw_boot_screen
    call s2_show_progress_bar

    jmp installer_start

; --- Локальный vga_print (до подключения ui.asm) ---
; dh=row, dl=col, bl=attr, si=str
s2_vprint:
    push ax
    push cx
    push di
    push es
    mov ax, 0xB800
    mov es, ax
    movzx ax, dh
    mov cx, 80
    mul cx
    movzx cx, dl
    add ax, cx
    shl ax, 1
    mov di, ax
    mov ah, bl
.loop:
    lodsb
    or al, al
    jz .done
    stosw
    jmp .loop
.done:
    pop es
    pop di
    pop cx
    pop ax
    ret

; --- Залить строку ---
; dh=row, dl=col, cx=count, al=char, bl=attr
s2_fill:
    push ax
    push bx
    push cx
    push di
    push es
    push ax             ; char
    mov ax, 0xB800
    mov es, ax
    movzx ax, dh
    push cx
    mov cx, 80
    mul cx
    pop cx
    push cx
    movzx cx, dl
    add ax, cx
    shl ax, 1
    mov di, ax
    pop cx
    pop ax
    mov ah, bl
.loop:
    stosw
    loop .loop
    pop es
    pop di
    pop cx
    pop bx
    pop ax
    ret

s2_draw_boot_screen:
    ; Залить весь экран синим
    push ax
    push cx
    push di
    push es
    mov ax, 0xB800
    mov es, ax
    xor di, di
    mov cx, 2000
    mov ax, 0x1720      ; синий фон, пробел
.fill:
    stosw
    loop .fill
    pop es
    pop di
    pop cx
    pop ax

    ; Верхний бар (строка 0) белый на синем
    push ax
    push cx
    push di
    push es
    mov ax, 0xB800
    mov es, ax
    xor di, di
    mov cx, 80
    mov ax, 0x1F20
.tb:
    stosw
    loop .tb
    pop es
    pop di
    pop cx
    pop ax

    mov si, s2_topbar
    mov dh, 0
    mov dl, 1
    mov bl, 0x1F
    call s2_vprint

    ; Нижний бар (строка 24)
    push ax
    push cx
    push di
    push es
    mov ax, 0xB800
    mov es, ax
    mov di, 24*80*2
    mov cx, 80
    mov ax, 0x7020
.bb:
    stosw
    loop .bb
    pop es
    pop di
    pop cx
    pop ax

    mov si, s2_bottombar
    mov dh, 24
    mov dl, 1
    mov bl, 0x70
    call s2_vprint

    ; Рамка ASCII вокруг логотипа
    ; Верхняя линия
    push ax
    push cx
    push di
    push es
    mov ax, 0xB800
    mov es, ax
    mov di, (6*80 + 18)*2
    mov al, '+'
    mov ah, 0x1E
    stosw
    mov cx, 42
.tl:
    mov al, '-'
    stosw
    loop .tl
    mov al, '+'
    stosw
    pop es
    pop di
    pop cx
    pop ax

    ; Боковые линии строк 7-14
    mov dh, 7
.sides:
    cmp dh, 14
    ja .sides_done
    push dx
    push ax
    push cx
    push di
    push es
    mov ax, 0xB800
    mov es, ax
    ; Левая |
    movzx ax, dh
    imul ax, 80
    add ax, 18
    shl ax, 1
    mov di, ax
    mov al, '|'
    mov ah, 0x1E
    stosw
    ; Правая |
    movzx ax, dh
    imul ax, 80
    add ax, 18+43
    shl ax, 1
    mov di, ax
    mov al, '|'
    stosw
    pop es
    pop di
    pop cx
    pop ax
    pop dx
    inc dh
    jmp .sides
.sides_done:

    ; Нижняя линия
    push ax
    push cx
    push di
    push es
    mov ax, 0xB800
    mov es, ax
    mov di, (15*80 + 18)*2
    mov al, '+'
    mov ah, 0x1E
    stosw
    mov cx, 42
.bl:
    mov al, '-'
    stosw
    loop .bl
    mov al, '+'
    stosw
    pop es
    pop di
    pop cx
    pop ax

    ; Логотип
    mov si, s2_logo1
    mov dh, 8
    mov dl, 20
    mov bl, 0x1E
    call s2_vprint

    mov si, s2_logo2
    mov dh, 9
    mov dl, 20
    mov bl, 0x1B
    call s2_vprint

    mov si, s2_logo3
    mov dh, 10
    mov dl, 20
    mov bl, 0x1A
    call s2_vprint

    mov si, s2_ver
    mov dh, 12
    mov dl, 23
    mov bl, 0x1F
    call s2_vprint

    ret

s2_show_progress_bar:
    mov si, s2_pb_lbl
    mov dh, 17
    mov dl, 28
    mov bl, 0x17
    call s2_vprint

    ; Пустая полоса
    push ax
    push cx
    push di
    push es
    mov ax, 0xB800
    mov es, ax
    mov di, (18*80 + 22)*2
    mov cx, 36
    mov ax, 0x17B0      ; тёмный блок
.empty:
    stosw
    loop .empty
    pop es
    pop di
    pop cx
    pop ax

    ; Заполнение
    mov bx, 0
    mov cx, 36
.anim:
    push cx
    push cx
    mov cx, 0x8000
.dly: loop .dly
    pop cx

    push bx
    push es
    push di
    mov ax, 0xB800
    mov es, ax
    movzx ax, bx
    add ax, 22 + 18*80
    shl ax, 1
    mov di, ax
    mov ax, 0x2FDB      ; яркий блок зелёный
    stosw
    pop di
    pop es
    pop bx
    inc bx
    pop cx
    loop .anim

    mov cx, 0xFFFF
.p1: loop .p1
    mov cx, 0xFFFF
.p2: loop .p2
    ret

s2_topbar    db '[ BarsikOS 0.3 pre-release 1 ]', 0
s2_bottombar db 'Starting up...', 0
s2_logo1     db '  BarsikOS  0.3  pre-release  1  ', 0
s2_logo2     db '  Free open-source OS by Barsik  ', 0
s2_logo3     db '  (: Cat :)                      ', 0
s2_ver       db '-- Loading, please wait... --', 0
s2_pb_lbl    db 'Loading...', 0

times 9216-($-$$) db 0