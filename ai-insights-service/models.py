from pydantic import BaseModel, Field
from typing import Dict, List

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