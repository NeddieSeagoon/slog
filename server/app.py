import argparse
import asyncio
import uvicorn
from fastapi import FastAPI

from config import settings
from database import engine
from models import Base
from endpoints import router
from discord_bot import create_discord_bot

app = FastAPI()
app.include_router(router)

bot = create_discord_bot(settings.DISCORD_BOT_TOKEN)
loop = None

@app.on_event("startup")
async def startup_event():
    global loop
    loop = asyncio.get_event_loop()
    # Start Discord bot in background
    asyncio.create_task(bot.start(settings.DISCORD_BOT_TOKEN))
    print("Discord bot startup task created.")

@app.on_event("shutdown")
async def shutdown_event():
    print("Shutting down application...")
    # Graceful shutdown logic if needed

def notify_discord_bot(event_data):
    if loop is not None:
        asyncio.run_coroutine_threadsafe(bot.handle_new_event(event_data), loop)

def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--init-db", action="store_true", help="Initialize the database tables")
    args = parser.parse_args()

    if args.init_db:
        print("Creating all tables in the database...")
        Base.metadata.create_all(bind=engine)
        print("Database tables created.")
        return

    uvicorn.run("app:app", host="0.0.0.0", port=8000, reload=False)

if __name__ == "__main__":
    main()
