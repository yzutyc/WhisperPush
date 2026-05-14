from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from starlette.middleware.base import BaseHTTPMiddleware
from starlette.requests import Request

from app.middleware.logging_middleware import RequestLoggingMiddleware
from app.routers import auth, secrets, messages, devices, two_factor, user_settings

app = FastAPI(title="WhisperPush API", version="1.0.0")

class DynamicCORSMiddleware(BaseHTTPMiddleware):
    async def dispatch(self, request: Request, call_next):
        origin = request.headers.get("origin", "")
        if origin.startswith("http://localhost") or origin.startswith("http://127.0.0.1"):
            response = await call_next(request)
            response.headers["Access-Control-Allow-Origin"] = origin
            response.headers["Access-Control-Allow-Credentials"] = "true"
            response.headers["Access-Control-Allow-Methods"] = "*"
            response.headers["Access-Control-Allow-Headers"] = "*"
            return response
        return await call_next(request)

app.add_middleware(RequestLoggingMiddleware)
app.add_middleware(DynamicCORSMiddleware)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=False,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(auth.router, prefix="/api/v1/auth", tags=["auth"])
app.include_router(two_factor.router, prefix="/api/v1/auth", tags=["auth"])
app.include_router(secrets.router, prefix="/api/v1/secrets", tags=["secrets"])
app.include_router(messages.router, prefix="/api/v1", tags=["messages"])
app.include_router(devices.router, prefix="/api/v1", tags=["devices"])
app.include_router(user_settings.router, tags=["user_settings"])

@app.get("/health")
async def health_check():
    return {"status": "healthy"}