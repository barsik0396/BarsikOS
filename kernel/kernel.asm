; BarsikOS v0.3 - Kernel
[BITS 16]

kernel_start:
kernel_main:
    call ui_draw_desktop
    call kern_show_cursor

main_loop:
    call ui_wait_key
    cmp al, 0x1B
    je .menu
    cmp al, 'd'
    je .dos
    cmp al, 'D'
    je .dos
    cmp al, 'q'
    je .shutdown
    cmp al, 'Q'
    je .shutdown
    jmp main_loop
.menu:
    call show_start_menu
    jmp main_loop
.dos:
    call ui_clear_screen_black
    jmp dos_main
.shutdown:
    call show_shutdown_dialog
    jmp main_loop

kern_show_cursor:
    mov ah, 0x01
    mov cx, 0x0607
    int 0x10
    ret

kern_hide_cursor:
    mov ah, 0x01
    mov cx, 0x2000
    int 0x10
    ret

; ═══════════════════════════════════════════════════
; Меню (ESC)
; ═══════════════════════════════════════════════════
show_start_menu:
    push ax
    push bx
    push si
    mov byte [menu_sel], 0

.draw:
    ; Рамка: строки 5..21, столбцы 2..37
    mov dh, 5
    mov dl, 2
    mov si, .top
    mov bl, 0x1E
    call vga_print

    mov dh, 6
    mov dl, 3
    mov si, .title
    mov bl, 0x1F
    call vga_print

    mov dh, 7
    mov dl, 2
    mov si, .sep
    mov bl, 0x1E
    call vga_print

    ; Боковые строки 8..19
    mov dh, 8
.sides:
    cmp dh, 19
    ja .sides_done
    push dx
    mov si, .pipe
    mov dl, 2
    mov bl, 0x1E
    call vga_print
    mov si, .pipe
    mov dl, 37
    mov bl, 0x1E
    call vga_print
    pop dx
    inc dh
    jmp .sides
.sides_done:

    mov dh, 19
    mov dl, 2
    mov si, .sep
    mov bl, 0x1E
    call vga_print

    mov dh, 21
    mov dl, 2
    mov si, .bot
    mov bl, 0x1E
    call vga_print

    ; Пункты меню
    mov bl, COL_MENU_ITEM
    cmp byte [menu_sel], 0
    jne .d0
    mov bl, COL_MENU_SEL
.d0:
    mov si, .item0
    mov dh, 9
    mov dl, 4
    call vga_print

    mov bl, COL_MENU_ITEM
    cmp byte [menu_sel], 1
    jne .d1
    mov bl, COL_MENU_SEL
.d1:
    mov si, .item1
    mov dh, 11
    mov dl, 4
    call vga_print

    mov bl, COL_MENU_ITEM
    cmp byte [menu_sel], 2
    jne .d2
    mov bl, COL_MENU_SEL
.d2:
    mov si, .item2
    mov dh, 13
    mov dl, 4
    call vga_print

    ; Кнопки строка 20
    mov si, .b_shut
    mov dh, 20
    mov dl, 4
    mov bl, COL_BTN_NORM
    call ui_draw_button

    mov si, .b_rest
    mov dh, 20
    mov dl, 17
    mov bl, COL_BTN_NORM
    call ui_draw_button

    mov si, .b_dos
    mov dh, 20
    mov dl, 29
    mov bl, COL_BTN_NORM
    call ui_draw_button

    call ui_wait_key

    cmp al, 0x1B
    je .close
    cmp ah, 0x48
    je .up
    cmp ah, 0x50
    je .down
    cmp al, 0x0D
    je .enter
    jmp .draw

.up:
    cmp byte [menu_sel], 0
    je .draw
    dec byte [menu_sel]
    jmp .draw
.down:
    cmp byte [menu_sel], 2
    je .draw
    inc byte [menu_sel]
    jmp .draw

.enter:
    cmp byte [menu_sel], 0
    je .go_dos
    cmp byte [menu_sel], 1
    je .go_about
    ; shutdown
    pop si
    pop bx
    pop ax
    call show_shutdown_dialog
    jmp main_loop

.go_dos:
    pop si
    pop bx
    pop ax
    call ui_clear_screen_black
    jmp dos_main

