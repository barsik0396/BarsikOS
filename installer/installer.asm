; BarsikOS v0.3 - Installer
[BITS 16]

installer_start:
    call ui_mouse_init
    mov bl, COL_DESKTOP
    call ui_clear_screen
    call inst_page1

inst_main_loop:
    call ui_wait_key
    cmp al, 0x0D
    je .next
    cmp ah, 0x4D
    je .next
    cmp al, 0x1B
    je .cancel
    cmp ah, 0x4B
    je .cancel
    jmp inst_main_loop

.next:
    cmp byte [inst_page], 1
    je .p1n
    jmp kernel_start
.p1n:
    call inst_page2
    jmp inst_main_loop

.cancel:
    cmp byte [inst_page], 1
    je .quit
    call inst_page1
    jmp inst_main_loop

.quit:
    mov bl, COL_DESKTOP
    call ui_clear_screen
    mov si, .s_bye
    mov dh, 12
    mov dl, 16
    mov bl, 0x1C
    call vga_print
    call ui_wait_key
    mov al, 0xFE
    out 0x64, al
    cli
    hlt
.s_bye db '[ Installation cancelled. Press any key to reboot. ]', 0

; ═══════════════════════════════════════════════════
; Страница 1: Welcome
; ═══════════════════════════════════════════════════
inst_page1:
    mov byte [inst_page], 1
    mov bl, 0x17
    call ui_clear_screen

    ; ── Верхний бар ──
    call inst_topbar

    ; ── Рамка окна: строки 3..21, столбцы 10..69 ──
    ; Верх: строка 3
    mov dh, 3
    mov dl, 10
    mov si, .top
    mov bl, 0x1E
    call vga_print

    ; Заголовок окна: строка 4
    mov dh, 4
    mov dl, 11
    mov si, .wt
    mov bl, 0x1F
    call vga_print

    ; Разделитель под заголовком: строка 5
    mov dh, 5
    mov dl, 10
    mov si, .sep
    mov bl, 0x1E
    call vga_print

    ; Боковые стороны строки 6..19
    mov dh, 6
.sides:
    cmp dh, 19
    ja .sides_done
    push dx
    mov si, .pipe
    mov dl, 10
    mov bl, 0x1E
    call vga_print
    mov si, .pipe
    mov dl, 69
    mov bl, 0x1E
    call vga_print
    pop dx
    inc dh
    jmp .sides
.sides_done:

    ; Разделитель перед кнопками: строка 19
    mov dh, 19
    mov dl, 10
    mov si, .sep
    mov bl, 0x1E
    call vga_print

    ; Низ: строка 21
    mov dh, 21
    mov dl, 10
    mov si, .bot
    mov bl, 0x1E
    call vga_print

    ; ── Текст внутри ──
    mov si, .h
    mov dh, 7
    mov dl, 13
    mov bl, 0x1E
    call vga_print

    mov si, .l1
    mov dh, 9
    mov dl, 12
    mov bl, 0x1F
    call vga_print

    mov si, .l2
    mov dh, 10
    mov dl, 12
    mov bl, 0x17
    call vga_print

    mov si, .l3
    mov dh, 11
    mov dl, 12
    mov bl, 0x17
    call vga_print

    mov si, .l4
    mov dh, 13
    mov dl, 12
    mov bl, 0x17
    call vga_print

    mov si, .l5
    mov dh, 14
    mov dl, 12
    mov bl, 0x17
    call vga_print

    ; ── Кнопки строка 20 ──
    mov si, .b_cancel
    mov dh, 20
    mov dl, 40
    mov bl, COL_BTN_NORM
    call ui_draw_button

    mov si, .b_next
    mov dh, 20
    mov dl, 55
    mov bl, COL_BTN_SEL
    call ui_draw_button

    ; ── Подсказка строка 23 ──
    mov si, .hint
    mov dh, 23
    mov dl, 18
    mov bl, 0x17
    call vga_print

    ret

