from fastapi import FastAPI

from app.api.routes import router


def create_app() -> FastAPI:
    app = FastAPI(
        title="Deng Killer Verification API",
        version="0.1.0",
        description="Privacy-preserving single-claim verification service.",
    )
    app.include_router(router)
    return app


app = create_app()
