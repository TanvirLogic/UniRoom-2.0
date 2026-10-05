import { apiClient } from './client';

export interface HealthStatusResponse {
  status: string;
  service: string;
  database: {
    status: string;
    provider: string;
    stats: {
      universities: number;
      rooms: number;
      scheduleSlots: number;
    };
  };
  email: {
    isConfigured: boolean;
    host: string;
    port: number;
    secure: boolean;
    user: string;
    from: string;
  };
  pushNotifications: {
    isInitialized: boolean;
    projectId: string | null;
    clientEmail: string | null;
    lastInitError?: string | null;
  };
  timestamp: string;
}

export interface DiagnosticsResponse {
  service: string;
  timestamp: string;
  email: {
    isConfigured: boolean;
    host: string;
    port: number;
    secure: boolean;
    user: string;
    from: string;
    verification: {
      success: boolean;
      message: string;
    };
  };
  pushNotifications: {
    isInitialized: boolean;
    projectId: string | null;
    clientEmail: string | null;
    lastInitError?: string | null;
  };
}

export interface TestResultResponse {
  success: boolean;
  message: string;
  messageId?: string;
  responseId?: string;
}

export const healthApi = {
  getHealth: async (): Promise<HealthStatusResponse> => {
    const res = await apiClient.get<HealthStatusResponse>('/health');
    return res.data;
  },

  getDiagnostics: async (): Promise<DiagnosticsResponse> => {
    const res = await apiClient.get<DiagnosticsResponse>('/health/diagnostics');
    return res.data;
  },

  testEmail: async (email: string): Promise<TestResultResponse> => {
    const res = await apiClient.post<TestResultResponse>('/health/test-email', { email });
    return res.data;
  },

  testPush: async (payload: { topic?: string; token?: string; title?: string; body?: string }): Promise<TestResultResponse> => {
    const res = await apiClient.post<TestResultResponse>('/health/test-push', payload);
    return res.data;
  },
};
