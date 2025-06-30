import logging
from models import CategoryPrediction
from utils import preprocess_text
from config import JOURNAL_CATEGORIES

logger = logging.getLogger(__name__)

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