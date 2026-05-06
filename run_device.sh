#!/bin/bash
# Скрипт запуска приложения на устройстве
# Обходит баг Flutter 3.41 + Xcode 26.2 beta с таймаутом debug сессии
#
# Использование:
#   ./run_device.sh          — сборка + установка + запуск
#   ./run_device.sh install  — только установка + запуск (без пересборки)
#   ./run_device.sh launch   — только запуск (без сборки и установки)

DEVICE_ID="6B961B30-6E77-5DA4-AC61-9ABA6A1BA525"
BUNDLE_ID="com.example.prayday"
APP_PATH="build/ios/iphoneos/Runner.app"

set -e

if [[ "$1" != "install" && "$1" != "launch" ]]; then
  echo "▶ Сборка debug..."
  flutter build ios --debug
fi

if [[ "$1" != "launch" ]]; then
  echo "▶ Установка на устройство..."
  xcrun devicectl device install app \
    --device "$DEVICE_ID" \
    "$APP_PATH"
fi

echo "▶ Запуск приложения..."
xcrun devicectl device process launch \
  --device "$DEVICE_ID" \
  "$BUNDLE_ID"

echo "✓ Готово! Приложение запущено на устройстве."
echo ""
echo "Для hot reload используй: flutter attach -d 00008110-001678D00139801E"
