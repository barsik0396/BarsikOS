; BarsikOS v0.3 - DOS Subsystem
; Linux-стиль путей: /, /bin, /home и т.д.
[BITS 16]

dos_main:
    ; Показать курсор
    mov ah, 0x01
    mov cx, 0x0607
    int 0x10

    ; Приветствие
    mov si, dos_welcome1
    call ui_print
    mov si, dos_welcome2
    call ui_print
    mov si, dos_newline
    call ui_print

    ; Начальная директория
    mov word [dos_curdir_ptr], dos_dir_root

dos_loop:
    ; Prompt: /current/dir @BarsikOS> _
    mov al, 0x0A     ; LF
    mov ah, 0x0E
    int 0x10

    ; Цвет prompt'а (зелёный) — через прямую запись в VGA
    ; Но для простоты используем teletype
    mov si, dos_prompt_start
    call ui_print

    ; Текущий каталог
    push si
    mov si, [dos_curdir_ptr]
    call ui_print
    pop si

    mov si, dos_prompt_end
    call ui_print

    ; Читаем команду
    mov di, dos_input_buf
    call dos_readline

    ; Выполняем
    call dos_exec

    jmp dos_loop

; ─── Читать строку ───
dos_readline:
    xor cx, cx
.loop:
    call ui_wait_key

    cmp al, 0x0D        ; Enter
    je .done

    cmp al, 0x08        ; Backspace
    je .bs

    cmp al, 0x1B        ; ESC
    je .cancel

    cmp al, 0x20
    jb .loop

    cmp cx, 78
    jae .loop

    mov [di], al
    inc di
    inc cx
    mov ah, 0x0E
    int 0x10
    jmp .loop

.bs:
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

.cancel:
    ; Очищаем буфер
    mov di, dos_input_buf
    mov byte [di], 0
    mov si, dos_newline
    call ui_print
    ret

.done:
    mov byte [di], 0
    mov si, dos_newline
    call ui_print
    ret

; ─── Выполнить команду ───
dos_exec:
    mov si, dos_input_buf

    ; Пропустить ведущие пробелы
.skip_space:
    lodsb
    cmp al, ' '
    je .skip_space
    cmp al, 0
    je .empty
    dec si

    ; Сравниваем с командами
    mov di, cmd_help
    call dos_strcmp
    jz .do_help

    mov di, cmd_exit
    call dos_strcmp
    jz .do_exit

    mov di, cmd_ls
    call dos_strcmp
    jz .do_ls

    mov di, cmd_ll
    call dos_strcmp
    jz .do_ls

    mov di, cmd_cd
    call dos_strcmp
    jz .do_cd

    mov di, cmd_pwd
    call dos_strcmp
    jz .do_pwd

    mov di, cmd_cat_file
    call dos_strcmp
    jz .do_cat

    mov di, cmd_uname
    call dos_strcmp
    jz .do_uname

    mov di, cmd_install
    call dos_strcmp
    jz .do_install

    mov di, cmd_clear
    call dos_strcmp
    jz .do_clear

    mov di, cmd_echo
    call dos_strcmp_prefix
    jz .do_echo

    ; Неизвестная команда
    mov si, dos_err_unknown1
    call ui_print
    mov si, dos_input_buf
    call ui_print
    mov si, dos_err_unknown2
    call ui_print
    ret

.empty:
    ret

.do_help:
    mov si, dos_help_text
    call ui_print
    ret

.do_exit:
    call ui_clear_screen_black
    mov ah, 0x01
    mov cx, 0x2000
    int 0x10
    jmp kernel_main

.do_ls:
    mov si, dos_ls_output
    call ui_print
    ret

.do_cd:
    ; Простая cd: переключение между /, /bin, /home
    mov si, dos_input_buf
    add si, 3           ; пропустить "cd "
    cmp byte [si], 0
    je .cd_root         ; просто cd → /
    cmp byte [si], '/'
    je .cd_check

.cd_check:
    ; Сравниваем аргумент
    push si
    mov di, dos_arg_bin
    call dos_strcmp_from_si
    jz .cd_bin

    pop si
    push si
    mov di, dos_arg_home
    call dos_strcmp_from_si
    jz .cd_home

    pop si
    push si
    mov di, dos_arg_root
    call dos_strcmp_from_si
    jz .cd_root2

    pop si
    mov si, dos_err_nodir
    call ui_print
    ret

.cd_root:
.cd_root2:
    pop si
    mov word [dos_curdir_ptr], dos_dir_root
    ret
.cd_bin:
    pop si
    mov word [dos_curdir_ptr], dos_dir_bin
    ret
.cd_home:
    pop si
    mov word [dos_curdir_ptr], dos_dir_home
    ret

.do_pwd:
    mov si, [dos_curdir_ptr]
    call ui_print
    mov si, dos_newline
    call ui_print
    ret

.do_cat:
    mov si, dos_cat_output
    call ui_print
    ret

.do_uname:
    mov si, dos_uname_str
    call ui_print
    ret

.do_clear:
    call ui_clear_screen_black
    ret

