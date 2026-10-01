import { apiClient } from './client';

export interface UserProfile {
  id: string;
  email: string;
  fullName: string;
  role: 'SUPER_ADMIN' | 'FACULTY' | 'CR' | 'STUDENT';
  universityId: string;
  departmentId: string;
  isEmailVerified: boolean;
}

export interface AuthResponse {
  user: UserProfile;
  accessToken: string;
  refreshToken: string;
  expiresIn?: number;
  tokens?: {
    accessToken: string;
    refreshToken: string;
    expiresIn: number;
  };
}

export const authApi = {
  login: async (email: string, password: string): Promise<AuthResponse> => {
    const res = await apiClient.post('/auth/login', { email, password });
    return res.data;
  },

  getProfile: async (): Promise<UserProfile> => {
    const res = await apiClient.get('/auth/me');
    return res.data;
  },
};
