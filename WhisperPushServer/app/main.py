from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from app.middleware.logging_middleware import RequestLoggingMiddleware
from app.routers import auth, secrets, messages, devices, two_factor, user_settings

app = FastAPI(title="WhisperPush API", version="0.1.10")

_main_loop = None


@app.on_event("startup")
def _save_event_loop():
    global _main_loop
    import asyncio
    _main_loop = asyncio.get_running_loop()


def get_main_loop():
    return _main_loop

app.add_middleware(RequestLoggingMiddleware)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
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