#!/usr/bin/env bash
# Проверка итогового состояния Task 1. Запускается внутри контейнера nginx-train.

expected="Hello from Nginx training!"
page=/var/www/html/index.nginx-debian.html

pass=0
fail=0

check() {
  local name=$1
  shift
  if "$@" >/dev/null 2>&1; then
    echo "PASS  $name"
    pass=$((pass + 1))
  else
    echo "FAIL  $name"
    fail=$((fail + 1))
  fi
}

# Шаг 1: сервис запущен и автозапуск включён
check "1. nginx is running" \
  systemctl is-active --quiet nginx
check "1. nginx autostart is enabled" \
  bash -c '[ "$(systemctl is-enabled nginx)" = enabled ]'

# Шаг 3: файл изменён и nginx его отдаёт
check "3. $page contains only '$expected'" \
  bash -c '[ "$(tr -d "\r" < "$1")" = "$2" ]' _ "$page" "$expected"
check "3. nginx serves '$expected'" \
  bash -c '[ "$(curl -s localhost | tr -d "\r")" = "$1" ]' _ "$expected"

echo
echo "Passed: $pass, failed: $fail"
if [ "$fail" -eq 0 ]; then
  echo "TASK 1: PASSED"
else
  echo "TASK 1: FAILED"
  exit 1
fi
