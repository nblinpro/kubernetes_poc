import os

import redis.asyncio as redis

TODOS_CACHE_KEY = "todos:all"
TODOS_CACHE_TTL_SECONDS = 30

client = redis.Redis(
    host=os.environ["REDIS_HOST"],
    port=int(os.environ.get("REDIS_PORT", "6379")),
    password=os.environ["REDIS_PASSWORD"],
    decode_responses=True,
)


async def get_cached_todos() -> str | None:
    return await client.get(TODOS_CACHE_KEY)


async def set_cached_todos(payload: str) -> None:
    await client.set(TODOS_CACHE_KEY, payload, ex=TODOS_CACHE_TTL_SECONDS)


async def invalidate_todos_cache() -> None:
    await client.delete(TODOS_CACHE_KEY)


async def ping() -> bool:
    return await client.ping()
