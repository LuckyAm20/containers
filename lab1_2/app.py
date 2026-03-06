from fastapi import FastAPI, HTTPException
from pydantic import BaseModel, Field
from typing import Dict, Optional, List
from uuid import UUID, uuid4
from datetime import datetime

app = FastAPI(
    title="Mini TODO Service",
    description="Простое FastAPI-приложение",
    version="0.1.0",
)

class TaskCreate(BaseModel):
    title: str = Field(..., min_length=1, max_length=200)
    description: Optional[str] = Field(None, max_length=1000)


class TaskUpdate(BaseModel):
    title: Optional[str] = Field(None, min_length=1, max_length=200)
    description: Optional[str] = Field(None, max_length=1000)
    is_done: Optional[bool] = None


class Task(TaskCreate):
    id: UUID
    is_done: bool = False
    created_at: datetime
    updated_at: datetime


tasks: Dict[UUID, Task] = {}

@app.get("/health", tags=["service"])
def health_check():
    return {"status": "ok"}


@app.get("/info", tags=["service"])
def info():
    return {
        "name": "Mini TODO Service",
        "version": "0.1.0",
        "description": "Пример FastAPI-приложения для лабораторной по Docker.",
        "tasks_count": len(tasks),
        "timestamp": datetime.utcnow().isoformat() + "Z",
    }

@app.post("/tasks", response_model=Task, tags=["tasks"])
def create_task(payload: TaskCreate):
    now = datetime.utcnow()
    task_id = uuid4()
    task = Task(
        id=task_id,
        title=payload.title,
        description=payload.description,
        is_done=False,
        created_at=now,
        updated_at=now,
    )
    tasks[task_id] = task
    return task


@app.get("/tasks", response_model=List[Task], tags=["tasks"])
def list_tasks(only_open: bool = False):
    values = list(tasks.values())
    if only_open:
        values = [t for t in values if not t.is_done]
    return values


@app.get("/tasks/{task_id}", response_model=Task, tags=["tasks"])
def get_task(task_id: UUID):
    task = tasks.get(task_id)
    if not task:
        raise HTTPException(status_code=404, detail="Task not found")
    return task


@app.patch("/tasks/{task_id}", response_model=Task, tags=["tasks"])
def update_task(task_id: UUID, payload: TaskUpdate):
    task = tasks.get(task_id)
    if not task:
        raise HTTPException(status_code=404, detail="Task not found")

    data = task.dict()
    update_data = payload.dict(exclude_unset=True)

    for key, value in update_data.items():
        data[key] = value

    data["updated_at"] = datetime.utcnow()
    updated_task = Task(**data)
    tasks[task_id] = updated_task
    return updated_task


@app.delete("/tasks/{task_id}", status_code=204, tags=["tasks"])
def delete_task(task_id: UUID):
    if task_id not in tasks:
        raise HTTPException(status_code=404, detail="Task not found")
    del tasks[task_id]
    return None


@app.get("/tasks-stats", tags=["tasks"])
def tasks_stats():
    total = len(tasks)
    done = sum(1 for t in tasks.values() if t.is_done)
    open_ = total - done

    return {
        "total": total,
        "done": done,
        "open": open_,
    }

