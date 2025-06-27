import React, { useState, useEffect } from 'react';
import { useAuth } from '../../auth/providers/AuthProvider';

interface Habit {
  id: number;
  name: string;
  description: string;
  frequency: 'daily' | 'weekly' | 'monthly';
  status: 'active' | 'paused' | 'completed';
  created_at: string;
}

export const Habits: React.FC = () => {
  const [habits, setHabits] = useState<Habit[]>([]);
  const [isLoading, setIsLoading] = useState(true);
  const [isFormOpen, setIsFormOpen] = useState(false);
  const [editingHabit, setEditingHabit] = useState<Habit | null>(null);
  const [formData, setFormData] = useState({
    name: '',
    description: '',
    frequency: 'daily' as Habit['frequency'],
    status: 'active' as Habit['status']
  });
  const [error, setError] = useState('');

  const API_BASE_URL = 'http://localhost:3000/api';

  useEffect(() => {
    fetchHabits();
  }, []);

  const getAuthHeaders = () => ({
    'Content-Type': 'application/json',
  });

  const fetchHabits = async () => {
    try {
      const response = await fetch(`${API_BASE_URL}/habits`, {
        credentials: 'include',
        headers: getAuthHeaders(),
      });
      if (response.ok) {
        const data = await response.json();
        setHabits(data);
      } else {
        setError('Failed to fetch habits');
      }
    } catch (error) {
      setError('Error fetching habits');
    } finally {
      setIsLoading(false);
    }
  };

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setError('');

    try {
      const url = editingHabit 
        ? `${API_BASE_URL}/habits/${editingHabit.id}`
        : `${API_BASE_URL}/habits`;
      
      const method = editingHabit ? 'PUT' : 'POST';
      
      const response = await fetch(url, {
        method,
        credentials: 'include',
        headers: getAuthHeaders(),
        body: JSON.stringify({ habit: formData }),
      });

      if (response.ok) {
        await fetchHabits();
        setIsFormOpen(false);
        setEditingHabit(null);
        setFormData({ name: '', description: '', frequency: 'daily', status: 'active' });
      } else {
        setError('Failed to save habit');
      }
    } catch (error) {
      setError('Error saving habit');
    }
  };

  const handleEdit = (habit: Habit) => {
    setEditingHabit(habit);
    setFormData({
      name: habit.name,
      description: habit.description,
      frequency: habit.frequency,
      status: habit.status
    });
    setIsFormOpen(true);
  };

  const handleDelete = async (id: number) => {
    if (!confirm('Are you sure you want to delete this habit?')) return;

    try {
      const response = await fetch(`${API_BASE_URL}/habits/${id}`, {
        method: 'DELETE',
        credentials: 'include',
        headers: getAuthHeaders(),
      });

      if (response.ok) {
        await fetchHabits();
      } else {
        setError('Failed to delete habit');
      }
    } catch (error) {
      setError('Error deleting habit');
    }
  };

  const openCreateForm = () => {
    setEditingHabit(null);
    setFormData({ name: '', description: '', frequency: 'daily', status: 'active' });
    setIsFormOpen(true);
  };

  const getStatusColor = (status: Habit['status']) => {
    switch (status) {
      case 'active': return 'text-green-700 bg-green-100';
      case 'paused': return 'text-yellow-700 bg-yellow-100';
      case 'completed': return 'text-blue-700 bg-blue-100';
      default: return 'text-gray-700 bg-gray-100';
    }
  };

  const getFrequencyColor = (frequency: Habit['frequency']) => {
    switch (frequency) {
      case 'daily': return 'text-purple-700 bg-purple-100';
      case 'weekly': return 'text-indigo-700 bg-indigo-100';
      case 'monthly': return 'text-pink-700 bg-pink-100';
      default: return 'text-gray-700 bg-gray-100';
    }
  };

  if (isLoading) return <div className="flex justify-center p-8">Loading...</div>;

  return (
    <div className="max-w-4xl mx-auto p-6">
      <div className="flex justify-between items-center mb-6">
        <h1 className="text-3xl font-bold text-gray-900">Habits</h1>
        <button
          onClick={openCreateForm}
          className="bg-indigo-600 hover:bg-indigo-700 text-white px-4 py-2 rounded-md"
        >
          New Habit
        </button>
      </div>

      {error && (
        <div className="bg-red-50 border border-red-200 text-red-600 px-4 py-3 rounded mb-4">
          {error}
        </div>
      )}

      {isFormOpen && (
        <div className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center p-4 z-50">
          <div className="bg-white rounded-lg max-w-md w-full p-6">
            <h2 className="text-xl font-bold mb-4">
              {editingHabit ? 'Edit Habit' : 'New Habit'}
            </h2>
            <form onSubmit={handleSubmit}>
              <div className="mb-4">
                <label className="block text-sm font-medium text-gray-700 mb-2">
                  Name
                </label>
                <input
                  type="text"
                  required
                  className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-indigo-500 focus:border-indigo-500"
                  value={formData.name}
                  onChange={(e) => setFormData({ ...formData, name: e.target.value })}
                />
              </div>
              <div className="mb-4">
                <label className="block text-sm font-medium text-gray-700 mb-2">
                  Description
                </label>
                <textarea
                  rows={3}
                  className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-indigo-500 focus:border-indigo-500"
                  value={formData.description}
                  onChange={(e) => setFormData({ ...formData, description: e.target.value })}
                />
              </div>
              <div className="mb-4">
                <label className="block text-sm font-medium text-gray-700 mb-2">
                  Frequency
                </label>
                <select
                  className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-indigo-500 focus:border-indigo-500"
                  value={formData.frequency}
                  onChange={(e) => setFormData({ ...formData, frequency: e.target.value as Habit['frequency'] })}
                >
                  <option value="daily">Daily</option>
                  <option value="weekly">Weekly</option>
                  <option value="monthly">Monthly</option>
                </select>
              </div>
              <div className="mb-4">
                <label className="block text-sm font-medium text-gray-700 mb-2">
                  Status
                </label>
                <select
                  className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-indigo-500 focus:border-indigo-500"
                  value={formData.status}
                  onChange={(e) => setFormData({ ...formData, status: e.target.value as Habit['status'] })}
                >
                  <option value="active">Active</option>
                  <option value="paused">Paused</option>
                  <option value="completed">Completed</option>
                </select>
              </div>
              <div className="flex justify-end space-x-3">
                <button
                  type="button"
                  onClick={() => setIsFormOpen(false)}
                  className="px-4 py-2 text-gray-600 border border-gray-300 rounded-md hover:bg-gray-50"
                >
                  Cancel
                </button>
                <button
                  type="submit"
                  className="px-4 py-2 bg-indigo-600 text-white rounded-md hover:bg-indigo-700"
                >
                  {editingHabit ? 'Update' : 'Create'}
                </button>
              </div>
            </form>
          </div>
        </div>
      )}

      <div className="grid gap-4">
        {habits.length === 0 ? (
          <div className="text-center py-8 text-gray-500">
            No habits yet. Create your first habit!
          </div>
        ) : (
          habits.map((habit) => (
            <div key={habit.id} className="bg-white border border-gray-200 rounded-lg p-6 shadow-sm">
              <div className="flex justify-between items-start mb-2">
                <h3 className="text-lg font-semibold text-gray-900">{habit.name}</h3>
                <div className="flex items-center space-x-2">
                  <span className={`px-2 py-1 rounded-full text-xs font-medium ${getFrequencyColor(habit.frequency)}`}>
                    {habit.frequency}
                  </span>
                  <span className={`px-2 py-1 rounded-full text-xs font-medium ${getStatusColor(habit.status)}`}>
                    {habit.status}
                  </span>
                  <button
                    onClick={() => handleEdit(habit)}
                    className="text-indigo-600 hover:text-indigo-900 text-sm"
                  >
                    Edit
                  </button>
                  <button
                    onClick={() => handleDelete(habit.id)}
                    className="text-red-600 hover:text-red-900 text-sm"
                  >
                    Delete
                  </button>
                </div>
              </div>
              {habit.description && (
                <p className="text-gray-700 mb-2">{habit.description}</p>
              )}
              <p className="text-sm text-gray-500">
                Created: {new Date(habit.created_at).toLocaleDateString()}
              </p>
            </div>
          ))
        )}
      </div>
    </div>
  );
}; 