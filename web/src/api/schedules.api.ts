import { apiClient } from './client';

export type DayOfWeekType = 'MON' | 'TUE' | 'WED' | 'THU' | 'FRI' | 'SAT' | 'SUN';

export interface RoutineSlotItem {
  dayOfWeek: DayOfWeekType;
  startTime: string; // "08:45"
  endTime: string;   // "10:05"
  roomNumber: string;
  buildingName?: string;
  campusName?: string;
  courseCode: string;
  courseName: string;
  batch: string;
  section: string;
  facultyCode: string;
}

export interface IngestRoutineData {
  university: string;
  department: string;
  semester?: string;
  slots: RoutineSlotItem[];
}

export interface CollisionItem {
  type: 'ROOM_DOUBLE_BOOKED' | 'FACULTY_CONFLICT' | 'SECTION_OVERLAP';
  severity: 'CRITICAL' | 'WARNING';
  entity: string;
  day: DayOfWeekType;
  timeWindow: string;
  conflictingSlots: RoutineSlotItem[];
  message: string;
}

export interface CombinedSectionInfo {
  dayOfWeek: DayOfWeekType;
  startTime: string;
  endTime: string;
  roomNumber: string;
  facultyCode: string;
  courseCode: string;
  courseName: string;
  sections: string[];
}

export interface ValidationReport {
  isValid: boolean;
  totalSlots: number;
  distinctRooms: string[];
  distinctBatches: string[];
  distinctFaculty: string[];
  distinctCourses: string[];
  collisions: CollisionItem[];
  unmappedRooms: string[];
  combinedSections?: CombinedSectionInfo[];
}

export interface IngestResult {
  success: boolean;
  university: string;
  department: string;
  slotsCreated: number;
  roomsProvisioned: number;
  timestamp: string;
}

export interface ScheduleSlotRecord {
  id: string;
  departmentId: string;
  roomId: string;
  facultyInitials: string;
  batch: string;
  section: string;
  courseCode: string;
  courseName: string;
  dayOfWeek: DayOfWeekType;
  startTime: string;
  endTime: string;
  isActive: boolean;
  room?: {
    id: string;
    roomNumber: string;
    floor: number;
    capacity: number;
    currentStatus: string;
  };
  department?: {
    id: string;
    code: string;
    name: string;
  };
}

export const schedulesApi = {
  /**
   * Parse a timetable PDF using the backend Python parsing engine
   */
  parseRoutineFile: async (
    formData: FormData,
  ): Promise<{ parsedRoutine: IngestRoutineData; validationReport: ValidationReport }> => {
    const headers: Record<string, string> = {
      'Content-Type': 'multipart/form-data',
    };
    const res = await apiClient.post('/admin/schedules/parse-file', formData, { headers });
    return res.data;
  },

  /**
   * Validate routine payload for schema and collision detection
   */
  validateRoutine: async (data: IngestRoutineData): Promise<ValidationReport> => {
    const res = await apiClient.post('/admin/schedules/validate', data);
    return res.data;
  },

  /**
   * Ingest and activate routine atomically
   */
  ingestRoutine: async (data: IngestRoutineData): Promise<IngestResult> => {
    const res = await apiClient.post('/admin/schedules/ingest', data);
    return res.data;
  },

  /**
   * Query active schedules
   */
  getSchedules: async (params?: {
    university?: string;
    department?: string;
    batch?: string;
    section?: string;
    courseCode?: string;
    dayOfWeek?: DayOfWeekType;
    roomId?: string;
    facultyCode?: string;
  }): Promise<ScheduleSlotRecord[]> => {
    const res = await apiClient.get('/schedules', { params });
    return res.data;
  },

  /**
   * Clear all schedule slots for a department
   */
  deleteDepartmentSchedules: async (university: string, department: string) => {
    const res = await apiClient.delete('/admin/schedules', {
      params: { university, department },
    });
    return res.data;
  },

  /**
   * Delete a single schedule slot (Routine Maintenance)
   */
  deleteScheduleSlot: async (id: string): Promise<{ success: boolean; message: string }> => {
    const res = await apiClient.delete(`/admin/schedules/slot/${id}`);
    return res.data;
  },
};