.top  db '+----------------------------------------------------------+', 0
.sep  db '+----------------------------------------------------------+', 0
.bot  db '+----------------------------------------------------------+', 0
.pipe db '|', 0
.wt   db ' Welcome to BarsikOS Setup', 0
.h    db '>>> Welcome to BarsikOS Setup <<<', 0
.l1   db 'Thank you for choosing BarsikOS!', 0
.l2   db 'BarsikOS is a free, open-source operating system', 0
.l3   db 'made by Barsik.', 0
.l4   db 'This wizard will guide you through the', 0
.l5   db 'installation process.', 0
.b_cancel db 'Cancel', 0
.b_next   db 'Next >', 0
.hint     db '< > Navigate   Enter=Next   ESC=Cancel', 0

; ═══════════════════════════════════════════════════
; Страница 2: Installing
; ═══════════════════════════════════════════════════
inst_page2:
    mov byte [inst_page], 2
    mov bl, 0x17
    call ui_clear_screen
    call inst_topbar

    ; Рамка
    mov dh, 3
    mov dl, 10
    mov si, .top
    mov bl, 0x1E
    call vga_print

    mov dh, 4
    mov dl, 11
    mov si, .wt
    mov bl, 0x1F
    call vga_print

    mov dh, 5
    mov dl, 10
    mov si, .sep
    mov bl, 0x1E
    call vga_print

    mov dh, 6
.sides:
    cmp dh, 19
    ja .sides_done
    push dx
    mov si, .pipe
    mov dl, 10
    mov bl, 0x1E
    call vga_print
    mov si, .pipe
    mov dl, 69
    mov bl, 0x1E
    call vga_print
    pop dx
    inc dh
    jmp .sides
.sides_done:

    mov dh, 19
    mov dl, 10
    mov si, .sep
    mov bl, 0x1E
    call vga_print

    mov dh, 21
    mov dl, 10
    mov si, .bot
    mov bl, 0x1E
    call vga_print

    ; Текст
    mov si, .h
    mov dh, 7
    mov dl, 13
    mov bl, 0x1E
    call vga_print

    mov si, .l1
    mov dh, 9
    mov dl, 12
    mov bl, 0x1F
    call vga_print

    mov si, .l2
    mov dh, 10
    mov dl, 12
    mov bl, 0x17
    call vga_print

    ; Прогресс-бар строка 13
    mov si, .pblbl
    mov dh, 12
    mov dl, 12
    mov bl, 0x17
    call vga_print

    push ax
    push cx
    push di
    push es
    mov ax, 0xB800
    mov es, ax
    mov di, (13*80 + 12)*2
    mov cx, 44
    mov al, '#'
    mov ah, 0x2F
.pb:
    push cx
    mov cx, 0x3000
.dly: loop .dly
    pop cx
    stosw
    loop .pb
    pop es
    pop di
    pop cx
    pop ax

    mov si, .done
    mov dh, 15
    mov dl, 12
    mov bl, 0x2F
    call vga_print

    ; Кнопки
    mov si, .b_back
    mov dh, 20
    mov dl, 40
    mov bl, COL_BTN_NORM
    call ui_draw_button

    mov si, .b_finish
    mov dh, 20
    mov dl, 55
    mov bl, COL_BTN_SEL
    call ui_draw_button

    mov si, .hint
    mov dh, 23
    mov dl, 15
    mov bl, 0x17
    call vga_print

    ret

.top  db '+----------------------------------------------------------+', 0
.sep  db '+----------------------------------------------------------+', 0
.bot  db '+----------------------------------------------------------+', 0
.pipe db '|', 0
.wt   db ' Installing BarsikOS', 0
.h    db '>>> Installing BarsikOS... <<<', 0
.l1   db 'Please wait while BarsikOS is installed.', 0
.l2   db 'This will only take a moment.', 0
.pblbl db 'Progress:', 0
.done  db '[OK] Installation complete!', 0
.b_back   db '< Back', 0
.b_finish db 'Finish', 0
.hint     db '< > Navigate   Enter=Finish   ESC=Back', 0

; ═══════════════════════════════════════════════════
; Верхний бар установщика
; ═══════════════════════════════════════════════════
inst_topbar:
    push ax
    push cx
    push di
    push es
    mov ax, 0xB800
    mov es, ax
    xor di, di
    mov cx, 80
    mov ax, 0x1F20
.loop:
    stosw
    loop .loop
    pop es
    pop di
    pop cx
    pop ax
    mov si, .s
    mov dh, 0
    mov dl, 1
    mov bl, COL_TOPBAR
    call vga_print
    ret
.s db '[ BarsikOS Setup ]', 0

inst_page db 0