from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel, Field
from transformers import pipeline
import logging
import os
import torch
from typing import Dict, List, Optional
import re
from datetime import datetime
from contextlib import asynccontextmanager

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# Global variables for models
sentiment_pipeline = None

# Predefined categories for journal entries
JOURNAL_CATEGORIES = {
    "personal_growth": ["self-improvement", "reflection", "goals", "learning", "growth", "development", "progress"],
    "relationships": ["family", "friends", "love", "social", "connection", "partner", "spouse", "relationship"],
    "work_career": ["work", "career", "job", "professional", "business", "office", "meeting", "project"],
    "health_wellness": ["health", "fitness", "mental health", "wellness", "exercise", "medical", "doctor", "therapy"],
    "travel_adventure": ["travel", "adventure", "vacation", "exploration", "journey", "trip", "visit", "explore"],
    "daily_life": ["routine", "daily", "mundane", "everyday", "ordinary", "morning", "evening", "home"],
    "emotions_feelings": ["happy", "sad", "angry", "excited", "anxious", "grateful", "feel", "feeling", "emotion"],
    "hobbies_interests": ["hobby", "creative", "art", "music", "reading", "gaming", "craft", "paint", "draw"],
    "spirituality": ["spiritual", "meditation", "prayer", "mindfulness", "faith", "religious", "god", "soul"],
    "challenges_struggles": ["difficult", "struggle", "challenge", "problem", "stress", "issue", "trouble", "hard"]
}

def load_models():
    """Load AI models on startup"""
    global sentiment_pipeline
    
    try:
        logger.info("Loading emotion classification model...")
        # Use a lightweight but effective emotion model
        sentiment_pipeline = pipeline(
            "text-classification",
            model="j-hartmann/emotion-english-distilroberta-base",
            device=-1,  # Force CPU usage to avoid GPU issues
            framework="pt"
        )
        logger.info("Emotion classification model loaded successfully")
        
    except Exception as e:
        logger.error(f"Error loading models: {e}")
        logger.info("Falling back to simple sentiment analysis")
        sentiment_pipeline = None

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

class JournalEntry(BaseModel):
    title: str = Field(..., min_length=1, max_length=500)
    content: str = Field(..., min_length=10, max_length=10000)

class MoodPrediction(BaseModel):
    mood_score: float = Field(..., description="Mood score from -1 (very negative) to 1 (very positive)")
    mood_label: str = Field(..., description="Human-readable mood label")
    confidence: float = Field(..., description="Confidence score (0-1)")
    emotions: Dict[str, float] = Field(..., description="Breakdown of specific emotions")

class CategoryPrediction(BaseModel):
    category: str = Field(..., description="Primary category")
    confidence: float = Field(..., description="Confidence score (0-1)")
    subcategories: List[str] = Field(..., description="Related subcategories")

class InsightResponse(BaseModel):
    mood: MoodPrediction
    category: CategoryPrediction
    processing_time_ms: float
    timestamp: str

def preprocess_text(text: str) -> str:
    """Clean and preprocess text for analysis"""
    # Remove extra whitespace and normalize
    text = re.sub(r'\s+', ' ', text.strip())
    # Remove special characters but keep punctuation for sentiment
    text = re.sub(r'[^\w\s.,!?-]', '', text)
    return text

def predict_mood_with_bert(text: str) -> MoodPrediction:
    """Predict mood using BERT-based emotion classification"""
    try:
        # Truncate text if too long (BERT has token limits)
        processed_text = preprocess_text(text)
        if len(processed_text) > 512:  # BERT limit
            processed_text = processed_text[:512]
        
        # Get emotion predictions
        emotions = sentiment_pipeline(processed_text)
        
        # Map emotions to mood score
        emotion_scores = {
            'joy': 0.8, 'optimism': 0.6, 'love': 0.7, 'surprise': 0.2,
            'sadness': -0.6, 'anger': -0.8, 'fear': -0.5, 'disgust': -0.4
        }
        
        # Calculate weighted mood score
        mood_score = 0.0
        emotion_breakdown = {}
        
        # Handle both single prediction and list of predictions
        if isinstance(emotions, list):
            emotions_list = emotions
        else:
            emotions_list = [emotions]
        
        for emotion in emotions_list:
            label = emotion['label'].lower()
            score = emotion['score']
            emotion_breakdown[label] = round(score, 3)
            
            if label in emotion_scores:
                mood_score += emotion_scores[label] * score
        
        # Normalize mood score to [-1, 1]
        mood_score = max(-1.0, min(1.0, mood_score))
        
        # Determine mood label
        if mood_score >= 0.4:
            mood_label = "very positive"
        elif mood_score >= 0.1:
            mood_label = "positive"
        elif mood_score >= -0.1:
            mood_label = "neutral"
        elif mood_score >= -0.4:
            mood_label = "negative"
        else:
            mood_label = "very negative"
        
        # Get confidence (highest emotion score)
        confidence = max([e['score'] for e in emotions_list])
        
        return MoodPrediction(
            mood_score=round(mood_score, 3),
            mood_label=mood_label,
            confidence=round(confidence, 3),
            emotions=emotion_breakdown
        )
        
    except Exception as e:
        logger.error(f"Error in BERT mood prediction: {e}")
        raise

