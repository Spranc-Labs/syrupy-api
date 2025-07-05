import React, { createContext, useContext, useState, useEffect, ReactNode } from 'react';
import { apiClient } from '../../../utils/apiClient';
import { tokenStorage } from '../../../utils/tokenStorage';

interface User {
  id: number;
  email: string;
  first_name?: string;
  last_name?: string;
  full_name?: string;
}

interface AuthContextType {
  user: User | null;
  isLoading: boolean;
  isInitialLoad: boolean; // New prop
  login: (email: string, password: string) => Promise<void>;
  register: (email: string, password: string, firstName?: string, lastName?: string) => Promise<void>;
  logout: () => void;
  isAuthenticated: boolean;
}

const AuthContext = createContext<AuthContextType | undefined>(undefined);

interface AuthProviderProps {
  children: ReactNode;
}

export const AuthProvider: React.FC<AuthProviderProps> = ({ children }) => {
  const [user, setUser] = useState<User | null>(null);
  const [isLoading, setIsLoading] = useState(false);
  const [isInitialLoad, setIsInitialLoad] = useState(true);

  useEffect(() => {
    fetchCurrentUser();
  }, []);

  const fetchCurrentUser = async () => {
    setIsInitialLoad(true);
    try {
      // Only try to fetch current user if we have tokens
      if (tokenStorage.hasValidTokens()) {
        const data = await apiClient.get('/auth/me');
        if (data.success && data.user) {
          setUser(data.user);
          console.log('User authenticated from stored tokens:', data.user.email);
        } else {
          setUser(null);
          tokenStorage.clearTokens();
        }
      } else {
        setUser(null);
        console.log('No valid tokens found, user needs to login');
      }
    } catch (error) {
      console.error('Error fetching current user:', error);
      setUser(null);
      tokenStorage.clearTokens();
    } finally {
      setIsInitialLoad(false);
    }
  };

  const login = async (email: string, password: string): Promise<void> => {
    setIsLoading(true);
    try {
      const data = await apiClient.post('/auth/login', { email, password });

      if (!data.success) {
        throw new Error(data.message || 'Login failed');
      }

      // Store tokens
      if (data.access_token && data.refresh_token) {
        tokenStorage.setTokens(data.access_token, data.refresh_token);
        console.log('Login successful, tokens stored for user:', data.user?.email);
      } else {
        console.warn('Login response missing tokens:', data);
      }

      setUser(data.user);
    } finally {
      setIsLoading(false);
    }
  };

  const register = async (email: string, password: string, firstName?: string, lastName?: string): Promise<void> => {
    setIsLoading(true);
    try {
      const data = await apiClient.post('/auth/register', {
        email,
        password,
        first_name: firstName,
        last_name: lastName
      });

      if (!data.success) {
        throw new Error(data.message || 'Registration failed');
      }

      // Store tokens
      if (data.access_token && data.refresh_token) {
        tokenStorage.setTokens(data.access_token, data.refresh_token);
      }

      setUser(data.user);
    } finally {
      setIsLoading(false);
    }
  };

  const logout = async () => {
    try {
      await apiClient.delete('/auth/logout');
    } catch (error) {
      console.error('Error logging out:', error);
    } finally {
      tokenStorage.clearTokens();
      setUser(null);
    }
  };

  const value: AuthContextType = {
    user,
    isLoading: isLoading,
    isInitialLoad: isInitialLoad, // New prop
    login,
    register,
    logout,
    isAuthenticated: !!user,
  };

  return <AuthContext.Provider value={value}>{children}</AuthContext.Provider>;
};

export const useAuth = (): AuthContextType => {
  const context = useContext(AuthContext);
  if (context === undefined) {
    throw new Error('useAuth must be used within an AuthProvider');
  }
  return context;
}; 