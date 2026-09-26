// Фронтенд Todo-приложения: Node.js отдаёт файлы из public/ на порту 3000.
// Любой адрес без файла (например /about) получает index.html — маршрутизацию делает app.js.

const http = require("http");
const fs = require("fs");
const path = require("path");

const PORT = 3000;
const PUBLIC = path.join(__dirname, "public");
const TYPES = {
  ".html": "text/html; charset=utf-8",
  ".js": "text/javascript; charset=utf-8",
  ".css": "text/css; charset=utf-8",
};

function resolveFile(pathname) {
  const file = path.join(PUBLIC, path.normalize(pathname));
  const insidePublic = file.startsWith(PUBLIC + path.sep);
  if (insidePublic && fs.existsSync(file) && fs.statSync(file).isFile()) {
    return file;
  }
  return path.join(PUBLIC, "index.html");
}

http
  .createServer((req, res) => {
    const { pathname } = new URL(req.url, "http://localhost");
    res.setHeader("X-Served-By", "todo-web");

    // API живёт в другом приложении — фронтенд его не обслуживает
    if (pathname.startsWith("/api/")) {
      res.writeHead(404, { "Content-Type": "application/json" });
      res.end(JSON.stringify({ error: "API is served by todo-api, not by the frontend" }));
      return;
    }

    const file = resolveFile(pathname);
    res.writeHead(200, { "Content-Type": TYPES[path.extname(file)] || "application/octet-stream" });
    fs.createReadStream(file).pipe(res);
  })
  .listen(PORT, () => console.log(`Todo frontend listening on port ${PORT}`));
