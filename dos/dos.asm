; BarsikOS v0.3 - DOS Subsystem
; Подсистема DOS с файловой системой

[BITS 16]

dos_main:
    ; Приветствие
    mov si, dos_welcome
    call ui_print
    
    ; Устанавливаем начальную директорию
    mov word [current_dir], dir_root

dos_loop:
    ; Показываем prompt
    mov si, [current_dir]
    call ui_print
    mov si, dos_prompt
    call ui_print
    
    ; Читаем команду
    mov di, input_buffer
    call dos_read_line
    
    ; Парсим и выполняем
    call dos_parse_command
    
    jmp dos_loop

dos_read_line:
    xor cx, cx
.loop:
    call ui_wait_key
    
    cmp al, 0x0D
    je .done
    
    cmp al, 0x08
    je .backspace
    
    cmp al, 32
    jb .loop
    
    cmp cx, 79
    jae .loop
    
    mov [di], al
    inc di
    inc cx
    
    mov ah, 0x0E
    int 0x10
    jmp .loop

.backspace:
    test cx, cx
    jz .loop
    
    dec di
    dec cx
    
    mov ah, 0x0E
    mov al, 0x08
    int 0x10
    mov al, ' '
    int 0x10
    mov al, 0x08
    int 0x10
    jmp .loop

.done:
    mov byte [di], 0
    mov si, newline
    call ui_print
    ret

dos_parse_command:
    mov si, input_buffer
    
    ; Проверяем команды
    mov di, cmd_help
    call dos_strcmp
    jz dos_cmd_help
    
    mov di, cmd_exit
    call dos_strcmp
    jz dos_cmd_exit
    
    mov di, cmd_ls
    call dos_strcmp
    jz dos_cmd_ls
    
    mov di, cmd_dir
    call dos_strcmp
    jz dos_cmd_ls
    
    mov di, cmd_makedir
    call dos_strcmp
    jz dos_cmd_makedir
    
    mov di, cmd_makefile
    call dos_strcmp
    jz dos_cmd_makefile
    
    mov di, cmd_install
    call dos_strcmp
    jz dos_cmd_install
    
    ; Неизвестная команда
    mov si, dos_unknown
    call ui_print
    ret

dos_strcmp:
    push si
    push di
.loop:
    lodsb
    mov bl, [di]
    inc di
    
    cmp al, ' '
    je .check_end
    cmp al, 0
    je .check_end
    
    cmp al, bl
    jne .not_equal
    jmp .loop

.check_end:
    cmp bl, 0
    je .equal
    cmp bl, ' '
    je .equal

.not_equal:
    pop di
    pop si
    or ax, 1
    ret

.equal:
    pop di
    pop si
    xor ax, ax
    ret

dos_cmd_help:
    mov si, dos_help_text
    call ui_print
    ret

dos_cmd_exit:
    call ui_clear_screen
    jmp kernel_main

dos_cmd_ls:
    mov si, dos_ls_text
    call ui_print
    ret

dos_cmd_makedir:
    mov si, dos_makedir_text
    call ui_print
    ret

dos_cmd_makefile:
    mov si, dos_makefile_text
    call ui_print
    ret

dos_cmd_install:
    ; Показываем меню переустановки
    call show_reinstall_menu
    ret

show_reinstall_menu:
    call ui_clear_screen
    
    mov dh, 0
    mov dl, 0
    mov si, reinstall_title
    call ui_print_at
    
    mov dh, 2
    mov dl, 0
    mov si, reinstall_line1
    call ui_print_at
    
    mov dh, 5
    mov dl, 10
    mov si, reinstall_line2
    call ui_print_at
    
    mov dh, 6
    mov dl, 6
    mov si, reinstall_line3
    call ui_print_at
    
    ; Список версий
    mov dh, 7
    mov dl, 9
    mov si, reinstall_opt1
    call ui_print_at
    
    mov dh, 8
    mov dl, 9
    mov si, reinstall_opt2
    call ui_print_at
    
    mov dh, 9
    mov dl, 9
    mov si, reinstall_opt3
    call ui_print_at
    
    mov dh, 10
    mov dl, 9
    mov si, reinstall_opt4
    call ui_print_at
    
    mov dh, 11
    mov dl, 9
    mov si, reinstall_opt5
    call ui_print_at
    
    ; Подсказка
    mov dh, 24
    mov dl, 0
    mov si, reinstall_hint
    call ui_print_at
    
    call ui_wait_key
    ret

; === Данные ===
dos_welcome db 'Welcome to DOS Subsystem for BarsikOS!', 0x0D, 0x0A
            db 'Type help for commands.', 0x0D, 0x0A, 0x0D, 0x0A, 0

dos_prompt db '@BarsikOS> ', 0
dos_unknown db 'Unknown command. Type help.', 0x0D, 0x0A, 0

dos_help_text db 'DOS Commands:', 0x0D, 0x0A
              db '  help       - This help', 0x0D, 0x0A
              db '  exit       - Exit to BarsikOS', 0x0D, 0x0A
              db '  ls, dir    - List files', 0x0D, 0x0A
              db '  makedir    - Create folder', 0x0D, 0x0A
              db '  makefile   - Create file', 0x0D, 0x0A
              db '  install    - Reinstall', 0x0D, 0x0A, 0x0D, 0x0A, 0

dos_ls_text db 'Files:', 0x0D, 0x0A
            db '  system/  config/  docs/', 0x0D, 0x0A, 0x0D, 0x0A, 0

dos_makedir_text db 'makedir not implemented yet.', 0x0D, 0x0A, 0
dos_makefile_text db 'makefile not implemented yet.', 0x0D, 0x0A, 0

; Команды
cmd_help db 'help', 0
cmd_exit db 'exit', 0
cmd_ls db 'ls', 0
cmd_dir db 'dir', 0
cmd_makedir db 'makedir', 0
cmd_makefile db 'makefile', 0
cmd_install db 'install', 0

; Переустановка
reinstall_title db 'System Reinstallation', 0x0D, 0x0A
                db '=====================', 0x0D, 0x0A, 0

reinstall_line1 db '=====================', 0x0D, 0x0A, 0
reinstall_line2 db 'Choose system', 0x0D, 0x0A, 0
reinstall_line3 db 'Select system from list below', 0x0D, 0x0A, 0

reinstall_opt1 db '[ BarsikOS 0.3 (no reinstall)                     ]', 0
reinstall_opt2 db '[ BarsikOS 0.3 (reinstall)                        ]', 0
reinstall_opt3 db '[ BarsikOS 0.2                                    ]', 0
reinstall_opt4 db '[ BarsikOS 0.1 (IMG)                              ]', 0
reinstall_opt5 db '[ BarsikOS 0.1 (ISO)                              ]', 0

reinstall_hint db 'ENTER = Select and reboot', 0

; Директории
dir_root db 'C:', 0

; Буферы
current_dir dw 0
input_buffer times 80 db 0
newline db 0x0D, 0x0A, 0