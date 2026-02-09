FROM python:3.12-slim AS builder

WORKDIR /build
COPY requirements.txt .
RUN pip install --no-cache-dir --target=/deps -r requirements.txt

FROM python:3.12-slim

RUN groupadd --gid 1000 app && useradd --uid 1000 --gid app --no-create-home app

WORKDIR /app
COPY --from=builder /deps /usr/local/lib/python3.12/site-packages
COPY . .

USER app
EXPOSE 8000

CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8000"]
