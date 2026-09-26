# Task 1 — Nginx как systemd-сервис в Linux-контейнере

## Цель

Собрать Linux-контейнер, внутри которого работает **systemd**, а Nginx установлен как обычный
systemd-сервис — так же, как на реальном сервере. Дальше управлять им через `systemctl`:
запуск, остановка, перезапуск, **reload** конфига, автозапуск.

## Что понадобится

- Docker Desktop для Windows в режиме **Linux containers** (режим по умолчанию).
  Проверка: `docker version` — в блоке `Server` должно быть `OS/Arch: linux/amd64`.
- Терминал (PowerShell).

## Почему это не «обычный» контейнер

Обычно в контейнере главный процесс (PID 1) — само приложение, и systemd там нет.
В этой задаче главным процессом будет **systemd** (`/sbin/init`), а уже он запустит Nginx как сервис.

Чтобы systemd смог работать в контейнере, ему нужно:

- доступ к cgroups — поэтому контейнер запускается с `--privileged`;
- `tmpfs` для `/run` и `/run/lock`;
- правильный сигнал остановки: systemd завершается по `SIGRTMIN+3`, а не по `SIGTERM`.

> `--privileged` даёт контейнеру почти полный доступ к хосту. Для учебного стенда это нормально,
> в продакшене так не делают.

## Задание

### Часть 1 — Dockerfile

Создай в этой папке `Dockerfile`, который:

1. Берёт за основу `ubuntu:24.04` (или `debian:12`).
2. Устанавливает через `apt` пакеты **`systemd`** и **`nginx`**.
3. Включает автозапуск Nginx как сервиса (`enable`).
4. Открывает порт `80`.
5. Задаёт сигнал остановки для systemd.
6. Запускает при старте контейнера **systemd**, а не nginx.

### Часть 2 — управление сервисом

Зайди в контейнер и выполни через `systemctl` / `journalctl`:

- [ ] Посмотри статус сервиса: он `active (running)` и `enabled`.
- [ ] Останови Nginx — страница на http://localhost:8080 перестала открываться. Запусти обратно.
- [ ] **Reload vs restart.** Запиши PID master-процесса и worker-процессов (`ps -ef | grep nginx`).
      Сделай `reload` — что поменялось? Сделай `restart` — что поменялось теперь? Объясни разницу.
- [ ] Измени стартовую страницу (`/var/www/html/index.nginx-debian.html`) или конфиг,
      примени изменения **через reload** без остановки сервиса.
- [ ] Специально сломай конфиг (например, убери `;`). Проверь его через `nginx -t`.
      Сделай `reload` — упал ли Nginx? Что показывают `systemctl status nginx` и `journalctl -u nginx`?
      Верни конфиг обратно.
- [ ] Выключи автозапуск (`disable`), перезапусти контейнер (`docker restart nginx-train`) —
      Nginx не поднялся. Включи обратно и проверь, что после рестарта контейнера он стартует сам.

### Критерии готовности

- [ ] `docker build` проходит без ошибок.
- [ ] Контейнер запущен и не падает (`docker ps` его показывает).
- [ ] Внутри контейнера `ps -p 1 -o comm=` показывает `systemd`.
- [ ] `systemctl status nginx` — `active (running)`, `enabled`.
- [ ] http://localhost:8080 открывает страницу «Welcome to nginx!».
- [ ] Все пункты Части 2 выполнены, ответы на вопросы записаны в `ANSWERS.md` в этой папке.

## Как собрать и запустить

Из папки `task-1-nginx-setup`:

```powershell
# собрать образ
docker build -t nginx-train .

# запустить контейнер с systemd
docker run -d --name nginx-train `
  --privileged `
  --tmpfs /run --tmpfs /run/lock `
  -p 8080:80 `
  nginx-train

# проверить
docker ps
curl.exe http://localhost:8080
```

Зайти внутрь:

```powershell
docker exec -it nginx-train bash
```

Шпаргалка команд внутри контейнера:

```bash
systemctl status nginx       # статус сервиса
systemctl start nginx        # запустить
systemctl stop nginx         # остановить
systemctl restart nginx      # перезапустить (полная остановка + запуск)
systemctl reload nginx       # перечитать конфиг без остановки
systemctl enable nginx       # включить автозапуск
systemctl disable nginx      # выключить автозапуск
systemctl is-enabled nginx
journalctl -u nginx -f       # логи сервиса (Ctrl+C — выход)

nginx -t                     # проверить конфиг на ошибки
ps -ef | grep nginx          # процессы nginx
```

Остановить и удалить контейнер (например, чтобы пересобрать):

```powershell
docker rm -f nginx-train
```

## Подсказки

<details>
<summary>Подсказка 1 — установка пакетов</summary>

В Dockerfile `apt` нужен флаг `-y`, и `apt-get update` должен быть в той же инструкции `RUN`.
Чтобы установка не задавала вопросов (выбор часового пояса и т.п.), задай
`DEBIAN_FRONTEND=noninteractive`.

</details>

<details>
<summary>Подсказка 2 — как запустить systemd</summary>

Бинарник systemd в образе — `/sbin/init` (это ссылка на `/lib/systemd/systemd`).
Посмотри инструкции `CMD` и `STOPSIGNAL`.
Ещё systemd понимает, что работает в контейнере, по переменной окружения `container=docker` — задай её через `ENV`.

</details>

<details>
<summary>Подсказка 3 — автозапуск</summary>

`systemctl enable` при сборке образа работает, даже если systemd ещё не запущен:
он просто создаёт симлинк в `/etc/systemd/system/multi-user.target.wants/`.
Проверь, может, пакет nginx уже сделал это сам.

</details>

<details>
<summary>Подсказка 4 — контейнер падает или systemd ругается</summary>

- Смотри `docker logs nginx-train`.
- Ошибки про cgroups → проверь, что запускаешь с `--privileged`.
- Если всё равно не стартует, попробуй добавить `--cgroupns=host -v /sys/fs/cgroup:/sys/fs/cgroup:rw`.

</details>

## Дополнительно (по желанию)

- Удали кэш `apt` в той же инструкции `RUN` и сравни размер образа через `docker images`.
- Отключи (`mask`) ненужные в контейнере юниты systemd, чтобы он стартовал быстрее
  (посмотри `systemctl list-units --failed` и `systemd-analyze blame`).
- Запусти контейнер с `--restart unless-stopped`, перезапусти Docker Desktop и проверь,
  что контейнер и Nginx поднялись сами.
