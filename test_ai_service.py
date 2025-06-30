#!/usr/bin/env python3
"""
Test script for the Journal Labeler Service
"""

import requests
import json
import time

BASE_URL = "http://localhost:8001"

def test_health():
    """Test the health endpoint"""
    print("Testing health endpoint...")
    try:
        response = requests.get(f"{BASE_URL}/health", timeout=10)
        print(f"Health Status: {response.status_code}")
        print(f"Response: {response.json()}")
        return response.status_code == 200
    except Exception as e:
        print(f"Health check failed: {e}")
        return False

def test_categories():
    """Test the categories endpoint"""
    print("\nTesting categories endpoint...")
    try:
        response = requests.get(f"{BASE_URL}/categories", timeout=10)
        print(f"Categories Status: {response.status_code}")
        data = response.json()
        print(f"Available categories: {data.get('categories', [])}")
        return response.status_code == 200
    except Exception as e:
        print(f"Categories test failed: {e}")
        return False

def test_analysis():
    """Test the full analysis endpoint"""
    print("\nTesting analysis endpoint...")
    
    test_entry = {
        "title": "Amazing Day at Work",
        "content": "Today was absolutely fantastic! I completed my project ahead of schedule and received great feedback from my manager. I feel so accomplished and motivated to take on new challenges. The team collaboration was excellent, and I learned a lot about leadership. I'm grateful for this opportunity to grow professionally."
    }
    
    try:
        response = requests.post(
            f"{BASE_URL}/analyze",
            json=test_entry,
            headers={"Content-Type": "application/json"},
            timeout=30
        )
        
        print(f"Analysis Status: {response.status_code}")
        
        if response.status_code == 200:
            data = response.json()
            print("\nAnalysis Results:")
            print(f"Mood Score: {data['mood']['mood_score']}")
            print(f"Mood Label: {data['mood']['mood_label']}")
            print(f"Category: {data['category']['category']}")
            print(f"Processing Time: {data['processing_time_ms']}ms")
            print(f"Emotions: {data['mood']['emotions']}")
            return True
        else:
            print(f"Error: {response.text}")
            return False
            
    except Exception as e:
        print(f"Analysis test failed: {e}")
        return False

def main():
    """Run all tests"""
    print("=== Journal Labeler Service Test ===\n")
    
    # Wait a bit for service to start
    print("Waiting for service to start...")
    time.sleep(5)
    
    tests = [
        ("Health Check", test_health),
        ("Categories", test_categories),
        ("Full Analysis", test_analysis)
    ]
    
    results = []
    for test_name, test_func in tests:
        print(f"\n{'='*50}")
        success = test_func()
        results.append((test_name, success))
        print(f"{'='*50}")
    
    print(f"\n{'='*50}")
    print("TEST SUMMARY:")
    print(f"{'='*50}")
    
    for test_name, success in results:
        status = "✅ PASS" if success else "❌ FAIL"
        print(f"{test_name}: {status}")
    
    all_passed = all(success for _, success in results)
    print(f"\nOverall: {'✅ ALL TESTS PASSED' if all_passed else '❌ SOME TESTS FAILED'}")
    
    return 0 if all_passed else 1

if __name__ == "__main__":
    exit(main()) 