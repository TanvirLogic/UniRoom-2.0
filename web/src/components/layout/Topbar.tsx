import React, { useEffect, useState } from 'react';
import { Building2, Activity, Globe } from 'lucide-react';
import { useAuth } from '../../context/AuthContext';
import { universitiesApi, UniversityItem } from '../../api/universities.api';

export const Topbar: React.FC = () => {
  const { selectedUniversity, setSelectedUniversity } = useAuth();
  const [unis, setUnis] = useState<UniversityItem[]>([]);
  const [isBackendOnline, setIsBackendOnline] = useState<boolean>(true);

  useEffect(() => {
    const fetchUnis = async () => {
      try {
        const data = await universitiesApi.getUniversities();
        setUnis(data);
        setIsBackendOnline(true);
      } catch (err) {
        console.error('Failed to load universities in topbar:', err);
        setIsBackendOnline(false);
      }
    };
    fetchUnis();
  }, []);

  return (
    <header className="h-16 border-b border-slate-800/80 bg-slate-900/60 backdrop-blur-md px-6 flex items-center justify-between sticky top-0 z-30">
      {/* University Context Switcher */}
      <div className="flex items-center gap-3">
        <div className="flex items-center gap-2 px-3 py-1.5 bg-slate-950/60 border border-slate-800 rounded-xl">
          <Building2 className="w-4 h-4 text-emerald-400" />
          <span className="text-xs text-slate-400 font-medium">Tenant Context:</span>
          <select
            value={selectedUniversity}
            onChange={(e) => setSelectedUniversity(e.target.value)}
            className="bg-transparent border-none text-xs font-semibold text-slate-200 focus:outline-none cursor-pointer"
          >
            <option value="" className="bg-slate-900 text-slate-200">
              All Universities
            </option>
            {unis.map((u) => (
              <option key={u.id} value={u.code} className="bg-slate-900 text-slate-200">
                {u.name} ({u.code})
              </option>
            ))}
          </select>
        </div>
      </div>

      {/* Right Tools & Status Pill */}
      <div className="flex items-center gap-4">
        {/* Backend API Health Indicator */}
        <div className="flex items-center gap-2 px-3 py-1 rounded-full bg-slate-950/60 border border-slate-800">
          <span
            className={`w-2 h-2 rounded-full ${
              isBackendOnline ? 'bg-emerald-400 animate-pulse' : 'bg-rose-500'
            }`}
          />
          <span className="text-[11px] font-medium text-slate-400 flex items-center gap-1">
            <Activity className="w-3 h-3 text-slate-500" />
            API Core: <span className={isBackendOnline ? 'text-emerald-400 font-semibold' : 'text-rose-400'}>
              {isBackendOnline ? 'Online (:3000)' : 'Offline'}
            </span>
          </span>
        </div>

        {/* Global Multi-Tenant Indicator */}
        <div className="hidden md:flex items-center gap-1.5 text-xs text-slate-400">
          <Globe className="w-3.5 h-3.5 text-slate-500" />
          <span>Multi-Tenant DB Isolated</span>
        </div>
      </div>
    </header>
  );
};
