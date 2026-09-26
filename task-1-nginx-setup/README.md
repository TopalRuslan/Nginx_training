# Task 1 — установка и запуск Nginx в Linux-контейнере

## Цель

Написать `Dockerfile`, который собирает Linux-контейнер с установленным Nginx и запускает его.
Внутри этого контейнера дальше будем делать все настройки Nginx.

## Что понадобится

- Docker Desktop для Windows (переключён на **Linux containers** — это режим по умолчанию).
  Проверка: `docker version` — в блоке `Server` должно быть `OS/Arch: linux/amd64`.
- Терминал (PowerShell).

## Задание

Создай в этой папке файл `Dockerfile`, который:

1. Берёт за основу обычный Linux-образ — `ubuntu:24.04` или `debian:12`.
   (Не бери готовый образ `nginx` — смысл в том, чтобы поставить его руками.)
2. Устанавливает Nginx через пакетный менеджер `apt`.
3. Открывает порт `80`.
4. Запускает Nginx при старте контейнера.

### Критерии готовности

- [ ] `docker build` проходит без ошибок.
- [ ] Контейнер запускается и **не завершается** сразу (`docker ps` его показывает).
- [ ] http://localhost:8080 в браузере открывает страницу «Welcome to nginx!».
- [ ] Можно зайти внутрь контейнера и увидеть конфиги в `/etc/nginx/`.

## Как собрать и запустить

Из папки `task-1-nginx-setup`:

```powershell
# собрать образ
docker build -t nginx-train .

# запустить контейнер в фоне, порт 8080 на хосте -> 80 в контейнере
docker run -d --name nginx-train -p 8080:80 nginx-train

# проверить
docker ps
curl.exe http://localhost:8080
```

Зайти внутрь контейнера и поработать с Nginx:

```powershell
docker exec -it nginx-train bash
```

Внутри контейнера:

```bash
nginx -v                 # версия
nginx -t                 # проверить конфиг на ошибки
nginx -s reload          # перечитать конфиг без остановки
cat /etc/nginx/nginx.conf
ls /etc/nginx/sites-enabled/
```

Остановить и удалить контейнер (например, чтобы пересобрать):

```powershell
docker rm -f nginx-train
```

## Важно: «сервис» в контейнере

На обычном сервере Nginx запускают как сервис через `systemctl start nginx`.
**В контейнере systemd нет**, поэтому так не получится. Вместо этого:

- Nginx сам является главным процессом контейнера (PID 1).
- Контейнер живёт, пока живёт этот процесс. Если Nginx уйдёт в фон (демонизируется),
  главный процесс завершится — и контейнер сразу остановится.
- Поэтому Nginx нужно запускать **в foreground**.

Роль «менеджера сервиса» выполняет Docker:
`docker start` / `docker stop` / `docker restart nginx-train`,
а автоперезапуск включается флагом `--restart unless-stopped` при `docker run`.

## Подсказки

<details>
<summary>Подсказка 1 — установка</summary>

При установке через `apt` в Dockerfile нужен флаг `-y`, иначе он будет ждать ответа «Y/n».
Не забудь сначала сделать `apt-get update` в той же инструкции `RUN`.

</details>

<details>
<summary>Подсказка 2 — контейнер сразу останавливается</summary>

Посмотри логи: `docker logs nginx-train`.
Скорее всего, Nginx ушёл в фон. Найди в `man nginx` / документации директиву `daemon`
и как передать её через флаг `-g`.

</details>

<details>
<summary>Подсказка 3 — инструкции Dockerfile</summary>

Понадобятся: `FROM`, `RUN`, `EXPOSE`, `CMD`.

</details>

## Дополнительно (по желанию)

- Удали кэш `apt` в той же инструкции `RUN`, чтобы образ был меньше. Сравни размер через `docker images`.
- Замени стартовую страницу на свою `index.html` через `COPY`.
- Запусти контейнер с `--restart unless-stopped`, перезапусти Docker Desktop и проверь, что Nginx поднялся сам.
