import React, { useEffect, useState } from 'react';
import {
  Building2,
  Plus,
  Search,
  Calendar,
  Globe,
  Trash2,
  Edit2,
  CheckCircle2,
  XCircle,
} from 'lucide-react';
import { Modal } from '../components/common/Modal';
import { universitiesApi, UniversityItem } from '../api/universities.api';

export const UniversitiesPage: React.FC = () => {
  const [unis, setUnis] = useState<UniversityItem[]>([]);
  const [search, setSearch] = useState('');
  const [isLoading, setIsLoading] = useState(true);

  // Modal State
  const [isModalOpen, setIsModalOpen] = useState(false);
  const [editingUni, setEditingUni] = useState<UniversityItem | null>(null);

  // Form Fields
  const [name, setName] = useState('');
  const [code, setCode] = useState('');
  const [domain, setDomain] = useState('');
  const [logoUrl, setLogoUrl] = useState('');
  const [operatingDays, setOperatingDays] = useState<string[]>(['MON', 'TUE', 'WED', 'THU']);
  const [isActive, setIsActive] = useState(true);
  const [isSubmitting, setIsSubmitting] = useState(false);
  const [errorMsg, setErrorMsg] = useState<string | null>(null);

  const fetchUniversities = async () => {
    setIsLoading(true);
    try {
      const data = await universitiesApi.getUniversities();
      setUnis(data);
    } catch (err) {
      console.error('Failed to load universities:', err);
    } finally {
      setIsLoading(false);
    }
  };

  useEffect(() => {
    fetchUniversities();
  }, []);

  const openCreateModal = () => {
    setEditingUni(null);
    setName('');
    setCode('');
    setDomain('');
    setLogoUrl('');
    setOperatingDays(['MON', 'TUE', 'WED', 'THU']);
    setIsActive(true);
    setErrorMsg(null);
    setIsModalOpen(true);
  };

  const openEditModal = (u: UniversityItem) => {
    setEditingUni(u);
    setName(u.name);
    setCode(u.code);
    setDomain(u.domain || '');
    setLogoUrl(u.logoUrl || '');
    setOperatingDays(u.operatingDays || ['MON', 'TUE', 'WED', 'THU']);
    setIsActive(u.isActive);
    setErrorMsg(null);
    setIsModalOpen(true);
  };

  const toggleDay = (day: string) => {
    if (operatingDays.includes(day)) {
      setOperatingDays(operatingDays.filter((d) => d !== day));
    } else {
      setOperatingDays([...operatingDays, day]);
    }
  };

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setIsSubmitting(true);
    setErrorMsg(null);

    try {
      if (editingUni) {
        await universitiesApi.updateUniversity(editingUni.id, {
          name,
          code,
          domain: domain || undefined,
          logoUrl: logoUrl || undefined,
          operatingDays,
          isActive,
        });
      } else {
        await universitiesApi.createUniversity({
          name,
          code,
          domain: domain || undefined,
          logoUrl: logoUrl || undefined,
          operatingDays,
          isActive,
        });
      }
      setIsModalOpen(false);
      fetchUniversities();
    } catch (err: any) {
      console.error('Save failed:', err);
      setErrorMsg(err.response?.data?.message || 'Operation failed');
    } finally {
      setIsSubmitting(false);
    }
  };

  const handleDelete = async (u: UniversityItem) => {
    if (!window.confirm(`Are you sure you want to delete ${u.name} (${u.code})? All child departments and rooms will be cascaded!`)) {
      return;
    }
    try {
      await universitiesApi.deleteUniversity(u.id);
      fetchUniversities();
    } catch (err: any) {
      alert(err.response?.data?.message || 'Failed to delete university');
    }
  };

  const filteredUnis = unis.filter(
    (u) =>
      u.name.toLowerCase().includes(search.toLowerCase()) ||
      u.code.toLowerCase().includes(search.toLowerCase()) ||
      (u.domain && u.domain.toLowerCase().includes(search.toLowerCase())),
  );

  const allDays = ['MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT', 'SUN'];

  return (
    <div className="space-y-6">
      {/* Header */}
      <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4">
        <div>
          <h1 className="text-2xl font-bold tracking-tight text-white flex items-center gap-2">
            <Building2 className="w-6 h-6 text-emerald-400" />
            <span>Institutional Universities</span>
          </h1>
          <p className="text-xs text-slate-400 mt-1">
            Manage multi-tenant university instances, institutional domain rules, and operating class days.
          </p>
        </div>
        <button
          onClick={openCreateModal}
          className="flex items-center gap-2 px-4 py-2.5 bg-emerald-500 hover:bg-emerald-600 text-slate-950 font-semibold rounded-xl text-xs shadow-lg shadow-emerald-500/20 transition-all cursor-pointer"
        >
          <Plus className="w-4 h-4" />
          <span>Provision University</span>
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
            placeholder="Search universities by name, code (UU), or email domain..."
            className="w-full pl-10 pr-4 py-2 bg-slate-950/60 border border-slate-800 rounded-xl text-xs text-slate-100 placeholder-slate-500 focus:outline-none focus:border-emerald-500 transition-colors"
          />
        </div>
        <div className="text-xs text-slate-400 px-2 font-medium">
          Total: <span className="text-emerald-400 font-semibold">{filteredUnis.length}</span>
        </div>
      </div>

      {/* Data Table */}
      <div className="bg-slate-900/60 border border-slate-800/80 rounded-3xl overflow-hidden shadow-xl">
        <div className="overflow-x-auto">
          <table className="w-full text-left text-xs">
            <thead>
              <tr className="border-b border-slate-800 bg-slate-900/80 text-slate-400 font-semibold uppercase tracking-wider text-[11px]">
                <th className="py-3.5 px-5">Code</th>
                <th className="py-3.5 px-5">University Name</th>
                <th className="py-3.5 px-5">Institutional Domain</th>
                <th className="py-3.5 px-5">Operating Schedule</th>
                <th className="py-3.5 px-5 text-center">Departments</th>
                <th className="py-3.5 px-5 text-center">Status</th>
                <th className="py-3.5 px-5 text-right">Actions</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-slate-800/60">
              {filteredUnis.length === 0 ? (
                <tr>
                  <td colSpan={7} className="py-12 text-center text-xs text-slate-500">
                    <Building2 className="w-8 h-8 text-slate-600 mx-auto mb-2" />
                    <p className="font-semibold text-slate-300">No Universities Provisioned</p>
                    <p className="text-slate-500 mt-1 mb-3">
                      Super Admin can create the first institutional university instance manually.
                    </p>
                    <button
                      onClick={openCreateModal}
                      className="px-4 py-2 bg-emerald-500 hover:bg-emerald-600 text-slate-950 font-bold rounded-xl text-xs cursor-pointer shadow-md shadow-emerald-500/20"
                    >
                      + Create University
                    </button>
                  </td>
                </tr>
              ) : (
                filteredUnis.map((u) => (
                  <tr key={u.id} className="hover:bg-slate-800/30 transition-colors">
                    <td className="py-4 px-5">
                      <span className="font-mono font-bold text-xs px-2 py-1 rounded-md bg-emerald-500/10 text-emerald-400 border border-emerald-500/20">
                        {u.code}
                      </span>
                    </td>
                    <td className="py-4 px-5 font-semibold text-slate-100">{u.name}</td>
                    <td className="py-4 px-5 text-slate-300 flex items-center gap-1.5">
                      <Globe className="w-3.5 h-3.5 text-slate-500" />
                      <span>{u.domain || 'N/A'}</span>
                    </td>
                    <td className="py-4 px-5">
                      <div className="flex flex-wrap gap-1">
                        {u.operatingDays?.map((day) => (
                          <span
                            key={day}
                            className="px-1.5 py-0.5 rounded text-[10px] font-semibold bg-slate-800 text-slate-300"
                          >
                            {day}
                          </span>
                        ))}
                      </div>
                    </td>
                    <td className="py-4 px-5 text-center">
                      <span className="px-2.5 py-1 rounded-lg bg-slate-800/80 font-mono font-bold text-slate-200 text-xs">
                        {u.departments?.length ?? 0}
                      </span>
                    </td>
                    <td className="py-4 px-5 text-center">
                      {u.isActive ? (
                        <span className="inline-flex items-center gap-1 px-2 py-0.5 rounded-full bg-emerald-500/10 text-emerald-400 text-xs font-medium border border-emerald-500/20">
                          <CheckCircle2 className="w-3 h-3" /> Active
                        </span>
                      ) : (
                        <span className="inline-flex items-center gap-1 px-2 py-0.5 rounded-full bg-slate-800 text-slate-400 text-xs font-medium">
                          <XCircle className="w-3 h-3" /> Inactive
                        </span>
                      )}
                    </td>
                    <td className="py-4 px-5 text-right">
                      <div className="flex items-center justify-end gap-1.5">
                        <button
                          onClick={() => openEditModal(u)}
                          title="Edit Details"
                          className="p-1.5 text-slate-400 hover:text-emerald-400 hover:bg-slate-800 rounded-lg transition-colors cursor-pointer"
                        >
                          <Edit2 className="w-4 h-4" />
                        </button>
                        <button
                          onClick={() => handleDelete(u)}
                          title="Delete University"
                          className="p-1.5 text-slate-400 hover:text-rose-400 hover:bg-rose-500/10 rounded-lg transition-colors cursor-pointer"
                        >
                          <Trash2 className="w-4 h-4" />
                        </button>
                      </div>
                    </td>
                  </tr>
                ))
              )}
            </tbody>
          </table>
        </div>
      </div>

      {/* Modal: Create / Edit University */}
      <Modal
        isOpen={isModalOpen}
        onClose={() => setIsModalOpen(false)}
        title={editingUni ? `Edit University (${editingUni.code})` : 'Provision New University'}
        subtitle="Configure institutional abbreviation, email domains, and operating class days"
      >
        <form onSubmit={handleSubmit} className="space-y-4">
          {errorMsg && (
            <div className="p-3 bg-rose-500/10 border border-rose-500/20 rounded-xl text-rose-400 text-xs">
              {errorMsg}
            </div>
          )}

          <div>
            <label className="block text-xs font-medium text-slate-300 mb-1">Full University Name *</label>
            <input
              type="text"
              required
              value={name}
              onChange={(e) => setName(e.target.value)}
              placeholder="e.g. Uttara University"
              className="w-full px-3.5 py-2 bg-slate-950/60 border border-slate-800 rounded-xl text-xs text-slate-100 placeholder-slate-500 focus:outline-none focus:border-emerald-500"
            />
          </div>

          <div className="grid grid-cols-2 gap-3">
            <div>
              <label className="block text-xs font-medium text-slate-300 mb-1">Abbreviation Code *</label>
              <input
                type="text"
                required
                value={code}
                onChange={(e) => setCode(e.target.value.toUpperCase())}
                placeholder="e.g. UU"
                className="w-full px-3.5 py-2 bg-slate-950/60 border border-slate-800 rounded-xl text-xs font-mono font-bold text-emerald-400 placeholder-slate-500 focus:outline-none focus:border-emerald-500"
              />
            </div>
            <div>
              <label className="block text-xs font-medium text-slate-300 mb-1">Institutional Domain</label>
              <input
                type="text"
                value={domain}
                onChange={(e) => setDomain(e.target.value)}
                placeholder="e.g. uttara.edu.bd"
                className="w-full px-3.5 py-2 bg-slate-950/60 border border-slate-800 rounded-xl text-xs text-slate-100 placeholder-slate-500 focus:outline-none focus:border-emerald-500"
              />
            </div>
          </div>

          <div>
            <label className="block text-xs font-medium text-slate-300 mb-1">Operating Class Days</label>
            <div className="flex flex-wrap gap-2 pt-1">
              {allDays.map((day) => {
                const isSelected = operatingDays.includes(day);
                return (
                  <button
                    type="button"
                    key={day}
                    onClick={() => toggleDay(day)}
                    className={`px-3 py-1.5 rounded-lg text-xs font-semibold transition-all cursor-pointer ${
                      isSelected
                        ? 'bg-emerald-500 text-slate-950 shadow-sm shadow-emerald-500/20'
                        : 'bg-slate-950/60 text-slate-400 border border-slate-800 hover:border-slate-700'
                    }`}
                  >
                    {day}
                  </button>
                );
              })}
            </div>
          </div>

          <div className="flex items-center gap-2 pt-2">
            <input
              type="checkbox"
              id="isActiveCheck"
              checked={isActive}
              onChange={(e) => setIsActive(e.target.checked)}
              className="w-4 h-4 rounded text-emerald-500 bg-slate-950 border-slate-800 focus:ring-emerald-500"
            />
            <label htmlFor="isActiveCheck" className="text-xs font-medium text-slate-300">
              Institution is currently active
            </label>
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
              {isSubmitting ? 'Saving...' : editingUni ? 'Update University' : 'Create University'}
            </button>
          </div>
        </form>
      </Modal>
    </div>
  );
};
