"""
AI Insights Service - Modular Version

Entry point for the modular AI insights service.
"""

import logging
from api import app

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8001) 