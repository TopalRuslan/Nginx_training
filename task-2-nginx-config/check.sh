#!/usr/bin/env bash
# Проверка итогового состояния Task 2. Запускается внутри контейнера nginx-train.

conf=/etc/nginx/conf.d/todo.conf
domain=todo.localhost

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

# Запрос к nginx с нужным доменом в заголовке Host — как из браузера.
# Ходим на 127.0.0.1, а не на localhost: localhost внутри контейнера — это IPv6 (::1),
# а сайт из задания слушает только IPv4 (listen 80), как и запросы с хоста через Docker.
request() {
  local host=$1
  shift
  curl -s -f -H "Host: $host" "$@"
}

# Ответ nginx для домена: код 2xx и тело содержит текст
responds_with() {
  local body
  body=$(request "$1" "127.0.0.1$2") && grep -qF "$3" <<< "$body"
}

# Ответ на адрес пришёл от нужного приложения (заголовок X-Served-By)
served_by() {
  request "$domain" -D - -o /dev/null "127.0.0.1$1" | grep -qiE "^X-Served-By: $2\s*$"
}

# Через nginx создаём задачу, проверяем, что она есть в списке, и удаляем её
api_roundtrip() {
  local created id
  created=$(request "$domain" -X POST -H 'Content-Type: application/json' \
    -d '{"title": "check.sh"}' 127.0.0.1/api/todos) || return 1
  id=$(grep -oE '"id": *[0-9]+' <<< "$created" | grep -oE '[0-9]+$') || return 1
  request "$domain" 127.0.0.1/api/todos | grep -qF '"title": "check.sh"' || return 1
  request "$domain" -X DELETE "127.0.0.1/api/todos/$id" >/dev/null
}

# Шаг 2: конфиг создан, default не тронут
check "2. $conf exists"                          test -f "$conf"
check "2. server_name is $domain" \
  grep -qE "^\s*server_name\s+$domain\s*;" "$conf"
check "2. default site is still enabled"         test -e /etc/nginx/sites-enabled/default

# Шаг 3: конфиг валиден, nginx работает
check "3. nginx config is valid"                 nginx -t
check "3. nginx is running"                      systemctl is-active --quiet nginx

# Шаг 4: запросы доходят до нужных приложений
check "4. $domain/ is served by todo-web"        served_by / todo-web
check "4. $domain/ returns the frontend" \
  responds_with "$domain" / "<title>Todo list</title>"
check "4. $domain/about returns the frontend" \
  responds_with "$domain" /about "<title>Todo list</title>"
check "4. $domain/api/health is served by todo-api" \
  served_by /api/health todo-api
check "4. $domain/api/todos: create and list a todo" \
  api_roundtrip
check "4. localhost returns the default site" \
  responds_with localhost / "Welcome to nginx!"

echo
echo "Passed: $pass, failed: $fail"
if [ "$fail" -eq 0 ]; then
  echo "TASK 2: PASSED"
else
  echo "TASK 2: FAILED"
  exit 1
fi
