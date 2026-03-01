; BarsikOS v0.3 - UI Library
; Функции для рисования окон, кнопок, меню

[BITS 16]

; ===== Функция: Очистка экрана =====
ui_clear_screen:
    push ax
    mov ax, 0x0003
    int 0x10
    pop ax
    ret

; ===== Функция: Установка курсора =====
; DH = строка, DL = столбец
ui_set_cursor:
    push ax
    push bx
    mov ah, 0x02
    mov bh, 0
    int 0x10
    pop bx
    pop ax
    ret

; ===== Функция: Печать строки =====
; SI = указатель на строку
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

; ===== Функция: Печать в позиции =====
; DH = строка, DL = столбец, SI = строка
ui_print_at:
    call ui_set_cursor
    call ui_print
    ret

; ===== Функция: Рисование горизонтальной линии =====
; DH = строка, DL = начало, CX = длина
ui_draw_hline:
    push ax
    push cx
    push dx
    
    call ui_set_cursor
    mov ah, 0x0E
    mov al, '-'
.loop:
    int 0x10
    loop .loop
    
    pop dx
    pop cx
    pop ax
    ret

; ===== Функция: Рисование окна =====
; DH = Y, DL = X, BH = высота, BL = ширина, SI = заголовок
ui_draw_window:
    push ax
    push bx
    push cx
    push dx
    push si
    
    ; Сохраняем параметры
    mov byte [win_y], dh
    mov byte [win_x], dl
    mov byte [win_h], bh
    mov byte [win_w], bl
    
    ; Верхняя линия с заголовком
    call ui_set_cursor
    mov ah, 0x0E
    mov al, '['
    int 0x10
    mov al, '#'
    int 0x10
    mov al, 'x'
    int 0x10
    mov al, '#'
    int 0x10
    
    ; Заголовок
    call ui_print
    
    ; Заполняем #
    movzx cx, bl
    sub cx, 4
    mov al, '#'
.top_loop:
    int 0x10
    loop .top_loop
    
    mov al, ']'
    int 0x10
    
    ; Боковые линии
    movzx cx, bh
    sub cx, 2
    mov dh, byte [win_y]
    inc dh
.side_loop:
    push cx
    
    mov dl, byte [win_x]
    call ui_set_cursor
    mov al, '['
    int 0x10
    
    ; Пробелы
    movzx cx, byte [win_w]
    sub cx, 2
    mov al, ' '
.space_loop:
    int 0x10
    loop .space_loop
    
    mov al, ']'
    int 0x10
    
    inc dh
    pop cx
    loop .side_loop
    
    ; Нижняя линия
    mov dl, byte [win_x]
    call ui_set_cursor
    mov al, '['
    int 0x10
    
    movzx cx, byte [win_w]
    sub cx, 2
    mov al, '#'
.bottom_loop:
    int 0x10
    loop .bottom_loop
    
    mov al, ']'
    int 0x10
    
    pop si
    pop dx
    pop cx
    pop bx
    pop ax
    ret

; ===== Функция: Рисование кнопки =====
; DH = Y, DL = X, SI = текст
ui_draw_button:
    push ax
    push dx
    
    call ui_set_cursor
    mov ah, 0x0E
    mov al, '['
    int 0x10
    mov al, ' '
    int 0x10
    
    call ui_print
    
    mov al, ' '
    int 0x10
    mov al, ']'
    int 0x10
    
    pop dx
    pop ax
    ret

; ===== Функция: Ожидание клавиши =====
; Возвращает: AL = ASCII код
ui_wait_key:
    xor ah, ah
    int 0x16
    ret

; ===== Данные =====
win_y db 0
win_x db 0
win_h db 0
win_w db 0
