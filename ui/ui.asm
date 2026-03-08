; BarsikOS v0.3 - UI Library
[BITS 16]

; Цвета
COL_DESKTOP    equ 0x17
COL_TOPBAR     equ 0x1F
COL_BOTTOMBAR  equ 0x70
COL_WINDOW_BD  equ 0x1E
COL_WINDOW_TTL equ 0x1F
COL_BTN_NORM   equ 0x70
COL_BTN_SEL    equ 0x4F
COL_MENU_ITEM  equ 0x17
COL_MENU_SEL   equ 0x3F
COL_STATUS     equ 0x2F

; ══════════════════════════════════════════════
; vga_print: dh=row, dl=col, bl=attr, si=str
; ══════════════════════════════════════════════
vga_print:
ui_print_at:
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

; ══════════════════════════════════════════════
; vga_fill: dh=row, dl=col, cx=count, al=char, bl=attr
; ══════════════════════════════════════════════
vga_fill:
    push ax
    push bx
    push cx
    push di
    push es
    mov bx, ax          ; сохраняем al в bl временно — нет, сохраним иначе
    ; al = char, bl = attr — но bl нам нужен для attr
    ; Передаём: al=char, bl=attr, cx=count, dh=row, dl=col
    push ax             ; сохраняем char
    mov ax, 0xB800
    mov es, ax
    movzx ax, dh
    push cx
    mov cx, 80
    mul cx
    pop cx
    movzx ax, ax
    push cx
    movzx cx, dl
    add ax, cx
    pop cx
    shl ax, 1
    mov di, ax
    pop ax              ; восстанавливаем char в al
    mov ah, bl          ; attr
.loop:
    stosw
    loop .loop
    pop es
    pop di
    pop cx
    pop bx
    pop ax
    ret

; ══════════════════════════════════════════════
; ui_clear_screen: bl=attr
; ══════════════════════════════════════════════
ui_clear_screen:
    push ax
    push cx
    push di
    push es
    mov ax, 0xB800
    mov es, ax
    xor di, di
    mov cx, 2000
    mov al, ' '
    mov ah, bl
.loop:
    stosw
    loop .loop
    pop es
    pop di
    pop cx
    pop ax
    ret

; ══════════════════════════════════════════════
; ui_draw_hbar: рисует горизонтальную строку дефисами
; dh=row, dl=col, cx=width, bl=attr
; ══════════════════════════════════════════════
ui_draw_hbar:
    push ax
    mov al, '-'
    call vga_fill
    pop ax
    ret

; ══════════════════════════════════════════════
; ui_draw_desktop
; ══════════════════════════════════════════════
ui_draw_desktop:
    push ax
    push bx
    push cx
    push si

    ; Фон
    mov bl, COL_DESKTOP
    call ui_clear_screen

    ; Верхний бар
    push di
    push es
    push cx
    push ax
    mov ax, 0xB800
    mov es, ax
    xor di, di
    mov cx, 80
    mov al, ' '
    mov ah, COL_TOPBAR
.tb:
    stosw
    loop .tb
    pop ax
    pop cx
    pop es
    pop di

    mov si, ui_s_topbar
    mov dh, 0
    mov dl, 1
    mov bl, COL_TOPBAR
    call vga_print

    mov si, ui_s_date
    mov dh, 0
    mov dl, 62
    mov bl, COL_TOPBAR
    call vga_print

    ; Разделитель строка 1
    push di
    push es
    push cx
    push ax
    mov ax, 0xB800
    mov es, ax
    mov di, 1*80*2
    mov cx, 80
    mov al, '-'
    mov ah, COL_TOPBAR
.sep:
    stosw
    loop .sep
    pop ax
    pop cx
    pop es
    pop di

    ; Нижний бар строка 24
    push di
    push es
    push cx
    push ax
    mov ax, 0xB800
    mov es, ax
    mov di, 24*80*2
    mov cx, 80
    mov al, ' '
    mov ah, COL_BOTTOMBAR
.bb:
    stosw
    loop .bb
    pop ax
    pop cx
    pop es
    pop di

    mov si, ui_s_bottombar
    mov dh, 24
    mov dl, 1
    mov bl, COL_BOTTOMBAR
    call vga_print

    ; Иконки рабочего стола
    mov si, ui_s_icon1
    mov dh, 4
    mov dl, 4
    mov bl, 0x1E
    call vga_print

    mov si, ui_s_icon2
    mov dh, 5
    mov dl, 4
    mov bl, 0x17
    call vga_print

    mov si, ui_s_icon3
    mov dh, 7
    mov dl, 4
    mov bl, 0x1E
    call vga_print

    mov si, ui_s_icon4
    mov dh, 8
    mov dl, 4
    mov bl, 0x17
    call vga_print

    pop si
    pop cx
    pop bx
    pop ax
    ret

; ══════════════════════════════════════════════
; ui_draw_box: рисует рамку ASCII +--+
; dh=top_row, dl=left_col, bh=height, bl=width
; ══════════════════════════════════════════════
ui_draw_box:
    push ax
    push bx
    push cx
    push dx
    push si
    push di
    push es

    mov [ui_box_y], dh
    mov [ui_box_x], dl
    mov [ui_box_h], bh
    mov [ui_box_w], bl

    mov ax, 0xB800
    mov es, ax

    ; Верхняя строка: +---...---+
    movzx ax, dh
    mov cx, 80
    mul cx
    movzx cx, dl
    add ax, cx
    shl ax, 1
    mov di, ax

    mov al, '+'
    mov ah, COL_WINDOW_BD
    stosw

    movzx cx, byte [ui_box_w]
    sub cx, 2
