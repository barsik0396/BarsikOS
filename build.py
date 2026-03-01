#!/usr/bin/env python3
"""
BarsikOS v0.3 Build System
Собирает полноценную ОС с UI, установщиком и DOS подсистемой
"""

import os
import sys
import subprocess
import shutil
import hashlib

class Colors:
    GREEN = '\033[92m'
    RED = '\033[91m'
    BLUE = '\033[94m'
    YELLOW = '\033[93m'
    END = '\033[0m'

def print_header(text):
    print(f"\n{Colors.BLUE}{'=' * 60}{Colors.END}")
    print(f"{Colors.BLUE}{text}{Colors.END}")
    print(f"{Colors.BLUE}{'=' * 60}{Colors.END}")

def print_success(text):
    print(f"{Colors.GREEN}✓ {text}{Colors.END}")

def print_error(text):
    print(f"{Colors.RED}✗ {text}{Colors.END}")

def print_info(text):
    print(f"{Colors.YELLOW}ℹ {text}{Colors.END}")

def run_command(cmd, description):
    """Выполнить команду с описанием"""
    print_info(f"{description}...")
    result = subprocess.run(cmd, capture_output=True, text=True)
    if result.returncode != 0:
        print_error(f"Ошибка: {description}")
        print(result.stderr)
        return False
    return True

def calculate_hash(filepath):
    """Вычислить SHA256 хэш файла"""
    sha256 = hashlib.sha256()
    with open(filepath, 'rb') as f:
        for chunk in iter(lambda: f.read(4096), b''):
            sha256.update(chunk)
    return sha256.hexdigest()

def build_component(src, dst, description):
    """Собрать один компонент"""
    print_info(f"Сборка: {description}")
    
    if not run_command(
        [NASM_PATH, '-f', 'bin', src, '-o', dst],
        f"Ассемблирование {src}"
    ):
        return False
    
    print_success(f"{description} готов")
    return True

def find_nasm():
    """Найти NASM в системе"""
    # Сначала пробуем через PATH
    nasm = shutil.which('nasm')
    if nasm:
        return nasm
    
    # Ищем в популярных местах Windows
    possible_paths = [
        r'D:\NASM\nasm.exe',
        r'C:\NASM\nasm.exe',
        r'C:\Program Files\NASM\nasm.exe',
        r'C:\Program Files (x86)\NASM\nasm.exe',
        os.path.expanduser(r'~\AppData\Local\bin\NASM\nasm.exe'),
    ]
    
    for path in possible_paths:
        if os.path.exists(path):
            print_info(f"NASM найден в: {path}")
            return path
    
    return None

def check_tools():
    """Проверить наличие необходимых инструментов"""
    print_header("Проверка инструментов")
    
    # Ищем NASM
    global NASM_PATH
    NASM_PATH = find_nasm()
    
    if NASM_PATH:
        print_success(f"NASM assembler найден")
    else:
        print_error(f"NASM assembler НЕ НАЙДЕН!")
    
    # Python
    if shutil.which('python3') or shutil.which('python'):
        print_success("Python 3 найден")
    else:
        print_error("Python 3 НЕ НАЙДЕН!")
    
    # ISO creators
    has_iso_tool = False
    for tool in ['xorrisofs', 'genisoimage']:
        if shutil.which(tool):
            print_success(f"{tool} найден")
            has_iso_tool = True
            break
    
    if not has_iso_tool:
        print_info("ISO creator не найден - ISO не будет создан")
    
    if not NASM_PATH:
        print_error("\n❌ Не хватает инструментов!")
        print_info("\nНАША СИТУАЦИЯ: NASM установлен в D:\\NASM\\nasm.exe")
        print_info("но не добавлен в PATH.")
        print_info("\nВыберите один из вариантов:")
        print_info("\n1. Добавить D:\\NASM в PATH:")
        print_info("   setx PATH \"%PATH%;D:\\NASM\"")
        print_info("   Потом перезапусти PowerShell")
        print_info("\n2. Использовать WSL (рекомендуется):")
        print_info("   wsl --install")
        print_info("   wsl")
        print_info("   sudo apt install nasm genisoimage")
        print_info("   cd /mnt/d/BarsikOS")
        print_info("   python3 build.py")
        return False
    
    return True

# Глобальная переменная для пути к NASM
NASM_PATH = 'nasm'

def main():
    print_header("BarsikOS v0.3 Build System")
    
    # Проверяем инструменты
    if not check_tools():
        return 1
    
    # Создаём директории
    os.makedirs("build", exist_ok=True)
    os.makedirs("build/old_versions", exist_ok=True)
    os.makedirs("iso_root", exist_ok=True)
    
    # === 1. Собираем компоненты ===
    print_header("Этап 1: Сборка компонентов")
    
    # Stage 1 Bootloader
    if not build_component(
        'boot/stage1.asm',
        'build/stage1.bin',
        'Stage 1 Bootloader'
    ):
        return 1
    
    # Installer + Kernel + DOS (все вместе)
    print_info("Объединяем Stage 2 + Installer + Kernel + DOS...")
    
    # Создаём главный файл который включает всё
    with open('build/stage2_full.asm', 'w') as f:
        f.write('; BarsikOS v0.3 - Stage 2 Full System\n')
        f.write('[BITS 16]\n')
        f.write('[ORG 0x1000]\n\n')
        f.write('%include "boot/stage2.asm"\n')
        f.write('%include "ui/ui.asm"\n')
        f.write('%include "installer/installer.asm"\n')
        f.write('%include "kernel/kernel.asm"\n')
        f.write('%include "dos/dos.asm"\n')
    
    if not build_component(
        'build/stage2_full.asm',
        'build/stage2_full.bin',
        'Stage 2 Full System'
    ):
        return 1
    
    # === 2. Объединяем в образ ===
    print_header("Этап 2: Создание образа")
    
    with open('build/barsikos_v03.bin', 'wb') as outfile:
        # Stage 1 (512 байт - сектор 1)
        with open('build/stage1.bin', 'rb') as f:
            data = f.read()
            if len(data) != 512:
                print_error(f"Stage 1 должен быть 512 байт, а не {len(data)}!")
                return 1
            outfile.write(data)
            print_success(f"Stage 1 добавлен ({len(data)} байт)")
        
        # Stage 2 Full (включает всё) - до 72 секторов (36KB)
        with open('build/stage2_full.bin', 'rb') as f:
            data = f.read()
            # Дополняем до 36864 байт (72 сектора)
            max_size = 36864
            if len(data) > max_size:
                print_error(f"Stage 2 слишком большой! ({len(data)} байт > {max_size})")
                print_info("Нужно упростить код")
                return 1
            if len(data) < max_size:
                data += b'\x00' * (max_size - len(data))
            outfile.write(data)
            print_success(f"Stage 2 Full добавлен ({len(data)} байт)")
    
    # Дополняем до 1.44MB
    current_size = os.path.getsize('build/barsikos_v03.bin')
    target_size = 1440 * 1024
    
    if current_size < target_size:
        with open('build/barsikos_v03.bin', 'ab') as f:
            f.write(b'\x00' * (target_size - current_size))
    
    print_success(f"Образ создан: build/barsikos_v03.bin ({target_size} байт)")
    
    # === 3. Подготовка старых версий ===
    print_header("Этап 3: Подготовка старых версий")
    
    old_versions = [
        ('BarsikOS-0.1-ISO.iso', 'c897812af108e1d8d64f99e33a077cf4c5143ff83e3aee3ec91e5fcc0c960083'),
        ('BarsikOS-0.1-IMG.img', '60c0d025dc0727bd6f48004b4bbbffc274fee5057bebb6cf4e48e45d10c4f7bb'),
        ('barsikos_v0.2.iso', '14ba190a06fb2e6da6bb437c3fa1ced394e893c384627ba861e47971962cc999')
    ]
    
    for filename, expected_hash in old_versions:
        if os.path.exists(filename):
            actual_hash = calculate_hash(filename)
            
            if actual_hash == expected_hash:
                shutil.copy(filename, f'build/old_versions/{filename}')
                print_success(f"{filename} проверен и добавлен")
            else:
                print_error(f"{filename} - хэш не совпадает!")
                print_info(f"Ожидается: {expected_hash}")
                print_info(f"Получено:  {actual_hash}")
        else:
            print_info(f"{filename} не найден (пропускаем)")
    
    # === 4. Создание ISO ===
    print_header("Этап 4: Создание ISO")
    
    # Ищем ISO creator
    iso_tool = None
    for tool in ['xorrisofs', 'genisoimage']:
        if shutil.which(tool):
            iso_tool = tool
            break
    
    if not iso_tool:
        print_info("ISO creator не найден - пропускаем создание ISO")
        print_info("Floppy образ .bin уже готов!")
    else:
        # Копируем образ в iso_root
        shutil.copy('build/barsikos_v03.bin', 'iso_root/barsikos.img')
        
        # Копируем старые версии
        if os.path.exists('build/old_versions'):
            for f in os.listdir('build/old_versions'):
                shutil.copy(
                    os.path.join('build/old_versions', f),
                    os.path.join('iso_root', f)
                )
        
        # Создаём ISO
        if run_command(
            [iso_tool,
             '-o', 'build/barsikos_v03.iso',
             '-b', 'barsikos.img',
             '-no-emul-boot',
             '-boot-load-size', '4',
             'iso_root/'],
            "Создание ISO"
        ):
            print_success("ISO создан: build/barsikos_v03.iso")
        else:
            print_info("Не удалось создать ISO, но .bin готов")
    
    # === 5. Вычисляем хэши ===
    print_header("Этап 5: Вычисление хэшей")
    
    hash_bin = calculate_hash('build/barsikos_v03.bin')
    print_info(f"barsikos_v03.bin: sha256:{hash_bin}")
    
    if os.path.exists('build/barsikos_v03.iso'):
        hash_iso = calculate_hash('build/barsikos_v03.iso')
        print_info(f"barsikos_v03.iso: sha256:{hash_iso}")
    
    # Сохраняем хэши
    with open('build/hashes.txt', 'w') as f:
        f.write(f"barsikos_v03.bin: sha256:{hash_bin}\n")
        if os.path.exists('build/barsikos_v03.iso'):
            f.write(f"barsikos_v03.iso: sha256:{hash_iso}\n")
    
    # === Финал ===
    print_header("✓ Сборка завершена!")
    
    print("\nСозданные файлы:")
    print(f"  • build/barsikos_v03.bin - Floppy образ")
    if os.path.exists('build/barsikos_v03.iso'):
        print(f"  • build/barsikos_v03.iso - ISO образ")
    print(f"  • build/hashes.txt - SHA256 хэши")
    
    print("\nЗапуск:")
    print(f"  qemu-system-i386 -drive file=build/barsikos_v03.bin,format=raw,if=floppy -boot a")
    if os.path.exists('build/barsikos_v03.iso'):
        print(f"  qemu-system-i386 -cdrom build/barsikos_v03.iso")
    
    print(f"\n{Colors.GREEN}Готово к релизу! 🚀🐱{Colors.END}\n")
    
    return 0

if __name__ == '__main__':
    sys.exit(main())