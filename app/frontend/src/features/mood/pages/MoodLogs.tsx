import React, { useState, useEffect } from 'react';
import { useAuth } from '../../auth/providers/AuthProvider';

interface MoodLog {
  id: number;
  rating: number;
  notes: string;
  logged_at: string;
  created_at: string;
}

export const MoodLogs: React.FC = () => {
  const [moodLogs, setMoodLogs] = useState<MoodLog[]>([]);
  const [isLoading, setIsLoading] = useState(true);
  const [isFormOpen, setIsFormOpen] = useState(false);
  const [editingMood, setEditingMood] = useState<MoodLog | null>(null);
  const [formData, setFormData] = useState({
    rating: 5,
    notes: '',
    logged_at: new Date().toISOString().split('T')[0]
  });
  const [error, setError] = useState('');

  const API_BASE_URL = 'http://localhost:3000/api';

  useEffect(() => {
    fetchMoodLogs();
  }, []);

  const getAuthHeaders = () => ({
    'Content-Type': 'application/json',
  });

  const fetchMoodLogs = async () => {
    try {
      const response = await fetch(`${API_BASE_URL}/mood_logs`, {
        credentials: 'include',
        headers: getAuthHeaders(),
      });
      if (response.ok) {
        const data = await response.json();
        // Handle paginated response format
        setMoodLogs(data.data || data);
      } else {
        setError('Failed to fetch mood logs');
      }
    } catch (error) {
      setError('Error fetching mood logs');
    } finally {
      setIsLoading(false);
    }
  };

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setError('');

    try {
      const url = editingMood 
        ? `${API_BASE_URL}/mood_logs/${editingMood.id}`
        : `${API_BASE_URL}/mood_logs`;
      
      const method = editingMood ? 'PUT' : 'POST';
      
      const response = await fetch(url, {
        method,
        credentials: 'include',
        headers: getAuthHeaders(),
        body: JSON.stringify({ mood_log: formData }),
      });

      if (response.ok) {
        await fetchMoodLogs();
        setIsFormOpen(false);
        setEditingMood(null);
        setFormData({
          rating: 5,
          notes: '',
          logged_at: new Date().toISOString().split('T')[0]
        });
      } else {
        setError('Failed to save mood log');
      }
    } catch (error) {
      setError('Error saving mood log');
    }
  };

  const handleEdit = (mood: MoodLog) => {
    setEditingMood(mood);
    setFormData({
      rating: mood.rating,
      notes: mood.notes,
      logged_at: mood.logged_at ? mood.logged_at.split('T')[0] : new Date().toISOString().split('T')[0]
    });
    setIsFormOpen(true);
  };

  const handleDelete = async (id: number) => {
    if (!confirm('Are you sure you want to delete this mood log?')) return;

    try {
      const response = await fetch(`${API_BASE_URL}/mood_logs/${id}`, {
        method: 'DELETE',
        credentials: 'include',
        headers: getAuthHeaders(),
      });

      if (response.ok) {
        await fetchMoodLogs();
      } else {
        setError('Failed to delete mood log');
      }
    } catch (error) {
      setError('Error deleting mood log');
    }
  };

  const openCreateForm = () => {
    setEditingMood(null);
    setFormData({
      rating: 5,
      notes: '',
      logged_at: new Date().toISOString().split('T')[0]
    });
    setIsFormOpen(true);
  };

  const getMoodEmoji = (value: number) => {
    if (value <= 2) return '😢';
    if (value <= 4) return '😕';
    if (value <= 6) return '😐';
    if (value <= 8) return '😊';
    return '😄';
  };

  const getMoodColor = (value: number) => {
    if (value <= 2) return 'text-red-700 bg-red-100';
    if (value <= 4) return 'text-orange-700 bg-orange-100';
    if (value <= 6) return 'text-yellow-700 bg-yellow-100';
    if (value <= 8) return 'text-green-700 bg-green-100';
    return 'text-blue-700 bg-blue-100';
  };

  if (isLoading) return <div className="flex justify-center p-8 text-gray-600 dark:text-gray-400">Loading...</div>;

  return (
    <div className="max-w-4xl mx-auto p-6">
      <div className="flex justify-between items-center mb-6">
        <h1 className="text-3xl font-bold text-gray-900 dark:text-white">Mood Logs</h1>
        <button
          onClick={openCreateForm}
          className="bg-indigo-600 hover:bg-indigo-700 text-white px-4 py-2 rounded-md"
        >
          Log Mood
        </button>
      </div>

      {error && (
        <div className="bg-red-50 border border-red-200 text-red-600 px-4 py-3 rounded mb-4">
          {error}
        </div>
      )}

      {isFormOpen && (
        <div className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center p-4 z-50">
          <div className="bg-white dark:bg-gray-800 rounded-lg max-w-md w-full p-6">
            <h2 className="text-xl font-bold mb-4 text-gray-900 dark:text-white">
              {editingMood ? 'Edit Mood Log' : 'New Mood Log'}
            </h2>
            <form onSubmit={handleSubmit}>
              <div className="mb-4">
                <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">
                  Mood (1-10 scale)
                </label>
                <div className="flex items-center space-x-4">
                  <input
                    type="range"
                    min="1"
                    max="10"
                    step="1"
                    className="flex-1"
                    value={formData.rating}
                    onChange={(e) => setFormData({ ...formData, rating: parseInt(e.target.value) })}
                  />
                  <div className="flex items-center space-x-2">
                    <span className="text-2xl">{getMoodEmoji(formData.rating)}</span>
                    <span className="font-medium">{formData.rating}/10</span>
                  </div>
                </div>
              </div>
              <div className="mb-4">
                <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">
                  Notes
                </label>
                <textarea
                  rows={4}
                  placeholder="How are you feeling? What happened today?"
                  className="w-full px-3 py-2 border border-gray-300 dark:border-gray-600 rounded-md focus:outline-none focus:ring-indigo-500 focus:border-indigo-500 dark:bg-gray-700 dark:text-white"
                  value={formData.notes}
                  onChange={(e) => setFormData({ ...formData, notes: e.target.value })}
                />
              </div>
              <div className="mb-4">
                <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">
                  Date
                </label>
                <input
                  type="date"
                  className="w-full px-3 py-2 border border-gray-300 dark:border-gray-600 rounded-md focus:outline-none focus:ring-indigo-500 focus:border-indigo-500 dark:bg-gray-700 dark:text-white"
                  value={formData.logged_at}
                  onChange={(e) => setFormData({ ...formData, logged_at: e.target.value })}
                />
              </div>
              <div className="flex justify-end space-x-3">
                <button
                  type="button"
                  onClick={() => setIsFormOpen(false)}
                  className="px-4 py-2 text-gray-600 dark:text-gray-400 border border-gray-300 dark:border-gray-600 rounded-md hover:bg-gray-50 dark:hover:bg-gray-700"
                >
                  Cancel
                </button>
                <button
                  type="submit"
                  className="px-4 py-2 bg-indigo-600 text-white rounded-md hover:bg-indigo-700"
                >
                  {editingMood ? 'Update' : 'Create'}
                </button>
              </div>
            </form>
          </div>
        </div>
      )}

      <div className="grid gap-4">
        {moodLogs.length === 0 ? (
          <div className="text-center py-8 text-gray-500 dark:text-gray-400">
            No mood logs yet. Log your first mood!
          </div>
        ) : (
          moodLogs.map((mood) => (
            <div key={mood.id} className="bg-white dark:bg-gray-800 border border-gray-200 dark:border-gray-700 rounded-lg p-6 shadow-sm">
              <div className="flex justify-between items-start mb-2">
                <div className="flex items-center space-x-3">
                  <span className="text-3xl">{getMoodEmoji(mood.rating)}</span>
                  <div>
                    <span className={`px-2 py-1 rounded-full text-xs font-medium ${getMoodColor(mood.rating)}`}>
                      {mood.rating}/10
                    </span>
                  </div>
                </div>
                <div className="flex items-center space-x-2">
                  <button
                    onClick={() => handleEdit(mood)}
                    className="text-indigo-600 hover:text-indigo-900 dark:text-indigo-400 dark:hover:text-indigo-300 text-sm"
                  >
                    Edit
                  </button>
                  <button
                    onClick={() => handleDelete(mood.id)}
                    className="text-red-600 hover:text-red-900 dark:text-red-400 dark:hover:text-red-300 text-sm"
                  >
                    Delete
                  </button>
                </div>
              </div>
              {mood.notes && (
                <p className="text-gray-700 dark:text-gray-300 mb-2">{mood.notes}</p>
              )}
              <p className="text-sm text-gray-500 dark:text-gray-400">
                Logged: {new Date(mood.logged_at).toLocaleDateString()}
              </p>
            </div>
          ))
        )}
      </div>
    </div>
  );
}; 