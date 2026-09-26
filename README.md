# Task 1 — управление Nginx как systemd-сервисом

## Стенд

```powershell
docker compose up -d --build
docker exec -it nginx-train bash
```

Nginx на хосте: http://localhost:8080. При старте контейнера nginx остановлен.
Dockerfile и compose.yaml не трогаем.

## Задание

1. **Запуск и автозапуск.** Проверь статус сервиса nginx. Если он остановлен —
   запусти его и включи автозапуск (enabled).
2. **Проверка в браузере.** Открой http://localhost:8080 — nginx отдаёт стандартную
   страницу «Welcome to nginx!».
3. **Своя страница.** `/var/www/html` — корневая папка сайта (`root`) в стандартном
   конфиге nginx (`/etc/nginx/sites-available/default`). Nginx отдаёт файлы из неё
   по запросу, а при запросе `/` ищет индексный файл — здесь это `index.nginx-debian.html`.
   Папка не обязательная: в следующих заданиях настроим nginx отдавать файлы из любого пути.

   Замени всё содержимое файла `/var/www/html/index.nginx-debian.html` на одну строку:

   ```
   Hello from Nginx training!
   ```
4. **Проверка изменений.** Обнови http://localhost:8080 — вместо «Welcome to nginx!»
   должна отображаться строка `Hello from Nginx training!`.

## Проверка

Чтобы проверить задание, запусти тест из терминала:

```bash
docker exec nginx-train bash /training/task-1-nginx-setup/check.sh
```
