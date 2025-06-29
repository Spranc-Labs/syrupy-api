from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
import logging
from datetime import datetime
from contextlib import asynccontextmanager

from models import JournalEntry, MoodPrediction, CategoryPrediction, InsightResponse
from services.mood_prediction import load_models, predict_mood, is_model_loaded
from services.category_prediction import predict_category
from config import JOURNAL_CATEGORIES

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

@asynccontextmanager
async def lifespan(app: FastAPI):
    # Startup
    load_models()
    yield
    # Shutdown
    logger.info("Shutting down AI insights service")

app = FastAPI(
    title="Syrupy AI Insights Service",
    description="AI-powered mood prediction and category labeling for journal entries",
    version="1.0.0",
    lifespan=lifespan
)

# Configure CORS
app.add_middleware(
    CORSMiddleware,
    allow_origins=["http://localhost:3000", "http://localhost:5173"],  # Rails API and Frontend
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

@app.get("/health")
async def health_check():
    """Health check endpoint"""
    return {
        "status": "healthy",
        "service": "ai-insights-service",
        "timestamp": datetime.utcnow().isoformat(),
        "models_loaded": is_model_loaded(),
        "bert_available": is_model_loaded()
    }

@app.post("/analyze", response_model=InsightResponse)
async def analyze_journal_entry(entry: JournalEntry):
    """
    Analyze a journal entry for mood and category insights
    """
    start_time = datetime.utcnow()
    
    try:
        # Combine title and content for analysis
        full_text = f"{entry.title}. {entry.content}"
        
        # Predict mood and category
        mood_prediction = predict_mood(full_text)
        category_prediction = predict_category(full_text)
        
        # Calculate processing time
        processing_time = (datetime.utcnow() - start_time).total_seconds() * 1000
        
        return InsightResponse(
            mood=mood_prediction,
            category=category_prediction,
            processing_time_ms=round(processing_time, 2),
            timestamp=datetime.utcnow().isoformat()
        )
        
    except Exception as e:
        logger.error(f"Error analyzing journal entry: {e}")
        raise HTTPException(status_code=500, detail=f"Analysis failed: {str(e)}")

@app.post("/predict_mood", response_model=MoodPrediction)
async def predict_mood_endpoint(entry: JournalEntry):
    """
    Predict mood only (for backward compatibility)
    """
    try:
        full_text = f"{entry.title}. {entry.content}"
        return predict_mood(full_text)
    except Exception as e:
        logger.error(f"Error predicting mood: {e}")
        raise HTTPException(status_code=500, detail=f"Mood prediction failed: {str(e)}")

@app.post("/predict_category", response_model=CategoryPrediction)
async def predict_category_endpoint(entry: JournalEntry):
    """
    Predict category only (for backward compatibility)
    """
    try:
        full_text = f"{entry.title}. {entry.content}"
        return predict_category(full_text)
    except Exception as e:
        logger.error(f"Error predicting category: {e}")
        raise HTTPException(status_code=500, detail=f"Category prediction failed: {str(e)}")

@app.get("/categories")
async def get_available_categories():
    """
    Get list of available categories
    """
    return {
        "categories": list(JOURNAL_CATEGORIES.keys()),
        "descriptions": {
            "personal_growth": "Self-improvement, reflection, and personal development",
            "relationships": "Family, friends, romantic relationships, and social connections",
            "work_career": "Professional life, career development, and workplace experiences",
            "health_wellness": "Physical and mental health, fitness, and wellness activities",
            "travel_adventure": "Travel experiences, adventures, and exploration",
            "daily_life": "Routine activities, everyday experiences, and mundane events",
            "emotions_feelings": "Emotional processing, feelings, and mood-focused entries",
            "hobbies_interests": "Creative pursuits, hobbies, and personal interests",
            "spirituality": "Spiritual practices, meditation, and faith-related content",
            "challenges_struggles": "Difficulties, problems, stress, and challenging situations"
        }
    } 