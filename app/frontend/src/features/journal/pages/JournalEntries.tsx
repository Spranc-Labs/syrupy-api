import React, { useState, useEffect, useMemo } from 'react';
import { Link } from 'react-router-dom';
import { useAuth } from '../../auth/providers/AuthProvider';

interface JournalEntry {
  id: number;
  title: string;
  content: string;
  tags?: Tag[];
  created_at: string;
  updated_at: string;
  word_count?: number;
  search_rank?: number;
  // AI Insights fields
  ai_analyzed?: boolean;
  ai_analyzed_at?: string;
  ai_category?: string;
  ai_category_display?: string;
  ai_emotions?: Record<string, number>;
  ai_mood_emoji?: string;
  ai_mood_label?: string;
  ai_mood_score?: string;
  ai_processing_time_ms?: string;
  dominant_emotion?: string;
  dominant_emotion_emoji?: string;
}

interface Tag {
  id: number;
  name: string;
  color: string;
}

export const JournalEntries: React.FC = () => {
  const [allEntries, setAllEntries] = useState<JournalEntry[]>([]);
  const [searchResults, setSearchResults] = useState<JournalEntry[]>([]);
  const [availableTags, setAvailableTags] = useState<Tag[]>([]);
  const [isLoading, setIsLoading] = useState(true);
  const [isSearching, setIsSearching] = useState(false);
  const [error, setError] = useState('');
  const [searchQuery, setSearchQuery] = useState('');
  const [selectedTag, setSelectedTag] = useState<string>('');
  const { user } = useAuth();

  const API_BASE_URL = 'http://localhost:3000/api';

  // Get the current entries to display (either all entries or search results)
  const displayEntries = useMemo(() => {
    let entries = searchQuery.trim() ? searchResults : allEntries;
    
    // Apply tag filtering on frontend
    if (selectedTag) {
      entries = entries.filter((entry: JournalEntry) =>
        entry.tags?.some(tag => tag.name === selectedTag)
      );
    }
    
    return entries;
  }, [allEntries, searchResults, searchQuery, selectedTag]);

  useEffect(() => {
    fetchTags();
    fetchAllEntries();
  }, []);

  useEffect(() => {
    // Only perform search if there's a query, otherwise show all entries
    if (searchQuery.trim()) {
      const timeoutId = setTimeout(() => {
        performSearch();
      }, 300);
      return () => clearTimeout(timeoutId);
    } else {
      // Clear search results immediately when query is empty
      setSearchResults([]);
      setIsSearching(false);
    }
  }, [searchQuery]);

  const getAuthHeaders = () => ({
    'Content-Type': 'application/json',
  });

  const fetchAllEntries = async () => {
    setIsLoading(true);
    try {
      const response = await fetch(`${API_BASE_URL}/journal_entries`, {
        credentials: 'include',
        headers: getAuthHeaders(),
      });
      
      if (response.ok) {
        const data = await response.json();
        const entries = data.data?.items || data;
        setAllEntries(entries);
      } else {
        setError('Failed to fetch entries');
      }
    } catch (error) {
      setError('Error fetching entries');
    } finally {
      setIsLoading(false);
    }
  };

  const performSearch = async () => {
    if (!searchQuery.trim()) return;
    
    setIsSearching(true);
    try {
      const params = new URLSearchParams();
      params.append('q', searchQuery.trim());

      const response = await fetch(`${API_BASE_URL}/journal_entries?${params}`, {
        credentials: 'include',
        headers: getAuthHeaders(),
      });
      
      if (response.ok) {
        const data = await response.json();
        const entries = data.data?.items || data;
        setSearchResults(entries);
      } else {
        setError('Failed to search entries');
      }
    } catch (error) {
      setError('Error searching entries');
    } finally {
      setIsSearching(false);
    }
  };

  const fetchTags = async () => {
    try {
      const response = await fetch(`${API_BASE_URL}/tags`, {
        credentials: 'include',
        headers: getAuthHeaders(),
      });
      if (response.ok) {
        const data = await response.json();
        setAvailableTags(data.data || data);
      }
    } catch (error) {
      console.error('Error fetching tags:', error);
    }
  };

  const handleDelete = async (id: number) => {
    if (!confirm('Are you sure you want to delete this entry?')) return;

    try {
      const response = await fetch(`${API_BASE_URL}/journal_entries/${id}`, {
        method: 'DELETE',
        credentials: 'include',
        headers: getAuthHeaders(),
      });

      if (response.ok) {
        // Remove from both allEntries and searchResults
        setAllEntries(prev => prev.filter(entry => entry.id !== id));
        setSearchResults(prev => prev.filter(entry => entry.id !== id));
      } else {
        setError('Failed to delete entry');
      }
    } catch (error) {
      setError('Error deleting entry');
    }
  };

  const handleClearSearch = () => {
    setSearchQuery('');
    setSelectedTag('');
    // No need to refetch - displayEntries will automatically switch to allEntries
  };

  const truncateContent = (content: string, maxLength: number = 200) => {
    if (content.length <= maxLength) return content;
    return content.substring(0, maxLength) + '...';
  };

  const highlightSearchTerms = (text: string, query: string) => {
    if (!query.trim()) return text;
    
    const terms = query.toLowerCase().split(/\s+/).filter(term => term.length > 0);
    let highlightedText = text;
    
    terms.forEach(term => {
      const regex = new RegExp(`(${term})`, 'gi');
      highlightedText = highlightedText.replace(regex, '<mark class="bg-yellow-200 dark:bg-yellow-800">$1</mark>');
    });
    
    return highlightedText;
  };

  const formatDate = (dateString: string) => {
    const date = new Date(dateString);
    const now = new Date();
    const diffTime = Math.abs(now.getTime() - date.getTime());
    const diffDays = Math.ceil(diffTime / (1000 * 60 * 60 * 24));

    if (diffDays === 1) return 'Today';
    if (diffDays === 2) return 'Yesterday';
    if (diffDays <= 7) return `${diffDays - 1} days ago`;
    
    return date.toLocaleDateString('en-US', {
      year: 'numeric',
      month: 'short',
      day: 'numeric'
    });
  };

  const getSearchResultsText = () => {
    const count = displayEntries.length;
    const hasSearch = searchQuery.trim() || selectedTag;
    
    if (!hasSearch) {
      return `${count} ${count === 1 ? 'entry' : 'entries'}`;
    }
    
    let text = `${count} ${count === 1 ? 'result' : 'results'}`;
    if (searchQuery.trim()) {
      text += ` for "${searchQuery}"`;
    }
    if (selectedTag) {
      text += ` tagged with "${selectedTag}"`;
    }
    return text;
  };

  if (isLoading) return <div className="flex justify-center p-8 text-gray-600 dark:text-gray-400">Loading...</div>;

  return (
    <div className="max-w-6xl mx-auto p-6">
      {/* Header */}
      <div className="flex flex-col sm:flex-row sm:items-center sm:justify-between mb-8">
        <div>
          <h1 className="text-3xl font-bold text-gray-900 dark:text-white mb-2">Journal Entries</h1>
          <p className="text-gray-600 dark:text-gray-400">
            {getSearchResultsText()}
          </p>
        </div>
        <Link
          to="/journal/new"
          className="mt-4 sm:mt-0 bg-indigo-600 hover:bg-indigo-700 text-white px-6 py-3 rounded-md font-medium inline-flex items-center"
        >
          <svg className="w-5 h-5 mr-2" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 4v16m8-8H4" />
          </svg>
          New Entry
        </Link>
      </div>

      {error && (
        <div className="bg-red-50 dark:bg-red-900/20 border border-red-200 dark:border-red-800 text-red-600 dark:text-red-400 px-4 py-3 rounded mb-6">
          {error}
        </div>
      )}

      {/* Search and Filters */}
      <div className="flex flex-col sm:flex-row gap-4 mb-6">
        <div className="flex-1">
          <div className="relative">
            <svg
              className="absolute left-3 top-1/2 transform -translate-y-1/2 text-gray-400 w-5 h-5"
              fill="none"
              stroke="currentColor"
              viewBox="0 0 24 24"
            >
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M21 21l-6-6m2-5a7 7 0 11-14 0 7 7 0 0114 0z" />
            </svg>
            <input
              type="text"
              placeholder="Search entries..."
              value={searchQuery}
              onChange={(e) => setSearchQuery(e.target.value)}
              className="w-full pl-10 pr-4 py-2 border border-gray-300 dark:border-gray-600 rounded-md focus:outline-none focus:ring-indigo-500 focus:border-indigo-500 dark:bg-gray-700 dark:text-white"
            />
            {isSearching && (
              <div className="absolute right-3 top-1/2 transform -translate-y-1/2">
                <svg className="animate-spin h-4 w-4 text-gray-400" fill="none" viewBox="0 0 24 24">
                  <circle className="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" strokeWidth="4"></circle>
                  <path className="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"></path>
                </svg>
              </div>
            )}
          </div>
        </div>
        <div className="sm:w-48">
          <select
            value={selectedTag}
            onChange={(e) => setSelectedTag(e.target.value)}
            className="w-full px-3 py-2 border border-gray-300 dark:border-gray-600 rounded-md focus:outline-none focus:ring-indigo-500 focus:border-indigo-500 dark:bg-gray-700 dark:text-white"
          >
            <option value="">All tags</option>
            {availableTags.map((tag) => (
              <option key={tag.id} value={tag.name}>
                {tag.name}
              </option>
            ))}
          </select>
        </div>
        {(searchQuery || selectedTag) && (
          <button
            onClick={handleClearSearch}
            className="px-4 py-2 text-gray-600 dark:text-gray-400 border border-gray-300 dark:border-gray-600 rounded-md hover:bg-gray-50 dark:hover:bg-gray-700"
          >
            Clear
          </button>
        )}
      </div>

      {/* Entries Grid */}
      <div className="space-y-6">
        {displayEntries.length === 0 ? (
          <div className="text-center py-12">
            {allEntries.length === 0 ? (
              <div>
                <svg className="mx-auto h-12 w-12 text-gray-400 dark:text-gray-500 mb-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 6.253v13m0-13C10.832 5.477 9.246 5 7.5 5S4.168 5.477 3 6.253v13C4.168 18.477 5.754 18 7.5 18s3.332.477 4.5 1.253m0-13C13.168 5.477 14.754 5 16.5 5c1.747 0 3.332.477 4.5 1.253v13C19.832 18.477 18.247 18 16.5 18c-1.746 0-3.332.477-4.5 1.253" />
                </svg>
                <h3 className="text-lg font-medium text-gray-900 dark:text-white mb-2">No journal entries yet</h3>
                <p className="text-gray-500 dark:text-gray-400 mb-4">Start your journaling journey by creating your first entry.</p>
                <Link
                  to="/journal/new"
                  className="bg-indigo-600 hover:bg-indigo-700 text-white px-4 py-2 rounded-md font-medium"
                >
                  Create First Entry
                </Link>
              </div>
            ) : (
              <div>
                <svg className="mx-auto h-12 w-12 text-gray-400 dark:text-gray-500 mb-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M21 21l-6-6m2-5a7 7 0 11-14 0 7 7 0 0114 0z" />
                </svg>
                <h3 className="text-lg font-medium text-gray-900 dark:text-white mb-2">No results found</h3>
                <p className="text-gray-500 dark:text-gray-400">Try adjusting your search terms or filters.</p>
              </div>
            )}
          </div>
        ) : (
          displayEntries.map((entry) => (
            <article key={entry.id} className="bg-white dark:bg-gray-800 border border-gray-200 dark:border-gray-700 rounded-lg p-6 shadow-sm hover:shadow-md transition-shadow">
              <div className="flex justify-between items-start mb-4">
                <div className="flex-1">
                  <h2 className="text-xl font-semibold text-gray-900 dark:text-white mb-2">
                    <span dangerouslySetInnerHTML={{ __html: highlightSearchTerms(entry.title, searchQuery) }} />
                  </h2>
                  <div className="flex items-center flex-wrap gap-x-4 gap-y-2 text-sm text-gray-500 dark:text-gray-400">
                    <span>{formatDate(entry.created_at)}</span>
                    {entry.word_count && (
                      <span>{entry.word_count} words</span>
                    )}
                    {entry.search_rank && searchQuery && (
                      <span className="bg-indigo-100 dark:bg-indigo-900 text-indigo-800 dark:text-indigo-200 px-2 py-1 rounded text-xs">
                        Relevance: {Math.round(entry.search_rank)}
                      </span>
                    )}
                    {/* Mood */}
                    {entry.ai_mood_emoji && entry.ai_mood_label && (
                      <div className="flex items-center space-x-1">
                        <span className="text-lg">{entry.ai_mood_emoji}</span>
                        <span className="text-sm text-gray-600 dark:text-gray-400 capitalize">
                          {entry.ai_mood_label}
                        </span>
                        {entry.ai_mood_score && (
                          <span className="text-xs text-gray-500 dark:text-gray-400">
                            ({parseFloat(entry.ai_mood_score).toFixed(1)})
                          </span>
                        )}
                      </div>
                    )}
                    {/* Category */}
                    {entry.ai_category_display && (
                      <div className="flex items-center space-x-1">
                        <span className="text-xs bg-blue-100 dark:bg-blue-900 text-blue-800 dark:text-blue-200 px-2 py-1 rounded-full">
                          {entry.ai_category_display}
                        </span>
                      </div>
                    )}
                  </div>
                </div>
                <div className="flex items-center space-x-2 ml-4">
                  <Link
                    to={`/journal/${entry.id}/edit`}
                    className="text-indigo-600 dark:text-indigo-400 hover:text-indigo-900 dark:hover:text-indigo-300 text-sm font-medium"
                  >
                    Edit
                  </Link>
                  <button
                    onClick={() => handleDelete(entry.id)}
                    className="text-red-600 dark:text-red-400 hover:text-red-900 dark:hover:text-red-300 text-sm font-medium"
                  >
                    Delete
                  </button>
                </div>
              </div>

              <div className="prose prose-gray dark:prose-invert max-w-none mb-4">
                <p 
                  className="text-gray-700 dark:text-gray-300 leading-relaxed"
                  dangerouslySetInnerHTML={{ 
                    __html: highlightSearchTerms(truncateContent(entry.content), searchQuery) 
                  }}
                />
              </div>

              {/* Tags and Emotions */}
              {(entry.tags && entry.tags.length > 0 || entry.ai_emotions && Object.keys(entry.ai_emotions).length > 0) && (
                <div className="flex flex-wrap gap-2 mt-4">
                  {entry.tags?.map((tag) => (
                    <span
                      key={tag.id}
                      className={`inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium ${
                        selectedTag === tag.name 
                          ? 'bg-indigo-200 dark:bg-indigo-800 text-indigo-900 dark:text-indigo-100'
                          : 'bg-indigo-100 dark:bg-indigo-900 text-indigo-800 dark:text-indigo-200'
                      }`}
                    >
                      <span dangerouslySetInnerHTML={{ __html: highlightSearchTerms(tag.name, searchQuery) }} />
                    </span>
                  ))}
                  {entry.ai_emotions && Object.entries(entry.ai_emotions)
                    .sort(([,a], [,b]) => b - a)
                    .slice(0, 5)
                    .map(([emotion, score]) => (
                      <span
                        key={emotion}
                        className="text-xs bg-gray-100 dark:bg-gray-700 text-gray-700 dark:text-gray-300 px-2 py-1 rounded-full"
                      >
                        {emotion} {(score * 100).toFixed(0)}%
                      </span>
                    ))
                  }
                </div>
              )}

              {/* AI Insights */}
              {entry.ai_analyzed && (
                <div className="mt-4 pt-4 border-t border-gray-200 dark:border-gray-700">
                  <div className="flex items-center justify-between">
                    <h4 className="text-sm font-medium text-gray-900 dark:text-white">AI Insights</h4>
                    <div className="flex items-center gap-3">
                      {/* Dominant Emotion */}
                      {entry.dominant_emotion_emoji && entry.dominant_emotion && (
                        <div className="flex items-center space-x-1">
                          <span className="text-sm">{entry.dominant_emotion_emoji}</span>
                          <span className="text-xs text-gray-600 dark:text-gray-400 capitalize">
                            {entry.dominant_emotion}
                          </span>
                        </div>
                      )}
                      {entry.ai_processing_time_ms && (
                        <span className="text-xs text-gray-500 dark:text-gray-400">
                          {parseFloat(entry.ai_processing_time_ms).toFixed(0)}ms
                        </span>
                      )}
                    </div>
                  </div>
                </div>
              )}
            </article>
          ))
        )}
      </div>
    </div>
  );
}; 