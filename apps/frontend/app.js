const API_BASE = "https://todo-api.192.168.80.169.nip.io";

const listEl = document.getElementById("todo-list");
const formEl = document.getElementById("add-form");
const titleEl = document.getElementById("new-title");

async function loadTodos() {
  const res = await fetch(`${API_BASE}/todos`);
  const todos = await res.json();
  renderTodos(todos);
}

function renderTodos(todos) {
  listEl.innerHTML = "";
  for (const todo of todos) {
    const li = document.createElement("li");
    li.className = todo.done ? "done" : "";

    const checkbox = document.createElement("input");
    checkbox.type = "checkbox";
    checkbox.checked = todo.done;
    checkbox.addEventListener("change", () => toggleTodo(todo.id));

    const span = document.createElement("span");
    span.textContent = todo.title;

    const deleteBtn = document.createElement("button");
    deleteBtn.textContent = "✕";
    deleteBtn.className = "delete-btn";
    deleteBtn.addEventListener("click", () => deleteTodo(todo.id));

    li.append(checkbox, span, deleteBtn);
    listEl.appendChild(li);
  }
}

async function createTodo(title) {
  await fetch(`${API_BASE}/todos`, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({ title }),
  });
  await loadTodos();
}

async function toggleTodo(id) {
  await fetch(`${API_BASE}/todos/${id}`, { method: "PATCH" });
  await loadTodos();
}

async function deleteTodo(id) {
  await fetch(`${API_BASE}/todos/${id}`, { method: "DELETE" });
  await loadTodos();
}

formEl.addEventListener("submit", (event) => {
  event.preventDefault();
  const title = titleEl.value.trim();
  if (!title) return;
  titleEl.value = "";
  createTodo(title);
});

loadTodos();
