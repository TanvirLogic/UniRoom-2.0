import { apiClient } from './client';

export interface UniversityItem {
  id: string;
  name: string;
  code: string;
  domain?: string;
  logoUrl?: string;
  operatingDays: string[];
  isActive: boolean;
  departments: Array<{
    id: string;
    code: string;
    name: string;
    _count?: { rooms: number; academicBatches: number };
  }>;
  _count?: { rooms: number; users: number };
}

export interface DepartmentItem {
  id: string;
  name: string;
  code: string;
  universityId: string;
  university?: { id: string; code: string; name: string };
  buildings?: Array<{ id: string; name: string; campusName: string; rooms?: any[] }>;
  academicBatches?: Array<{ id: string; name: string; sections: string[]; isActive: boolean }>;
  _count?: { rooms: number; scheduleSlots: number; users: number };
}

export const universitiesApi = {
  getUniversities: async (onlyActive = false): Promise<UniversityItem[]> => {
    const res = await apiClient.get('/universities', { params: { onlyActive } });
    return res.data;
  },

  getUniversityById: async (id: string): Promise<UniversityItem> => {
    const res = await apiClient.get(`/universities/${id}`);
    return res.data;
  },

  createUniversity: async (data: {
    name: string;
    code: string;
    domain?: string;
    logoUrl?: string;
    operatingDays?: string[];
    isActive?: boolean;
  }): Promise<UniversityItem> => {
    const res = await apiClient.post('/admin/universities', data);
    return res.data;
  },

  updateUniversity: async (
    id: string,
    data: Partial<{
      name: string;
      code: string;
      domain?: string;
      logoUrl?: string;
      operatingDays?: string[];
      isActive?: boolean;
    }>,
  ): Promise<UniversityItem> => {
    const res = await apiClient.put(`/admin/universities/${id}`, data);
    return res.data;
  },

  deleteUniversity: async (id: string): Promise<{ success: boolean }> => {
    const res = await apiClient.delete(`/admin/universities/${id}`);
    return res.data;
  },

  getDepartments: async (params?: { university?: string; search?: string }): Promise<DepartmentItem[]> => {
    const res = await apiClient.get('/departments', { params });
    return res.data;
  },

  getDepartmentById: async (id: string): Promise<DepartmentItem> => {
    const res = await apiClient.get(`/departments/${id}`);
    return res.data;
  },

  createDepartment: async (data: {
    university: string;
    code: string;
    name: string;
  }): Promise<DepartmentItem> => {
    const res = await apiClient.post('/admin/departments', data);
    return res.data;
  },

  updateDepartment: async (
    id: string,
    data: { name?: string; code?: string; university?: string },
  ): Promise<DepartmentItem> => {
    const res = await apiClient.put(`/admin/departments/${id}`, data);
    return res.data;
  },

  deleteDepartment: async (id: string): Promise<{ success: boolean }> => {
    const res = await apiClient.delete(`/admin/departments/${id}`);
    return res.data;
  },
};
