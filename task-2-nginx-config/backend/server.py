"""Бекенд Todo-приложения: простой JSON API на порту 5000.

GET    /api/health       -> {"status": "ok"}
GET    /api/todos        -> список задач
POST   /api/todos        -> создать задачу, тело: {"title": "..."}
PATCH  /api/todos/<id>   -> отметить выполненной, тело: {"done": true}
DELETE /api/todos/<id>   -> удалить задачу

Задачи хранятся в памяти: при перезапуске список возвращается к задачам по умолчанию.
"""

import json
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer

PORT = 5000
TODOS_PREFIX = "/api/todos/"

# Задачи по умолчанию — чтобы API сразу возвращал данные
todos = [
    {"id": 1, "title": "Открыть API напрямую на порту 5500", "done": True},
    {"id": 2, "title": "Настроить nginx для todo.localhost", "done": False},
]
next_id = 3


class Handler(BaseHTTPRequestHandler):
    def send_json(self, status, data):
        body = json.dumps(data, ensure_ascii=False).encode()
        self.send_response(status)
        self.send_header("Content-Type", "application/json; charset=utf-8")
        self.send_header("Content-Length", str(len(body)))
        self.send_header("X-Served-By", "todo-api")
        self.end_headers()
        self.wfile.write(body)

    def read_json(self):
        length = int(self.headers.get("Content-Length", 0))
        try:
            data = json.loads(self.rfile.read(length))
        except ValueError:
            return {}
        return data if isinstance(data, dict) else {}

    def find_todo(self):
        """Задача из адреса /api/todos/<id> или None."""
        todo_id = self.path[len(TODOS_PREFIX):]
        if self.path.startswith(TODOS_PREFIX) and todo_id.isdigit():
            for todo in todos:
                if todo["id"] == int(todo_id):
                    return todo
        return None

    def do_GET(self):
        if self.path == "/api/health":
            self.send_json(200, {"status": "ok"})
        elif self.path == "/api/todos":
            self.send_json(200, todos)
        else:
            self.send_json(404, {"error": "not found"})

    def do_POST(self):
        global next_id
        if self.path != "/api/todos":
            return self.send_json(404, {"error": "not found"})

        title = self.read_json().get("title")
        if not isinstance(title, str) or not title.strip():
            return self.send_json(400, {"error": "title is required"})

        todo = {"id": next_id, "title": title.strip(), "done": False}
        next_id += 1
        todos.append(todo)
        self.send_json(201, todo)

    def do_PATCH(self):
        todo = self.find_todo()
        if todo is None:
            return self.send_json(404, {"error": "not found"})
        todo["done"] = bool(self.read_json().get("done"))
        self.send_json(200, todo)

    def do_DELETE(self):
        todo = self.find_todo()
        if todo is None:
            return self.send_json(404, {"error": "not found"})
        todos.remove(todo)
        self.send_json(200, todo)


if __name__ == "__main__":
    print(f"Todo API listening on port {PORT}", flush=True)
    ThreadingHTTPServer(("0.0.0.0", PORT), Handler).serve_forever()