.do_echo:
    ; Печатаем всё после "echo "
    mov si, dos_input_buf
    add si, 5           ; "echo "
    cmp byte [si], 0
    je .echo_empty
    call ui_print
    mov si, dos_newline
    call ui_print
    ret
.echo_empty:
    mov si, dos_newline
    call ui_print
    ret

.do_install:
    call dos_show_install
    ret

; ─── INSTALL команда — меню выбора версий ───
dos_show_install:
    push ax
    push bx
    push si

    call ui_clear_screen_black

    ; Заголовок
    mov ah, 0x01
    mov cx, 0x2000
    int 0x10

    ; Заголовок через VGA
    push di
    push es
    push cx
    push ax
    mov ax, 0xB800
    mov es, ax
    xor di, di
    mov cx, 80
    mov al, ' '
    mov ah, 0x70
.inst_top:
    stosw
    loop .inst_top
    pop ax
    pop cx
    pop es
    pop di

    mov si, inst_menu_title
    mov dh, 0
    mov dl, 1
    mov bl, 0x70
    call vga_print

    ; Окно
    mov dh, 2
    mov dl, 5
    mov bh, 19
    mov bl, 70
    mov si, inst_menu_win
    call ui_draw_window

    mov si, inst_menu_hdr
    mov dh, 4
    mov dl, 8
    mov bl, 0x1F
    call vga_print

    ; Список версий с навигацией
    mov byte [inst_menu_sel], 0

.inst_redraw:
    ; Рисуем 5 вариантов
    mov cl, 0
.draw_loop:
    cmp cl, 5
    je .draw_done

    movzx ax, cl
    add al, 7           ; строки 7-11
    mov dh, al

    mov al, cl
    cmp al, [inst_menu_sel]
    jne .item_normal
    mov bl, COL_MENU_SEL
    jmp .item_draw
.item_normal:
    mov bl, COL_MENU_ITEM
.item_draw:
    mov dl, 8

    ; Выбираем строку
    push cx
    movzx bx, cl
    shl bx, 1
    mov si, [inst_items + bx]
    call vga_print
    pop cx

    inc cl
    jmp .draw_loop
.draw_done:

    ; Разделитель
    push di
    push es
    push cx
    push ax
    mov ax, 0xB800
    mov es, ax
    mov di, 14*80*2 + 6*2
    mov cx, 68
    mov al, 0xC4
    mov ah, COL_WINDOW_BD
.isep:
    stosw
    loop .isep
    pop ax
    pop cx
    pop es
    pop di

    ; Кнопки
    mov si, inst_menu_btn_sel
    mov dh, 15
    mov dl, 20
    mov bl, COL_BTN_SEL
    call ui_draw_button

    mov si, inst_menu_btn_cancel
    mov dh, 15
    mov dl, 40
    mov bl, COL_BTN_NORM
    call ui_draw_button

    mov si, inst_menu_hint
    mov dh, 23
    mov dl, 18
    mov bl, 0x07
    call vga_print

    ; Читаем клавишу
    call ui_wait_key

    cmp al, 0x1B
    je .inst_cancel

    cmp ah, 0x48        ; вверх
    je .inst_up

    cmp ah, 0x50        ; вниз
    je .inst_down

    cmp al, 0x0D
    je .inst_select

    jmp .inst_redraw

.inst_up:
    cmp byte [inst_menu_sel], 0
    je .inst_redraw
    dec byte [inst_menu_sel]
    jmp .inst_redraw

.inst_down:
    cmp byte [inst_menu_sel], 4
    je .inst_redraw
    inc byte [inst_menu_sel]
    jmp .inst_redraw

.inst_select:
    cmp byte [inst_menu_sel], 0
    je .sel_v03_stay    ; v0.3 без переустановки

    ; Остальные варианты - показываем сообщение "не реализовано"
    call ui_clear_screen_black
    mov ah, 0x01
    mov cx, 0x0607
    int 0x10
    mov si, inst_not_avail
    call ui_print
    pop si
    pop bx
    pop ax
    ret

.sel_v03_stay:
    ; Просто возвращаемся в DOS
    call ui_clear_screen_black
    mov ah, 0x01
    mov cx, 0x0607
    int 0x10
    mov si, inst_already
    call ui_print
    pop si
    pop bx
    pop ax
    ret

.inst_cancel:
    call ui_clear_screen_black
    mov ah, 0x01
    mov cx, 0x0607
    int 0x10
    pop si
    pop bx
    pop ax
    ret

; ─── dos_strcmp: сравнить [si] и [di] (до пробела/нуля) ───
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
    jne .ne
    jmp .loop
.check_end:
    cmp bl, 0
    je .eq
    cmp bl, ' '
    je .eq
.ne:
    pop di
    pop si
    or ax, 1
    ret
.eq:
    pop di
    pop si
    xor ax, ax
    ret

; ─── dos_strcmp_prefix: совпадает ли префикс ───
dos_strcmp_prefix:
    push si
    push di
.loop:
    mov bl, [di]
    cmp bl, 0
    je .eq
    lodsb
    cmp al, bl
    jne .ne
    inc di
    jmp .loop
.ne:
    pop di
    pop si
    or ax, 1
    ret
