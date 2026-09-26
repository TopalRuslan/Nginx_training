const $ = (id) => document.getElementById(id);

// Маршрутизация на клиенте: /about — страница с описанием, всё остальное — список
const isAbout = location.pathname === "/about";
$(isAbout ? "page-about" : "page-todos").hidden = false;
document
  .querySelector(`nav a[href="${isAbout ? "/about" : "/"}"]`)
  .setAttribute("aria-current", "page");

function light(id, on) {
  $(id).classList.toggle("on", on);
}

// Проверяем по заголовкам ответов, через кого прошли запросы
async function traceRoute() {
  try {
    const res = await fetch("/app.js", { method: "HEAD", cache: "no-store" });
    light("node-web", res.headers.get("X-Served-By") === "todo-web");
    light("node-nginx", (res.headers.get("Server") || "").startsWith("nginx"));
  } catch {
    light("node-web", false);
  }
  try {
    const res = await fetch("/api/health", { cache: "no-store" });
    light("node-api", res.ok && res.headers.get("X-Served-By") === "todo-api");
  } catch {
    light("node-api", false);
  }
}

async function api(method, path, body) {
  const res = await fetch(path, {
    method,
    headers: body ? { "Content-Type": "application/json" } : {},
    body: body && JSON.stringify(body),
  });
  if (!res.ok) throw new Error(`${method} ${path} → ${res.status}`);
  return res.json();
}

function showStatus(text) {
  $("status").textContent = text;
}

function renderTodo(todo) {
  const li = document.createElement("li");
  li.className = todo.done ? "item done" : "item";

  const check = document.createElement("input");
  check.type = "checkbox";
  check.id = `todo-${todo.id}`;
  check.checked = todo.done;
  check.onchange = () => run(() => api("PATCH", `/api/todos/${todo.id}`, { done: check.checked }));

  const label = document.createElement("label");
  label.htmlFor = check.id;
  label.textContent = todo.title;

  const remove = document.createElement("button");
  remove.className = "remove";
  remove.textContent = "×";
  remove.setAttribute("aria-label", `Удалить «${todo.title}»`);
  remove.onclick = () => run(() => api("DELETE", `/api/todos/${todo.id}`));

  li.append(check, label, remove);
  return li;
}

async function load() {
  const todos = await api("GET", "/api/todos");
  $("list").replaceChildren(...todos.map(renderTodo));

  const done = todos.filter((t) => t.done).length;
  $("summary").textContent = todos.length
    ? `Готово ${done} из ${todos.length}`
    : "Список пуст — добавь первую задачу.";
  showStatus("");
}

// Выполнить действие с API и перерисовать список; при ошибке — объяснить, что случилось
async function run(action) {
  try {
    await action();
    await load();
  } catch (e) {
    showStatus(
      `API не отвечает (${e.message}). Открой приложение через nginx: http://todo.localhost:8088`
    );
  }
}

$("add-form").onsubmit = (event) => {
  event.preventDefault();
  const input = $("title");
  const title = input.value.trim();
  if (!title) return;
  input.value = "";
  run(() => api("POST", "/api/todos", { title }));
};

traceRoute();
if (!isAbout) run(() => Promise.resolve());
