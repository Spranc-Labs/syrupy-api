import React, { useState, useEffect } from 'react';
import { useNavigate, useParams } from 'react-router-dom';
import { useAuth } from '../../auth/providers/AuthProvider';

interface JournalEntry {
  id: number;
  title: string;
  content: string;
  tags?: Tag[];
  created_at: string;
  updated_at: string;
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

export const JournalEditor: React.FC = () => {
  const navigate = useNavigate();
  const { id } = useParams();
  const { user } = useAuth();
  const isEditing = Boolean(id);

  const [title, setTitle] = useState('');
  const [content, setContent] = useState('');
  const [selectedTags, setSelectedTags] = useState<Tag[]>([]);
  const [availableTags, setAvailableTags] = useState<Tag[]>([]);
  const [newTagName, setNewTagName] = useState('');
  const [isLoading, setIsLoading] = useState(false);
  const [isSaving, setIsSaving] = useState(false);
  const [error, setError] = useState('');
  const [showTagInput, setShowTagInput] = useState(false);

  const API_BASE_URL = 'http://localhost:3000/api';

  useEffect(() => {
    fetchTags();
    if (isEditing) {
      fetchEntry();
    }
  }, [id]);

  const getAuthHeaders = () => ({
    'Content-Type': 'application/json',
  });

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

  const fetchEntry = async () => {
    if (!id) return;
    
    setIsLoading(true);
    try {
      const response = await fetch(`${API_BASE_URL}/journal_entries/${id}`, {
        credentials: 'include',
        headers: getAuthHeaders(),
      });
      if (response.ok) {
        const entry = await response.json();
        console.log(entry, "++++ENTRU");
        setTitle(entry.title);
        setContent(entry.content);
        setSelectedTags(entry.tags || []);
      } else {
        setError('Failed to fetch entry');
      }
    } catch (error) {
      setError('Error fetching entry');
    } finally {
      setIsLoading(false);
    }
  };

  const handleSave = async () => {
    if (!title.trim() || !content.trim()) {
      setError('Title and content are required');
      return;
    }

    setIsSaving(true);
    setError('');

    try {
      const url = isEditing 
        ? `${API_BASE_URL}/journal_entries/${id}`
        : `${API_BASE_URL}/journal_entries`;
      
      const method = isEditing ? 'PUT' : 'POST';
      
      const payload = {
        title: title.trim(),
        content: content.trim(),
        tag_ids: selectedTags.map(tag => tag.id)
      };

      const response = await fetch(url, {
        method,
        credentials: 'include',
        headers: getAuthHeaders(),
        body: JSON.stringify(payload),
      });

      if (response.ok) {
        navigate('/journal');
      } else {
        const errorText = await response.text();
        try {
          const errorData = JSON.parse(errorText);
          setError(errorData.message || JSON.stringify(errorData.errors) || 'Failed to save entry');
        } catch {
          setError(`Failed to save entry (${response.status}): ${errorText}`);
        }
      }
    } catch (error) {
      setError('Error saving entry: ' + (error instanceof Error ? error.message : String(error)));
    } finally {
      setIsSaving(false);
    }
  };

  const createTag = async () => {
    if (!newTagName.trim()) return;

    try {
      const response = await fetch(`${API_BASE_URL}/tags`, {
        method: 'POST',
        credentials: 'include',
        headers: getAuthHeaders(),
        body: JSON.stringify({
          name: newTagName.trim(),
          color: '#6366f1' // Default indigo color
        }),
      });

      if (response.ok) {
        const data = await response.json();
        const newTag = data.data;
        setAvailableTags([...availableTags, newTag]);
        setSelectedTags([...selectedTags, newTag]);
        setNewTagName('');
        setShowTagInput(false);
      }
    } catch (error) {
      console.error('Error creating tag:', error);
    }
  };

  const toggleTag = (tag: Tag) => {
    const isSelected = selectedTags.some(t => t.id === tag.id);
    if (isSelected) {
      setSelectedTags(selectedTags.filter(t => t.id !== tag.id));
    } else {
      setSelectedTags([...selectedTags, tag]);
    }
  };

  const formatText = (format: string) => {
    const textarea = document.getElementById('content-editor') as HTMLTextAreaElement;
    if (!textarea) return;

    const start = textarea.selectionStart;
    const end = textarea.selectionEnd;
    const selectedText = content.substring(start, end);

    let formattedText = '';
    let newCursorPos = start;

    switch (format) {
      case 'bold':
        formattedText = `**${selectedText}**`;
        newCursorPos = selectedText ? end + 4 : start + 2;
        break;
      case 'italic':
        formattedText = `*${selectedText}*`;
        newCursorPos = selectedText ? end + 2 : start + 1;
        break;
      case 'bullet': {
        const lines = selectedText.split('\n');
        formattedText = lines.map(line => line.trim() ? `• ${line}` : line).join('\n');
        newCursorPos = end + lines.filter(line => line.trim()).length * 2;
        break;
      }
      default:
        return;
    }

    const newContent = content.substring(0, start) + formattedText + content.substring(end);
    setContent(newContent);

    // Set cursor position after state update
    setTimeout(() => {
      textarea.focus();
      textarea.setSelectionRange(newCursorPos, newCursorPos);
    }, 0);
  };

  if (isLoading) {
    return <div className="flex justify-center p-8 text-gray-600 dark:text-gray-400">Loading...</div>;
  }

  return (
    <div className="max-w-4xl mx-auto p-6">
      {/* Header */}
      <div className="flex items-center justify-between mb-6">
        <div className="flex items-center space-x-4">
          <button
            onClick={() => navigate('/journal')}
            className="flex items-center text-gray-600 dark:text-gray-400 hover:text-gray-900 dark:hover:text-white"
          >
            <svg className="w-5 h-5 mr-2" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M15 19l-7-7 7-7" />
            </svg>
            Back to Journal
          </button>
          <h1 className="text-2xl font-bold text-gray-900 dark:text-white">
            {isEditing ? 'Edit Entry' : 'New Entry'}
          </h1>
        </div>
        <button
          onClick={handleSave}
          disabled={isSaving || !title.trim() || !content.trim()}
          className="bg-indigo-600 hover:bg-indigo-700 disabled:bg-gray-400 text-white px-6 py-2 rounded-md font-medium transition-colors"
        >
          {isSaving ? 'Saving...' : 'Save Entry'}
        </button>
      </div>

      {error && (
        <div className="bg-red-50 dark:bg-red-900/20 border border-red-200 dark:border-red-800 text-red-600 dark:text-red-400 px-4 py-3 rounded mb-6">
          {error}
        </div>
      )}

      <div className="space-y-6">
        {/* Title */}
        <div>
          <input
            type="text"
            placeholder="Entry title..."
            value={title}
            onChange={(e) => setTitle(e.target.value)}
            className="w-full text-3xl font-bold bg-transparent border-none outline-none text-gray-900 dark:text-white placeholder-gray-500 dark:placeholder-gray-400"
          />
        </div>

        {/* Formatting Toolbar */}
        <div className="flex items-center space-x-2 py-2 border-b border-gray-200 dark:border-gray-700">
          <button
            onClick={() => formatText('bold')}
            className="p-2 text-gray-600 dark:text-gray-400 hover:text-gray-900 dark:hover:text-white hover:bg-gray-100 dark:hover:bg-gray-700 rounded"
            title="Bold"
          >
            <svg className="w-5 h-5" fill="currentColor" viewBox="0 0 20 20">
              <path fillRule="evenodd" d="M5 4a1 1 0 011-1h3a3 3 0 110 6H6v2h3a3 3 0 110 6H6a1 1 0 01-1-1V4zm2 1v4h2a1 1 0 100-2H7zm0 6v4h3a1 1 0 100-2H7z" clipRule="evenodd" />
            </svg>
          </button>
          <button
            onClick={() => formatText('italic')}
            className="p-2 text-gray-600 dark:text-gray-400 hover:text-gray-900 dark:hover:text-white hover:bg-gray-100 dark:hover:bg-gray-700 rounded"
            title="Italic"
          >
            <svg className="w-5 h-5" fill="currentColor" viewBox="0 0 20 20">
              <path fillRule="evenodd" d="M8 1a1 1 0 011 1v1h2a1 1 0 110 2h-.5l-1 8H11a1 1 0 110 2H9a1 1 0 01-1-1v-1H6a1 1 0 110-2h.5l1-8H7a1 1 0 110-2h1V2a1 1 0 011-1z" clipRule="evenodd" />
            </svg>
          </button>
          <button
            onClick={() => formatText('bullet')}
            className="p-2 text-gray-600 dark:text-gray-400 hover:text-gray-900 dark:hover:text-white hover:bg-gray-100 dark:hover:bg-gray-700 rounded"
            title="Bullet List"
          >
            <svg className="w-5 h-5" fill="currentColor" viewBox="0 0 20 20">
              <path fillRule="evenodd" d="M3 4a1 1 0 011-1h12a1 1 0 110 2H4a1 1 0 01-1-1zm0 4a1 1 0 011-1h12a1 1 0 110 2H4a1 1 0 01-1-1zm0 4a1 1 0 011-1h12a1 1 0 110 2H4a1 1 0 01-1-1z" clipRule="evenodd" />
            </svg>
          </button>
        </div>

        {/* Content Editor */}
        <div>
          <textarea
            id="content-editor"
            placeholder="Start writing your thoughts..."
            value={content}
            onChange={(e) => setContent(e.target.value)}
            className="w-full min-h-96 bg-transparent border-none outline-none text-gray-900 dark:text-white placeholder-gray-500 dark:placeholder-gray-400 text-lg leading-relaxed resize-none"
            style={{ fontFamily: 'Georgia, serif' }}
          />
        </div>

        {/* Tags Section */}
        <div className="border-t border-gray-200 dark:border-gray-700 pt-6">
          <div className="flex items-center justify-between mb-4">
            <h3 className="text-lg font-medium text-gray-900 dark:text-white">Tags</h3>
            <button
              onClick={() => setShowTagInput(!showTagInput)}
              className="text-indigo-600 dark:text-indigo-400 hover:text-indigo-700 dark:hover:text-indigo-300 text-sm font-medium"
            >
              + Add Tag
            </button>
          </div>

          {/* Selected Tags */}
          {selectedTags.length > 0 && (
            <div className="flex flex-wrap gap-2 mb-4">
              {selectedTags.map((tag) => (
                <span
                  key={tag.id}
                  className="inline-flex items-center px-3 py-1 rounded-full text-sm font-medium bg-indigo-100 dark:bg-indigo-900 text-indigo-800 dark:text-indigo-200"
                >
                  {tag.name}
                  <button
                    onClick={() => toggleTag(tag)}
                    className="ml-2 text-indigo-600 dark:text-indigo-400 hover:text-indigo-800 dark:hover:text-indigo-200"
                  >
                    ×
                  </button>
                </span>
              ))}
            </div>
          )}

          {/* New Tag Input */}
          {showTagInput && (
            <div className="flex items-center space-x-2 mb-4">
              <input
                type="text"
                placeholder="Tag name"
                value={newTagName}
                onChange={(e) => setNewTagName(e.target.value)}
                className="px-3 py-2 border border-gray-300 dark:border-gray-600 rounded-md focus:outline-none focus:ring-indigo-500 focus:border-indigo-500 dark:bg-gray-700 dark:text-white"
                onKeyPress={(e) => e.key === 'Enter' && createTag()}
              />
              <button
                onClick={createTag}
                className="bg-indigo-600 hover:bg-indigo-700 text-white px-4 py-2 rounded-md text-sm"
              >
                Create
              </button>
              <button
                onClick={() => setShowTagInput(false)}
                className="text-gray-500 dark:text-gray-400 hover:text-gray-700 dark:hover:text-gray-300"
              >
                Cancel
              </button>
            </div>
          )}

          {/* Available Tags */}
          {availableTags.length > 0 && (
            <div>
              <p className="text-sm text-gray-600 dark:text-gray-400 mb-2">Available tags:</p>
              <div className="flex flex-wrap gap-2">
                {availableTags
                  .filter(tag => !selectedTags.some(t => t.id === tag.id))
                  .map((tag) => (
                    <button
                      key={tag.id}
                      onClick={() => toggleTag(tag)}
                      className="inline-flex items-center px-3 py-1 rounded-full text-sm font-medium border border-gray-300 dark:border-gray-600 text-gray-700 dark:text-gray-300 hover:bg-gray-50 dark:hover:bg-gray-700"
                    >
                      {tag.name}
                    </button>
                  ))}
              </div>
            </div>
          )}
        </div>
      </div>
    </div>
  );
}; 