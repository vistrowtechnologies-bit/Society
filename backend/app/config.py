from pydantic import field_validator
from pydantic_settings import BaseSettings


class Settings(BaseSettings):
    database_url: str
    secret_key: str
    access_token_expire_minutes: int = 1440
    upload_dir: str = "uploads"
    openai_api_key: str = ""
    # Comma-separated list of allowed browser origins. Default "*" is fine for
    # local dev; set a real list (e.g. "https://app.societyos.in") in production.
    cors_origins: str = "*"

    @field_validator("database_url")
    @classmethod
    def _normalize_db_url(cls, v: str) -> str:
        # Managed hosts (Railway, Heroku, Render) hand out "postgres://..." or
        # "postgresql://..."; pin the psycopg2 driver SQLAlchemy expects. SQLite
        # URLs (used in tests) are passed through untouched.
        if v.startswith("postgres://"):
            v = "postgresql+psycopg2://" + v[len("postgres://"):]
        elif v.startswith("postgresql://"):
            v = "postgresql+psycopg2://" + v[len("postgresql://"):]
        return v

    @property
    def cors_origin_list(self) -> list[str]:
        return [o.strip() for o in self.cors_origins.split(",") if o.strip()]

    class Config:
        env_file = ".env"


settings = Settings()
