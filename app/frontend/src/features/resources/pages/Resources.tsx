import React, { useState, useEffect } from 'react';
import { apiClient } from '../../../utils/apiClient';

interface Resource {
  id: number;
  url: string;
  title?: string;
  status: 'pending' | 'processed' | 'failed';
  domain?: string;
  has_content: boolean;
  created_at: string;
  updated_at: string;
  tags?: Tag[];
}

interface Tag {
  id: number;
  name: string;
  color: string;
}

export const Resources: React.FC = () => {
  const [resources, setResources] = useState<Resource[]>([]);
  const [isLoading, setIsLoading] = useState(true);
  const [showAddForm, setShowAddForm] = useState(false);
  const [newResourceUrl, setNewResourceUrl] = useState('');
  const [isSubmitting, setIsSubmitting] = useState(false);
  const [searchQuery, setSearchQuery] = useState('');

  useEffect(() => {
    fetchResources();
  }, []);

  const fetchResources = async () => {
    try {
      const response = await apiClient.get('/resources');
      console.log('Resources API response:', response); // Debug log
      
      // Handle different response formats like other endpoints
      const resourcesData = Array.isArray(response.data) ? response.data : 
                           Array.isArray(response) ? response : [];
      
      console.log('Processed resources data:', resourcesData); // Debug log
      setResources(resourcesData);
    } catch (error) {
      console.error('Error fetching resources:', error);
      setResources([]); // Set empty array on error
    } finally {
      setIsLoading(false);
    }
  };

  const handleAddResource = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!newResourceUrl.trim()) return;

    setIsSubmitting(true);
    try {
      const response = await apiClient.post('/resources', {
        url: newResourceUrl.trim()
      });
      
      console.log('Add resource API response:', response); // Debug log
      
      // Handle the response format properly
      const newResource = response.data || response;
      console.log('New resource:', newResource); // Debug log
      
      // Validate the new resource has required properties
      if (newResource && newResource.id && newResource.url) {
        setResources(prev => [newResource, ...prev]);
        setNewResourceUrl('');
        setShowAddForm(false);
      } else {
        console.error('Invalid resource response format:', newResource);
      }
    } catch (error) {
      console.error('Error adding resource:', error);
    } finally {
      setIsSubmitting(false);
    }
  };

  const handleDeleteResource = async (id: number) => {
    if (!confirm('Are you sure you want to delete this resource?')) return;

    try {
      await apiClient.delete(`/resources/${id}`);
      setResources(prev => prev.filter(resource => resource.id !== id));
    } catch (error) {
      console.error('Error deleting resource:', error);
    }
  };

  const filteredResources = resources.filter(resource =>
    (resource.url?.toLowerCase().includes(searchQuery.toLowerCase()) || false) ||
    (resource.title?.toLowerCase().includes(searchQuery.toLowerCase()) || false) ||
    (resource.domain?.toLowerCase().includes(searchQuery.toLowerCase()) || false)
  );

  const getStatusBadge = (status: string) => {
    const statusConfig = {
      pending: { color: 'bg-yellow-100 text-yellow-800 dark:bg-yellow-900 dark:text-yellow-300', text: 'Pending' },
      processed: { color: 'bg-green-100 text-green-800 dark:bg-green-900 dark:text-green-300', text: 'Processed' },
      failed: { color: 'bg-red-100 text-red-800 dark:bg-red-900 dark:text-red-300', text: 'Failed' }
    };

    const config = statusConfig[status as keyof typeof statusConfig] || statusConfig.pending;
    
    return (
      <span className={`inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium ${config.color}`}>
        {config.text}
      </span>
    );
  };

  if (isLoading) {
    return (
      <div className="flex justify-center p-8 text-gray-600 dark:text-gray-400">
        Loading resources...
      </div>
    );
  }

  return (
    <div className="max-w-7xl mx-auto p-6">
      <div className="mb-8">
        <div className="flex justify-between items-center mb-4">
          <div>
            <h1 className="text-3xl font-bold text-gray-900 dark:text-white mb-2">
              My Resources
            </h1>
            <p className="text-gray-600 dark:text-gray-400">
              Save articles, links, and resources for future reference
            </p>
          </div>
          <button
            onClick={() => setShowAddForm(true)}
            className="bg-indigo-600 hover:bg-indigo-700 text-white px-4 py-2 rounded-lg font-medium transition-colors"
          >
            Add Resource
          </button>
        </div>

        {/* Search */}
        <div className="mb-6">
          <input
            type="text"
            placeholder="Search resources..."
            value={searchQuery}
            onChange={(e) => setSearchQuery(e.target.value)}
            className="w-full px-4 py-2 border border-gray-300 dark:border-gray-600 rounded-lg bg-white dark:bg-gray-800 text-gray-900 dark:text-white focus:ring-2 focus:ring-indigo-500 focus:border-transparent"
          />
        </div>
      </div>

      {/* Add Resource Modal */}
      {showAddForm && (
        <div className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50">
          <div className="bg-white dark:bg-gray-800 rounded-lg p-6 w-full max-w-md mx-4">
            <h2 className="text-xl font-semibold text-gray-900 dark:text-white mb-4">
              Add New Resource
            </h2>
            <form onSubmit={handleAddResource}>
              <div className="mb-4">
                <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">
                  URL
                </label>
                <input
                  type="url"
                  value={newResourceUrl}
                  onChange={(e) => setNewResourceUrl(e.target.value)}
                  placeholder="https://example.com/article"
                  className="w-full px-3 py-2 border border-gray-300 dark:border-gray-600 rounded-lg bg-white dark:bg-gray-700 text-gray-900 dark:text-white focus:ring-2 focus:ring-indigo-500 focus:border-transparent"
                  required
                />
              </div>
              <div className="flex justify-end space-x-3">
                <button
                  type="button"
                  onClick={() => setShowAddForm(false)}
                  className="px-4 py-2 text-gray-700 dark:text-gray-300 hover:bg-gray-100 dark:hover:bg-gray-700 rounded-lg transition-colors"
                >
                  Cancel
                </button>
                <button
                  type="submit"
                  disabled={isSubmitting}
                  className="px-4 py-2 bg-indigo-600 hover:bg-indigo-700 text-white rounded-lg font-medium transition-colors disabled:opacity-50"
                >
                  {isSubmitting ? 'Adding...' : 'Add Resource'}
                </button>
              </div>
            </form>
          </div>
        </div>
      )}

      {/* Resources List */}
      <div className="space-y-4">
        {filteredResources.length === 0 ? (
          <div className="text-center py-12">
            <div className="text-gray-400 mb-4">
              <svg className="w-16 h-16 mx-auto" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={1.5} d="M13.828 10.172a4 4 0 00-5.656 0l-4 4a4 4 0 105.656 5.656l1.102-1.101m-.758-4.899a4 4 0 005.656 0l4-4a4 4 0 00-5.656-5.656l-1.1 1.1" />
              </svg>
            </div>
            <h3 className="text-lg font-medium text-gray-900 dark:text-white mb-2">
              No resources yet
            </h3>
            <p className="text-gray-600 dark:text-gray-400 mb-4">
              Start building your personal library by adding your first resource
            </p>
            <button
              onClick={() => setShowAddForm(true)}
              className="bg-indigo-600 hover:bg-indigo-700 text-white px-4 py-2 rounded-lg font-medium transition-colors"
            >
              Add Your First Resource
            </button>
          </div>
        ) : (
          filteredResources.map((resource) => {
            // Safety check for malformed resource objects
            if (!resource || !resource.id || !resource.url) {
              console.warn('Skipping invalid resource:', resource);
              return null;
            }
            
            return (
            <div
              key={resource.id}
              className="bg-white dark:bg-gray-800 rounded-lg border border-gray-200 dark:border-gray-700 p-6 hover:shadow-md transition-shadow"
            >
              <div className="flex justify-between items-start">
                <div className="flex-1">
                  <div className="flex items-center space-x-2 mb-2">
                    {getStatusBadge(resource.status)}
                    {resource.domain && (
                      <span className="text-sm text-gray-500 dark:text-gray-400">
                        {resource.domain}
                      </span>
                    )}
                  </div>
                  <h3 className="text-lg font-medium text-gray-900 dark:text-white mb-2">
                    {resource.title || 'Untitled'}
                  </h3>
                  <a
                    href={resource.url}
                    target="_blank"
                    rel="noopener noreferrer"
                    className="text-indigo-600 dark:text-indigo-400 hover:underline break-all"
                  >
                    {resource.url}
                  </a>
                  <div className="mt-3 flex items-center space-x-4 text-sm text-gray-500 dark:text-gray-400">
                    <span>Added {new Date(resource.created_at).toLocaleDateString()}</span>
                    {resource.has_content && (
                      <span className="flex items-center">
                        <svg className="w-4 h-4 mr-1" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                          <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M9 12h6m-6 4h6m2 5H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z" />
                        </svg>
                        Content saved
                      </span>
                    )}
                  </div>
                  {resource.tags && resource.tags.length > 0 && (
                    <div className="mt-3 flex flex-wrap gap-2">
                      {resource.tags.map((tag) => (
                        <span
                          key={tag.id}
                          className="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium"
                          style={{ backgroundColor: tag.color + '20', color: tag.color }}
                        >
                          {tag.name}
                        </span>
                      ))}
                    </div>
                  )}
                </div>
                <div className="ml-4">
                  <button
                    onClick={() => handleDeleteResource(resource.id)}
                    className="text-gray-400 hover:text-red-600 dark:hover:text-red-400 transition-colors"
                  >
                    <svg className="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                      <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M19 7l-.867 12.142A2 2 0 0116.138 21H7.862a2 2 0 01-1.995-1.858L5 7m5 4v6m4-6v6m1-10V4a1 1 0 00-1-1h-4a1 1 0 00-1 1v3M4 7h16" />
                    </svg>
                  </button>
                </div>
              </div>
            </div>
            );
          }).filter(Boolean) // Remove any null entries
        )}
      </div>
    </div>
  );
}; 