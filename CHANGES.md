# CHANGES – Лаба 1 (HW 1)

- Добавлено мини-приложение на **FastAPI**:
  - TODO-сервис с in-memory хранилищем.
  - Ручки: `/health`, `/info`, CRUD по `/tasks`, `/tasks-stats`.

- Добавлен **хороший Dockerfile** (`Dockerfile.good`):
  - Базовый образ: `python:3.11-slim`.
  - Multi-stage build: `builder` + минимальный `runtime`.
  - Установка зависимостей в builder и перенос в runtime.
  - Непривилегированный пользователь `app`, `WORKDIR /app`.
  - `EXPOSE 8000`, exec-форма `CMD ["uvicorn", ...]`.

- Добавлен **плохой Dockerfile** (`Dockerfile.bad`):
  - Тяжёлый образ `python:3.11`.
  - Работа под root.
  - `COPY . /app` без `.dockerignore`.
  - `RUN pip install ...` прямо в runtime, без multi-stage.
  - Нет `EXPOSE` и healthcheck, строковый `CMD uvicorn app:app ...`.

- Реализовано использование **volume** при запуске:
  - `-v ./data:/app/data` для обоих контейнеров.

- Добавлены краткие ответы на вопросы:
  - Как ограничивать ресурсы (CPU/память) в docker-compose.
  - Как запускать только отдельный сервис из `docker-compose.yml`.
  