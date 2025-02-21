"""
Reads environment variables using pydantic. Expects a .env file or system env.
"""
import os
from pydantic import BaseSettings

class Settings(BaseSettings):
    DATABASE_URL: str
    DISCORD_BOT_TOKEN: str

    class Config:
        env_file = ".env"
        env_file_encoding = "utf-8"

settings = Settings()
