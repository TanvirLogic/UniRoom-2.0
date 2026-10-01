import React, { useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { DoorOpen, ShieldCheck, Lock, Mail, ArrowRight, Sparkles, CheckCircle2 } from 'lucide-react';
import { useAuth } from '../context/AuthContext';

export const LoginPage: React.FC = () => {
  const navigate = useNavigate();
  const { login } = useAuth();

  const [email, setEmail] = useState('admin@uttara.edu.bd');
  const [password, setPassword] = useState('Password123!');
  const [isLoading, setIsLoading] = useState(false);
  const [errorMsg, setErrorMsg] = useState<string | null>(null);

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setErrorMsg(null);
    setIsLoading(true);

    try {
      await login(email, password);
      navigate('/');
    } catch (err: any) {
      console.error('Login failed:', err);
      const msg =
        err.response?.data?.message ||
        err.message ||
        'Invalid credentials or network failure';
      setErrorMsg(msg);
    } finally {
      setIsLoading(false);
    }
  };

  const fillQuickCredentials = () => {
    setEmail('admin@uttara.edu.bd');
    setPassword('Password123!');
  };

  return (
    <div className="min-h-screen w-full flex bg-slate-950 text-slate-100 font-sans">
      {/* Left Feature Showcase (Desktop) */}
      <div className="hidden lg:flex flex-col justify-between w-1/2 p-12 bg-gradient-to-br from-slate-900 via-slate-950 to-slate-900 border-r border-slate-800/80 relative overflow-hidden">
        {/* Background glow orbs */}
        <div className="absolute top-1/4 left-1/4 w-96 h-96 bg-emerald-500/10 rounded-full blur-3xl pointer-events-none" />
        <div className="absolute bottom-1/4 right-1/4 w-96 h-96 bg-teal-500/10 rounded-full blur-3xl pointer-events-none" />

        {/* Top Logo */}
        <div className="flex items-center gap-3 relative z-10">
          <div className="w-10 h-10 rounded-xl bg-gradient-to-tr from-emerald-600 to-teal-500 flex items-center justify-center text-white shadow-xl shadow-emerald-500/20">
            <DoorOpen className="w-6 h-6" />
          </div>
          <div>
            <h1 className="font-bold text-base tracking-tight text-white flex items-center gap-2">
              UniRoom-Live <span className="text-xs px-2 py-0.5 bg-emerald-500/20 text-emerald-400 rounded-md font-semibold">2.0</span>
            </h1>
            <p className="text-xs text-slate-400">Classroom & Routine Orchestration Platform</p>
          </div>
        </div>

        {/* Center Pitch */}
        <div className="relative z-10 space-y-6 max-w-lg">
          <div className="inline-flex items-center gap-2 px-3 py-1.5 rounded-full bg-emerald-500/10 border border-emerald-500/20 text-emerald-400 text-xs font-medium">
            <Sparkles className="w-3.5 h-3.5" />
            <span>Enterprise Multi-Tenant Super Admin</span>
          </div>
          <h2 className="text-3xl font-extrabold tracking-tight text-white leading-tight">
            Centralized Command for Universities, Cohorts & Free Classrooms.
          </h2>
          <p className="text-sm text-slate-400 leading-relaxed">
            Manage multi-campus entities, configure academic cohorts, synchronize daily schedules, and supervise real-time room occupancy with zero concurrency collisions.
          </p>

          <div className="space-y-3 pt-2">
            {[
              'Multi-Tenant Relational Isolation (PostgreSQL 16)',
              'Zero-Friction Hierarchical Cohort Provisioning',
              'Sub-Second Real-Time OCC Availability Engine',
              'Zero-Cost Gmail SMTP & JWT Token Rotation',
            ].map((feature, i) => (
              <div key={i} className="flex items-center gap-2.5 text-xs text-slate-300">
                <CheckCircle2 className="w-4 h-4 text-emerald-400 flex-shrink-0" />
                <span>{feature}</span>
              </div>
            ))}
          </div>
        </div>

        {/* Bottom Metadata */}
        <div className="relative z-10 flex items-center justify-between text-[11px] text-slate-500 border-t border-slate-800/80 pt-6">
          <span>Uttara University Production Deployment</span>
          <span>Security Level: Cryptographic RBAC</span>
        </div>
      </div>

      {/* Right Login Form */}
      <div className="flex-1 flex flex-col justify-center items-center p-8 sm:p-12 relative">
        <div className="w-full max-w-md space-y-8">
          <div>
            <div className="inline-flex items-center gap-2 px-2.5 py-1 rounded-lg bg-emerald-500/10 text-emerald-400 text-xs font-medium mb-3">
              <ShieldCheck className="w-3.5 h-3.5" />
              <span>Super Admin Portal</span>
            </div>
            <h2 className="text-2xl font-bold tracking-tight text-white">Sign In to UniDash</h2>
            <p className="text-xs text-slate-400 mt-1">
              Enter your institutional administrative credentials to continue.
            </p>
          </div>

          {errorMsg && (
            <div className="p-3.5 bg-rose-500/10 border border-rose-500/20 rounded-xl text-rose-400 text-xs flex items-center gap-2">
              <span className="w-2 h-2 rounded-full bg-rose-400 flex-shrink-0" />
              <span>{errorMsg}</span>
            </div>
          )}

          <form onSubmit={handleSubmit} className="space-y-4">
            <div>
              <label className="block text-xs font-medium text-slate-300 mb-1.5">
                Administrative Email
              </label>
              <div className="relative">
                <div className="absolute inset-y-0 left-0 pl-3.5 flex items-center pointer-events-none text-slate-500">
                  <Mail className="w-4 h-4" />
                </div>
                <input
                  type="email"
                  required
                  value={email}
                  onChange={(e) => setEmail(e.target.value)}
                  placeholder="admin@uttara.edu.bd"
                  className="w-full pl-10 pr-4 py-2.5 bg-slate-900/80 border border-slate-800 rounded-xl text-xs text-slate-100 placeholder-slate-500 focus:outline-none focus:border-emerald-500 focus:ring-1 focus:ring-emerald-500 transition-all"
                />
              </div>
            </div>

            <div>
              <label className="block text-xs font-medium text-slate-300 mb-1.5">
                Master Password
              </label>
              <div className="relative">
                <div className="absolute inset-y-0 left-0 pl-3.5 flex items-center pointer-events-none text-slate-500">
                  <Lock className="w-4 h-4" />
                </div>
                <input
                  type="password"
                  required
                  value={password}
                  onChange={(e) => setPassword(e.target.value)}
                  placeholder="••••••••••••"
                  className="w-full pl-10 pr-4 py-2.5 bg-slate-900/80 border border-slate-800 rounded-xl text-xs text-slate-100 placeholder-slate-500 focus:outline-none focus:border-emerald-500 focus:ring-1 focus:ring-emerald-500 transition-all"
                />
              </div>
            </div>

            <button
              type="submit"
              disabled={isLoading}
              className="w-full mt-2 py-2.5 px-4 bg-emerald-500 hover:bg-emerald-600 active:bg-emerald-700 disabled:opacity-50 text-slate-950 font-semibold rounded-xl text-xs flex items-center justify-center gap-2 shadow-lg shadow-emerald-500/20 transition-all cursor-pointer"
            >
              {isLoading ? (
                <>
                  <div className="w-3.5 h-3.5 border-2 border-slate-950 border-t-transparent rounded-full animate-spin" />
                  <span>Authenticating...</span>
                </>
              ) : (
                <>
                  <span>Authenticate & Enter</span>
                  <ArrowRight className="w-4 h-4" />
                </>
              )}
            </button>
          </form>

          {/* Quick Demo Credentials Autofill */}
          <div className="p-4 bg-slate-900/50 border border-slate-800/80 rounded-2xl space-y-2 text-center">
            <span className="text-[11px] text-slate-400 block">Default Seed Super Admin:</span>
            <div className="flex items-center justify-center gap-2">
              <code className="text-xs bg-slate-950 px-2.5 py-1 rounded-md text-emerald-400 font-mono">
                admin@uttara.edu.bd
              </code>
              <code className="text-xs bg-slate-950 px-2 py-1 rounded-md text-slate-300 font-mono">
                Password123!
              </code>
            </div>
            <button
              type="button"
              onClick={fillQuickCredentials}
              className="text-[11px] text-emerald-400 hover:text-emerald-300 font-medium underline cursor-pointer"
            >
              Auto-fill Seed Credentials
            </button>
          </div>
        </div>
      </div>
    </div>
  );
};
