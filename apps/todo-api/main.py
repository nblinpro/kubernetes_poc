import json
from contextlib import asynccontextmanager

from fastapi import FastAPI, HTTPException
from pydantic import BaseModel
from sqlalchemy import delete, select

from cache import get_cached_todos, invalidate_todos_cache, ping as redis_ping, set_cached_todos
from db import SessionLocal, Todo, init_db


class TodoCreate(BaseModel):
    title: str


class TodoOut(BaseModel):
    id: int
    title: str
    done: bool

    model_config = {"from_attributes": True}


@asynccontextmanager
async def lifespan(app: FastAPI):
    await init_db()
    yield


app = FastAPI(title="todo-api", lifespan=lifespan)


@app.get("/health")
async def health():
    async with SessionLocal() as session:
        await session.execute(select(1))
    await redis_ping()
    return {"status": "ok"}


@app.post("/todos", response_model=TodoOut, status_code=201)
async def create_todo(payload: TodoCreate):
    async with SessionLocal() as session:
        todo = Todo(title=payload.title, done=False)
        session.add(todo)
        await session.commit()
        await session.refresh(todo)
    await invalidate_todos_cache()
    return todo


@app.get("/todos", response_model=list[TodoOut])
async def list_todos():
    cached = await get_cached_todos()
    if cached is not None:
        return json.loads(cached)

    async with SessionLocal() as session:
        result = await session.execute(select(Todo).order_by(Todo.id))
        todos = result.scalars().all()

    payload = [TodoOut.model_validate(t).model_dump() for t in todos]
    await set_cached_todos(json.dumps(payload))
    return payload


@app.get("/todos/{todo_id}", response_model=TodoOut)
async def get_todo(todo_id: int):
    async with SessionLocal() as session:
        todo = await session.get(Todo, todo_id)
        if todo is None:
            raise HTTPException(status_code=404, detail="todo not found")
        return todo


@app.patch("/todos/{todo_id}", response_model=TodoOut)
async def toggle_todo(todo_id: int):
    async with SessionLocal() as session:
        todo = await session.get(Todo, todo_id)
        if todo is None:
            raise HTTPException(status_code=404, detail="todo not found")
        todo.done = not todo.done
        await session.commit()
        await session.refresh(todo)
    await invalidate_todos_cache()
    return todo


@app.delete("/todos/{todo_id}", status_code=204)
async def delete_todo(todo_id: int):
    async with SessionLocal() as session:
        todo = await session.get(Todo, todo_id)
        if todo is None:
            raise HTTPException(status_code=404, detail="todo not found")
        await session.execute(delete(Todo).where(Todo.id == todo_id))
        await session.commit()
    await invalidate_todos_cache()
