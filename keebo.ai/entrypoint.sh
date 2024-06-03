#!/usr/bin/env bash

# /app/app.py

# echo "starting uvicorn on port ${PORT}"
# uvicorn main:app --port ${PORT} --reload

echo "starting app"
python3 main.py

# echo "starting server on port ${PORT}"
# fastapi dev main.py --port ${PORT}