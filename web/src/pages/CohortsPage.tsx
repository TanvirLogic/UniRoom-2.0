import React, { useEffect, useState, useMemo } from 'react';
import {
  Users2,
  Plus,
  Trash2,
  Save,
  Layers,
  Sparkles,
  CheckCircle2,
  FileCode,
  Search,
  X,
  ArrowLeft,
  RotateCcw,
  Building2,
  PlusCircle,
  GraduationCap,
  AlertCircle,
  RefreshCw,
} from 'lucide-react';
import { ChipInput } from '../components/common/ChipInput';
import { useAuth } from '../context/AuthContext';
import { universitiesApi, DepartmentItem } from '../api/universities.api';
import { metaApi, BatchItem } from '../api/meta.api';

interface BatchRow {
  name: string;
  sections: string[];
}

export const CohortsPage: React.FC = () => {
  const { selectedUniversity } = useAuth();

  // Navigation: defaults directly to the batch directory for immediate visibility
  const [activeTab, setActiveTab] = useState<'directory' | 'add' | 'sync'>('directory');

  // Core Data
  const [depts, setDepts] = useState<DepartmentItem[]>([]);
  const [batches, setBatches] = useState<BatchItem[]>([]);
  const [isLoading, setIsLoading] = useState(false);
  const [isSaving, setIsSaving] = useState(false);
  const [successMsg, setSuccessMsg] = useState<string | null>(null);
  const [errorMsg, setErrorMsg] = useState<string | null>(null);

  // Directory Filters
  const [selectedDept, setSelectedDept] = useState<string>('ALL');
  const [searchQuery, setSearchQuery] = useState<string>('');

  // Add Batches Form State
  const [targetDept, setTargetDept] = useState<string>('CSE');
  const [batchRows, setBatchRows] = useState<BatchRow[]>([
    { name: '', sections: ['A', 'B'] },
  ]);

  // Bulk Tree JSON State
  const defaultSampleJson = JSON.stringify(
    {
      university: selectedUniversity || 'UU',
      departments: [
        {
          department: 'CSE',
          batches: [
            { name: '68', sections: ['A', 'B', 'C'] },
            { name: '69', sections: ['A', 'B'] },
            { name: '70', sections: ['A', 'B', 'C', 'D'] },
          ],
        },
        {
          department: 'EEE',
          batches: [
            { name: '64', sections: ['A', 'B'] },
            { name: '65', sections: ['A', 'B'] },
          ],
        },
      ],
    },
    null,
    2,
  );
  const [treeJson, setTreeJson] = useState<string>(defaultSampleJson);

  // Load Data
  const loadData = async () => {
    setIsLoading(true);
    try {
      const [deptsData, batchesData] = await Promise.all([
        universitiesApi.getDepartments({ university: selectedUniversity || 'UU' }),
        metaApi.getBatches({ university: selectedUniversity || 'UU' }),
      ]);
      setDepts(deptsData);
      setBatches(batchesData);
      if (deptsData.length > 0 && !targetDept) {
        setTargetDept(deptsData[0].code);
      }
    } catch (err: any) {
      console.error('Failed to load batches:', err);
      setErrorMsg(err.response?.data?.message || 'Failed to load batches data');
    } finally {
      setIsLoading(false);
    }
  };

  useEffect(() => {
    loadData();
  }, [selectedUniversity]);

  // Compute batch counts per department for filter pills
  const deptCounts = useMemo(() => {
    const counts: Record<string, number> = {};
    batches.forEach((b) => {
      const code = b.department?.code || '';
      if (code) {
        counts[code] = (counts[code] || 0) + 1;
      }
    });
    return counts;
  }, [batches]);

  // Filter batches for display
  const displayedBatches = useMemo(() => {
    const query = searchQuery.trim().toLowerCase();
    return batches.filter((b) => {
      const matchesDept = selectedDept === 'ALL' || b.department?.code === selectedDept;
      if (!matchesDept) return false;

      if (!query) return true;
      const matchesName = b.name.toLowerCase().includes(query);
      const matchesDeptCode = b.department?.code?.toLowerCase().includes(query);
      const matchesDeptName = b.department?.name?.toLowerCase().includes(query);
      const matchesSection = b.sections.some((s) => s.toLowerCase().includes(query));
      return matchesName || matchesDeptCode || matchesDeptName || matchesSection;
    });
  }, [batches, selectedDept, searchQuery]);

  // Form Row Actions
  const addBatchRow = () => {
    setBatchRows((prev) => [...prev, { name: '', sections: ['A', 'B'] }]);
  };

  const removeBatchRow = (index: number) => {
    setBatchRows((prev) => prev.filter((_, i) => i !== index));
  };

  const updateBatchName = (index: number, name: string) => {
    const updated = [...batchRows];
    updated[index].name = name;
    setBatchRows(updated);
  };

  const updateBatchSections = (index: number, sections: string[]) => {
    const updated = [...batchRows];
    updated[index].sections = sections;
    setBatchRows(updated);
  };

  const openAddFormForDept = (deptCode?: string) => {
    if (deptCode && deptCode !== 'ALL') {
      setTargetDept(deptCode);
    } else if (selectedDept !== 'ALL') {
      setTargetDept(selectedDept);
    } else if (depts.length > 0) {
      setTargetDept(depts[0].code);
    }
    setErrorMsg(null);
    setSuccessMsg(null);
    setActiveTab('add');
  };

  // Submit Batches Form
  const handleSaveBatches = async () => {
    setErrorMsg(null);
    setSuccessMsg(null);

    const invalid = batchRows.some((b) => !b.name.trim() || b.sections.length === 0);
    if (invalid) {
      setErrorMsg('Every batch must have a batch number and at least one active section.');
      return;
    }

    try {
      setIsSaving(true);
      await metaApi.createBatches({
        university: selectedUniversity || 'UU',
        department: targetDept,
        batches: batchRows,
      });

      setSuccessMsg(`Successfully provisioned ${batchRows.length} batch(es) for ${targetDept}!`);
      // Reset form card
      setBatchRows([{ name: '', sections: ['A', 'B'] }]);
      // Switch straight to directory filtered to this department so admin sees results
      setSelectedDept(targetDept);
      setActiveTab('directory');
      await loadData();
    } catch (err: any) {
      console.error('Batch save failed:', err);
      setErrorMsg(err.response?.data?.message || 'Failed to save batches');
    } finally {
      setIsSaving(false);
    }
  };

  // Submit Tree JSON
  const handleSyncTree = async () => {
    setErrorMsg(null);
    setSuccessMsg(null);

    try {
      const parsed = JSON.parse(treeJson);
      setIsSaving(true);
      const res = await metaApi.syncUniversityTree(parsed);
      setSuccessMsg(`University tree synchronized successfully for ${res.university.code}!`);
      setActiveTab('directory');
      setSelectedDept('ALL');
      await loadData();
    } catch (err: any) {
      console.error('Tree sync failed:', err);
      setErrorMsg(err.response?.data?.message || 'Invalid JSON format or sync error');
    } finally {
      setIsSaving(false);
    }
  };

  // Delete Batch
  const handleDeleteBatch = async (b: BatchItem) => {
    if (!window.confirm(`Are you sure you want to delete Batch ${b.name} (${b.department?.code || 'Dept'})?`)) return;
    try {
      await metaApi.deleteBatch(b.id);
      setSuccessMsg(`Batch ${b.name} was successfully removed.`);
      loadData();
    } catch (err: any) {
      setErrorMsg(err.response?.data?.message || 'Failed to delete batch');
    }
  };

  // Toggle Active State
  const handleToggleActive = async (b: BatchItem) => {
    try {
      await metaApi.updateBatch(b.id, { isActive: !b.isActive });
      loadData();
    } catch (err: any) {
      setErrorMsg(err.response?.data?.message || 'Failed to update batch status');
    }
  };

  return (
    <div className="space-y-6">
      {/* Header Banner */}
      <div className="flex flex-col md:flex-row md:items-center justify-between gap-4 p-6 bg-gradient-to-r from-slate-900 via-slate-900/90 to-slate-950 border border-slate-800/80 rounded-3xl shadow-xl">
        <div>
          <div className="flex items-center gap-2 mb-1.5">
            <span className="px-2.5 py-0.5 rounded-full bg-emerald-500/10 text-emerald-400 border border-emerald-500/20 text-xs font-semibold">
              Academic Hierarchy
            </span>
            <span className="text-xs text-slate-500">
              Campus: <span className="text-slate-300 font-semibold">{selectedUniversity || 'All'}</span>
            </span>
          </div>
          <h1 className="text-2xl font-bold tracking-tight text-white flex items-center gap-2.5">
            <Users2 className="w-6 h-6 text-emerald-400" />
            <span>Batches & Sections Management</span>
          </h1>
          <p className="text-xs text-slate-400 mt-1">
            Browse active student cohorts, provision new batch numbers, or synchronize multi-department routines.
          </p>
        </div>

        {/* Tab Switcher */}
        <div className="flex items-center p-1 bg-slate-950/80 border border-slate-800 rounded-2xl shadow-inner self-start md:self-auto">
          <button
            onClick={() => {
              setActiveTab('directory');
              setErrorMsg(null);
              setSuccessMsg(null);
            }}
            className={`flex items-center gap-2 px-3.5 py-2 rounded-xl text-xs font-semibold transition-all cursor-pointer ${
              activeTab === 'directory'
                ? 'bg-emerald-500 text-slate-950 shadow-md shadow-emerald-500/20'
                : 'text-slate-400 hover:text-slate-200'
            }`}
          >
            <Layers className="w-3.5 h-3.5" />
            <span>All Batches</span>
            <span
              className={`text-[10px] px-1.5 py-0.2 rounded-full font-bold ${
                activeTab === 'directory'
                  ? 'bg-slate-950/30 text-slate-950'
                  : 'bg-slate-800 text-slate-300'
              }`}
            >
              {batches.length}
            </span>
          </button>

          <button
            onClick={() => openAddFormForDept()}
            className={`flex items-center gap-2 px-3.5 py-2 rounded-xl text-xs font-semibold transition-all cursor-pointer ${
              activeTab === 'add'
                ? 'bg-emerald-500 text-slate-950 shadow-md shadow-emerald-500/20'
                : 'text-slate-400 hover:text-slate-200'
            }`}
          >
            <PlusCircle className="w-3.5 h-3.5" />
            <span>Add Batches</span>
          </button>

          <button
            onClick={() => {
              setActiveTab('sync');
              setErrorMsg(null);
              setSuccessMsg(null);
            }}
            className={`flex items-center gap-2 px-3.5 py-2 rounded-xl text-xs font-semibold transition-all cursor-pointer ${
              activeTab === 'sync'
                ? 'bg-emerald-500 text-slate-950 shadow-md shadow-emerald-500/20'
                : 'text-slate-400 hover:text-slate-200'
            }`}
          >
            <FileCode className="w-3.5 h-3.5" />
            <span>Bulk Sync (JSON)</span>
          </button>
        </div>
      </div>

      {/* Notifications */}
      {successMsg && (
        <div className="p-4 bg-emerald-500/10 border border-emerald-500/20 rounded-2xl text-emerald-400 text-xs flex items-center justify-between shadow-sm animate-fadeIn">
          <div className="flex items-center gap-2.5">
            <CheckCircle2 className="w-4 h-4 flex-shrink-0" />
            <span className="font-medium">{successMsg}</span>
          </div>
          <button
            onClick={() => setSuccessMsg(null)}
            className="text-emerald-400/70 hover:text-emerald-300 p-1 cursor-pointer"
          >
            <X className="w-3.5 h-3.5" />
          </button>
        </div>
      )}

      {errorMsg && (
        <div className="p-4 bg-rose-500/10 border border-rose-500/20 rounded-2xl text-rose-400 text-xs flex items-center justify-between shadow-sm animate-fadeIn">
          <div className="flex items-center gap-2.5">
            <AlertCircle className="w-4 h-4 flex-shrink-0" />
            <span className="font-medium">{errorMsg}</span>
          </div>
          <button
            onClick={() => setErrorMsg(null)}
            className="text-rose-400/70 hover:text-rose-300 p-1 cursor-pointer"
          >
            <X className="w-3.5 h-3.5" />
          </button>
        </div>
      )}

      {/* TAB 1: ALL BATCHES DIRECTORY (DEFAULT) */}
      {activeTab === 'directory' && (
        <div className="space-y-5">
          {/* Controls Bar: Department Pills + Search + Quick Action */}
          <div className="p-4 bg-slate-900/70 border border-slate-800/80 rounded-3xl space-y-4 shadow-lg">
            <div className="flex flex-col lg:flex-row lg:items-center justify-between gap-4">
              {/* Department Pills */}
              <div className="flex items-center gap-1.5 flex-wrap">
                <span className="text-xs font-semibold text-slate-400 mr-2 flex items-center gap-1.5">
                  <GraduationCap className="w-3.5 h-3.5 text-emerald-400" />
                  <span>Department:</span>
                </span>

                <button
                  onClick={() => setSelectedDept('ALL')}
                  className={`px-3 py-1.5 rounded-xl text-xs font-semibold transition-all cursor-pointer ${
                    selectedDept === 'ALL'
                      ? 'bg-emerald-500 text-slate-950 font-bold shadow-sm shadow-emerald-500/20'
                      : 'bg-slate-950/60 text-slate-400 hover:text-slate-200 border border-slate-800/80'
                  }`}
                >
                  All ({batches.length})
                </button>

                {depts.map((d) => {
                  const count = deptCounts[d.code] || 0;
                  const isSelected = selectedDept === d.code;
                  return (
                    <button
                      key={d.id}
                      onClick={() => setSelectedDept(d.code)}
                      className={`px-3 py-1.5 rounded-xl text-xs font-semibold transition-all cursor-pointer flex items-center gap-1.5 ${
                        isSelected
                          ? 'bg-emerald-500 text-slate-950 font-bold shadow-sm shadow-emerald-500/20'
                          : 'bg-slate-950/60 text-slate-400 hover:text-slate-200 border border-slate-800/80'
                      }`}
                    >
                      <span>{d.code}</span>
                      <span
                        className={`text-[10px] px-1.5 py-0.2 rounded-md ${
                          isSelected
                            ? 'bg-slate-950/20 text-slate-950 font-extrabold'
                            : 'bg-slate-800 text-slate-400'
                        }`}
                      >
                        {count}
                      </span>
                    </button>
                  );
                })}
              </div>

              {/* Right Side: Search & CTA */}
              <div className="flex items-center gap-3 w-full lg:w-auto">
                <div className="relative flex-1 lg:w-64">
                  <Search className="w-3.5 h-3.5 absolute left-3 top-1/2 -translate-y-1/2 text-slate-500" />
                  <input
                    type="text"
                    value={searchQuery}
                    onChange={(e) => setSearchQuery(e.target.value)}
                    placeholder="Search batch or section..."
                    className="w-full pl-8 pr-8 py-2 bg-slate-950/80 border border-slate-800 rounded-xl text-xs text-slate-200 placeholder-slate-600 focus:outline-none focus:border-emerald-500 transition-colors"
                  />
                  {searchQuery && (
                    <button
                      onClick={() => setSearchQuery('')}
                      className="absolute right-2.5 top-1/2 -translate-y-1/2 text-slate-500 hover:text-slate-300"
                    >
                      <X className="w-3 h-3" />
                    </button>
                  )}
                </div>

                <button
                  onClick={() => openAddFormForDept(selectedDept)}
                  className="flex items-center gap-2 px-4 py-2 bg-emerald-500 hover:bg-emerald-600 text-slate-950 font-bold rounded-xl text-xs shadow-md shadow-emerald-500/20 transition-all cursor-pointer whitespace-nowrap"
                >
                  <Plus className="w-4 h-4" />
                  <span>Add Batches</span>
                </button>
              </div>
            </div>
          </div>

          {/* Batches Grid */}
          {isLoading ? (
            <div className="p-12 text-center bg-slate-900/40 border border-slate-800/80 rounded-3xl flex flex-col items-center justify-center gap-3">
              <RefreshCw className="w-6 h-6 text-emerald-400 animate-spin" />
              <p className="text-xs text-slate-400 font-medium">Loading batches telemetry...</p>
            </div>
          ) : displayedBatches.length === 0 ? (
            /* Empty State */
            <div className="p-12 text-center bg-slate-900/40 border border-slate-800/80 rounded-3xl space-y-3">
              <div className="w-12 h-12 rounded-2xl bg-slate-800/60 text-slate-400 flex items-center justify-center mx-auto">
                <Users2 className="w-6 h-6" />
              </div>
              <h3 className="text-sm font-bold text-slate-200">No Batches Found</h3>
              <p className="text-xs text-slate-400 max-w-md mx-auto">
                {searchQuery
                  ? `No batches matching "${searchQuery}". Clear your search or try another keyword.`
                  : selectedDept !== 'ALL'
                  ? `No batches registered yet for ${selectedDept}. Create your first batch in seconds.`
                  : 'No batches configured for this university yet.'}
              </p>
              <div className="pt-2">
                {searchQuery ? (
                  <button
                    onClick={() => setSearchQuery('')}
                    className="px-4 py-2 bg-slate-800 hover:bg-slate-700 text-slate-200 text-xs font-semibold rounded-xl border border-slate-700/60 cursor-pointer"
                  >
                    Clear Search Filter
                  </button>
                ) : (
                  <button
                    onClick={() => openAddFormForDept(selectedDept)}
                    className="px-4 py-2 bg-emerald-500 hover:bg-emerald-600 text-slate-950 text-xs font-bold rounded-xl shadow-md shadow-emerald-500/20 cursor-pointer"
                  >
                    + Add First Batch for {selectedDept === 'ALL' ? 'Department' : selectedDept}
                  </button>
                )}
              </div>
            </div>
          ) : (
            /* Cards Grid */
            <div className="grid grid-cols-1 sm:grid-cols-2 md:grid-cols-3 lg:grid-cols-4 gap-4">
              {displayedBatches.map((b) => (
                <div
                  key={b.id}
                  className="p-5 bg-slate-900/60 border border-slate-800/80 hover:border-slate-700/80 rounded-3xl space-y-4 shadow-lg transition-all group flex flex-col justify-between"
                >
                  <div className="space-y-3">
                    {/* Card Top: Batch Title, Department Pill, Status Toggle */}
                    <div className="flex items-center justify-between gap-2">
                      <div className="flex items-center gap-2">
                        <span className="font-mono font-extrabold text-base text-slate-100">
                          Batch {b.name}
                        </span>
                        <span className="px-2 py-0.5 rounded-lg bg-emerald-500/10 text-emerald-400 border border-emerald-500/20 font-mono text-[11px] font-bold">
                          {b.department?.code || selectedDept}
                        </span>
                      </div>

                      <button
                        onClick={() => handleToggleActive(b)}
                        title="Click to toggle Active / Inactive"
                        className={`text-[10px] font-bold px-2 py-0.5 rounded-full border transition-all cursor-pointer ${
                          b.isActive
                            ? 'bg-emerald-500/10 text-emerald-400 border-emerald-500/20 hover:bg-emerald-500/20'
                            : 'bg-slate-800 text-slate-500 border-slate-700 hover:bg-slate-700'
                        }`}
                      >
                        {b.isActive ? 'ACTIVE' : 'ARCHIVED'}
                      </button>
                    </div>

                    {/* Department Name */}
                    {b.department?.name && (
                      <p className="text-[11px] text-slate-400 truncate" title={b.department.name}>
                        {b.department.name}
                      </p>
                    )}

                    {/* Section Chips */}
                    <div>
                      <div className="flex items-center justify-between mb-1.5">
                        <span className="text-[10px] text-slate-500 uppercase font-bold tracking-wider">
                          Active Sections ({b.sections.length})
                        </span>
                      </div>
                      <div className="flex flex-wrap gap-1.5">
                        {b.sections.map((sec) => (
                          <span
                            key={sec}
                            className="px-2.5 py-1 bg-slate-950/80 text-emerald-300 font-mono text-xs font-bold rounded-lg border border-slate-800/80 shadow-sm"
                          >
                            Sec {sec}
                          </span>
                        ))}
                      </div>
                    </div>
                  </div>

                  {/* Card Bottom: Quick Actions */}
                  <div className="pt-3 border-t border-slate-800/60 flex items-center justify-between text-xs">
                    <span className="text-[10px] text-slate-500 font-medium">
                      {b.department?.university?.code || selectedUniversity || 'UU'}
                    </span>
                    <button
                      onClick={() => handleDeleteBatch(b)}
                      className="text-xs text-slate-500 hover:text-rose-400 flex items-center gap-1 transition-colors cursor-pointer"
                    >
                      <Trash2 className="w-3.5 h-3.5" />
                      <span>Delete</span>
                    </button>
                  </div>
                </div>
              ))}
            </div>
          )}
        </div>
      )}

      {/* TAB 2: ADD BATCHES (INTUITIVE STEP-BY-STEP WORKFLOW) */}
      {activeTab === 'add' && (
        <div className="space-y-6">
          {/* Target Department Selection Bar */}
          <div className="p-6 bg-slate-900/80 border border-slate-800 rounded-3xl shadow-xl flex flex-col md:flex-row md:items-center justify-between gap-5">
            <div className="space-y-1">
              <div className="flex items-center gap-2">
                <button
                  type="button"
                  onClick={() => setActiveTab('directory')}
                  className="text-xs text-slate-400 hover:text-slate-200 flex items-center gap-1.5 font-medium cursor-pointer"
                >
                  <ArrowLeft className="w-3.5 h-3.5" />
                  <span>Back to Batches</span>
                </button>
              </div>
              <h2 className="text-base font-bold text-slate-100">Provision Batches by Department</h2>
              <p className="text-xs text-slate-400">
                Select your academic department below and define one or more batch numbers with their section cohorts.
              </p>
            </div>

            {/* Department Dropdown */}
            <div className="flex items-center gap-3">
              <span className="text-xs font-semibold text-slate-300 whitespace-nowrap">Department:</span>
              <select
                value={targetDept}
                onChange={(e) => setTargetDept(e.target.value)}
                className="px-4 py-2.5 bg-slate-950 border border-slate-700 rounded-xl text-xs font-bold text-emerald-400 focus:outline-none focus:border-emerald-500 cursor-pointer shadow-inner min-w-[200px]"
              >
                {depts.map((d) => (
                  <option key={d.id} value={d.code} className="bg-slate-900 text-slate-200">
                    {d.code} — {d.name}
                  </option>
                ))}
              </select>
            </div>
          </div>

          {/* Action Row */}
          <div className="flex items-center justify-between">
            <div className="flex items-center gap-2">
              <span className="text-xs font-semibold text-slate-300">
                Batch Definitions ({batchRows.length})
              </span>
              <span className="text-xs text-slate-500">— Targeting {targetDept}</span>
            </div>

            <div className="flex items-center gap-3">
              <button
                type="button"
                onClick={addBatchRow}
                className="flex items-center gap-2 px-3.5 py-2 bg-slate-800 hover:bg-slate-700 text-slate-200 rounded-xl text-xs font-semibold border border-slate-700/60 transition-colors cursor-pointer"
              >
                <Plus className="w-4 h-4 text-emerald-400" />
                <span>Add Another Batch</span>
              </button>

              <button
                type="button"
                onClick={handleSaveBatches}
                disabled={isSaving}
                className="flex items-center gap-2 px-5 py-2 bg-emerald-500 hover:bg-emerald-600 disabled:opacity-50 text-slate-950 font-bold rounded-xl text-xs shadow-lg shadow-emerald-500/20 transition-all cursor-pointer"
              >
                <Save className="w-4 h-4" />
                <span>{isSaving ? 'Provisioning...' : `Save Batches for ${targetDept}`}</span>
              </button>
            </div>
          </div>

          {/* Dynamic Batch Cards */}
          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
            {batchRows.map((row, idx) => (
              <div
                key={idx}
                className="p-5 bg-slate-900/60 border border-slate-800/80 rounded-3xl relative space-y-4 shadow-lg group hover:border-slate-700 transition-colors"
              >
                <div className="flex items-center justify-between">
                  <div className="flex items-center gap-2">
                    <span className="w-6 h-6 rounded-lg bg-emerald-500/10 text-emerald-400 text-xs font-bold flex items-center justify-center">
                      #{idx + 1}
                    </span>
                    <span className="text-xs font-semibold text-slate-300">Batch Specification</span>
                  </div>
                  {batchRows.length > 1 && (
                    <button
                      type="button"
                      onClick={() => removeBatchRow(idx)}
                      className="p-1 text-slate-500 hover:text-rose-400 transition-colors"
                      title="Remove Row"
                    >
                      <Trash2 className="w-4 h-4" />
                    </button>
                  )}
                </div>

                <div>
                  <label className="block text-xs font-medium text-slate-400 mb-1">
                    Batch Number / Identifier *
                  </label>
                  <input
                    type="text"
                    required
                    value={row.name}
                    onChange={(e) => updateBatchName(idx, e.target.value)}
                    placeholder="e.g. 68, 69, Spring-26"
                    className="w-full px-3.5 py-2.5 bg-slate-950/80 border border-slate-800 rounded-xl text-xs font-bold text-slate-100 placeholder-slate-600 focus:outline-none focus:border-emerald-500"
                  />
                </div>

                <div>
                  <ChipInput
                    label="Active Sections *"
                    chips={row.sections}
                    onChange={(chips) => updateBatchSections(idx, chips)}
                    placeholder="Type section (A, B, C...) and hit Enter"
                  />
                </div>
              </div>
            ))}
          </div>
        </div>
      )}

      {/* TAB 3: CAMPUS BULK SYNC (HIERARCHICAL JSON) */}
      {activeTab === 'sync' && (
        <div className="p-6 bg-slate-900/60 border border-slate-800/80 rounded-3xl space-y-5 shadow-xl">
          <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4">
            <div>
              <div className="flex items-center gap-2 mb-1">
                <button
                  type="button"
                  onClick={() => setActiveTab('directory')}
                  className="text-xs text-slate-400 hover:text-slate-200 flex items-center gap-1.5 font-medium cursor-pointer"
                >
                  <ArrowLeft className="w-3.5 h-3.5" />
                  <span>Back to Batches</span>
                </button>
              </div>
              <h2 className="text-base font-bold text-slate-100">Whole University Bulk Tree Synchronizer</h2>
              <p className="text-xs text-slate-400 mt-0.5">
                Ingest or synchronize batches and section cohorts across multiple departments in one atomic payload.
              </p>
            </div>

            <div className="flex items-center gap-3">
              <button
                type="button"
                onClick={() => setTreeJson(defaultSampleJson)}
                className="flex items-center gap-2 px-3.5 py-2 bg-slate-800 hover:bg-slate-700 text-slate-200 rounded-xl text-xs font-semibold border border-slate-700/60 transition-colors cursor-pointer"
                title="Reset to clean JSON template"
              >
                <RotateCcw className="w-3.5 h-3.5 text-slate-400" />
                <span>Clean Template</span>
              </button>

              <button
                type="button"
                onClick={handleSyncTree}
                disabled={isSaving}
                className="flex items-center gap-2 px-5 py-2 bg-emerald-500 hover:bg-emerald-600 disabled:opacity-50 text-slate-950 font-bold rounded-xl text-xs shadow-lg shadow-emerald-500/20 transition-all cursor-pointer"
              >
                <Save className="w-4 h-4" />
                <span>{isSaving ? 'Synchronizing...' : 'Sync Full University Tree'}</span>
              </button>
            </div>
          </div>

          <div className="relative">
            <textarea
              rows={16}
              value={treeJson}
              onChange={(e) => setTreeJson(e.target.value)}
              className="w-full p-4 bg-slate-950/90 border border-slate-800 rounded-2xl font-mono text-xs text-emerald-400 focus:outline-none focus:border-emerald-500 leading-relaxed shadow-inner"
            />
          </div>

          <div className="p-4 bg-slate-950/50 border border-slate-800/80 rounded-2xl text-xs text-slate-400 space-y-1">
            <p className="font-semibold text-slate-300">Format Instructions:</p>
            <p>
              • Provide university code in <code className="text-emerald-400 font-mono">"university"</code>.
            </p>
            <p>
              • In <code className="text-emerald-400 font-mono">"departments"</code>, list department code along with an array of batch objects containing <code className="text-emerald-400 font-mono">"name"</code> and an array of <code className="text-emerald-400 font-mono">"sections"</code>.
            </p>
          </div>
        </div>
      )}
    </div>
  );
};
