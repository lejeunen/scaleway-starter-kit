import os
from contextlib import asynccontextmanager

from fastapi import Depends, FastAPI, HTTPException
from sqlalchemy import func, select, text
from sqlalchemy.ext.asyncio import AsyncSession

from database import async_session, engine, get_session
from models import Base, Wisdom, WisdomCreate, WisdomResponse
from seed import SEED_DATA


async def init_db():
    async with engine.begin() as conn:
        await conn.run_sync(Base.metadata.create_all)

    async with async_session() as session:
        result = await session.execute(select(func.count(Wisdom.id)))
        count = result.scalar()
        if count == 0:
            for entry in SEED_DATA:
                session.add(Wisdom(**entry))
            await session.commit()


@asynccontextmanager
async def lifespan(app: FastAPI):
    await init_db()
    yield
    await engine.dispose()


app = FastAPI(
    title="Sovereign Cloud Wisdom",
    description="Principles, facts, and proverbs about European digital sovereignty.",
    version="1.0.0",
    lifespan=lifespan,
)


@app.get("/", response_model=WisdomResponse)
async def random_wisdom(session: AsyncSession = Depends(get_session)):
    """Get a random piece of sovereign cloud wisdom."""
    result = await session.execute(select(Wisdom).order_by(func.random()).limit(1))
    wisdom = result.scalar_one_or_none()
    if not wisdom:
        raise HTTPException(status_code=404, detail="No wisdom found. The database is empty.")
    return wisdom


@app.get("/wisdom", response_model=list[WisdomResponse])
async def list_wisdom(
    category: str | None = None,
    session: AsyncSession = Depends(get_session),
):
    """List all wisdom entries, optionally filtered by category."""
    query = select(Wisdom).order_by(Wisdom.id)
    if category:
        query = query.where(Wisdom.category == category)
    result = await session.execute(query)
    return result.scalars().all()


@app.get("/wisdom/{wisdom_id}", response_model=WisdomResponse)
async def get_wisdom(wisdom_id: int, session: AsyncSession = Depends(get_session)):
    """Get a specific wisdom entry by ID."""
    result = await session.execute(select(Wisdom).where(Wisdom.id == wisdom_id))
    wisdom = result.scalar_one_or_none()
    if not wisdom:
        raise HTTPException(status_code=404, detail="Wisdom not found.")
    return wisdom


@app.post("/wisdom", response_model=WisdomResponse, status_code=201)
async def create_wisdom(
    payload: WisdomCreate,
    session: AsyncSession = Depends(get_session),
):
    """Submit a new piece of sovereign cloud wisdom."""
    wisdom = Wisdom(
        text=payload.text,
        author=payload.author,
        category=payload.category.value,
    )
    session.add(wisdom)
    await session.commit()
    await session.refresh(wisdom)
    return wisdom


@app.get("/health")
async def health_check():
    """Health check endpoint — verifies database connectivity."""
    try:
        async with engine.connect() as conn:
            await conn.execute(text("SELECT 1"))
        return {"status": "healthy", "database": "connected"}
    except Exception as e:
        raise HTTPException(
            status_code=503,
            detail={"status": "unhealthy", "database": str(e)},
        )


if __name__ == "__main__":
    import uvicorn

    port = int(os.getenv("APP_PORT", "8000"))
    uvicorn.run("main:app", host="0.0.0.0", port=port)
