import React, { useEffect, useState } from 'react';
import { useNavigate } from 'react-router-dom';
import {
  GraduationCap,
  Plus,
  Search,
  Building2,
  DoorOpen,
  Calendar,
  Trash2,
  Edit2,
  Users,
} from 'lucide-react';
import { Modal } from '../components/common/Modal';
import { useAuth } from '../context/AuthContext';
import { universitiesApi, DepartmentItem, UniversityItem } from '../api/universities.api';

export const DepartmentsPage: React.FC = () => {
  const navigate = useNavigate();
  const { selectedUniversity } = useAuth();

  const [depts, setDepts] = useState<DepartmentItem[]>([]);
  const [unis, setUnis] = useState<UniversityItem[]>([]);
  const [search, setSearch] = useState('');
  const [isLoading, setIsLoading] = useState(true);

  // Modal State
  const [isModalOpen, setIsModalOpen] = useState(false);
  const [editingDept, setEditingDept] = useState<DepartmentItem | null>(null);

  // Form Fields
  const [uniCode, setUniCode] = useState('UU');
  const [name, setName] = useState('');
  const [code, setCode] = useState('');
  const [isSubmitting, setIsSubmitting] = useState(false);
  const [errorMsg, setErrorMsg] = useState<string | null>(null);

  const fetchInitialData = async () => {
    setIsLoading(true);
    try {
      const [deptsData, unisData] = await Promise.all([
        universitiesApi.getDepartments({ university: selectedUniversity || undefined }),
        universitiesApi.getUniversities(),
      ]);
      setDepts(deptsData);
      setUnis(unisData);
      if (unisData.length > 0 && !selectedUniversity) {
        setUniCode(unisData[0].code);
      } else if (selectedUniversity) {
        setUniCode(selectedUniversity);
      }
    } catch (err) {
      console.error('Failed to load departments data:', err);
    } finally {
      setIsLoading(false);
    }
  };

  useEffect(() => {
    fetchInitialData();
  }, [selectedUniversity]);

  const openCreateModal = () => {
    setEditingDept(null);
    setName('');
    setCode('');
    setUniCode(selectedUniversity || unis[0]?.code || 'UU');
    setErrorMsg(null);
    setIsModalOpen(true);
  };

  const openEditModal = (d: DepartmentItem) => {
    setEditingDept(d);
    setName(d.name);
    setCode(d.code);
    setUniCode(d.university?.code || 'UU');
    setErrorMsg(null);
    setIsModalOpen(true);
  };

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setIsSubmitting(true);
    setErrorMsg(null);

    try {
      if (editingDept) {
        await universitiesApi.updateDepartment(editingDept.id, {
          name,
          code,
          university: uniCode,
        });
      } else {
        await universitiesApi.createDepartment({
          university: uniCode,
          code,
          name,
        });
      }
      setIsModalOpen(false);
      fetchInitialData();
    } catch (err: any) {
      console.error('Department save failed:', err);
      setErrorMsg(err.response?.data?.message || 'Operation failed');
    } finally {
      setIsSubmitting(false);
    }
  };

  const handleDelete = async (d: DepartmentItem) => {
    if (!window.confirm(`Delete department ${d.name} (${d.code})? Associated rooms and batches will be deleted!`)) {
      return;
    }
    try {
      await universitiesApi.deleteDepartment(d.id);
      fetchInitialData();
    } catch (err: any) {
      alert(err.response?.data?.message || 'Failed to delete department');
    }
  };

  const filteredDepts = depts.filter(
    (d) =>
      d.name.toLowerCase().includes(search.toLowerCase()) ||
      d.code.toLowerCase().includes(search.toLowerCase()),
  );

  return (
    <div className="space-y-6">
      {/* Header */}
      <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4">
        <div>
          <h1 className="text-2xl font-bold tracking-tight text-white flex items-center gap-2">
            <GraduationCap className="w-6 h-6 text-emerald-400" />
            <span>Academic Departments</span>
          </h1>
          <p className="text-xs text-slate-400 mt-1">
            Organize departments, manage physical building affiliations, and monitor routine capacity.
          </p>
        </div>
        <button
          onClick={openCreateModal}
          className="flex items-center gap-2 px-4 py-2.5 bg-emerald-500 hover:bg-emerald-600 text-slate-950 font-semibold rounded-xl text-xs shadow-lg shadow-emerald-500/20 transition-all cursor-pointer"
        >
          <Plus className="w-4 h-4" />
          <span>New Department</span>
        </button>
      </div>

      {/* Filter / Search Bar */}
      <div className="flex items-center gap-3 p-3 bg-slate-900/60 border border-slate-800/80 rounded-2xl">
        <div className="relative flex-1">
          <Search className="w-4 h-4 text-slate-500 absolute left-3.5 top-1/2 -translate-y-1/2" />
          <input
            type="text"
            value={search}
            onChange={(e) => setSearch(e.target.value)}
            placeholder="Search departments by name or short code (e.g. CSE, Electrical)..."
            className="w-full pl-10 pr-4 py-2 bg-slate-950/60 border border-slate-800 rounded-xl text-xs text-slate-100 placeholder-slate-500 focus:outline-none focus:border-emerald-500 transition-colors"
          />
        </div>
        <div className="text-xs text-slate-400 px-2 font-medium">
          Total: <span className="text-emerald-400 font-semibold">{filteredDepts.length}</span>
        </div>
      </div>

      {/* Departments Grid */}
      {filteredDepts.length === 0 && !isLoading ? (
        <div className="py-12 text-center text-xs text-slate-500 bg-slate-950/40 rounded-2xl border border-slate-800/60 space-y-3">
          <GraduationCap className="w-8 h-8 text-slate-600 mx-auto" />
          <p className="font-semibold text-slate-300">No Academic Departments Found</p>
          <p className="text-slate-500">
            Super Admin can create departments manually to begin structuring academic cohorts.
          </p>
          <button
            onClick={openCreateModal}
            className="px-4 py-2 bg-emerald-500 hover:bg-emerald-600 text-slate-950 font-bold rounded-xl text-xs cursor-pointer shadow-md shadow-emerald-500/20"
          >
            + Create Department
          </button>
        </div>
      ) : (
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
          {filteredDepts.map((d) => (
            <div
              key={d.id}
              className="p-5 bg-slate-900/60 border border-slate-800/80 rounded-3xl flex flex-col justify-between hover:border-slate-700 transition-all group"
            >
              <div>
                <div className="flex items-start justify-between">
                  <div>
                    <span className="font-mono font-bold text-sm px-2.5 py-1 rounded-lg bg-emerald-500/10 text-emerald-400 border border-emerald-500/20 inline-block mb-2">
                      {d.code}
                    </span>
                    <h3 className="text-base font-bold text-slate-100 leading-snug">{d.name}</h3>
                  </div>
                  <div className="flex items-center gap-1 opacity-80 group-hover:opacity-100 transition-opacity">
                    <button
                      onClick={() => openEditModal(d)}
                      title="Edit Department"
                      className="p-1.5 text-slate-400 hover:text-emerald-400 hover:bg-slate-800 rounded-lg transition-colors cursor-pointer"
                    >
                      <Edit2 className="w-3.5 h-3.5" />
                    </button>
                    <button
                      onClick={() => handleDelete(d)}
                      title="Delete Department"
                      className="p-1.5 text-slate-400 hover:text-rose-400 hover:bg-rose-500/10 rounded-lg transition-colors cursor-pointer"
                    >
                      <Trash2 className="w-3.5 h-3.5" />
                    </button>
                  </div>
                </div>

                <div className="flex items-center gap-2 mt-2 text-xs text-slate-400">
                  <Building2 className="w-3.5 h-3.5 text-slate-500" />
                  <span>{d.university?.name || 'Institutional Campus'} ({d.university?.code || 'UNI'})</span>
                </div>
              </div>

              {/* Stats Row */}
              <div className="grid grid-cols-3 gap-2 mt-5 pt-4 border-t border-slate-800/60 text-center">
                <div className="p-2 bg-slate-950/40 rounded-xl">
                  <div className="text-[10px] text-slate-400 flex items-center justify-center gap-1">
                    <DoorOpen className="w-3 h-3 text-emerald-400" />
                    <span>Rooms</span>
                  </div>
                  <div className="text-sm font-bold text-slate-200 mt-0.5">{d._count?.rooms ?? 0}</div>
                </div>

                <div className="p-2 bg-slate-950/40 rounded-xl">
                  <div className="text-[10px] text-slate-400 flex items-center justify-center gap-1">
                    <Calendar className="w-3 h-3 text-blue-400" />
                    <span>Routines</span>
                  </div>
                  <div className="text-sm font-bold text-slate-200 mt-0.5">{d._count?.scheduleSlots ?? 0}</div>
                </div>

                <div className="p-2 bg-slate-950/40 rounded-xl">
                  <div className="text-[10px] text-slate-400 flex items-center justify-center gap-1">
                    <Users className="w-3 h-3 text-purple-400" />
                    <span>Users</span>
                  </div>
                  <div className="text-sm font-bold text-slate-200 mt-0.5">{d._count?.users ?? 0}</div>
                </div>
              </div>
            </div>
          ))}
        </div>
      )}

      {/* Modal: Create / Edit Department */}
      <Modal
        isOpen={isModalOpen}
        onClose={() => setIsModalOpen(false)}
        title={editingDept ? `Edit Department (${editingDept.code})` : 'Create Academic Department'}
        subtitle="Specify university affiliation, department code, and descriptive title"
      >
        <form onSubmit={handleSubmit} className="space-y-4">
          {errorMsg && (
            <div className="p-3 bg-rose-500/10 border border-rose-500/20 rounded-xl text-rose-400 text-xs">
              {errorMsg}
            </div>
          )}

          {unis.length === 0 ? (
            <div className="p-4 bg-amber-500/10 border border-amber-500/20 rounded-xl text-amber-300 text-xs space-y-2.5">
              <p className="font-semibold">No Universities Configured</p>
              <p className="text-slate-400">
                You must create a University first before creating a Department.
              </p>
              <button
                type="button"
                onClick={() => {
                  setIsModalOpen(false);
                  navigate('/universities');
                }}
                className="px-3.5 py-1.5 bg-amber-500 hover:bg-amber-400 text-slate-950 font-bold rounded-xl text-xs transition-colors cursor-pointer"
              >
                Go to Universities Page →
              </button>
            </div>
          ) : (
            <div>
              <label className="block text-xs font-medium text-slate-300 mb-1">Parent University *</label>
              <select
                value={uniCode}
                onChange={(e) => setUniCode(e.target.value)}
                className="w-full px-3.5 py-2 bg-slate-950/60 border border-slate-800 rounded-xl text-xs text-slate-100 focus:outline-none focus:border-emerald-500 cursor-pointer"
              >
                {unis.map((u) => (
                  <option key={u.id} value={u.code} className="bg-slate-900">
                    {u.name} ({u.code})
                  </option>
                ))}
              </select>
            </div>
          )}

          <div className="grid grid-cols-3 gap-3">
            <div>
              <label className="block text-xs font-medium text-slate-300 mb-1">Short Code *</label>
              <input
                type="text"
                required
                value={code}
                onChange={(e) => setCode(e.target.value.toUpperCase())}
                placeholder="e.g. CSE"
                className="w-full px-3.5 py-2 bg-slate-950/60 border border-slate-800 rounded-xl text-xs font-mono font-bold text-emerald-400 placeholder-slate-500 focus:outline-none focus:border-emerald-500"
              />
            </div>
            <div className="col-span-2">
              <label className="block text-xs font-medium text-slate-300 mb-1">Department Name *</label>
              <input
                type="text"
                required
                value={name}
                onChange={(e) => setName(e.target.value)}
                placeholder="e.g. Computer Science & Engineering"
                className="w-full px-3.5 py-2 bg-slate-950/60 border border-slate-800 rounded-xl text-xs text-slate-100 placeholder-slate-500 focus:outline-none focus:border-emerald-500"
              />
            </div>
          </div>

          <div className="flex items-center justify-end gap-2.5 pt-4 border-t border-slate-800">
            <button
              type="button"
              onClick={() => setIsModalOpen(false)}
              className="px-4 py-2 bg-slate-800 hover:bg-slate-700 text-slate-300 rounded-xl text-xs font-medium transition-colors cursor-pointer"
            >
              Cancel
            </button>
            <button
              type="submit"
              disabled={isSubmitting}
              className="px-4 py-2 bg-emerald-500 hover:bg-emerald-600 disabled:opacity-50 text-slate-950 font-semibold rounded-xl text-xs shadow-md shadow-emerald-500/20 transition-all cursor-pointer"
            >
              {isSubmitting ? 'Saving...' : editingDept ? 'Update Department' : 'Create Department'}
            </button>
          </div>
        </form>
      </Modal>
    </div>
  );
};
