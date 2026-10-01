import axios from 'axios';

export const API_BASE_URL = import.meta.env.VITE_API_URL || 'https://uniroom-2-0.onrender.com/api/v1';

export const apiClient = axios.create({
  baseURL: API_BASE_URL,
  headers: {
    'Content-Type': 'application/json',
  },
});

// Request Interceptor: Attach Access Token
apiClient.interceptors.request.use(
  (config) => {
    const token = localStorage.getItem('uniroom_access_token');
    if (token && config.headers) {
      config.headers.Authorization = `Bearer ${token}`;
    }
    return config;
  },
  (error) => Promise.reject(error),
);

// Response Interceptor: Unwrap NestJS ApiResponse Envelope and Handle 401s
apiClient.interceptors.response.use(
  (response) => {
    if (
      response.data &&
      typeof response.data === 'object' &&
      'data' in response.data &&
      'success' in response.data &&
      response.data.success === true
    ) {
      response.data = response.data.data;
    }
    return response;
  },
  async (error) => {
    if (error.response?.status === 401 && !error.config?._retry) {
      // If we receive a 401 on an authenticated route, clear session
      if (localStorage.getItem('uniroom_access_token')) {
        localStorage.removeItem('uniroom_access_token');
        localStorage.removeItem('uniroom_refresh_token');
        localStorage.removeItem('uniroom_user');
        window.location.href = '/login';
      }
    }
    return Promise.reject(error);
  },
);
