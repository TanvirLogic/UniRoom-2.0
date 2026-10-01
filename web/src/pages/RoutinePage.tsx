import React, { useEffect, useState, useMemo } from 'react';
import {
  Calendar,
  Sparkles,
  Upload,
  FileCode,
  CheckCircle2,
  AlertTriangle,
  Layers,
  Users2,
  DoorOpen,
  GraduationCap,
  Save,
  Search,
  Trash2,
  RefreshCw,
  Plus,
  X,
  FileText,
  KeyRound,
  Eye,
  EyeOff,
  Clock,
  ArrowRight,
  Filter,
  RotateCcw,
} from 'lucide-react';
import { useAuth } from '../context/AuthContext';
import { universitiesApi, DepartmentItem, UniversityItem } from '../api/universities.api';
import {
  schedulesApi,
  RoutineSlotItem,
  IngestRoutineData,
  ValidationReport,
  DayOfWeekType,
  ScheduleSlotRecord,
} from '../api/schedules.api';
import FULL_CSE_DATASET from '../data/cse_fall_2026_full_routine.json';

export const RoutinePage: React.FC = () => {
  const { selectedUniversity } = useAuth();

  // Navigation Tabs: 'ai' | 'json' | 'active'
  const [activeTab, setActiveTab] = useState<'ai' | 'json' | 'active'>(() => {
    return (localStorage.getItem('uniroom_routine_active_tab') as 'ai' | 'json' | 'active') || 'active';
  });

  const handleSelectTab = (tab: 'ai' | 'json' | 'active') => {
    setActiveTab(tab);
    localStorage.setItem('uniroom_routine_active_tab', tab);
  };

  // Hierarchy Scope
  const [depts, setDepts] = useState<DepartmentItem[]>([]);
  const [targetDept, setTargetDept] = useState<string>('CSE');

  // File Upload State (Mode A)
  const [selectedFile, setSelectedFile] = useState<File | null>(null);
  const [customApiKey, setCustomApiKey] = useState<string>('');
  const [showApiKey, setShowApiKey] = useState(false);
  const [isParsing, setIsParsing] = useState(false);

  // JSON Ingestion State (Mode B)
  const [jsonInput, setJsonInput] = useState<string>(() =>
    JSON.stringify(
      {
        university: selectedUniversity || 'UU',
        department: 'CSE',
        semester: 'Fall 2026',
        slots: [],
      },
      null,
      2,
    ),
  );

  // Staging Slots State (persisted so navigating away does not discard staging work)
  const [stagedSlots, setStagedSlots] = useState<RoutineSlotItem[]>(() => {
    try {
      const saved = sessionStorage.getItem('uniroom_staged_slots');
      return saved ? JSON.parse(saved) : [];
    } catch {
      return [];
    }
  });

  useEffect(() => {
    try {
      if (stagedSlots.length > 0) {
        sessionStorage.setItem('uniroom_staged_slots', JSON.stringify(stagedSlots));
      } else {
        sessionStorage.removeItem('uniroom_staged_slots');
      }
    } catch (e) {
      console.warn('Failed to cache staged slots:', e);
    }
  }, [stagedSlots]);

  const [validationReport, setValidationReport] = useState<ValidationReport | null>(null);
  const [isValidating, setIsValidating] = useState(false);
  const [isIngesting, setIsIngesting] = useState(false);

  // Staging Filters
  const [dayFilter, setDayFilter] = useState<string>('ALL');
  const [stagingBatchFilter, setStagingBatchFilter] = useState<string>('ALL');
  const [stagingSectionFilter, setStagingSectionFilter] = useState<string>('ALL');
  const [stagingCourseFilter, setStagingCourseFilter] = useState<string>('ALL');
  const [tableSearch, setTableSearch] = useState<string>('');
  const [showCombinedDetails, setShowCombinedDetails] = useState<boolean>(false);

  // Active Schedules State (Tab 3)
  const [activeSchedules, setActiveSchedules] = useState<ScheduleSlotRecord[]>([]);
  const [isLoadingActive, setIsLoadingActive] = useState(false);
  const [activeDayFilter, setActiveDayFilter] = useState<string>('ALL');
  const [activeBatchFilter, setActiveBatchFilter] = useState<string>('ALL');
  const [activeSectionFilter, setActiveSectionFilter] = useState<string>('ALL');
  const [activeCourseFilter, setActiveCourseFilter] = useState<string>('ALL');
  const [activeSearch, setActiveSearch] = useState<string>('');
  const [deletingSlotId, setDeletingSlotId] = useState<string | null>(null);

  // Global Alerts
  const [successMsg, setSuccessMsg] = useState<string | null>(null);
  const [errorMsg, setErrorMsg] = useState<string | null>(null);

  // Load Department Hierarchy
  const loadDepartments = async () => {
    try {
      const data = await universitiesApi.getDepartments({
        university: selectedUniversity || 'UU',
      });
      setDepts(data);
      if (data.length > 0 && !targetDept) {
        setTargetDept(data[0].code);
      }
    } catch (err) {
      console.error('Failed to load departments:', err);
    }
  };

  useEffect(() => {
    loadDepartments();
  }, [selectedUniversity]);

  // Load Active Schedules immediately and whenever university or department changes
  const loadActiveSchedules = async () => {
    setIsLoadingActive(true);
    try {
      const res = await schedulesApi.getSchedules({
        university: selectedUniversity || 'UU',
        department: targetDept,
      });
      setActiveSchedules(res);
    } catch (err) {
      console.error('Failed to load active schedules:', err);
    } finally {
      setIsLoadingActive(false);
    }
  };

  useEffect(() => {
    loadActiveSchedules();
  }, [selectedUniversity, targetDept]);

  // Run validation whenever staged slots change
  const triggerValidation = async (slotsToValidate: RoutineSlotItem[]) => {
    setIsValidating(true);
    setErrorMsg(null);
    try {
      const report = await schedulesApi.validateRoutine({
        university: selectedUniversity || 'UU',
        department: targetDept,
        slots: slotsToValidate,
      });
      setValidationReport(report);
    } catch (err: any) {
      setErrorMsg(err.response?.data?.message || 'Validation request failed');
    } finally {
      setIsValidating(false);
    }
  };

  useEffect(() => {
    triggerValidation(stagedSlots);
  }, [stagedSlots, targetDept]);

  // Mode A: File Upload AI Parse
  const handleParseFile = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!selectedFile) {
      setErrorMsg('Please select a timetable PDF or image file first.');
      return;
    }

    setIsParsing(true);
    setErrorMsg(null);
    setSuccessMsg(null);

    const formData = new FormData();
    formData.append('file', selectedFile);
    formData.append('university', selectedUniversity || 'UU');
    formData.append('department', targetDept);

    try {
      const res = await schedulesApi.parseRoutineFile(formData, customApiKey || undefined);
      setStagedSlots(res.parsedRoutine.slots || []);
      setValidationReport(res.validationReport);
      setJsonInput(JSON.stringify(res.parsedRoutine, null, 2));
      setSuccessMsg(
        `Successfully extracted ${res.parsedRoutine.slots.length} schedule slots with AI!`,
      );
      handleSelectTab('json');
    } catch (err: any) {
      console.error('AI parse failed:', err);
      setErrorMsg(
        err.response?.data?.message ||
          'Failed to parse file. Verify Gemini API key or use Mode B (JSON Paste).',
      );
    } finally {
      setIsParsing(false);
    }
  };

  // Mode B: Load Full Master Fall 2026 CSE Routine (435 slots)
  const handleLoadFull = () => {
    const payload: IngestRoutineData = {
      university: selectedUniversity || 'UU',
      department: targetDept,
      semester: 'Fall 2026',
      slots: FULL_CSE_DATASET.slots as RoutineSlotItem[],
    };
    setJsonInput(JSON.stringify(payload, null, 2));
    setStagedSlots(FULL_CSE_DATASET.slots as RoutineSlotItem[]);
    setSuccessMsg(
      `Loaded full master Fall 2026 CSE routine (${FULL_CSE_DATASET.slots.length} slots across 10 batches)!`,
    );
  };

  // Mode B: Parse & Apply JSON Input
  const handleApplyJson = () => {
    setErrorMsg(null);
    try {
      const parsed: IngestRoutineData = JSON.parse(jsonInput);
      if (!parsed.slots || !Array.isArray(parsed.slots)) {
        throw new Error("JSON must contain a 'slots' array.");
      }
      setStagedSlots(parsed.slots);
      setSuccessMsg(`Parsed ${parsed.slots.length} slots from JSON editor.`);
    } catch (err: any) {
      setErrorMsg(`JSON Parse Error: ${err.message}`);
    }
  };

  // Remove Slot from Staging
  const handleRemoveSlot = (index: number) => {
    const updated = stagedSlots.filter((_, i) => i !== index);
    setStagedSlots(updated);
  };

  // Auto-resolve room conflicts by overwriting with latest allocation
  const handleAutoResolveCollisions = () => {
    const resolved: RoutineSlotItem[] = [];
    let count = 0;
    for (const s of stagedSlots) {
      const sNorm = s.roomNumber.trim().toLowerCase();
      const sFac = s.facultyCode.trim().toUpperCase();
      const sCourse = s.courseCode.trim().toUpperCase();

      const existingIdx = resolved.findIndex((prev) => {
        if (
          prev.roomNumber.trim().toLowerCase() === sNorm &&
          prev.dayOfWeek === s.dayOfWeek
        ) {
          const overlaps = prev.startTime < s.endTime && prev.endTime > s.startTime;
          if (!overlaps) return false;

          // Preserve legitimate Combined/Joint Section lectures
          const isCombined =
            prev.facultyCode.trim().toUpperCase() === sFac &&
            prev.courseCode.trim().toUpperCase() === sCourse &&
            prev.startTime.trim() === s.startTime.trim() &&
            prev.endTime.trim() === s.endTime.trim() &&
            (prev.batch.trim() !== s.batch.trim() ||
              prev.section.trim().toUpperCase() !== s.section.trim().toUpperCase());

          if (isCombined) {
            return false;
          }

          return true;
        }
        return false;
      });

      if (existingIdx !== -1) {
        resolved[existingIdx] = s;
        count++;
      } else {
        resolved.push(s);
      }
    }

    setStagedSlots(resolved);
    setSuccessMsg(
      `Auto-resolved ${count} conflicting room allocation(s). Overwritten according to allocation!`,
    );
  };

  // Commit and Ingest Routine (Overwrites room infos & allocations cleanly)
  const handleIngestRoutine = async () => {
    if (stagedSlots.length === 0) {
      setErrorMsg('No schedule slots to ingest. Please parse a file or load JSON first.');
      return;
    }

    setIsIngesting(true);
    setErrorMsg(null);
    setSuccessMsg(null);

    try {
      const result = await schedulesApi.ingestRoutine({
        university: selectedUniversity || 'UU',
        department: targetDept,
        semester: 'Fall 2026',
        slots: stagedSlots,
      });

      setSuccessMsg(
        `Routine activated! Overwrote room infos & allocations cleanly for ${result.department} (${result.slotsCreated} slots active, ${result.roomsProvisioned} new rooms created, 0 room conflicts remaining).`,
      );
      sessionStorage.removeItem('uniroom_staged_slots');
      setStagedSlots([]);
      handleSelectTab('active');
      loadActiveSchedules();
    } catch (err: any) {
      console.error('Routine ingestion failed:', err);
      setErrorMsg(err.response?.data?.message || 'Failed to ingest routine');
    } finally {
      setIsIngesting(false);
    }
  };

  // Clear Department Active Routine
  const handleClearDepartmentSchedules = async () => {
    if (
      !window.confirm(
        `Are you sure you want to delete all active schedule slots for Department ${targetDept}?`,
      )
    )
      return;

    try {
      await schedulesApi.deleteDepartmentSchedules(selectedUniversity || 'UU', targetDept);
      setSuccessMsg(`All schedule slots cleared for ${targetDept}.`);
      loadActiveSchedules();
    } catch (err: any) {
      setErrorMsg(err.response?.data?.message || 'Failed to clear schedules');
    }
  };

  // Routine Maintenance: Delete Single Schedule Slot
  const handleDeleteActiveSlot = async (slot: ScheduleSlotRecord) => {
    const desc = `${slot.courseCode} (${slot.dayOfWeek} ${slot.startTime}–${slot.endTime}, Batch ${slot.batch} Sec ${slot.section})`;
    if (!window.confirm(`Are you sure you want to delete schedule slot:\n${desc}?`)) {
      return;
    }

    setDeletingSlotId(slot.id);
    try {
      await schedulesApi.deleteScheduleSlot(slot.id);
      setActiveSchedules((prev) => prev.filter((s) => s.id !== slot.id));
      setSuccessMsg(`Deleted schedule slot: ${desc}`);
    } catch (err: any) {
      setErrorMsg(err.response?.data?.message || 'Failed to delete schedule slot');
    } finally {
      setDeletingSlotId(null);
    }
  };

  // Active Schedules distinct filter options
  const activeBatches = useMemo(() => {
    const set = new Set<string>();
    activeSchedules.forEach((s) => s.batch && set.add(s.batch.trim()));
    return Array.from(set).sort((a, b) => b.localeCompare(a, undefined, { numeric: true }));
  }, [activeSchedules]);

  const activeSections = useMemo(() => {
    const set = new Set<string>();
    activeSchedules
      .filter((s) => activeBatchFilter === 'ALL' || s.batch?.trim() === activeBatchFilter)
      .forEach((s) => s.section && set.add(s.section.trim()));
    return Array.from(set).sort();
  }, [activeSchedules, activeBatchFilter]);

  const activeCourses = useMemo(() => {
    const map = new Map<string, string>();
    activeSchedules.forEach((s) => {
      const code = s.courseCode?.trim();
      if (code && !map.has(code)) {
        map.set(code, s.courseName?.trim() || code);
      }
    });
    return Array.from(map.entries())
      .map(([code, name]) => ({ code, name }))
      .sort((a, b) => a.code.localeCompare(b.code));
  }, [activeSchedules]);

  // Filtered Active Schedules
  const displayedActiveSchedules = useMemo(() => {
    const q = activeSearch.toLowerCase().trim();
    return activeSchedules.filter((slot) => {
      if (activeDayFilter !== 'ALL' && slot.dayOfWeek !== activeDayFilter) return false;
      if (activeBatchFilter !== 'ALL' && slot.batch?.trim() !== activeBatchFilter) return false;
      if (activeSectionFilter !== 'ALL' && slot.section?.trim() !== activeSectionFilter) return false;
      if (activeCourseFilter !== 'ALL' && slot.courseCode?.trim() !== activeCourseFilter) return false;

      if (!q) return true;
      return (
        (slot.room?.roomNumber || '').toLowerCase().includes(q) ||
        slot.courseCode.toLowerCase().includes(q) ||
        slot.courseName.toLowerCase().includes(q) ||
        slot.batch.toLowerCase().includes(q) ||
        slot.section.toLowerCase().includes(q) ||
        slot.facultyInitials.toLowerCase().includes(q)
      );
    });
  }, [
    activeSchedules,
    activeDayFilter,
    activeBatchFilter,
    activeSectionFilter,
    activeCourseFilter,
    activeSearch,
  ]);

  const hasActiveFilters =
    activeDayFilter !== 'ALL' ||
    activeBatchFilter !== 'ALL' ||
    activeSectionFilter !== 'ALL' ||
    activeCourseFilter !== 'ALL' ||
    activeSearch !== '';

  const resetActiveFilters = () => {
    setActiveDayFilter('ALL');
    setActiveBatchFilter('ALL');
    setActiveSectionFilter('ALL');
    setActiveCourseFilter('ALL');
    setActiveSearch('');
  };

  // Staging distinct filter options
  const stagingBatches = useMemo(() => {
    const set = new Set<string>();
    stagedSlots.forEach((s) => s.batch && set.add(s.batch.trim()));
    return Array.from(set).sort((a, b) => b.localeCompare(a, undefined, { numeric: true }));
  }, [stagedSlots]);

  const stagingSections = useMemo(() => {
    const set = new Set<string>();
    stagedSlots
      .filter((s) => stagingBatchFilter === 'ALL' || s.batch?.trim() === stagingBatchFilter)
      .forEach((s) => s.section && set.add(s.section.trim()));
    return Array.from(set).sort();
  }, [stagedSlots, stagingBatchFilter]);

  const stagingCourses = useMemo(() => {
    const map = new Map<string, string>();
    stagedSlots.forEach((s) => {
      const code = s.courseCode?.trim();
      if (code && !map.has(code)) {
        map.set(code, s.courseName?.trim() || code);
      }
    });
    return Array.from(map.entries())
      .map(([code, name]) => ({ code, name }))
      .sort((a, b) => a.code.localeCompare(b.code));
  }, [stagedSlots]);

  // Filter Staged Slots
  const displayedSlots = useMemo(() => {
    const q = tableSearch.toLowerCase().trim();
    return stagedSlots.filter((slot) => {
      if (dayFilter !== 'ALL' && slot.dayOfWeek !== dayFilter) return false;
      if (stagingBatchFilter !== 'ALL' && slot.batch?.trim() !== stagingBatchFilter) return false;
      if (stagingSectionFilter !== 'ALL' && slot.section?.trim() !== stagingSectionFilter) return false;
      if (stagingCourseFilter !== 'ALL' && slot.courseCode?.trim() !== stagingCourseFilter) return false;

      if (!q) return true;
      return (
        slot.roomNumber.toLowerCase().includes(q) ||
        slot.courseCode.toLowerCase().includes(q) ||
        slot.courseName.toLowerCase().includes(q) ||
        slot.batch.toLowerCase().includes(q) ||
        slot.section.toLowerCase().includes(q) ||
        slot.facultyCode.toLowerCase().includes(q)
      );
    });
  }, [
    stagedSlots,
    dayFilter,
    stagingBatchFilter,
    stagingSectionFilter,
    stagingCourseFilter,
    tableSearch,
  ]);

  const hasStagingFilters =
    dayFilter !== 'ALL' ||
    stagingBatchFilter !== 'ALL' ||
    stagingSectionFilter !== 'ALL' ||
    stagingCourseFilter !== 'ALL' ||
    tableSearch !== '';

  const resetStagingFilters = () => {
    setDayFilter('ALL');
    setStagingBatchFilter('ALL');
    setStagingSectionFilter('ALL');
    setStagingCourseFilter('ALL');
    setTableSearch('');
  };

  return (
    <div className="space-y-6">
      {/* Header Banner */}
      <div className="p-6 bg-gradient-to-r from-slate-900 via-slate-900/90 to-slate-950 border border-slate-800/80 rounded-3xl shadow-xl flex flex-col md:flex-row md:items-center justify-between gap-4">
        <div>
          <div className="flex items-center gap-2 mb-1.5">
            <span className="px-2.5 py-0.5 rounded-full bg-emerald-500/10 text-emerald-400 border border-emerald-500/20 text-xs font-semibold">
              Automated Timetable Ingestion Engine
            </span>
            <span className="text-xs text-slate-500">
              Campus: <span className="text-slate-300 font-semibold">{selectedUniversity || 'UU'}</span>
            </span>
          </div>
          <h1 className="text-2xl font-bold tracking-tight text-white flex items-center gap-2.5">
            <Calendar className="w-6 h-6 text-emerald-400" />
            <span>Routine Parser & Ingestion Center</span>
          </h1>
          <p className="text-xs text-slate-400 mt-1">
            Automated AI document parsing, mathematical collision detection, and atomic timetable hydration.
          </p>
        </div>

        {/* Target Department Selector & Ingest CTA */}
        <div className="flex items-center gap-3">
          <div className="flex items-center gap-2 bg-slate-950/80 px-3.5 py-2 rounded-2xl border border-slate-800">
            <GraduationCap className="w-4 h-4 text-emerald-400" />
            <span className="text-xs text-slate-400 font-medium">Department:</span>
            <select
              value={targetDept}
              onChange={(e) => setTargetDept(e.target.value)}
              className="bg-transparent text-xs font-bold text-emerald-400 focus:outline-none cursor-pointer"
            >
              {depts.map((d) => (
                <option key={d.id} value={d.code} className="bg-slate-900 text-slate-200">
                  {d.code} — {d.name}
                </option>
              ))}
            </select>
          </div>

          <button
            onClick={handleIngestRoutine}
            disabled={isIngesting || stagedSlots.length === 0}
            className="flex items-center gap-2 px-5 py-2.5 bg-emerald-500 hover:bg-emerald-600 disabled:opacity-50 text-slate-950 font-bold rounded-xl text-xs shadow-lg shadow-emerald-500/20 transition-all cursor-pointer whitespace-nowrap"
          >
            <Save className="w-4 h-4" />
            <span>{isIngesting ? 'Activating Routine...' : 'Activate Routine'}</span>
          </button>
        </div>
      </div>

      {/* Notifications */}
      {successMsg && (
        <div className="p-4 bg-emerald-500/10 border border-emerald-500/20 rounded-2xl text-emerald-400 text-xs flex items-center justify-between shadow-sm">
          <div className="flex items-center gap-2.5">
            <CheckCircle2 className="w-4 h-4 flex-shrink-0" />
            <span className="font-medium">{successMsg}</span>
          </div>
          <button onClick={() => setSuccessMsg(null)} className="text-emerald-400/70 hover:text-emerald-300">
            <X className="w-3.5 h-3.5" />
          </button>
        </div>
      )}

      {errorMsg && (
        <div className="p-4 bg-rose-500/10 border border-rose-500/20 rounded-2xl text-rose-400 text-xs flex items-center justify-between shadow-sm">
          <div className="flex items-center gap-2.5">
            <AlertTriangle className="w-4 h-4 flex-shrink-0" />
            <span className="font-medium">{errorMsg}</span>
          </div>
          <button onClick={() => setErrorMsg(null)} className="text-rose-400/70 hover:text-rose-300">
            <X className="w-3.5 h-3.5" />
          </button>
        </div>
      )}

      {/* Mode Navigation Tabs */}
      <div className="flex items-center p-1 bg-slate-900 border border-slate-800 rounded-2xl w-fit">
        <button
          onClick={() => handleSelectTab('json')}
          className={`flex items-center gap-2 px-4 py-2 rounded-xl text-xs font-semibold transition-all cursor-pointer ${
            activeTab === 'json'
              ? 'bg-emerald-500 text-slate-950 shadow-sm shadow-emerald-500/20'
              : 'text-slate-400 hover:text-slate-200'
          }`}
        >
          <FileCode className="w-4 h-4" />
          <span>JSON & External AI Ingest</span>
        </button>

        <button
          onClick={() => handleSelectTab('ai')}
          className={`flex items-center gap-2 px-4 py-2 rounded-xl text-xs font-semibold transition-all cursor-pointer ${
            activeTab === 'ai'
              ? 'bg-emerald-500 text-slate-950 shadow-sm shadow-emerald-500/20'
              : 'text-slate-400 hover:text-slate-200'
          }`}
        >
          <Sparkles className="w-4 h-4" />
          <span>Automated AI File Parser</span>
        </button>

        <button
          onClick={() => handleSelectTab('active')}
          className={`flex items-center gap-2 px-4 py-2 rounded-xl text-xs font-semibold transition-all cursor-pointer ${
            activeTab === 'active'
              ? 'bg-emerald-500 text-slate-950 shadow-sm shadow-emerald-500/20'
              : 'text-slate-400 hover:text-slate-200'
          }`}
        >
          <Calendar className="w-4 h-4" />
          <span>Active Schedules ({activeSchedules.length})</span>
        </button>
      </div>

      {/* TAB 1: AI FILE PARSER (MODE A) */}
      {/* TAB 1: AI & DETERMINISTIC FILE PARSER (MODE A) */}
      {activeTab === 'ai' && (
        <div className="p-6 bg-slate-900/60 border border-slate-800/80 rounded-3xl space-y-5 shadow-xl">
          <div className="space-y-1">
            <div className="flex flex-wrap items-center gap-2.5">
              <h3 className="text-base font-bold text-slate-100 flex items-center gap-2">
                <Sparkles className="w-4 h-4 text-emerald-400" />
                <span>Automated Timetable Parser Engine</span>
              </h3>
              <span className="px-2.5 py-0.5 bg-emerald-500/10 text-emerald-400 text-[11px] font-bold rounded-lg border border-emerald-500/20">
                ⚡ Python Table Extractor + AI Fallback
              </span>
            </div>
            <p className="text-xs text-slate-400">
              Upload your official timetable PDF or image. Official PDF tables are processed by our high-precision deterministic Python extractor (100% exact, $0 API cost). Photos and scans automatically fall back to Gemini 2.0 Flash AI.
            </p>
          </div>

          <form onSubmit={handleParseFile} className="space-y-4">
            {/* File Dropzone */}
            <div className="border-2 border-dashed border-slate-800 hover:border-emerald-500/50 rounded-3xl p-8 text-center transition-all bg-slate-950/40">
              <input
                type="file"
                id="routineFile"
                accept=".pdf,image/*"
                onChange={(e) => {
                  if (e.target.files && e.target.files[0]) {
                    setSelectedFile(e.target.files[0]);
                  }
                }}
                className="hidden"
              />
              <label htmlFor="routineFile" className="cursor-pointer space-y-2 block">
                <div className="w-12 h-12 rounded-2xl bg-emerald-500/10 text-emerald-400 flex items-center justify-center mx-auto">
                  <Upload className="w-6 h-6" />
                </div>
                <div className="text-xs font-bold text-slate-200">
                  {selectedFile ? selectedFile.name : 'Click to select or drag and drop routine file'}
                </div>
                <p className="text-[11px] text-slate-500">
                  Supports PDF documents, PNG, JPG, or screenshot pages (up to 20MB)
                </p>
              </label>
            </div>

            {/* Optional Custom Gemini Key */}
            <div className="p-4 bg-slate-950/60 border border-slate-800/80 rounded-2xl space-y-2">
              <div className="flex items-center justify-between">
                <div className="flex items-center gap-2 text-xs font-semibold text-slate-300">
                  <KeyRound className="w-3.5 h-3.5 text-amber-400" />
                  <span>Google Gemini API Key (Optional AI Fallback)</span>
                </div>
                <span className="text-[10px] text-slate-500">Not needed for PDFs parsed with Python</span>
              </div>
              <div className="relative">
                <input
                  type={showApiKey ? 'text' : 'password'}
                  value={customApiKey}
                  onChange={(e) => setCustomApiKey(e.target.value)}
                  placeholder="Paste your Gemini Flash API key (if parsing scanned photos)..."
                  className="w-full px-3.5 py-2 pr-10 bg-slate-900 border border-slate-800 rounded-xl text-xs text-slate-200 placeholder-slate-600 focus:outline-none focus:border-emerald-500"
                />
                <button
                  type="button"
                  onClick={() => setShowApiKey(!showApiKey)}
                  className="absolute right-3 top-1/2 -translate-y-1/2 text-slate-500 hover:text-slate-300"
                >
                  {showApiKey ? <EyeOff className="w-3.5 h-3.5" /> : <Eye className="w-3.5 h-3.5" />}
                </button>
              </div>
            </div>

            <div className="flex justify-end">
              <button
                type="submit"
                disabled={isParsing || !selectedFile}
                className="flex items-center gap-2 px-6 py-2.5 bg-emerald-500 hover:bg-emerald-600 disabled:opacity-50 text-slate-950 font-bold rounded-xl text-xs shadow-lg shadow-emerald-500/20 cursor-pointer transition-all"
              >
                {isParsing ? (
                  <>
                    <RefreshCw className="w-4 h-4 animate-spin" />
                    <span>Extracting Timetable Slots...</span>
                  </>
                ) : (
                  <>
                    <Sparkles className="w-4 h-4" />
                    <span>Extract & Parse Timetable</span>
                  </>
                )}
              </button>
            </div>
          </form>
        </div>
      )}

      {/* TAB 2: JSON & PROMPT INGEST (MODE B) */}
      {activeTab === 'json' && (
        <div className="p-6 bg-slate-900/60 border border-slate-800/80 rounded-3xl space-y-4 shadow-xl">
          <div className="flex flex-col lg:flex-row lg:items-center justify-between gap-4">
            <div>
              <h3 className="text-base font-bold text-slate-100 flex items-center gap-2">
                <FileCode className="w-4 h-4 text-emerald-400" />
                <span>JSON Routine Ingestion & Direct Activation</span>
              </h3>
              <p className="text-xs text-slate-400">
                Paste structured routine JSON, or load the pre-parsed official Fall 2026 CSE department dataset.
              </p>
            </div>

            <div className="flex flex-wrap items-center gap-2.5">
              <button
                type="button"
                onClick={handleLoadFull}
                className="flex items-center gap-2 px-3.5 py-2 bg-emerald-500/10 hover:bg-emerald-500/20 text-emerald-400 font-bold rounded-xl text-xs border border-emerald-500/20 transition-all cursor-pointer"
                title="Load complete 435 slots from Fall 2026 5-page PDF"
              >
                <Sparkles className="w-3.5 h-3.5" />
                <span>Load Master (435 Slots)</span>
              </button>

              <button
                type="button"
                onClick={handleApplyJson}
                className="flex items-center gap-2 px-4 py-2 bg-slate-800 hover:bg-slate-700 text-slate-200 font-semibold rounded-xl text-xs border border-slate-700/60 transition-all cursor-pointer"
              >
                <span>Apply to Staging Table</span>
                <ArrowRight className="w-3.5 h-3.5" />
              </button>
            </div>
          </div>

          <div className="relative">
            <textarea
              rows={12}
              value={jsonInput}
              onChange={(e) => setJsonInput(e.target.value)}
              className="w-full p-4 bg-slate-950/90 border border-slate-800 rounded-2xl font-mono text-xs text-emerald-400 focus:outline-none focus:border-emerald-500 leading-relaxed shadow-inner"
            />
          </div>
        </div>
      )}

      {/* TAB 3: CURRENT ACTIVE SCHEDULES */}
      {activeTab === 'active' && (
        <div className="p-6 bg-slate-900/60 border border-slate-800/80 rounded-3xl space-y-5 shadow-xl">
          <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4">
            <div>
              <h3 className="text-base font-bold text-slate-100 flex items-center gap-2">
                <Calendar className="w-4 h-4 text-emerald-400" />
                <span>Active Master Timetable for {targetDept}</span>
              </h3>
              <p className="text-xs text-slate-400">
                Live schedule slots currently stored in PostgreSQL powering real-time room occupancy and student calendars.
              </p>
            </div>

            <div className="flex items-center gap-2.5">
              <button
                onClick={loadActiveSchedules}
                disabled={isLoadingActive}
                className="p-2 bg-slate-800 text-slate-300 rounded-xl hover:bg-slate-700 cursor-pointer"
                title="Refresh schedule slots"
              >
                <RefreshCw className={`w-3.5 h-3.5 ${isLoadingActive ? 'animate-spin' : ''}`} />
              </button>
              {activeSchedules.length > 0 && (
                <button
                  onClick={handleClearDepartmentSchedules}
                  className="px-3.5 py-1.5 bg-rose-500/10 hover:bg-rose-500/20 text-rose-400 rounded-xl text-xs font-semibold border border-rose-500/20 cursor-pointer"
                >
                  Clear All Schedules
                </button>
              )}
            </div>
          </div>

          {/* Dedicated Filter & Maintenance Bar */}
          <div className="p-4 bg-slate-950/70 border border-slate-800/80 rounded-2xl space-y-3.5">
            {/* Weekday Selector Pills */}
            <div className="flex items-center gap-1.5 flex-wrap">
              <span className="text-xs font-semibold text-slate-400 mr-1 flex items-center gap-1.5">
                <Clock className="w-3.5 h-3.5 text-emerald-400" />
                <span>Day:</span>
              </span>
              {['ALL', 'MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT', 'SUN'].map((d) => (
                <button
                  key={d}
                  onClick={() => setActiveDayFilter(d)}
                  className={`px-3 py-1 rounded-xl text-xs font-semibold cursor-pointer transition-all ${
                    activeDayFilter === d
                      ? 'bg-emerald-500 text-slate-950 font-bold'
                      : 'bg-slate-900 text-slate-400 hover:text-slate-200 border border-slate-800'
                  }`}
                >
                  {d}
                </button>
              ))}
            </div>

            {/* Batch, Section, Course, and Search Controls */}
            <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-2.5 pt-1">
              {/* Batch Filter */}
              <div className="flex items-center gap-2 bg-slate-900 px-3 py-1.5 rounded-xl border border-slate-800">
                <Users2 className="w-3.5 h-3.5 text-emerald-400 flex-shrink-0" />
                <span className="text-xs text-slate-400">Batch:</span>
                <select
                  value={activeBatchFilter}
                  onChange={(e) => {
                    setActiveBatchFilter(e.target.value);
                    setActiveSectionFilter('ALL');
                  }}
                  className="bg-transparent text-xs font-bold text-slate-200 focus:outline-none cursor-pointer w-full"
                >
                  <option value="ALL" className="bg-slate-900 text-slate-200">
                    All Batches ({activeBatches.length})
                  </option>
                  {activeBatches.map((b) => (
                    <option key={b} value={b} className="bg-slate-900 text-slate-200">
                      Batch {b}
                    </option>
                  ))}
                </select>
              </div>

              {/* Section Filter */}
              <div className="flex items-center gap-2 bg-slate-900 px-3 py-1.5 rounded-xl border border-slate-800">
                <Layers className="w-3.5 h-3.5 text-blue-400 flex-shrink-0" />
                <span className="text-xs text-slate-400">Section:</span>
                <select
                  value={activeSectionFilter}
                  onChange={(e) => setActiveSectionFilter(e.target.value)}
                  className="bg-transparent text-xs font-bold text-slate-200 focus:outline-none cursor-pointer w-full"
                >
                  <option value="ALL" className="bg-slate-900 text-slate-200">
                    All Sections ({activeSections.length})
                  </option>
                  {activeSections.map((sec) => (
                    <option key={sec} value={sec} className="bg-slate-900 text-slate-200">
                      Section {sec}
                    </option>
                  ))}
                </select>
              </div>

              {/* Course Filter */}
              <div className="flex items-center gap-2 bg-slate-900 px-3 py-1.5 rounded-xl border border-slate-800">
                <FileText className="w-3.5 h-3.5 text-purple-400 flex-shrink-0" />
                <span className="text-xs text-slate-400">Course:</span>
                <select
                  value={activeCourseFilter}
                  onChange={(e) => setActiveCourseFilter(e.target.value)}
                  className="bg-transparent text-xs font-bold text-slate-200 focus:outline-none cursor-pointer w-full truncate"
                >
                  <option value="ALL" className="bg-slate-900 text-slate-200">
                    All Courses ({activeCourses.length})
                  </option>
                  {activeCourses.map((c) => (
                    <option key={c.code} value={c.code} className="bg-slate-900 text-slate-200">
                      {c.code} - {c.name}
                    </option>
                  ))}
                </select>
              </div>

              {/* Search Filter */}
              <div className="relative">
                <Search className="w-3.5 h-3.5 absolute left-3 top-1/2 -translate-y-1/2 text-slate-500" />
                <input
                  type="text"
                  value={activeSearch}
                  onChange={(e) => setActiveSearch(e.target.value)}
                  placeholder="Search room, teacher, course..."
                  className="w-full pl-8 pr-3 py-1.5 bg-slate-900 border border-slate-800 rounded-xl text-xs text-slate-200 placeholder-slate-500 focus:outline-none focus:border-emerald-500"
                />
              </div>
            </div>

            {/* Filter Summary & Quick Reset */}
            <div className="flex items-center justify-between pt-1 text-xs">
              <span className="text-slate-400">
                Showing <span className="text-emerald-400 font-bold">{displayedActiveSchedules.length}</span> of{' '}
                <span className="text-slate-200 font-bold">{activeSchedules.length}</span> active slots
              </span>

              {hasActiveFilters && (
                <button
                  onClick={resetActiveFilters}
                  className="flex items-center gap-1.5 px-2.5 py-1 bg-slate-800 hover:bg-slate-700 text-slate-300 rounded-lg text-[11px] font-semibold transition-all cursor-pointer"
                >
                  <RotateCcw className="w-3 h-3 text-amber-400" />
                  <span>Reset Filters</span>
                </button>
              )}
            </div>
          </div>

          {/* Active Schedules Table */}
          {isLoadingActive ? (
            <div className="py-12 text-center text-xs text-slate-500">
              <RefreshCw className="w-6 h-6 animate-spin mx-auto mb-2 text-emerald-400" />
              Loading active department schedules...
            </div>
          ) : activeSchedules.length === 0 ? (
            <div className="py-12 text-center text-xs text-slate-500 bg-slate-950/40 rounded-2xl border border-slate-800/60">
              No active routine slots found for {targetDept}. Ingest a routine above to activate.
            </div>
          ) : displayedActiveSchedules.length === 0 ? (
            <div className="py-12 text-center text-xs text-slate-400 bg-slate-950/40 rounded-2xl border border-slate-800/60 space-y-2">
              <p>No active schedule slots match the selected filters.</p>
              <button
                onClick={resetActiveFilters}
                className="px-3 py-1 bg-slate-800 hover:bg-slate-700 text-emerald-400 rounded-xl text-xs font-semibold cursor-pointer"
              >
                Reset Filters
              </button>
            </div>
          ) : (
            <div className="overflow-x-auto max-h-[600px]">
              <table className="w-full text-left text-xs">
                <thead className="sticky top-0 bg-slate-900 border-b border-slate-800 text-slate-400 font-semibold uppercase text-[11px]">
                  <tr>
                    <th className="py-2.5 px-3">Day</th>
                    <th className="py-2.5 px-3">Time Window</th>
                    <th className="py-2.5 px-3">Physical Room</th>
                    <th className="py-2.5 px-3">Course</th>
                    <th className="py-2.5 px-3">Batch & Sec</th>
                    <th className="py-2.5 px-3">Teacher</th>
                    <th className="py-2.5 px-3 text-right">Maintenance</th>
                  </tr>
                </thead>
                <tbody className="divide-y divide-slate-800/60">
                  {displayedActiveSchedules.map((slot) => (
                    <tr key={slot.id} className="hover:bg-slate-800/30 transition-colors">
                      <td className="py-2.5 px-3 font-bold text-emerald-400">{slot.dayOfWeek}</td>
                      <td className="py-2.5 px-3 font-mono text-slate-300">
                        {slot.startTime} – {slot.endTime}
                      </td>
                      <td className="py-2.5 px-3 font-semibold text-slate-200">
                        {slot.room?.roomNumber || 'Room'}
                      </td>
                      <td className="py-2.5 px-3 text-slate-300">
                        <span className="font-mono text-emerald-400 font-bold">{slot.courseCode}</span>{' '}
                        <span>{slot.courseName}</span>
                      </td>
                      <td className="py-2.5 px-3 font-bold text-slate-200">
                        Batch {slot.batch} ({slot.section})
                      </td>
                      <td className="py-2.5 px-3 font-mono font-bold text-amber-400">
                        {slot.facultyInitials}
                      </td>
                      <td className="py-2.5 px-3 text-right">
                        <button
                          type="button"
                          onClick={() => handleDeleteActiveSlot(slot)}
                          disabled={deletingSlotId === slot.id}
                          className="text-slate-500 hover:text-rose-400 p-1 cursor-pointer transition-colors disabled:opacity-50"
                          title="Delete slot from active routine"
                        >
                          {deletingSlotId === slot.id ? (
                            <RefreshCw className="w-3.5 h-3.5 animate-spin text-rose-400" />
                          ) : (
                            <Trash2 className="w-3.5 h-3.5" />
                          )}
                        </button>
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          )}
        </div>
      )}

      {/* STAGING & HEALTH DIAGNOSTICS SECTION (Visible for Ingestion) */}
      {activeTab !== 'active' && (
        <div className="space-y-5">
          {/* Diagnostic Metrics Cards */}
          <div className="grid grid-cols-2 sm:grid-cols-3 lg:grid-cols-6 gap-3">
            <div className="p-4 bg-slate-900/60 border border-slate-800 rounded-2xl space-y-1">
              <span className="text-[11px] font-medium text-slate-400">Staged Slots</span>
              <p className="text-xl font-bold text-slate-100">{stagedSlots.length}</p>
            </div>

            <div className="p-4 bg-slate-900/60 border border-slate-800 rounded-2xl space-y-1">
              <span className="text-[11px] font-medium text-slate-400">Distinct Rooms</span>
              <p className="text-xl font-bold text-emerald-400">
                {validationReport?.distinctRooms.length ?? 0}
              </p>
            </div>

            <div className="p-4 bg-slate-900/60 border border-slate-800 rounded-2xl space-y-1">
              <span className="text-[11px] font-medium text-slate-400">Target Batches</span>
              <p className="text-xl font-bold text-blue-400">
                {validationReport?.distinctBatches.length ?? 0}
              </p>
            </div>

            <div className="p-4 bg-slate-900/60 border border-slate-800 rounded-2xl space-y-1">
              <span className="text-[11px] font-medium text-slate-400">Faculty Count</span>
              <p className="text-xl font-bold text-purple-400">
                {validationReport?.distinctFaculty.length ?? 0}
              </p>
            </div>

            <div className="p-4 bg-slate-900/60 border border-slate-800 rounded-2xl space-y-1">
              <span className="text-[11px] font-medium text-slate-400">Joint Classes</span>
              <p className="text-xl font-bold text-cyan-400">
                {validationReport?.combinedSections?.length ?? 0}
              </p>
            </div>

            <div
              className={`p-4 border rounded-2xl space-y-1 ${
                validationReport?.collisions && validationReport.collisions.length > 0
                  ? 'bg-rose-500/10 border-rose-500/30 text-rose-400'
                  : 'bg-emerald-500/10 border-emerald-500/30 text-emerald-400'
              }`}
            >
              <span className="text-[11px] font-medium opacity-80">Collision Warnings</span>
              <p className="text-xl font-bold">
                {validationReport?.collisions.length ?? 0}
              </p>
            </div>
          </div>

          {/* Joint / Combined Sections Informational Box */}
          {validationReport?.combinedSections && validationReport.combinedSections.length > 0 && (
            <div className="p-4 bg-blue-500/10 border border-blue-500/20 rounded-2xl space-y-3">
              <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-2">
                <div className="flex items-center gap-2 text-xs font-bold text-blue-400">
                  <Layers className="w-4 h-4 flex-shrink-0" />
                  <span>
                    Joint / Combined Section Lectures Identified ({validationReport.combinedSections.length}):
                  </span>
                </div>
                <button
                  type="button"
                  onClick={() => setShowCombinedDetails(!showCombinedDetails)}
                  className="flex items-center gap-1.5 px-3 py-1 bg-blue-500/20 hover:bg-blue-500/30 text-blue-300 font-semibold rounded-xl text-xs transition-all cursor-pointer border border-blue-500/30"
                >
                  <span>{showCombinedDetails ? 'Hide Details' : 'View Joint Classes'}</span>
                </button>
              </div>
              <p className="text-[11px] text-slate-400">
                These lectures are held simultaneously in the same room for multiple sections with the same faculty (e.g. GED02221 for Batch 67B & 67C in Room 0006 with MRN). They are recognized as valid joint lectures and preserved for all sections.
              </p>
              {showCombinedDetails && (
                <div className="grid grid-cols-1 md:grid-cols-2 gap-2 pt-1 max-h-56 overflow-y-auto pr-1">
                  {validationReport.combinedSections.map((cs, idx) => (
                    <div
                      key={idx}
                      className="p-2.5 bg-slate-900/80 border border-slate-800 rounded-xl text-xs flex items-start justify-between gap-2"
                    >
                      <div>
                        <div className="font-semibold text-slate-200">
                          <span className="text-emerald-400 font-mono font-bold mr-1.5">{cs.courseCode}</span>
                          <span>{cs.courseName}</span>
                        </div>
                        <div className="text-[11px] text-slate-400 mt-0.5">
                          {cs.dayOfWeek} {cs.startTime}–{cs.endTime} • Room <span className="text-slate-200 font-semibold">{cs.roomNumber}</span> • Faculty <span className="text-amber-400 font-mono font-semibold">{cs.facultyCode}</span>
                        </div>
                      </div>
                      <div className="flex flex-wrap gap-1 text-[10px] items-center justify-end">
                        {cs.sections.map((sec, sIdx) => (
                          <span
                            key={sIdx}
                            className="px-2 py-0.5 bg-blue-500/10 text-blue-300 border border-blue-500/20 rounded-md font-semibold whitespace-nowrap"
                          >
                            {sec}
                          </span>
                        ))}
                      </div>
                    </div>
                  ))}
                </div>
              )}
            </div>
          )}

          {/* Collision Alerts Box */}
          {validationReport?.collisions && validationReport.collisions.length > 0 && (
            <div className="p-4 bg-amber-500/10 border border-amber-500/20 rounded-2xl space-y-3">
              <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-2">
                <div className="flex items-center gap-2 text-xs font-bold text-amber-400">
                  <AlertTriangle className="w-4 h-4 flex-shrink-0" />
                  <span>
                    Timetable Allocation Conflicts Detected ({validationReport.collisions.length}):
                  </span>
                </div>
                <button
                  type="button"
                  onClick={handleAutoResolveCollisions}
                  className="flex items-center gap-1.5 px-3 py-1.5 bg-amber-500 hover:bg-amber-400 text-slate-950 font-bold rounded-xl text-xs transition-all cursor-pointer shadow-sm shadow-amber-500/20"
                >
                  <Sparkles className="w-3.5 h-3.5" />
                  <span>Auto-Resolve (Overwrite to Allocation)</span>
                </button>
              </div>
              <p className="text-[11px] text-slate-400">
                Commit & Activate automatically overwrites previous room allocations cleanly. You can also click the button above to auto-resolve overlapping room double-bookings directly in staging.
              </p>
              <ul className="text-xs text-amber-300 space-y-1 list-disc list-inside max-h-40 overflow-y-auto pr-2">
                {validationReport.collisions.map((c, idx) => (
                  <li key={idx}>{c.message}</li>
                ))}
              </ul>
            </div>
          )}

          {/* Interactive Staging Table */}
          <div className="p-6 bg-slate-900/60 border border-slate-800/80 rounded-3xl space-y-4 shadow-xl">
            {/* Filter Controls Header */}
            <div className="p-4 bg-slate-950/70 border border-slate-800/80 rounded-2xl space-y-3.5">
              {/* Day Filter Pills */}
              <div className="flex items-center gap-1.5 flex-wrap">
                <span className="text-xs font-semibold text-slate-400 mr-1 flex items-center gap-1.5">
                  <Clock className="w-3.5 h-3.5 text-emerald-400" />
                  <span>Day:</span>
                </span>
                {['ALL', 'MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT', 'SUN'].map((d) => (
                  <button
                    key={d}
                    onClick={() => setDayFilter(d)}
                    className={`px-3 py-1 rounded-xl text-xs font-semibold cursor-pointer transition-all ${
                      dayFilter === d
                        ? 'bg-emerald-500 text-slate-950 font-bold'
                        : 'bg-slate-900 text-slate-400 hover:text-slate-200 border border-slate-800'
                    }`}
                  >
                    {d}
                  </button>
                ))}
              </div>

              {/* Batch, Section, Course, and Search Controls */}
              <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-2.5 pt-1">
                {/* Batch Filter */}
                <div className="flex items-center gap-2 bg-slate-900 px-3 py-1.5 rounded-xl border border-slate-800">
                  <Users2 className="w-3.5 h-3.5 text-emerald-400 flex-shrink-0" />
                  <span className="text-xs text-slate-400">Batch:</span>
                  <select
                    value={stagingBatchFilter}
                    onChange={(e) => {
                      setStagingBatchFilter(e.target.value);
                      setStagingSectionFilter('ALL');
                    }}
                    className="bg-transparent text-xs font-bold text-slate-200 focus:outline-none cursor-pointer w-full"
                  >
                    <option value="ALL" className="bg-slate-900 text-slate-200">
                      All Batches ({stagingBatches.length})
                    </option>
                    {stagingBatches.map((b) => (
                      <option key={b} value={b} className="bg-slate-900 text-slate-200">
                        Batch {b}
                      </option>
                    ))}
                  </select>
                </div>

                {/* Section Filter */}
                <div className="flex items-center gap-2 bg-slate-900 px-3 py-1.5 rounded-xl border border-slate-800">
                  <Layers className="w-3.5 h-3.5 text-blue-400 flex-shrink-0" />
                  <span className="text-xs text-slate-400">Section:</span>
                  <select
                    value={stagingSectionFilter}
                    onChange={(e) => setStagingSectionFilter(e.target.value)}
                    className="bg-transparent text-xs font-bold text-slate-200 focus:outline-none cursor-pointer w-full"
                  >
                    <option value="ALL" className="bg-slate-900 text-slate-200">
                      All Sections ({stagingSections.length})
                    </option>
                    {stagingSections.map((sec) => (
                      <option key={sec} value={sec} className="bg-slate-900 text-slate-200">
                        Section {sec}
                      </option>
                    ))}
                  </select>
                </div>

                {/* Course Filter */}
                <div className="flex items-center gap-2 bg-slate-900 px-3 py-1.5 rounded-xl border border-slate-800">
                  <FileText className="w-3.5 h-3.5 text-purple-400 flex-shrink-0" />
                  <span className="text-xs text-slate-400">Course:</span>
                  <select
                    value={stagingCourseFilter}
                    onChange={(e) => setStagingCourseFilter(e.target.value)}
                    className="bg-transparent text-xs font-bold text-slate-200 focus:outline-none cursor-pointer w-full truncate"
                  >
                    <option value="ALL" className="bg-slate-900 text-slate-200">
                      All Courses ({stagingCourses.length})
                    </option>
                    {stagingCourses.map((c) => (
                      <option key={c.code} value={c.code} className="bg-slate-900 text-slate-200">
                        {c.code} - {c.name}
                      </option>
                    ))}
                  </select>
                </div>

                {/* Table Search Filter */}
                <div className="relative">
                  <Search className="w-3.5 h-3.5 absolute left-3 top-1/2 -translate-y-1/2 text-slate-500" />
                  <input
                    type="text"
                    value={tableSearch}
                    onChange={(e) => setTableSearch(e.target.value)}
                    placeholder="Filter by room, course, teacher..."
                    className="w-full pl-8 pr-3 py-1.5 bg-slate-900 border border-slate-800 rounded-xl text-xs text-slate-200 placeholder-slate-500 focus:outline-none focus:border-emerald-500"
                  />
                </div>
              </div>

              {/* Filter Summary & Quick Reset */}
              <div className="flex items-center justify-between pt-1 text-xs">
                <span className="text-slate-400">
                  Showing <span className="text-emerald-400 font-bold">{displayedSlots.length}</span> of{' '}
                  <span className="text-slate-200 font-bold">{stagedSlots.length}</span> staged slots
                </span>

                {hasStagingFilters && (
                  <button
                    onClick={resetStagingFilters}
                    className="flex items-center gap-1.5 px-2.5 py-1 bg-slate-800 hover:bg-slate-700 text-slate-300 rounded-lg text-[11px] font-semibold transition-all cursor-pointer"
                  >
                    <RotateCcw className="w-3 h-3 text-amber-400" />
                    <span>Reset Filters</span>
                  </button>
                )}
              </div>
            </div>

            {/* Staging Data Grid */}
            <div className="overflow-x-auto max-h-[500px]">
              <table className="w-full text-left text-xs">
                <thead className="sticky top-0 bg-slate-900 border-b border-slate-800 text-slate-400 font-semibold uppercase text-[11px]">
                  <tr>
                    <th className="py-2.5 px-3">Day</th>
                    <th className="py-2.5 px-3">Time Window</th>
                    <th className="py-2.5 px-3">Physical Room</th>
                    <th className="py-2.5 px-3">Course</th>
                    <th className="py-2.5 px-3">Batch & Sec</th>
                    <th className="py-2.5 px-3">Teacher</th>
                    <th className="py-2.5 px-3 text-right">Action</th>
                  </tr>
                </thead>
                <tbody className="divide-y divide-slate-800/60">
                  {displayedSlots.map((slot, idx) => (
                    <tr key={idx} className="hover:bg-slate-800/30 transition-colors">
                      <td className="py-2.5 px-3 font-bold text-emerald-400">{slot.dayOfWeek}</td>
                      <td className="py-2.5 px-3 font-mono text-slate-300">
                        {slot.startTime} – {slot.endTime}
                      </td>
                      <td className="py-2.5 px-3 font-semibold text-slate-200">
                        {slot.roomNumber}
                      </td>
                      <td className="py-2.5 px-3 text-slate-300">
                        <span className="font-mono text-emerald-400 font-bold">{slot.courseCode}</span>{' '}
                        <span>{slot.courseName}</span>
                      </td>
                      <td className="py-2.5 px-3 font-bold text-slate-200">
                        Batch {slot.batch} ({slot.section})
                      </td>
                      <td className="py-2.5 px-3 font-mono font-bold text-amber-400">
                        {slot.facultyCode}
                      </td>
                      <td className="py-2.5 px-3 text-right">
                        <button
                          type="button"
                          onClick={() => handleRemoveSlot(idx)}
                          className="text-slate-500 hover:text-rose-400 p-1 cursor-pointer transition-colors"
                          title="Remove slot"
                        >
                          <Trash2 className="w-3.5 h-3.5" />
                        </button>
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>

            {/* Bottom Ingestion Summary Bar */}
            <div className="pt-4 border-t border-slate-800/80 flex flex-col sm:flex-row sm:items-center justify-between gap-3 text-xs">
              <span className="text-slate-400">
                Displaying <span className="text-slate-200 font-bold">{displayedSlots.length}</span> of{' '}
                <span className="text-slate-200 font-bold">{stagedSlots.length}</span> staged slots for{' '}
                <span className="text-emerald-400 font-bold">{targetDept}</span>
              </span>

              <button
                type="button"
                onClick={handleIngestRoutine}
                disabled={isIngesting || stagedSlots.length === 0}
                className="flex items-center gap-2 px-5 py-2.5 bg-emerald-500 hover:bg-emerald-600 disabled:opacity-50 text-slate-950 font-bold rounded-xl text-xs shadow-lg shadow-emerald-500/20 cursor-pointer transition-all self-end sm:self-auto"
              >
                <Save className="w-4 h-4" />
                <span>{isIngesting ? 'Activating Routine...' : 'Commit & Activate Routine'}</span>
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
};