.top_dash:
    mov al, '-'
    mov ah, COL_WINDOW_BD
    stosw
    loop .top_dash

    mov al, '+'
    mov ah, COL_WINDOW_BD
    stosw

    ; Боковые строки
    movzx ax, byte [ui_box_y]
    inc ax
    movzx cx, byte [ui_box_h]
    sub cx, 2
.side_row:
    push cx
    push ax

    ; Левая |
    push ax
    mov cx, ax
    imul cx, 80
    movzx ax, byte [ui_box_x]
    add cx, ax
    shl cx, 1
    mov di, cx
    mov al, '|'
    mov ah, COL_WINDOW_BD
    stosw
    pop ax

    ; Заполнение пробелами
    mov cx, ax
    imul cx, 80
    movzx ax, byte [ui_box_x]
    inc ax
    add cx, ax
    shl cx, 1
    mov di, cx
    movzx cx, byte [ui_box_w]
    sub cx, 2
    mov al, ' '
    mov ah, COL_WINDOW_BD
.fill_sp:
    stosw
    loop .fill_sp

    ; Правая |
    pop ax
    push ax
    mov cx, ax
    imul cx, 80
    movzx ax, byte [ui_box_x]
    movzx bx, byte [ui_box_w]
    add ax, bx
    dec ax
    add cx, ax
    shl cx, 1
    mov di, cx
    mov al, '|'
    mov ah, COL_WINDOW_BD
    stosw

    pop ax
    inc ax
    pop cx
    loop .side_row

    ; Нижняя строка: +---...---+
    movzx ax, byte [ui_box_y]
    movzx cx, byte [ui_box_h]
    add ax, cx
    dec ax
    imul ax, 80
    movzx cx, byte [ui_box_x]
    add ax, cx
    shl ax, 1
    mov di, ax

    mov al, '+'
    mov ah, COL_WINDOW_BD
    stosw

    movzx cx, byte [ui_box_w]
    sub cx, 2
.bot_dash:
    mov al, '-'
    mov ah, COL_WINDOW_BD
    stosw
    loop .bot_dash

    mov al, '+'
    mov ah, COL_WINDOW_BD
    stosw

    pop es
    pop di
    pop si
    pop dx
    pop cx
    pop bx
    pop ax
    ret

; ══════════════════════════════════════════════
; ui_draw_window: рамка + заголовок
; dh=row, dl=col, bh=height, bl=width, si=title
; ══════════════════════════════════════════════
ui_draw_window:
    push si
    call ui_draw_box
    pop si

    ; Заголовок в строке top+1, col+2
    push dx
    mov dh, [ui_box_y]
    mov dl, [ui_box_x]
    add dl, 2
    mov bl, COL_WINDOW_TTL
    call vga_print
    pop dx
    ret

; ══════════════════════════════════════════════
; ui_draw_button: dh=row, dl=col, bl=attr, si=text
; ══════════════════════════════════════════════
ui_draw_button:
    push ax
    push di
    push es
    push cx
    push bx
    mov ax, 0xB800
    mov es, ax
    movzx ax, dh
    mov cx, 80
    mul cx
    movzx cx, dl
    add ax, cx
    shl ax, 1
    mov di, ax
    mov bh, bl
    mov ah, bh
    mov al, '['
    stosw
    mov al, ' '
    stosw
.txt:
    lodsb
    or al, al
    jz .done
    mov ah, bh
    stosw
    jmp .txt
.done:
    mov al, ' '
    stosw
    mov al, ']'
    stosw
    pop bx
    pop cx
    pop es
    pop di
    pop ax
    ret

; ══════════════════════════════════════════════
; ui_wait_key → al=ASCII, ah=scancode
; ══════════════════════════════════════════════
ui_wait_key:
    xor ah, ah
    int 0x16
    ret

; ══════════════════════════════════════════════
; ui_mouse_init
; ══════════════════════════════════════════════
ui_mouse_init:
    push ax
    push bx
    xor ax, ax
    int 0x33
    cmp ax, 0xFFFF
    jne .no
    mov ax, 0x0001
    int 0x33
    mov byte [ui_mouse_ok], 1
.no:
    pop bx
    pop ax
    ret

; ══════════════════════════════════════════════
; ui_print: teletype print, si=str
; ══════════════════════════════════════════════
ui_print:
    push ax
.loop:
    lodsb
    or al, al
    jz .done
    mov ah, 0x0E
    int 0x10
    jmp .loop
.done:
    pop ax
    ret

; ══════════════════════════════════════════════
; Данные
; ══════════════════════════════════════════════
ui_s_topbar    db '[ BarsikOS 0.3 pre-release 1 ]', 0
ui_s_date      db 'Feb 27, 2026', 0
ui_s_bottombar db 'ESC=Menu  D=DOS  Q=Shutdown', 0
ui_s_icon1     db '[>] Terminal', 0
ui_s_icon2     db '    /bin/shell', 0
ui_s_icon3     db '[i] About BarsikOS', 0
ui_s_icon4     db '    v0.3 pre-release', 0

ui_box_y  db 0
ui_box_x  db 0
ui_box_h  db 0
ui_box_w  db 0

; ══════════════════════════════════════════════
; ui_clear_screen_black: очистить в чёрный (для DOS)
; ══════════════════════════════════════════════
ui_clear_screen_black:
    push ax
    push cx
    push di
    push es
    mov ax, 0xB800
    mov es, ax
    xor di, di
    mov cx, 2000
    mov ax, 0x0720
.loop:
    stosw
    loop .loop
    pop es
    pop di
    pop cx
    pop ax
    ; Показать курсор
    mov ah, 0x01
    mov cx, 0x0607
    int 0x10
    ret

ui_mouse_ok  db 0