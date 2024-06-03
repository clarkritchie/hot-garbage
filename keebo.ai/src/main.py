#!/usr/bin/env python

from fastapi import FastAPI
import os

PORT = int(os.getenv("PORT", 8000))
print(f"starting fast api server on {PORT}")

app = FastAPI()

@app.get("/")
def read_root():
    return {"BAR": "World"}

# Run the FastAPI server using uvicorn
if __name__ == "__main__":
    import uvicorn

    uvicorn.run(app, host="0.0.0.0", port=PORT)