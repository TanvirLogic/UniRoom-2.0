import React from 'react';
import { NavLink } from 'react-router-dom';
import {
  LayoutDashboard,
  Building2,
  GraduationCap,
  Users2,
  DoorOpen,
  Calendar,
  FileCode2,
  LogOut,
  Sparkles,
} from 'lucide-react';
import { useAuth } from '../../context/AuthContext';

export const Sidebar: React.FC = () => {
  const { user, logout } = useAuth();

  const navItems = [
    { label: 'Dashboard', path: '/', icon: LayoutDashboard },
    { label: 'Universities', path: '/universities', icon: Building2 },
    { label: 'Departments', path: '/departments', icon: GraduationCap },
    { label: 'Batches & Sections', path: '/cohorts', icon: Users2 },
    { label: 'Rooms & Inventory', path: '/rooms', icon: DoorOpen },
    { label: 'Routine & Schedules', path: '/routine', icon: Calendar },
  ];

  return (
    <aside className="w-64 flex flex-col bg-slate-900/90 border-r border-slate-800/80 backdrop-blur-xl h-screen sticky top-0">
      {/* Brand Header */}
      <div className="h-16 flex items-center gap-3 px-6 border-b border-slate-800/80 bg-slate-900/60">
        <div className="w-9 h-9 rounded-xl bg-gradient-to-tr from-emerald-600 to-teal-500 flex items-center justify-center text-white shadow-lg shadow-emerald-500/20">
          <DoorOpen className="w-5 h-5" />
        </div>
        <div>
          <span className="font-bold text-sm tracking-tight text-white flex items-center gap-1.5">
            UniRoom-Live <span className="text-[10px] font-semibold px-1.5 py-0.2 bg-emerald-500/20 text-emerald-400 rounded-md">2.0</span>
          </span>
          <p className="text-[11px] text-slate-400 font-medium">Enterprise Admin</p>
        </div>
      </div>

      {/* Navigation */}
      <div className="flex-1 px-3 py-6 space-y-1 overflow-y-auto">
        <div className="px-3 pb-2 text-[10px] font-semibold text-slate-500 uppercase tracking-wider">
          Main Modules
        </div>
        {navItems.map((item) => (
          <NavLink
            key={item.path}
            to={item.path}
            end={item.path === '/'}
            className={({ isActive }) =>
              `flex items-center gap-3 px-3.5 py-2.5 rounded-xl text-xs font-medium transition-all duration-150 ${
                isActive
                  ? 'bg-emerald-500/10 text-emerald-400 border border-emerald-500/20 font-semibold shadow-sm shadow-emerald-500/10'
                  : 'text-slate-400 hover:text-slate-200 hover:bg-slate-800/60'
              }`
            }
          >
            <item.icon className="w-4 h-4" />
            <span>{item.label}</span>
          </NavLink>
        ))}

        <div className="pt-6 px-3 pb-2 text-[10px] font-semibold text-slate-500 uppercase tracking-wider">
          Developer Tools
        </div>
        <a
          href="http://localhost:3000/api/docs"
          target="_blank"
          rel="noreferrer"
          className="flex items-center justify-between px-3.5 py-2.5 rounded-xl text-xs font-medium text-slate-400 hover:text-slate-200 hover:bg-slate-800/60 transition-colors"
        >
          <div className="flex items-center gap-3">
            <FileCode2 className="w-4 h-4 text-emerald-400" />
            <span>Swagger API Specs</span>
          </div>
          <Sparkles className="w-3.5 h-3.5 text-amber-400" />
        </a>
      </div>

      {/* User Footer */}
      <div className="p-3 border-t border-slate-800/80 bg-slate-900/40">
        <div className="flex items-center justify-between p-2 rounded-xl bg-slate-950/40 border border-slate-800/60">
          <div className="flex items-center gap-2.5 overflow-hidden">
            <div className="w-8 h-8 rounded-lg bg-emerald-500/20 text-emerald-400 flex items-center justify-center font-bold text-xs">
              {user?.fullName?.charAt(0) || 'A'}
            </div>
            <div className="truncate">
              <p className="text-xs font-semibold text-slate-200 truncate">{user?.fullName || 'Super Admin'}</p>
              <p className="text-[10px] text-emerald-400 font-medium">SUPER_ADMIN</p>
            </div>
          </div>
          <button
            onClick={logout}
            title="Log Out"
            className="p-1.5 text-slate-400 hover:text-rose-400 hover:bg-rose-500/10 rounded-lg transition-colors"
          >
            <LogOut className="w-4 h-4" />
          </button>
        </div>
      </div>
    </aside>
  );
};