.eq:
    pop di
    pop si
    xor ax, ax
    ret

; ─── dos_strcmp_from_si: сравнить [si] с [di] ───
dos_strcmp_from_si:
.loop:
    lodsb
    mov bl, [di]
    inc di
    cmp al, 0
    je .check2
    cmp al, bl
    jne .ne
    jmp .loop
.check2:
    cmp bl, 0
    je .eq
.ne:
    or ax, 1
    ret
.eq:
    xor ax, ax
    ret

; ─── Данные ───
dos_curdir_ptr  dw dos_dir_root

dos_dir_root  db '/', 0
dos_dir_bin   db '/bin', 0
dos_dir_home  db '/home', 0
dos_dir_etc   db '/etc', 0

dos_welcome1  db 'BarsikOS DOS Subsystem v0.3', 0x0D, 0x0A, 0
dos_welcome2  db 'Type "help" for commands. Type "exit" to return.', 0x0D, 0x0A, 0

dos_prompt_start  db 0
dos_prompt_end    db ' @BarsikOS> ', 0
dos_newline       db 0x0D, 0x0A, 0

dos_help_text  db 'Available commands:', 0x0D, 0x0A
               db '  help          - Show this help', 0x0D, 0x0A
               db '  exit          - Return to BarsikOS desktop', 0x0D, 0x0A
               db '  ls, ll        - List files/directories', 0x0D, 0x0A
               db '  cd <path>     - Change directory (/, /bin, /home)', 0x0D, 0x0A
               db '  pwd           - Print working directory', 0x0D, 0x0A
               db '  cat <file>    - Show file contents', 0x0D, 0x0A
               db '  uname         - System information', 0x0D, 0x0A
               db '  echo <text>   - Print text', 0x0D, 0x0A
               db '  clear         - Clear screen', 0x0D, 0x0A
               db '  install       - Manage BarsikOS installations', 0x0D, 0x0A
               db 0x0D, 0x0A, 0

dos_ls_output  db 'dr-xr-xr-x  bin/', 0x0D, 0x0A
               db 'dr-xr-xr-x  etc/', 0x0D, 0x0A
               db 'dr-xr-xr-x  home/', 0x0D, 0x0A
               db 'dr-xr-xr-x  sys/', 0x0D, 0x0A
               db '-r-xr-xr-x  kernel.bin', 0x0D, 0x0A
               db 0x0D, 0x0A, 0

dos_cat_output  db '[file contents not implemented yet]', 0x0D, 0x0A, 0

dos_uname_str   db 'BarsikOS 0.3 pre-release 1  x86 16bit', 0x0D, 0x0A
                db '(c) 2026 barsik0396 - free open-source software', 0x0D, 0x0A
                db 0x0D, 0x0A, 0

dos_err_unknown1  db 'bash: ', 0
dos_err_unknown2  db ': command not found', 0x0D, 0x0A, 0
dos_err_nodir     db 'cd: no such directory', 0x0D, 0x0A, 0

; команды
cmd_help      db 'help', 0
cmd_exit      db 'exit', 0
cmd_ls        db 'ls', 0
cmd_ll        db 'll', 0
cmd_cd        db 'cd', 0
cmd_pwd       db 'pwd', 0
cmd_cat_file  db 'cat', 0
cmd_uname     db 'uname', 0
cmd_install   db 'install', 0
cmd_clear     db 'clear', 0
cmd_echo      db 'echo', 0

dos_arg_bin   db '/bin', 0
dos_arg_home  db '/home', 0
dos_arg_root  db '/', 0

; Меню установки
inst_menu_sel      db 0
inst_menu_title    db ' BarsikOS Install Manager', 0
inst_menu_win      db ' Select version', 0
inst_menu_hdr      db 'Choose a BarsikOS version to install:', 0

; Массив указателей на строки меню
inst_items:
    dw inst_item0
    dw inst_item1
    dw inst_item2
    dw inst_item3
    dw inst_item4

inst_item0  db 0xBB, ' BarsikOS 0.3 pre-release 1  [current, no reinstall]   ', 0
inst_item1  db 0xBB, ' BarsikOS 0.3 pre-release 1  [reinstall]               ', 0
inst_item2  db 0xBB, ' BarsikOS 0.2                                           ', 0
inst_item3  db 0xBB, ' BarsikOS 0.1  (IMG)                                    ', 0
inst_item4  db 0xBB, ' BarsikOS 0.1  (ISO)                                    ', 0

inst_menu_btn_sel     db 'Install / Select', 0
inst_menu_btn_cancel  db 'Cancel', 0
inst_menu_hint        db 0x18, 0x19, ' Navigate   Enter', 0xF9, 'Select   ESC', 0xF9, 'Cancel', 0

inst_not_avail  db 'This version is not available in this build.', 0x0D, 0x0A
                db 'Visit: https://barsik0396.github.io/BarsikOS/', 0x0D, 0x0A
                db 0x0D, 0x0A, 0
inst_already    db 'BarsikOS 0.3 is already running. No action taken.', 0x0D, 0x0A
                db 0x0D, 0x0A, 0

dos_input_buf  times 80 db 0