def predict_mood_fallback(text: str) -> MoodPrediction:
    """Fallback mood prediction using keyword analysis"""
    positive_words = [
        "amazing", "awesome", "excellent", "fantastic", "great", "happy", "joy", "love", 
        "wonderful", "good", "best", "perfect", "beautiful", "excited", "grateful",
        "accomplished", "successful", "proud", "confident", "optimistic", "blessed"
    ]
    
    negative_words = [
        "awful", "terrible", "bad", "sad", "angry", "frustrated", "disappointed", 
        "worried", "anxious", "stressed", "depressed", "hate", "worst", "horrible",
        "failed", "difficult", "struggle", "pain", "hurt", "lonely", "scared"
    ]
    
    processed_text = preprocess_text(text.lower())
    
    # Count positive and negative words
    positive_count = sum(1 for word in positive_words if word in processed_text)
    negative_count = sum(1 for word in negative_words if word in processed_text)
    
    # Calculate mood score
    total_words = len(processed_text.split())
    if total_words == 0:
        mood_score = 0.0
    else:
        # Normalize by text length and apply weights
        positive_weight = positive_count / max(total_words, 1) * 5
        negative_weight = negative_count / max(total_words, 1) * 5
        mood_score = positive_weight - negative_weight
        mood_score = max(-1.0, min(1.0, mood_score))
    
    # Determine mood label
    if mood_score >= 0.4:
        mood_label = "very positive"
    elif mood_score >= 0.1:
        mood_label = "positive"
    elif mood_score >= -0.1:
        mood_label = "neutral"
    elif mood_score >= -0.4:
        mood_label = "negative"
    else:
        mood_label = "very negative"
    
    # Calculate confidence
    confidence = min(0.7, (positive_count + negative_count) / max(total_words / 10, 1))
    confidence = max(0.3, confidence)
    
    # Create emotion breakdown
    emotions = {}
    if positive_count > negative_count:
        emotions["joy"] = 0.6
        emotions["optimism"] = 0.4
    elif negative_count > positive_count:
        emotions["sadness"] = 0.5
        emotions["fear"] = 0.3
    else:
        emotions["neutral"] = 0.8
    
    return MoodPrediction(
        mood_score=round(mood_score, 3),
        mood_label=mood_label,
        confidence=round(confidence, 3),
        emotions=emotions
    )

def predict_mood(text: str) -> MoodPrediction:
    """Predict mood using BERT if available, fallback to keyword analysis"""
    if sentiment_pipeline is not None:
        try:
            return predict_mood_with_bert(text)
        except Exception as e:
            logger.warning(f"BERT prediction failed, using fallback: {e}")
            return predict_mood_fallback(text)
    else:
        return predict_mood_fallback(text)

def predict_category(text: str) -> CategoryPrediction:
    """Predict category using keyword matching and semantic analysis"""
    try:
        processed_text = preprocess_text(text.lower())
        category_scores = {}
        
        # Score each category based on keyword matches
        for category, keywords in JOURNAL_CATEGORIES.items():
            score = 0.0
            matched_keywords = []
            
            for keyword in keywords:
                # Count keyword occurrences with different weights
                if keyword in processed_text:
                    # Exact match
                    count = processed_text.count(keyword)
                    score += count * 1.0
                    matched_keywords.append(keyword)
                    
                # Partial matches (less weight)
                for word in processed_text.split():
                    if keyword in word and len(word) > 3:
                        score += 0.3
            
            if score > 0:
                category_scores[category] = {
                    'score': score,
                    'keywords': matched_keywords
                }
        
        if not category_scores:
            # Default to daily_life if no matches
            return CategoryPrediction(
                category="daily_life",
                confidence=0.3,
                subcategories=[]
            )
        
        # Get top category
        top_category = max(category_scores.keys(), key=lambda k: category_scores[k]['score'])
        max_score = category_scores[top_category]['score']
        
        # Normalize confidence (simple heuristic)
        confidence = min(0.95, max_score / (len(processed_text.split()) * 0.1))
        confidence = max(0.1, confidence)
        
        # Get related subcategories (other categories with decent scores)
        subcategories = [
            cat for cat, data in category_scores.items() 
            if cat != top_category and data['score'] >= max_score * 0.3
        ]
        
        return CategoryPrediction(
            category=top_category,
            confidence=round(confidence, 3),
            subcategories=subcategories[:3]  # Limit to top 3
        )
        
    except Exception as e:
        logger.error(f"Error in category prediction: {e}")
        return CategoryPrediction(
            category="daily_life",
            confidence=0.3,
            subcategories=[]
        )

@app.get("/health")
async def health_check():
    """Health check endpoint"""
    return {
        "status": "healthy",
        "service": "ai-insights-service",
        "timestamp": datetime.utcnow().isoformat(),
        "models_loaded": sentiment_pipeline is not None,
        "bert_available": sentiment_pipeline is not None
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

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=80)
