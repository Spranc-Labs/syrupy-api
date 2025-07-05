import React, { useState, useEffect } from 'react';
import { useAuth } from '../../auth/providers/AuthProvider';
import { apiClient } from '../../../utils/apiClient';

interface Habit {
  id: number;
  name: string;
  description: string;
  frequency: 'daily' | 'weekly' | 'monthly';
  active: boolean;
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
    active: true
  });
  const [error, setError] = useState('');

  useEffect(() => {
    fetchHabits();
  }, []);

  const fetchHabits = async () => {
    try {
      const data = await apiClient.get('/habits');
      // Handle paginated response format or direct array
      setHabits(data.data?.items || data.data || data);
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
      const payload = { habit: formData };
      
      if (editingHabit) {
        await apiClient.put(`/habits/${editingHabit.id}`, payload);
      } else {
        await apiClient.post('/habits', payload);
      }

      await fetchHabits();
      setIsFormOpen(false);
      setEditingHabit(null);
      setFormData({ name: '', description: '', frequency: 'daily', active: true });
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
      active: habit.active
    });
    setIsFormOpen(true);
  };

  const handleDelete = async (id: number) => {
    if (!confirm('Are you sure you want to delete this habit?')) return;

    try {
      await apiClient.delete(`/habits/${id}`);
      await fetchHabits();
    } catch (error) {
      setError('Error deleting habit');
    }
  };

  const openCreateForm = () => {
    setEditingHabit(null);
    setFormData({ name: '', description: '', frequency: 'daily', active: true });
    setIsFormOpen(true);
  };

  const getActiveColor = (active: boolean) => {
    return active ? 'text-green-700 bg-green-100' : 'text-gray-700 bg-gray-100';
  };

  const getFrequencyColor = (frequency: Habit['frequency']) => {
    switch (frequency) {
      case 'daily': return 'text-purple-700 bg-purple-100';
      case 'weekly': return 'text-indigo-700 bg-indigo-100';
      case 'monthly': return 'text-pink-700 bg-pink-100';
      default: return 'text-gray-700 bg-gray-100';
    }
  };

  if (isLoading) return <div className="flex justify-center p-8 text-gray-600 dark:text-gray-400">Loading...</div>;

  return (
    <div className="max-w-4xl mx-auto p-6">
      <div className="flex justify-between items-center mb-6">
        <h1 className="text-3xl font-bold text-gray-900 dark:text-white">Habits</h1>
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
          <div className="bg-white dark:bg-gray-800 rounded-lg max-w-md w-full p-6">
            <h2 className="text-xl font-bold mb-4 text-gray-900 dark:text-white">
              {editingHabit ? 'Edit Habit' : 'New Habit'}
            </h2>
            <form onSubmit={handleSubmit}>
              <div className="mb-4">
                <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">
                  Name
                </label>
                <input
                  type="text"
                  required
                  className="w-full px-3 py-2 border border-gray-300 dark:border-gray-600 rounded-md focus:outline-none focus:ring-indigo-500 focus:border-indigo-500 dark:bg-gray-700 dark:text-white"
                  value={formData.name}
                  onChange={(e) => setFormData({ ...formData, name: e.target.value })}
                />
              </div>
              <div className="mb-4">
                <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">
                  Description
                </label>
                <textarea
                  rows={3}
                  className="w-full px-3 py-2 border border-gray-300 dark:border-gray-600 rounded-md focus:outline-none focus:ring-indigo-500 focus:border-indigo-500 dark:bg-gray-700 dark:text-white"
                  value={formData.description}
                  onChange={(e) => setFormData({ ...formData, description: e.target.value })}
                />
              </div>
              <div className="mb-4">
                <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">
                  Frequency
                </label>
                <select
                  className="w-full px-3 py-2 border border-gray-300 dark:border-gray-600 rounded-md focus:outline-none focus:ring-indigo-500 focus:border-indigo-500 dark:bg-gray-700 dark:text-white"
                  value={formData.frequency}
                  onChange={(e) => setFormData({ ...formData, frequency: e.target.value as Habit['frequency'] })}
                >
                  <option value="daily">Daily</option>
                  <option value="weekly">Weekly</option>
                  <option value="monthly">Monthly</option>
                </select>
              </div>
              <div className="mb-4">
                <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">
                  Status
                </label>
                <select
                  className="w-full px-3 py-2 border border-gray-300 dark:border-gray-600 rounded-md focus:outline-none focus:ring-indigo-500 focus:border-indigo-500 dark:bg-gray-700 dark:text-white"
                  value={formData.active ? 'active' : 'inactive'}
                  onChange={(e) => setFormData({ ...formData, active: e.target.value === 'active' })}
                >
                  <option value="active">Active</option>
                  <option value="inactive">Inactive</option>
                </select>
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
                  {editingHabit ? 'Update' : 'Create'}
                </button>
              </div>
            </form>
          </div>
        </div>
      )}

      <div className="grid gap-4">
        {habits.length === 0 ? (
          <div className="text-center py-8 text-gray-500 dark:text-gray-400">
            No habits yet. Create your first habit!
          </div>
        ) : (
          habits.map((habit) => (
            <div key={habit.id} className="bg-white dark:bg-gray-800 border border-gray-200 dark:border-gray-700 rounded-lg p-6 shadow-sm">
              <div className="flex justify-between items-start mb-2">
                <h3 className="text-lg font-semibold text-gray-900 dark:text-white">{habit.name}</h3>
                <div className="flex items-center space-x-2">
                  <span className={`px-2 py-1 rounded-full text-xs font-medium ${getFrequencyColor(habit.frequency)}`}>
                    {habit.frequency}
                  </span>
                  <span className={`px-2 py-1 rounded-full text-xs font-medium ${getActiveColor(habit.active)}`}>
                    {habit.active ? 'Active' : 'Inactive'}
                  </span>
                  <button
                    onClick={() => handleEdit(habit)}
                    className="text-indigo-600 hover:text-indigo-900 dark:text-indigo-400 dark:hover:text-indigo-300 text-sm"
                  >
                    Edit
                  </button>
                  <button
                    onClick={() => handleDelete(habit.id)}
                    className="text-red-600 hover:text-red-900 dark:text-red-400 dark:hover:text-red-300 text-sm"
                  >
                    Delete
                  </button>
                </div>
              </div>
              {habit.description && (
                <p className="text-gray-700 dark:text-gray-300 mb-2">{habit.description}</p>
              )}
              <p className="text-sm text-gray-500 dark:text-gray-400">
                Created: {new Date(habit.created_at).toLocaleDateString()}
              </p>
            </div>
          ))
        )}
      </div>
    </div>
  );
}; 