.go_about:
    pop si
    pop bx
    pop ax
    call show_about
    jmp main_loop

.close:
    pop si
    pop bx
    pop ax
    call ui_draw_desktop
    call kern_show_cursor
    ret

.top   db '+----------------------------------+', 0
.sep   db '+----------------------------------+', 0
.bot   db '+----------------------------------+', 0
.pipe  db '|', 0
.title db ' BarsikOS Menu', 0
.item0 db ' > DOS Subsystem            ', 0
.item1 db ' > About BarsikOS...        ', 0
.item2 db ' > Shutdown...              ', 0
.b_shut db 'Shutdown', 0
.b_rest db 'Restart', 0
.b_dos  db 'DOS', 0

menu_sel db 0

; ═══════════════════════════════════════════════════
; About
; ═══════════════════════════════════════════════════
show_about:
    push ax
    push bx
    push si

    mov bl, COL_DESKTOP
    call ui_clear_screen

    ; Верхний бар
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
    mov si, .tbs
    mov dh, 0
    mov dl, 1
    mov bl, COL_TOPBAR
    call vga_print

    ; Рамка: строки 2..22, столбцы 8..71
    mov dh, 2
    mov dl, 8
    mov si, .top
    mov bl, 0x1E
    call vga_print

    mov dh, 3
    mov dl, 9
    mov si, .wt
    mov bl, 0x1F
    call vga_print

    mov dh, 4
    mov dl, 8
    mov si, .sep
    mov bl, 0x1E
    call vga_print

    mov dh, 5
.sides:
    cmp dh, 21
    ja .sides_done
    push dx
    mov si, .pipe
    mov dl, 8
    mov bl, 0x1E
    call vga_print
    mov si, .pipe
    mov dl, 71
    mov bl, 0x1E
    call vga_print
    pop dx
    inc dh
    jmp .sides
.sides_done:

    mov dh, 22
    mov dl, 8
    mov si, .bot
    mov bl, 0x1E
    call vga_print

    ; Контент
    mov si, .logo
    mov dh, 5
    mov dl, 24
    mov bl, 0x1E
    call vga_print

    mov si, .l1
    mov dh, 7
    mov dl, 11
    mov bl, 0x1F
    call vga_print

    mov si, .l2
    mov dh, 8
    mov dl, 11
    mov bl, 0x17
    call vga_print

    mov si, .l3
    mov dh, 9
    mov dl, 11
    mov bl, 0x17
    call vga_print

    mov si, .l4
    mov dh, 10
    mov dl, 11
    mov bl, 0x17
    call vga_print

    ; Разделитель
    push ax
    push cx
    push di
    push es
    mov ax, 0xB800
    mov es, ax
    mov di, (12*80 + 9)*2
    mov cx, 62
    mov al, '-'
    mov ah, 0x1E
.as1:
    stosw
    loop .as1
    pop es
    pop di
    pop cx
    pop ax

    mov si, .l5
    mov dh, 13
    mov dl, 11
    mov bl, 0x1E
    call vga_print

    mov si, .l6
    mov dh, 14
    mov dl, 11
    mov bl, 0x17
    call vga_print

    mov si, .l7
    mov dh, 15
    mov dl, 11
    mov bl, 0x17
    call vga_print

    mov si, .l8
    mov dh, 16
    mov dl, 11
    mov bl, 0x17
    call vga_print

    push ax
    push cx
    push di
    push es
    mov ax, 0xB800
    mov es, ax
    mov di, (18*80 + 9)*2
    mov cx, 62
    mov al, '-'
    mov ah, 0x1E
.as2:
    stosw
    loop .as2
    pop es
    pop di
    pop cx
    pop ax

    mov si, .l9
    mov dh, 19
    mov dl, 11
    mov bl, 0x17
    call vga_print

    mov si, .l10
    mov dh, 20
    mov dl, 11
    mov bl, 0x17
    call vga_print

    mov si, .btn
    mov dh, 21
    mov dl, 61
    mov bl, COL_BTN_SEL
    call ui_draw_button

    mov si, .hint
    mov dh, 23
    mov dl, 28
    mov bl, 0x17
    call vga_print

    call ui_wait_key

    pop si
    pop bx
    pop ax
    call ui_draw_desktop
    call kern_show_cursor
    ret

