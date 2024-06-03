FROM python:latest
WORKDIR /app

COPY src/*.py .

RUN chmod +x app.py
# RUN chmod +x main.py

RUN pip install fastapi
RUN pip install "uvicorn[standard]"

COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh