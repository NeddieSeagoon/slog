from database import engine
from models import Base

if __name__ == "__main__":
    print("Creating all tables in the database...")
    Base.metadata.create_all(bind=engine)
    print("Database tables created.")