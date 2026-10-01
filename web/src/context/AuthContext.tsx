import React, { createContext, useContext, useEffect, useState } from 'react';
import { authApi, UserProfile } from '../api/auth.api';

interface AuthContextType {
  user: UserProfile | null;
  token: string | null;
  isLoading: boolean;
  selectedUniversity: string;
  setSelectedUniversity: (code: string) => void;
  login: (email: string, pass: string) => Promise<void>;
  logout: () => void;
}

const AuthContext = createContext<AuthContextType | undefined>(undefined);

export const AuthProvider: React.FC<{ children: React.ReactNode }> = ({ children }) => {
  const [user, setUser] = useState<UserProfile | null>(() => {
    const saved = localStorage.getItem('uniroom_user');
    return saved ? JSON.parse(saved) : null;
  });
  const [token, setToken] = useState<string | null>(() => localStorage.getItem('uniroom_access_token'));
  const [isLoading, setIsLoading] = useState<boolean>(true);
  const [selectedUniversity, setSelectedUniversity] = useState<string>(() => {
    return localStorage.getItem('uniroom_selected_uni') || 'UU';
  });

  useEffect(() => {
    const verifyAuth = async () => {
      const storedToken = localStorage.getItem('uniroom_access_token');
      if (storedToken) {
        try {
          const profile = await authApi.getProfile();
          setUser(profile);
          localStorage.setItem('uniroom_user', JSON.stringify(profile));
        } catch (err) {
          console.error('Session validation failed:', err);
          logout();
        }
      }
      setIsLoading(false);
    };

    verifyAuth();
  }, []);

  const login = async (email: string, pass: string) => {
    const res = await authApi.login(email, pass);
    const token = res.accessToken || res.tokens?.accessToken;
    const refresh = res.refreshToken || res.tokens?.refreshToken;
    const user = res.user;

    if (!token) {
      throw new Error('Authentication response did not contain an access token');
    }

    localStorage.setItem('uniroom_access_token', token);
    if (refresh) {
      localStorage.setItem('uniroom_refresh_token', refresh);
    }
    localStorage.setItem('uniroom_user', JSON.stringify(user));
    setToken(token);
    setUser(user);
  };

  const logout = () => {
    localStorage.removeItem('uniroom_access_token');
    localStorage.removeItem('uniroom_refresh_token');
    localStorage.removeItem('uniroom_user');
    setToken(null);
    setUser(null);
  };

  const updateSelectedUniversity = (code: string) => {
    setSelectedUniversity(code);
    localStorage.setItem('uniroom_selected_uni', code);
  };

  return (
    <AuthContext.Provider
      value={{
        user,
        token,
        isLoading,
        selectedUniversity,
        setSelectedUniversity: updateSelectedUniversity,
        login,
        logout,
      }}
    >
      {children}
    </AuthContext.Provider>
  );
};

export const useAuth = () => {
  const ctx = useContext(AuthContext);
  if (!ctx) throw new Error('useAuth must be used within an AuthProvider');
  return ctx;
};
