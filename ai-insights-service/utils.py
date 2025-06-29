import re

def preprocess_text(text: str) -> str:
    """Clean and preprocess text for analysis"""
    # Remove extra whitespace and normalize
    text = re.sub(r'\s+', ' ', text.strip())
    # Remove special characters but keep punctuation for sentiment
    text = re.sub(r'[^\w\s.,!?-]', '', text)
    return text 