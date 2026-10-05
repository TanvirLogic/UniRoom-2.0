import React, { useEffect, useState } from 'react';
import { useNavigate } from 'react-router-dom';
import {
  Building2,
  GraduationCap,
  DoorOpen,
  Users2,
  CheckCircle,
  PlusCircle,
  ExternalLink,
  RefreshCw,
  Sparkles,
  Mail,
  Bell,
  Send,
  CheckCircle2,
  AlertCircle,
  Server,
} from 'lucide-react';
import { StatCard } from '../components/common/StatCard';
import { StatusBadge } from '../components/common/StatusBadge';
import { useAuth } from '../context/AuthContext';
import { universitiesApi, UniversityItem, DepartmentItem } from '../api/universities.api';
import { roomsApi, RoomsResponse } from '../api/rooms.api';
import { metaApi, BatchItem } from '../api/meta.api';
import { healthApi, HealthStatusResponse } from '../api/health.api';

export const DashboardPage: React.FC = () => {
  const navigate = useNavigate();
  const { selectedUniversity, user } = useAuth();

  const [isLoading, setIsLoading] = useState(true);
  const [unis, setUnis] = useState<UniversityItem[]>([]);
  const [depts, setDepts] = useState<DepartmentItem[]>([]);
  const [batches, setBatches] = useState<BatchItem[]>([]);
  const [healthData, setHealthData] = useState<HealthStatusResponse | null>(null);
  const [testEmailAddress, setTestEmailAddress] = useState(user?.email || '');
  const [isSendingTestEmail, setIsSendingTestEmail] = useState(false);
  const [testEmailResult, setTestEmailResult] = useState<string | null>(null);
  const [isSendingTestPush, setIsSendingTestPush] = useState(false);
  const [testPushResult, setTestPushResult] = useState<string | null>(null);
  const [roomStats, setRoomStats] = useState<RoomsResponse['stats']>({
    total: 0,
    available: 0,
    runningClass: 0,
    reserved: 0,
    maintenance: 0,
  });

  const loadDashboardData = async () => {
    setIsLoading(true);
    try {
      const [unisData, deptsData, batchesData, roomsData, healthRes] = await Promise.all([
        universitiesApi.getUniversities(),
        universitiesApi.getDepartments({ university: selectedUniversity || undefined }),
        metaApi.getBatches({ university: selectedUniversity || undefined }),
        roomsApi.getRooms({ universityId: selectedUniversity || undefined }),
        healthApi.getHealth().catch(() => null),
      ]);

      setUnis(unisData);
      setDepts(deptsData);
      setBatches(batchesData);
      setRoomStats(roomsData.stats);
      if (healthRes) {
        setHealthData(healthRes);
      }
    } catch (err) {
      console.error('Failed to load dashboard data:', err);
    } finally {
      setIsLoading(false);
    }
  };

  const handleSendTestEmail = async () => {
    if (!testEmailAddress || !testEmailAddress.includes('@')) {
      setTestEmailResult('Please provide a valid email address.');
      return;
    }
    setIsSendingTestEmail(true);
    setTestEmailResult(null);
    try {
      const res = await healthApi.testEmail(testEmailAddress);
      setTestEmailResult(res.message);
    } catch (err: any) {
      setTestEmailResult(`Delivery Error: ${err.response?.data?.message || err.message}`);
    } finally {
      setIsSendingTestEmail(false);
    }
  };

  const handleSendTestPush = async () => {
    setIsSendingTestPush(true);
    setTestPushResult(null);
    try {
      const res = await healthApi.testPush({
        topic: 'test_channel',
        title: '🔔 UniRoom-Live 2.0 Test Push',
        body: 'Real-time FCM push notification broadcast verified successfully from Admin Panel!',
      });
      setTestPushResult(res.message);
    } catch (err: any) {
      setTestPushResult(`Broadcast Error: ${err.response?.data?.message || err.message}`);
    } finally {
      setIsSendingTestPush(false);
    }
  };

  useEffect(() => {
    loadDashboardData();
  }, [selectedUniversity]);

  const activeUniversityName =
    unis.find((u) => u.code === selectedUniversity)?.name || 'All Active Universities';

  return (
    <div className="space-y-8">
      {/* Header Banner */}
      <div className="flex flex-col md:flex-row md:items-center justify-between gap-4 p-6 bg-gradient-to-r from-slate-900 via-slate-900/90 to-slate-950 border border-slate-800/80 rounded-3xl shadow-xl">
        <div>
          <div className="flex items-center gap-2 mb-1.5">
            <span className="px-2.5 py-0.5 rounded-full bg-emerald-500/10 text-emerald-400 border border-emerald-500/20 text-xs font-semibold">
              Live Operations Control
            </span>
            <span className="text-xs text-slate-500">Scope: {activeUniversityName}</span>
          </div>
          <h1 className="text-2xl font-bold tracking-tight text-white">System Command Overview</h1>
          <p className="text-xs text-slate-400 mt-1">
            Real-time status of multi-tenant campus entities, academic cohorts, and physical room capacity.
          </p>
        </div>
        <div className="flex items-center gap-2.5">
          <button
            onClick={loadDashboardData}
            disabled={isLoading}
            className="flex items-center gap-2 px-3.5 py-2 bg-slate-800/80 hover:bg-slate-700 text-slate-200 rounded-xl text-xs font-medium border border-slate-700/50 transition-all cursor-pointer"
          >
            <RefreshCw className={`w-3.5 h-3.5 ${isLoading ? 'animate-spin text-emerald-400' : ''}`} />
            <span>Refresh Telemetry</span>
          </button>
          <button
            onClick={() => navigate('/cohorts')}
            className="flex items-center gap-2 px-4 py-2 bg-emerald-500 hover:bg-emerald-600 text-slate-950 rounded-xl text-xs font-semibold shadow-md shadow-emerald-500/20 transition-all cursor-pointer"
          >
            <Users2 className="w-4 h-4" />
            <span>Batches & Sections</span>
          </button>
        </div>
      </div>

      {/* Metric Cards Grid */}
      <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4">
        <StatCard
          title="Universities"
          value={unis.length}
          subtitle="Multi-tenant root instances"
          icon={Building2}
          color="emerald"
        />
        <StatCard
          title="Academic Departments"
          value={depts.length}
          subtitle={`Across ${selectedUniversity || 'all campuses'}`}
          icon={GraduationCap}
          color="blue"
        />
        <StatCard
          title="Physical Rooms"
          value={roomStats.total}
          subtitle={`${roomStats.available} ready for occupancy`}
          icon={DoorOpen}
          color="purple"
        />
        <StatCard
          title="Batches & Sections"
          value={batches.length}
          subtitle="Active student cohorts"
          icon={Users2}
          color="amber"
        />
      </div>

      {/* Room Occupancy Distribution */}
      <div className="p-6 bg-slate-900/60 border border-slate-800/80 rounded-3xl space-y-5">
        <div className="flex items-center justify-between">
          <div>
            <h2 className="text-base font-semibold text-slate-100">Live Room Availability State</h2>
            <p className="text-xs text-slate-400 mt-0.5">Real-time status breakdown across managed classrooms and labs</p>
          </div>
          <button
            onClick={() => navigate('/rooms')}
            className="text-xs text-emerald-400 hover:text-emerald-300 font-medium flex items-center gap-1 cursor-pointer"
          >
            <span>View Full Grid</span>
            <ExternalLink className="w-3.5 h-3.5" />
          </button>
        </div>

        {/* Progress Bar */}
        <div className="h-4 w-full bg-slate-950 rounded-full overflow-hidden flex border border-slate-800">
          <div
            style={{ width: `${(roomStats.available / (roomStats.total || 1)) * 100}%` }}
            className="bg-emerald-500 transition-all duration-500"
            title={`Available: ${roomStats.available}`}
          />
          <div
            style={{ width: `${(roomStats.runningClass / (roomStats.total || 1)) * 100}%` }}
            className="bg-amber-500 transition-all duration-500"
            title={`Running: ${roomStats.runningClass}`}
          />
          <div
            style={{ width: `${(roomStats.reserved / (roomStats.total || 1)) * 100}%` }}
            className="bg-blue-500 transition-all duration-500"
            title={`Reserved: ${roomStats.reserved}`}
          />
          <div
            style={{ width: `${(roomStats.maintenance / (roomStats.total || 1)) * 100}%` }}
            className="bg-rose-500 transition-all duration-500"
            title={`Maintenance: ${roomStats.maintenance}`}
          />
        </div>

        {/* Status Pills Grid */}
        <div className="grid grid-cols-2 sm:grid-cols-4 gap-3 pt-2">
          <div className="p-3 bg-slate-950/60 border border-slate-800/60 rounded-xl flex items-center justify-between">
            <div className="flex items-center gap-2">
              <span className="w-2.5 h-2.5 rounded-full bg-emerald-400" />
              <span className="text-xs text-slate-300 font-medium">Available</span>
            </div>
            <span className="text-sm font-bold text-emerald-400">{roomStats.available}</span>
          </div>

          <div className="p-3 bg-slate-950/60 border border-slate-800/60 rounded-xl flex items-center justify-between">
            <div className="flex items-center gap-2">
              <span className="w-2.5 h-2.5 rounded-full bg-amber-400" />
              <span className="text-xs text-slate-300 font-medium">Running Class</span>
            </div>
            <span className="text-sm font-bold text-amber-400">{roomStats.runningClass}</span>
          </div>

          <div className="p-3 bg-slate-950/60 border border-slate-800/60 rounded-xl flex items-center justify-between">
            <div className="flex items-center gap-2">
              <span className="w-2.5 h-2.5 rounded-full bg-blue-400" />
              <span className="text-xs text-slate-300 font-medium">Reserved</span>
            </div>
            <span className="text-sm font-bold text-blue-400">{roomStats.reserved}</span>
          </div>

          <div className="p-3 bg-slate-950/60 border border-slate-800/60 rounded-xl flex items-center justify-between">
            <div className="flex items-center gap-2">
              <span className="w-2.5 h-2.5 rounded-full bg-rose-400" />
              <span className="text-xs text-slate-300 font-medium">Maintenance</span>
            </div>
            <span className="text-sm font-bold text-rose-400">{roomStats.maintenance}</span>
          </div>
        </div>
      </div>

      {/* Cloud Integrations & Real-Time Messaging Telemetry */}
      <div className="p-6 bg-slate-900/60 border border-slate-800/80 rounded-3xl space-y-5">
        <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-3">
          <div>
            <div className="flex items-center gap-2 mb-1">
              <span className="px-2 py-0.5 rounded-full bg-cyan-500/10 text-cyan-400 border border-cyan-500/20 text-[10px] font-semibold uppercase tracking-wider">
                Production Services Telemetry
              </span>
            </div>
            <h2 className="text-base font-semibold text-slate-100 flex items-center gap-2">
              <Server className="w-4 h-4 text-emerald-400" />
              <span>Cloud Services & Real-time Integrations</span>
            </h2>
            <p className="text-xs text-slate-400 mt-0.5">
              Live operational health of SMTP transactional emails and Firebase Cloud Messaging (FCM) push notifications.
            </p>
          </div>
        </div>

        <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
          {/* SMTP Transactional Email Panel */}
          <div className="p-4 bg-slate-950/60 border border-slate-800/60 rounded-2xl flex flex-col justify-between space-y-4">
            <div className="space-y-3">
              <div className="flex items-center justify-between">
                <div className="flex items-center gap-2.5">
                  <div className="p-2 rounded-xl bg-blue-500/10 text-blue-400 border border-blue-500/20">
                    <Mail className="w-4 h-4" />
                  </div>
                  <div>
                    <h3 className="text-sm font-semibold text-slate-200">Email Delivery Service</h3>
                    <p className="text-[11px] text-slate-400">SMTP Transporter (Gmail / Institutional)</p>
                  </div>
                </div>
                {healthData?.email?.isConfigured ? (
                  <span className="flex items-center gap-1.5 px-2.5 py-1 rounded-full text-[11px] font-medium bg-emerald-500/10 text-emerald-400 border border-emerald-500/20">
                    <CheckCircle2 className="w-3.5 h-3.5" />
                    <span>Active & Ready</span>
                  </span>
                ) : (
                  <span className="flex items-center gap-1.5 px-2.5 py-1 rounded-full text-[11px] font-medium bg-amber-500/10 text-amber-400 border border-amber-500/20">
                    <AlertCircle className="w-3.5 h-3.5" />
                    <span>Needs Render Env</span>
                  </span>
                )}
              </div>

              <div className="p-3 bg-slate-900/60 rounded-xl space-y-1.5 font-mono text-[11px]">
                <div className="flex justify-between text-slate-400">
                  <span>Host:</span>
                  <span className="text-slate-200">{healthData?.email?.host || 'smtp.gmail.com'}:{healthData?.email?.port || 465}</span>
                </div>
                <div className="flex justify-between text-slate-400">
                  <span>Account:</span>
                  <span className="text-slate-200">{healthData?.email?.user || 'Not configured'}</span>
                </div>
                <div className="flex justify-between text-slate-400">
                  <span>Sender:</span>
                  <span className="text-slate-300 truncate max-w-[220px]">{healthData?.email?.from || 'UniRoom-Live <no-reply@uniroom.live>'}</span>
                </div>
              </div>
            </div>

            <div className="space-y-2 pt-2 border-t border-slate-800/60">
              <label className="text-[11px] font-medium text-slate-400">Test Live Email Delivery:</label>
              <div className="flex gap-2">
                <input
                  type="email"
                  value={testEmailAddress}
                  onChange={(e) => setTestEmailAddress(e.target.value)}
                  placeholder="name@example.com"
                  className="flex-1 px-3 py-1.5 bg-slate-900 border border-slate-700/60 rounded-xl text-xs text-slate-200 placeholder-slate-500 focus:outline-none focus:border-emerald-500"
                />
                <button
                  onClick={handleSendTestEmail}
                  disabled={isSendingTestEmail}
                  className="flex items-center gap-1.5 px-3 py-1.5 bg-blue-600 hover:bg-blue-500 text-white rounded-xl text-xs font-medium transition-all disabled:opacity-50 cursor-pointer"
                >
                  <Send className={`w-3 h-3 ${isSendingTestEmail ? 'animate-spin' : ''}`} />
                  <span>{isSendingTestEmail ? 'Sending...' : 'Test PIN'}</span>
                </button>
              </div>
              {testEmailResult && (
                <p className="text-[11px] text-slate-300 bg-slate-900/80 p-2 rounded-lg border border-slate-800 mt-1">
                  {testEmailResult}
                </p>
              )}
            </div>
          </div>

          {/* Firebase Push Notifications Panel */}
          <div className="p-4 bg-slate-950/60 border border-slate-800/60 rounded-2xl flex flex-col justify-between space-y-4">
            <div className="space-y-3">
              <div className="flex items-center justify-between">
                <div className="flex items-center gap-2.5">
                  <div className="p-2 rounded-xl bg-amber-500/10 text-amber-400 border border-amber-500/20">
                    <Bell className="w-4 h-4" />
                  </div>
                  <div>
                    <h3 className="text-sm font-semibold text-slate-200">Push Notifications</h3>
                    <p className="text-[11px] text-slate-400">Firebase Cloud Messaging (FCM Admin SDK)</p>
                  </div>
                </div>
                {healthData?.pushNotifications?.isInitialized ? (
                  <span className="flex items-center gap-1.5 px-2.5 py-1 rounded-full text-[11px] font-medium bg-emerald-500/10 text-emerald-400 border border-emerald-500/20">
                    <CheckCircle2 className="w-3.5 h-3.5" />
                    <span>Active & Ready</span>
                  </span>
                ) : (
                  <span className="flex items-center gap-1.5 px-2.5 py-1 rounded-full text-[11px] font-medium bg-amber-500/10 text-amber-400 border border-amber-500/20">
                    <AlertCircle className="w-3.5 h-3.5" />
                    <span>Paused / No Key</span>
                  </span>
                )}
              </div>

              <div className="p-3 bg-slate-900/60 rounded-xl space-y-1.5 font-mono text-[11px]">
                <div className="flex justify-between text-slate-400">
                  <span>Project ID:</span>
                  <span className="text-slate-200">{healthData?.pushNotifications?.projectId || 'uniroom-live'}</span>
                </div>
                <div className="flex justify-between text-slate-400">
                  <span>Client Service:</span>
                  <span className="text-slate-200 truncate max-w-[220px]">{healthData?.pushNotifications?.clientEmail || 'Pending credentials'}</span>
                </div>
                <div className="flex justify-between text-slate-400">
                  <span>Active Topics:</span>
                  <span className="text-slate-300">/dept_*_crs, /dept_*_sec_*</span>
                </div>
              </div>
            </div>

            <div className="space-y-2 pt-2 border-t border-slate-800/60">
              <label className="text-[11px] font-medium text-slate-400">Test Push Broadcast Alert:</label>
              <div className="flex items-center justify-between gap-3">
                <span className="text-xs text-slate-400 truncate">Broadcast to /topics/test_channel</span>
                <button
                  onClick={handleSendTestPush}
                  disabled={isSendingTestPush}
                  className="flex items-center gap-1.5 px-3 py-1.5 bg-amber-600 hover:bg-amber-500 text-white rounded-xl text-xs font-medium transition-all disabled:opacity-50 cursor-pointer"
                >
                  <Send className={`w-3 h-3 ${isSendingTestPush ? 'animate-spin' : ''}`} />
                  <span>{isSendingTestPush ? 'Broadcasting...' : 'Broadcast Push'}</span>
                </button>
              </div>
              {testPushResult && (
                <p className="text-[11px] text-slate-300 bg-slate-900/80 p-2 rounded-lg border border-slate-800 mt-1">
                  {testPushResult}
                </p>
              )}
            </div>
          </div>
        </div>
      </div>

      {/* Departments Summary Table */}
      <div className="p-6 bg-slate-900/60 border border-slate-800/80 rounded-3xl space-y-4">
        <div className="flex items-center justify-between">
          <div>
            <h2 className="text-base font-semibold text-slate-100">Academic Departments & Batches</h2>
            <p className="text-xs text-slate-400 mt-0.5">Physical department units and active student batch counts</p>
          </div>
          <button
            onClick={() => navigate('/departments')}
            className="text-xs text-emerald-400 hover:text-emerald-300 font-medium cursor-pointer"
          >
            Manage Departments →
          </button>
        </div>

        <div className="overflow-x-auto">
          <table className="w-full text-left text-xs">
            <thead>
              <tr className="border-b border-slate-800 text-slate-400 font-semibold uppercase tracking-wider text-[11px]">
                <th className="py-3 px-4">Code</th>
                <th className="py-3 px-4">Department Name</th>
                <th className="py-3 px-4">Institution</th>
                <th className="py-3 px-4 text-center">Physical Rooms</th>
                <th className="py-3 px-4 text-center">Schedule Slots</th>
                <th className="py-3 px-4 text-right">Quick Action</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-slate-800/60">
              {depts.map((d) => (
                <tr key={d.id} className="hover:bg-slate-800/30 transition-colors">
                  <td className="py-3.5 px-4 font-mono font-bold text-emerald-400">{d.code}</td>
                  <td className="py-3.5 px-4 font-medium text-slate-200">{d.name}</td>
                  <td className="py-3.5 px-4 text-slate-400">{d.university?.code || 'UU'}</td>
                  <td className="py-3.5 px-4 text-center">
                    <span className="px-2 py-0.5 rounded-md bg-slate-800 text-slate-300 font-mono font-semibold">
                      {d._count?.rooms ?? 0}
                    </span>
                  </td>
                  <td className="py-3.5 px-4 text-center">
                    <span className="px-2 py-0.5 rounded-md bg-slate-800 text-slate-300 font-mono font-semibold">
                      {d._count?.scheduleSlots ?? 0}
                    </span>
                  </td>
                  <td className="py-3.5 px-4 text-right">
                    <button
                      onClick={() => navigate('/cohorts')}
                      className="px-2.5 py-1 text-xs text-emerald-400 hover:text-emerald-300 hover:bg-emerald-500/10 rounded-lg transition-colors cursor-pointer"
                    >
                      View Batches
                    </button>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      </div>
    </div>
  );
};
