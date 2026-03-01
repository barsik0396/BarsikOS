; BarsikOS v0.3 - Kernel
; Основное ядро системы с UI

[BITS 16]

kernel_main:
    ; ОТЛАДКА: Сообщение что ядро запустилось
    mov si, msg_kernel_start
    call ui_print
    
    call ui_clear_screen
    call draw_desktop
    
main_loop:
    call ui_wait_key
    
    ; Проверяем клавиши
    cmp al, 0x1B        ; ESC - меню
    je show_start_menu
    
    cmp al, 'r'         ; R - О релизе
    je show_about
    
    cmp al, 'd'         ; D - DOS
    je start_dos
    
    cmp al, 'q'         ; Q - выход
    je shutdown
    
    jmp main_loop

draw_desktop:
    ; Верхняя панель
    mov dh, 0
    mov dl, 0
    mov si, msg_topbar
    call ui_print_at
    
    ; Дата справа
    mov dh, 0
    mov dl, 55
    mov si, msg_date
    call ui_print_at
    
    ; Логотип в центре
    mov dh, 6
    mov dl, 19
    mov si, msg_logo_box1
    call ui_print_at
    
    mov dh, 7
    mov dl, 19
    mov si, msg_logo_box2
    call ui_print_at
    
    mov dh, 8
    mov dl, 19
    mov si, msg_logo_box3
    call ui_print_at
    
    ; Нижняя панель
    mov dh, 24
    mov dl, 0
    mov si, msg_bottombar
    call ui_print_at
    
    ret

show_start_menu:
    ; Рисуем меню "Пуск"
    mov dh, 14
    mov dl, 0
    mov bh, 10
    mov bl, 43
    mov si, msg_menu_title
    call ui_draw_window
    
    ; Пункты меню
    mov dh, 16
    mov dl, 2
    mov si, menu_dos
    call ui_print_at
    
    mov dh, 17
    mov dl, 2
    mov si, menu_about
    call ui_print_at
    
    mov dh, 22
    mov dl, 2
    mov si, menu_buttons
    call ui_print_at
    
    ; Ждём выбор
    call ui_wait_key
    
    cmp al, '1'
    je start_dos
    
    cmp al, '2'
    je show_about
    
    cmp al, '3'
    je shutdown
    
    ; Перерисовываем рабочий стол
    call ui_clear_screen
    call draw_desktop
    jmp main_loop

show_about:
    call ui_clear_screen
    
    ; Окно "О релизе"
    mov dh, 2
    mov dl, 5
    mov bh, 18
    mov bl, 65
    mov si, about_title
    call ui_draw_window
    
    ; Текст
    mov dh, 4
    mov dl, 7
    mov si, about_line1
    call ui_print_at
    
    mov dh, 5
    mov dl, 7
    mov si, about_line2
    call ui_print_at
    
    mov dh, 6
    mov dl, 7
    mov si, about_line3
    call ui_print_at
    
    mov dh, 7
    mov dl, 7
    mov si, about_line4
    call ui_print_at
    
    mov dh, 8
    mov dl, 7
    mov si, about_line5
    call ui_print_at
    
    mov dh, 10
    mov dl, 7
    mov si, about_line6
    call ui_print_at
    
    mov dh, 11
    mov dl, 7
    mov si, about_line7
    call ui_print_at
    
    mov dh, 13
    mov dl, 7
    mov si, about_line8
    call ui_print_at
    
    mov dh, 14
    mov dl, 7
    mov si, about_line9
    call ui_print_at
    
    mov dh, 16
    mov dl, 7
    mov si, about_line10
    call ui_print_at
    
    mov dh, 17
    mov dl, 7
    mov si, about_line11
    call ui_print_at
    
    ; Кнопка OK
    mov dh, 18
    mov dl, 60
    mov si, btn_ok
    call ui_draw_button
    
    call ui_wait_key
    
    call ui_clear_screen
    call draw_desktop
    jmp main_loop

start_dos:
    ; Здесь будет DOS подсистема
    call ui_clear_screen
    jmp dos_main

shutdown:
    call ui_clear_screen
    mov dh, 12
    mov dl, 30
    mov si, msg_goodbye
    call ui_print_at
    cli
    hlt

; === Сообщения ===
msg_topbar db '[                          BarsikOS 0.3 - pre-release!                          ]', 0
msg_date db '[ Feb 27, 2026      ]', 0
msg_bottombar db '[     ESC - Menu          [D] - DOS                                                    ]', 0

msg_logo_box1 db '[ BarsikOS 0.3 pre-release 1    ]', 0
msg_logo_box2 db '[           (: Cat :)           ]', 0
msg_logo_box3 db '[                               ]', 0

msg_menu_title db 'Search...', 0
menu_dos db '[ DOS Subsystem - configure...      ]', 0
menu_about db '[ About release...                  ]', 0
menu_buttons db '[ Shutdown ] [ Restart ] [ DOS ]', 0

about_title db 'About BarsikOS v0.3', 0
about_line1 db 'Information about BarsikOS version v0.3 (pre)', 0
about_line2 db 'GitHub: https://github.com/barsik0396/BarsikOS', 0
about_line3 db 'Version: v0.3 (pre-release)', 0
about_line4 db 'Published by: barsik0396', 0
about_line5 db 'More: https://barsik0396.github.io/BarsikOS/l?l=r03', 0
about_line6 db 'Added:', 0
about_line7 db ' UI interface, installer', 0
about_line8 db 'Changed:', 0
about_line9 db ' DOS is now subsystem only', 0
about_line10 db 'Removed:', 0
about_line11 db ' Regular DOS (now DOS is subsystem)', 0

btn_ok db 'OK', 0
msg_goodbye db 'Goodbye!', 0
msg_kernel_start db 'Kernel started!', 0x0D, 0x0A, 0

; === DOS подсистема ===
dos_main: