FROM python:latest
WORKDIR /src

COPY src/app.py .
RUN chmod +x app.py

COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh