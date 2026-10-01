import { apiClient } from './client';

export type RoomStatusType = 'AVAILABLE' | 'RUNNING_CLASS' | 'RESERVED' | 'MAINTENANCE';

export interface RoomItem {
  id: string;
  roomNumber: string;
  floor: number;
  capacity: number;
  currentStatus: RoomStatusType;
  currentCourse?: string;
  currentTeacher?: string;
  currentBatch?: string;
  leaseExpiresAt?: string;
  version: number;
  buildingId: string;
  departmentId: string;
  universityId: string;
  building?: { id: string; name: string; campusName: string };
  department?: { id: string; code: string; name: string };
  university?: { id: string; code: string; name: string };
}

export interface RoomsResponse {
  rooms: RoomItem[];
  stats: {
    total: number;
    available: number;
    runningClass: number;
    reserved: number;
    maintenance: number;
  };
  pagination: {
    page: number;
    limit: number;
    totalPages: number;
    hasNextPage: boolean;
    hasPreviousPage: boolean;
  };
}

export interface BuildingItem {
  id: string;
  name: string;
  campusName: string;
  departmentId: string;
  department?: { id: string; code: string; name: string };
  _count?: { rooms: number };
}

export const roomsApi = {
  getRooms: async (params?: {
    universityId?: string;
    departmentId?: string;
    buildingId?: string;
    status?: RoomStatusType;
    search?: string;
    page?: number;
    limit?: number;
  }): Promise<RoomsResponse> => {
    const res = await apiClient.get('/rooms', { params });
    return res.data;
  },

  getBuildings: async (params?: { departmentId?: string; universityId?: string }): Promise<BuildingItem[]> => {
    const res = await apiClient.get('/buildings', { params });
    return res.data;
  },

  createBuilding: async (data: {
    departmentId: string;
    name: string;
    campusName?: string;
  }): Promise<BuildingItem> => {
    const res = await apiClient.post('/admin/buildings', data);
    return res.data;
  },

  updateBuilding: async (
    id: string,
    data: {
      name?: string;
      campusName?: string;
      departmentId?: string;
    },
  ): Promise<BuildingItem> => {
    const res = await apiClient.put(`/admin/buildings/${id}`, data);
    return res.data;
  },

  deleteBuilding: async (id: string): Promise<any> => {
    const res = await apiClient.delete(`/admin/buildings/${id}`);
    return res.data;
  },

  createRoom: async (data: {
    universityId: string;
    departmentId: string;
    buildingId: string;
    roomNumber: string;
    floor: number;
    capacity: number;
    currentStatus?: RoomStatusType;
  }): Promise<RoomItem> => {
    const res = await apiClient.post('/admin/rooms', data);
    return res.data;
  },

  updateRoomStatus: async (
    id: string,
    data: {
      status: RoomStatusType;
      version: number;
      courseCode?: string;
      teacherInitials?: string;
      batch?: string;
      durationMinutes?: number;
      note?: string;
    },
  ): Promise<RoomItem> => {
    const res = await apiClient.patch(`/rooms/${id}/status`, data);
    return res.data;
  },

  getRoomLogs: async (roomId: string): Promise<any[]> => {
    const res = await apiClient.get(`/rooms/${roomId}/logs`);
    return res.data;
  },
};
