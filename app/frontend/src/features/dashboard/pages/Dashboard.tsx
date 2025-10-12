import React, { useState, useEffect } from 'react';
import { Link } from 'react-router-dom';
import { useAuth } from '../../auth/providers/AuthProvider';
import { apiClient } from 'src/utils/apiClient';

interface DashboardStats {
  journalEntries: number;
  goals: number;
  habits: number;
  moodLogs: number;
  resources: number;
}

export const Dashboard: React.FC = () => {
  const { user } = useAuth();
  const [stats, setStats] = useState<DashboardStats>({
    journalEntries: 0,
    goals: 0,
    habits: 0,
    moodLogs: 0,
    resources: 0,
  });
  const [isLoading, setIsLoading] = useState(true);

  useEffect(() => {
    fetchStats();
  }, []);

  const fetchStats = async () => {
    try {
      const [journalData, goalsData, habitsData, moodData, resourcesData] = await Promise.all([
        apiClient.get('/journal_entries'),
        apiClient.get('/goals'),
        apiClient.get('/habits'),
        apiClient.get('/mood_logs'),
        apiClient.get('/resources'),
      ]);

      // Helper function to get count from different response formats
      const getCount = (response: any) => {
        // If response has data.items (paginated), return the total count
        if (response.data?.items && response.data?.total !== undefined) {
          return response.data.total;
        }
        // If response.data is an array, return its length
        if (Array.isArray(response.data)) {
          return response.data.length;
        }
        // If response is directly an array (direct Blueprint render), return its length
        if (Array.isArray(response)) {
          return response.length;
        }
        return 0;
      };

      setStats({
        journalEntries: getCount(journalData),
        goals: getCount(goalsData),
        habits: getCount(habitsData),
        moodLogs: getCount(moodData),
        resources: getCount(resourcesData),
      });
    } catch (error) {
      console.error('Error fetching stats:', error);
    } finally {
      setIsLoading(false);
    }
  };

  const getUserDisplayName = () => {
    if (!user) return 'User';
    if (user.full_name) return user.full_name;
    if (user.first_name) return user.first_name;
    return user.email;
  };

  if (isLoading) {
    return <div className="flex justify-center p-8 text-gray-600 dark:text-gray-400">Loading...</div>;
  }

  return (
    <div className="max-w-7xl mx-auto p-6">
      <div className="mb-8">
        <h1 className="text-3xl font-bold text-gray-900 dark:text-white mb-2">
          Welcome back, {getUserDisplayName()}!
        </h1>
        <p className="text-gray-600 dark:text-gray-400">
          Here's your journaling overview for today.
        </p>
      </div>

      {/* Stats Grid */}
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 xl:grid-cols-5 gap-6 mb-8">
        <Link
          to="/journal"
          className="bg-white dark:bg-gray-800 p-6 rounded-lg border border-gray-200 dark:border-gray-700 shadow-sm hover:shadow-md transition-shadow"
        >
          <div className="flex items-center justify-between">
            <div>
              <p className="text-sm font-medium text-gray-600 dark:text-gray-400">Journal Entries</p>
              <p className="text-3xl font-bold text-indigo-600 dark:text-indigo-400">{stats.journalEntries}</p>
            </div>
            <div className="text-indigo-600 dark:text-indigo-400">
              <svg className="w-8 h-8" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 6.253v13m0-13C10.832 5.477 9.246 5 7.5 5S4.168 5.477 3 6.253v13C4.168 18.477 5.754 18 7.5 18s3.332.477 4.5 1.253m0-13C13.168 5.477 14.754 5 16.5 5c1.747 0 3.332.477 4.5 1.253v13C19.832 18.477 18.247 18 16.5 18c-1.746 0-3.332.477-4.5 1.253" />
              </svg>
            </div>
          </div>
        </Link>

        <Link
          to="/goals"
          className="bg-white dark:bg-gray-800 p-6 rounded-lg border border-gray-200 dark:border-gray-700 shadow-sm hover:shadow-md transition-shadow"
        >
          <div className="flex items-center justify-between">
            <div>
              <p className="text-sm font-medium text-gray-600 dark:text-gray-400">Goals</p>
              <p className="text-3xl font-bold text-green-600 dark:text-green-400">{stats.goals}</p>
            </div>
            <div className="text-green-600 dark:text-green-400">
              <svg className="w-8 h-8" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M9 12l2 2 4-4m6 2a9 9 0 11-18 0 9 9 0 0118 0z" />
              </svg>
            </div>
          </div>
        </Link>

        <Link
          to="/habits"
          className="bg-white dark:bg-gray-800 p-6 rounded-lg border border-gray-200 dark:border-gray-700 shadow-sm hover:shadow-md transition-shadow"
        >
          <div className="flex items-center justify-between">
            <div>
              <p className="text-sm font-medium text-gray-600 dark:text-gray-400">Habits</p>
              <p className="text-3xl font-bold text-purple-600 dark:text-purple-400">{stats.habits}</p>
            </div>
            <div className="text-purple-600 dark:text-purple-400">
              <svg className="w-8 h-8" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M4 4v5h.582m15.356 2A8.001 8.001 0 004.582 9m0 0H9m11 11v-5h-.581m0 0a8.003 8.003 0 01-15.357-2m15.357 2H15" />
              </svg>
            </div>
          </div>
        </Link>

        <Link
          to="/mood"
          className="bg-white dark:bg-gray-800 p-6 rounded-lg border border-gray-200 dark:border-gray-700 shadow-sm hover:shadow-md transition-shadow"
        >
          <div className="flex items-center justify-between">
            <div>
              <p className="text-sm font-medium text-gray-600 dark:text-gray-400">Mood Logs</p>
              <p className="text-3xl font-bold text-yellow-600 dark:text-yellow-400">{stats.moodLogs}</p>
            </div>
            <div className="text-yellow-600 dark:text-yellow-400">
              <svg className="w-8 h-8" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M14.828 14.828a4 4 0 01-5.656 0M9 10h1.5a1.5 1.5 0 001.5-1.5V9a1.5 1.5 0 00-1.5-1.5H9m0 0V7.5a1.5 1.5 0 011.5-1.5H12m-3 4.5h1.5m-1.5 0v3M9 16.5h1.5" />
              </svg>
            </div>
          </div>
        </Link>

        <Link
          to="/resources"
          className="bg-white dark:bg-gray-800 p-6 rounded-lg border border-gray-200 dark:border-gray-700 shadow-sm hover:shadow-md transition-shadow"
        >
          <div className="flex items-center justify-between">
            <div>
              <p className="text-sm font-medium text-gray-600 dark:text-gray-400">Resources</p>
              <p className="text-3xl font-bold text-blue-600 dark:text-blue-400">{stats.resources}</p>
            </div>
            <div className="text-blue-600 dark:text-blue-400">
              <svg className="w-8 h-8" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M13.828 10.172a4 4 0 00-5.656 0l-4 4a4 4 0 105.656 5.656l1.102-1.101m-.758-4.899a4 4 0 005.656 0l4-4a4 4 0 00-5.656-5.656l-1.1 1.1" />
              </svg>
            </div>
          </div>
        </Link>
      </div>

      {/* Quick Actions */}
      <div className="bg-white dark:bg-gray-800 rounded-lg border border-gray-200 dark:border-gray-700 shadow-sm p-6">
        <h2 className="text-xl font-semibold text-gray-900 dark:text-white mb-4">Quick Actions</h2>
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 xl:grid-cols-5 gap-4">
          <Link
            to="/journal/new"
            className="flex items-center justify-center p-4 border border-gray-300 dark:border-gray-600 rounded-lg hover:bg-gray-50 dark:hover:bg-gray-700 transition-colors"
          >
            <span className="text-gray-700 dark:text-gray-300 font-medium">New Journal Entry</span>
          </Link>
          <Link
            to="/goals"
            className="flex items-center justify-center p-4 border border-gray-300 dark:border-gray-600 rounded-lg hover:bg-gray-50 dark:hover:bg-gray-700 transition-colors"
          >
            <span className="text-gray-700 dark:text-gray-300 font-medium">Add Goal</span>
          </Link>
          <Link
            to="/habits"
            className="flex items-center justify-center p-4 border border-gray-300 dark:border-gray-600 rounded-lg hover:bg-gray-50 dark:hover:bg-gray-700 transition-colors"
          >
            <span className="text-gray-700 dark:text-gray-300 font-medium">Track Habit</span>
          </Link>
          <Link
            to="/mood"
            className="flex items-center justify-center p-4 border border-gray-300 dark:border-gray-600 rounded-lg hover:bg-gray-50 dark:hover:bg-gray-700 transition-colors"
          >
            <span className="text-gray-700 dark:text-gray-300 font-medium">Log Mood</span>
          </Link>
          <Link
            to="/resources"
            className="flex items-center justify-center p-4 border border-gray-300 dark:border-gray-600 rounded-lg hover:bg-gray-50 dark:hover:bg-gray-700 transition-colors"
          >
            <span className="text-gray-700 dark:text-gray-300 font-medium">Add Resource</span>
          </Link>
        </div>
      </div>
    </div>
  );
}; 