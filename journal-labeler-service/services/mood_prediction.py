import logging
from transformers import pipeline
from typing import Optional
from models import MoodPrediction
from utils import preprocess_text

logger = logging.getLogger(__name__)

# Global variable for the sentiment pipeline (same as original)
sentiment_pipeline: Optional[pipeline] = None

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

def is_model_loaded() -> bool:
    """Check if the sentiment pipeline is loaded"""
    return sentiment_pipeline is not None 