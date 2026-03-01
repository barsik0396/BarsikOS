; BarsikOS v0.3 - Installer
; Установщик системы

[BITS 16]

installer_start:
    ; ОТЛАДКА
    mov si, msg_installer_start
    call ui_print
    
    call ui_clear_screen
    
    ; Заголовок
    mov dh, 0
    mov dl, 0
    mov si, msg_title
    call ui_print_at
    
    ; Показываем страницу 1
    call show_page1
    
    ; Ждём Enter
    call ui_wait_key
    cmp al, 0x0D
    jne installer_start
    
    ; Показываем страницу 2
    call show_page2
    
    ; Ждём Enter
    call ui_wait_key
    
    ; Запускаем систему
    jmp kernel_start

show_page1:
    call ui_clear_screen
    
    mov dh, 0
    mov dl, 0
    mov si, msg_title
    call ui_print_at
    
    ; Рисуем окно
    mov dh, 4
    mov dl, 15
    mov bh, 10
    mov bl, 45
    mov si, msg_win_title1
    call ui_draw_window
    
    ; Текст внутри окна
    mov dh, 6
    mov dl, 17
    mov si, msg_text1
    call ui_print_at
    
    mov dh, 7
    mov dl, 17
    mov si, msg_text2
    call ui_print_at
    
    mov dh, 8
    mov dl, 17
    mov si, msg_text3
    call ui_print_at
    
    ; Кнопки
    mov dh, 12
    mov dl, 34
    mov si, btn_cancel
    call ui_draw_button
    
    mov dh, 12
    mov dl, 46
    mov si, btn_next
    call ui_draw_button
    
    ret

show_page2:
    call ui_clear_screen
    
    mov dh, 0
    mov dl, 0
    mov si, msg_title
    call ui_print_at
    
    ; Рисуем окно
    mov dh, 4
    mov dl, 15
    mov bh, 10
    mov bl, 45
    mov si, msg_win_title1
    call ui_draw_window
    
    ; Текст
    mov dh, 6
    mov dl, 17
    mov si, msg_done1
    call ui_print_at
    
    mov dh, 7
    mov dl, 17
    mov si, msg_done2
    call ui_print_at
    
    ; Кнопка
    mov dh, 12
    mov dl, 46
    mov si, btn_finish
    call ui_draw_button
    
    ret

; Сообщения
msg_title db 'BarsikOS Setup', 0
msg_win_title1 db 'Installing BarsikOS', 0

msg_text1 db 'Thank you for choosing BarsikOS!', 0
msg_text2 db 'BarsikOS is a free open-source OS', 0
msg_text3 db 'made by Barsik. :)', 0

msg_done1 db 'BarsikOS has been successfully', 0
msg_done2 db 'installed! Thank you!', 0

btn_cancel db 'Cancel', 0
btn_next db 'Next', 0
btn_finish db 'Finish', 0
msg_installer_start db 'Installer started!', 0x0D, 0x0A, 0

; Переход к ядру будет здесь
kernel_start: