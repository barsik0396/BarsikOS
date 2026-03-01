@echo off
chcp 65001 >nul

::
::
:: Скрипт сборки BarsikOS v0.3
:: Написал: barsik0396
:: GitHub: https://github.com/barsik0396/BarsikOS
::
::

:: Конфигурация
:: Сколько будет этапов? (визуально)
SET "stages=3"
:: Какая версия python?
SET "py=3.14"

:: "Баннер"
echo.
echo BarsikOS build script
echo Создал: barsik0396
echo.


:: Этап 1 — очистка прошлой сборки
echo Этап 1 - очистка прошлой сборки
:: Удаление папки build
echo Удаление папки...
echo Выполнение: rd /s /q build
rd /s /q build
:: Создание папки build
echo Создание папки...
echo Выполнение: md build
md build
:: Сообщение о завершении
echo Этап 1 завершён!

:: Этап 2 — сборка (через python-скрипт)
echo Этап 2 - сборка
echo Выполнение: py -%py% build.py
call py -%py% build.py

:: Завершение
echo.
echo Сборка завершена!
echo Результаты можно посмотреть в папке build.
echo.
exit /b 0