.tbs  db '[ About BarsikOS ]', 0
.top  db '+--------------------------------------------------------------+', 0
.sep  db '+--------------------------------------------------------------+', 0
.bot  db '+--------------------------------------------------------------+', 0
.pipe db '|', 0
.wt   db ' About BarsikOS v0.3', 0
.logo db '[ BarsikOS 0.3 pre-release 1 ]', 0
.l1   db 'BarsikOS - Free Open-Source Operating System', 0
.l2   db 'Version:  v0.3 pre-release 1', 0
.l3   db 'Author:   barsik0396', 0
.l4   db 'Website:  https://barsik0396.github.io/BarsikOS/', 0
.l5   db "What's new in v0.3:", 0
.l6   db '  + Graphical UI', 0
.l7   db '  + Installer wizard with navigation', 0
.l8   db '  + DOS Subsystem with Linux-style paths', 0
.l9   db '  Changed: DOS is now a subsystem (not standalone)', 0
.l10  db '  Removed: Drive letters (now /path style)', 0
.btn  db 'OK', 0
.hint db 'Press any key to close', 0

; ═══════════════════════════════════════════════════
; Shutdown диалог
; ═══════════════════════════════════════════════════
show_shutdown_dialog:
    push ax
    push bx
    push si
    mov byte [shut_sel], 0

    ; Рамка: строки 8..14, столбцы 22..55
    mov dh, 8
    mov dl, 22
    mov si, .top
    mov bl, 0x1E
    call vga_print

    mov dh, 9
    mov dl, 23
    mov si, .wt
    mov bl, 0x1F
    call vga_print

    mov dh, 10
    mov dl, 22
    mov si, .sep
    mov bl, 0x1E
    call vga_print

    ; Строки 11-12
    mov dh, 11
.sides:
    cmp dh, 13
    ja .sides_done
    push dx
    mov si, .pipe
    mov dl, 22
    mov bl, 0x1E
    call vga_print
    mov si, .pipe
    mov dl, 55
    mov bl, 0x1E
    call vga_print
    pop dx
    inc dh
    jmp .sides
.sides_done:

    mov dh, 14
    mov dl, 22
    mov si, .bot
    mov bl, 0x1E
    call vga_print

    mov si, .msg
    mov dh, 11
    mov dl, 25
    mov bl, 0x17
    call vga_print

.draw_btns:
    mov si, .b_yes
    mov dh, 13
    mov dl, 25
    mov bl, COL_BTN_NORM
    cmp byte [shut_sel], 0
    jne .dy
    mov bl, COL_BTN_SEL
.dy:
    call ui_draw_button

    mov si, .b_no
    mov dh, 13
    mov dl, 40
    mov bl, COL_BTN_NORM
    cmp byte [shut_sel], 1
    jne .dn
    mov bl, COL_BTN_SEL
.dn:
    call ui_draw_button

    call ui_wait_key
    cmp al, 0x1B
    je .cancel
    cmp ah, 0x4B
    je .left
    cmp ah, 0x4D
    je .right
    cmp al, 0x0D
    je .enter
    jmp .draw_btns

.left:
    mov byte [shut_sel], 0
    jmp .draw_btns
.right:
    mov byte [shut_sel], 1
    jmp .draw_btns

.enter:
    cmp byte [shut_sel], 0
    je .do_shut
.cancel:
    pop si
    pop bx
    pop ax
    call ui_draw_desktop
    call kern_show_cursor
    ret

.do_shut:
    mov bl, 0x00
    call ui_clear_screen
    mov si, .bye
    mov dh, 12
    mov dl, 27
    mov bl, 0x0F
    call vga_print
    cli
    hlt

.top  db '+--------------------------------+', 0
.sep  db '+--------------------------------+', 0
.bot  db '+--------------------------------+', 0
.pipe db '|', 0
.wt   db ' Shutdown', 0
.msg  db 'Shut down BarsikOS?', 0
.b_yes db 'Shutdown', 0
.b_no  db 'Cancel', 0
.bye   db 'Goodbye! See you soon. :)', 0

shut_sel db 0