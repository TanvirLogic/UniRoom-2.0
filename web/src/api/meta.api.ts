import { apiClient } from './client';

export interface BatchItem {
  id: string;
  name: string;
  sections: string[];
  isActive: boolean;
  departmentId: string;
  department?: {
    id: string;
    code: string;
    name: string;
    university?: { id: string; code: string; name: string };
  };
}

export interface RegistrationOptions {
  universities: Array<{
    id: string;
    code: string;
    name: string;
    domain?: string;
    departments: Array<{
      id: string;
      code: string;
      name: string;
      batches: Array<{
        id: string;
        name: string;
        sections: string[];
      }>;
    }>;
  }>;
}

export const metaApi = {
  getRegistrationOptions: async (): Promise<RegistrationOptions> => {
    const res = await apiClient.get('/meta/registration-options');
    return res.data;
  },

  getBatches: async (params?: { university?: string; department?: string }): Promise<BatchItem[]> => {
    const res = await apiClient.get('/admin/batches', { params });
    return res.data;
  },

  createBatches: async (data: {
    university: string;
    department: string;
    batches: Array<{ name: string; sections: string[]; isActive?: boolean }>;
  }) => {
    const res = await apiClient.post('/admin/batches', data);
    return res.data;
  },

  syncUniversityTree: async (data: {
    university: string;
    departments: Array<{
      department: string;
      batches: Array<{ name: string; sections: string[]; isActive?: boolean }>;
    }>;
  }) => {
    const res = await apiClient.post('/admin/batches/university-tree', data);
    return res.data;
  },

  updateBatch: async (
    id: string,
    data: { sections?: string[]; isActive?: boolean },
  ): Promise<BatchItem> => {
    const res = await apiClient.put(`/admin/batches/${id}`, data);
    return res.data;
  },

  deleteBatch: async (id: string): Promise<{ success: boolean }> => {
    const res = await apiClient.delete(`/admin/batches/${id}`);
    return res.data;
  },
};
