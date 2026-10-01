import React, { useEffect, useState, useMemo } from 'react';
import {
  DoorOpen,
  Plus,
  Search,
  Filter,
  RefreshCw,
  Clock,
  History,
  CheckCircle2,
  Users,
  Layers,
  Building2,
  Edit2,
  Trash2,
  X,
} from 'lucide-react';
import { Modal } from '../components/common/Modal';
import { StatusBadge } from '../components/common/StatusBadge';
import { useAuth } from '../context/AuthContext';
import { roomsApi, RoomItem, RoomStatusType, BuildingItem } from '../api/rooms.api';
import { universitiesApi, DepartmentItem } from '../api/universities.api';

export const RoomsPage: React.FC = () => {
  const { selectedUniversity } = useAuth();

  const [rooms, setRooms] = useState<RoomItem[]>([]);
  const [buildings, setBuildings] = useState<BuildingItem[]>([]);
  const [depts, setDepts] = useState<DepartmentItem[]>([]);
  const [selectedDept, setSelectedDept] = useState<string>('');
  const [selectedStatus, setSelectedStatus] = useState<string>('');
  const [search, setSearch] = useState<string>('');
  const [isLoading, setIsLoading] = useState<boolean>(true);

  // Status Change State
  const [changingRoom, setChangingRoom] = useState<RoomItem | null>(null);
  const [newStatus, setNewStatus] = useState<RoomStatusType>('AVAILABLE');
  const [statusNote, setStatusNote] = useState('');
  const [durationMinutes, setDurationMinutes] = useState(90);
  const [isUpdatingStatus, setIsUpdatingStatus] = useState(false);

  // Add Room Modal State
  const [isAddModalOpen, setIsAddModalOpen] = useState(false);
  const [newRoomNumber, setNewRoomNumber] = useState('');
  const [newFloor, setNewFloor] = useState(5);
  const [newCapacity, setNewCapacity] = useState(45);
  const [newBuildingId, setNewBuildingId] = useState('');
  const [newDeptId, setNewDeptId] = useState('');
  const [isAddingRoom, setIsAddingRoom] = useState(false);

  // Audit Logs State
  const [auditLogsModalOpen, setAuditLogsModalOpen] = useState(false);
  const [selectedRoomLogs, setSelectedRoomLogs] = useState<any[]>([]);
  const [logRoomNumber, setLogRoomNumber] = useState('');
  const [isLoadingLogs, setIsLoadingLogs] = useState(false);

  // Building Management State
  const [isBuildingModalOpen, setIsBuildingModalOpen] = useState(false);
  const [editingBuilding, setEditingBuilding] = useState<BuildingItem | null>(null);
  const [bldgName, setBldgName] = useState('');
  const [bldgCampus, setBldgCampus] = useState('Main Campus');
  const [bldgDeptId, setBldgDeptId] = useState('');
  const [isSubmittingBuilding, setIsSubmittingBuilding] = useState(false);
  const [bldgError, setBldgError] = useState<string | null>(null);
  const [bldgSuccess, setBldgSuccess] = useState<string | null>(null);

  const fetchMetadata = async () => {
    try {
      const [bldgsData, deptsData] = await Promise.all([
        roomsApi.getBuildings({ universityId: selectedUniversity || undefined }),
        universitiesApi.getDepartments({ university: selectedUniversity || undefined }),
      ]);

      setBuildings(bldgsData);
      setDepts(deptsData);

      if (bldgsData.length > 0 && !newBuildingId) setNewBuildingId(bldgsData[0].id);
      if (deptsData.length > 0 && !newDeptId) setNewDeptId(deptsData[0].id);
      if (deptsData.length > 0 && !bldgDeptId) setBldgDeptId(deptsData[0].id);
    } catch (err) {
      console.error('Failed to load room metadata:', err);
    }
  };

  const fetchRooms = async () => {
    setIsLoading(true);
    try {
      const roomsRes = await roomsApi.getRooms({
        universityId: selectedUniversity || undefined,
        departmentId: selectedDept || undefined,
        status: (selectedStatus as RoomStatusType) || undefined,
        limit: 100,
      });

      setRooms(roomsRes.rooms);
    } catch (err) {
      console.error('Failed to load rooms:', err);
    } finally {
      setIsLoading(false);
    }
  };

  const refreshAll = async () => {
    await Promise.all([fetchMetadata(), fetchRooms()]);
  };

  useEffect(() => {
    fetchMetadata();
  }, [selectedUniversity]);

  useEffect(() => {
    fetchRooms();
  }, [selectedUniversity, selectedDept, selectedStatus]);

  // Instant client-side search filtering (zero network latency)
  const displayedRooms = useMemo(() => {
    if (!search.trim()) return rooms;
    const q = search.trim().toLowerCase();
    return rooms.filter(
      (r) =>
        r.roomNumber.toLowerCase().includes(q) ||
        r.department?.code?.toLowerCase().includes(q) ||
        r.department?.name?.toLowerCase().includes(q) ||
        r.building?.name?.toLowerCase().includes(q) ||
        String(r.floor).includes(q) ||
        String(r.capacity).includes(q),
    );
  }, [rooms, search]);

  // Handle Live Status Toggle (OCC)
  const openStatusModal = (room: RoomItem) => {
    setChangingRoom(room);
    setNewStatus(room.currentStatus);
    setStatusNote('');
    setDurationMinutes(90);
  };

  const handleUpdateStatus = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!changingRoom) return;

    setIsUpdatingStatus(true);
    try {
      await roomsApi.updateRoomStatus(changingRoom.id, {
        status: newStatus,
        version: changingRoom.version,
        durationMinutes: newStatus === 'RUNNING_CLASS' ? durationMinutes : undefined,
        note: statusNote || undefined,
      });

      setChangingRoom(null);
      fetchRooms();
    } catch (err: any) {
      alert(err.response?.data?.message || 'Status transition conflict. Room version changed!');
    } finally {
      setIsUpdatingStatus(false);
    }
  };

  // Open Room Audit Logs
  const openLogs = async (room: RoomItem) => {
    setLogRoomNumber(room.roomNumber);
    setAuditLogsModalOpen(true);
    setIsLoadingLogs(true);
    try {
      const logs = await roomsApi.getRoomLogs(room.id);
      setSelectedRoomLogs(logs);
    } catch (err) {
      console.error('Failed to fetch logs:', err);
      setSelectedRoomLogs([]);
    } finally {
      setIsLoadingLogs(false);
    }
  };

  // Handle Add Room
  const handleAddRoom = async (e: React.FormEvent) => {
    e.preventDefault();
    setIsAddingRoom(true);
    try {
      await roomsApi.createRoom({
        universityId: selectedUniversity || 'UU',
        departmentId: newDeptId,
        buildingId: newBuildingId,
        roomNumber: newRoomNumber,
        floor: Number(newFloor),
        capacity: Number(newCapacity),
      });

      setIsAddModalOpen(false);
      setNewRoomNumber('');
      refreshAll();
    } catch (err: any) {
      alert(err.response?.data?.message || 'Failed to add room');
    } finally {
      setIsAddingRoom(false);
    }
  };

  // Building Management Handlers
  const openBuildingModal = () => {
    setEditingBuilding(null);
    setBldgName('');
    setBldgCampus('Main Campus');
    if (depts.length > 0) setBldgDeptId(depts[0].id);
    setBldgError(null);
    setBldgSuccess(null);
    setIsBuildingModalOpen(true);
  };

  const handleEditBuilding = (b: BuildingItem) => {
    setEditingBuilding(b);
    setBldgName(b.name);
    setBldgCampus(b.campusName || 'Main Campus');
    setBldgDeptId(b.departmentId || (depts[0]?.id ?? ''));
    setBldgError(null);
    setBldgSuccess(null);
  };

  const handleSaveBuilding = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!bldgName.trim()) {
      setBldgError('Building name is required.');
      return;
    }
    if (!bldgDeptId) {
      setBldgError('Please select a department.');
      return;
    }

    setIsSubmittingBuilding(true);
    setBldgError(null);
    setBldgSuccess(null);

    try {
      if (editingBuilding) {
        await roomsApi.updateBuilding(editingBuilding.id, {
          name: bldgName.trim(),
          campusName: bldgCampus.trim(),
          departmentId: bldgDeptId,
        });
        setBldgSuccess(`Building "${bldgName}" updated successfully!`);
      } else {
        const created = await roomsApi.createBuilding({
          name: bldgName.trim(),
          campusName: bldgCampus.trim(),
          departmentId: bldgDeptId,
        });
        setBldgSuccess(`Building "${bldgName}" created successfully!`);
        if (!newBuildingId) setNewBuildingId(created.id);
      }
      setEditingBuilding(null);
      setBldgName('');
      setBldgCampus('Main Campus');
      refreshAll();
    } catch (err: any) {
      console.error('Failed to save building:', err);
      setBldgError(err.response?.data?.message || 'Failed to save building');
    } finally {
      setIsSubmittingBuilding(false);
    }
  };

  const handleDeleteBuilding = async (b: BuildingItem) => {
    const roomCount = b._count?.rooms ?? 0;
    const warning = roomCount > 0
      ? `Warning: Building "${b.name}" has ${roomCount} room(s) assigned to it! Deleting this building will permanently delete those rooms. Proceed?`
      : `Are you sure you want to delete Building "${b.name}"?`;

    if (!window.confirm(warning)) return;

    try {
      await roomsApi.deleteBuilding(b.id);
      setBldgSuccess(`Building "${b.name}" was successfully removed.`);
      refreshAll();
    } catch (err: any) {
      console.error('Failed to delete building:', err);
      setBldgError(err.response?.data?.message || 'Failed to delete building');
    }
  };

  return (
    <div className="space-y-6">
      {/* Header */}
      <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4">
        <div>
          <h1 className="text-2xl font-bold tracking-tight text-white flex items-center gap-2">
            <DoorOpen className="w-6 h-6 text-emerald-400" />
            <span>Physical Rooms & OCC Live Availability</span>
          </h1>
          <p className="text-xs text-slate-400 mt-1">
            Real-time status tracking, OCC collision prevention, and physical building infrastructure.
          </p>
        </div>
        <div className="flex items-center gap-2.5">
          <button
            onClick={refreshAll}
            className="p-2.5 bg-slate-900 border border-slate-800 text-slate-400 hover:text-slate-200 rounded-xl transition-colors cursor-pointer"
            title="Refresh"
          >
            <RefreshCw className={`w-4 h-4 ${isLoading ? 'animate-spin text-emerald-400' : ''}`} />
          </button>
          <button
            onClick={openBuildingModal}
            className="flex items-center gap-2 px-3.5 py-2.5 bg-slate-800 hover:bg-slate-700 text-slate-200 font-semibold rounded-xl text-xs border border-slate-700/60 transition-all cursor-pointer"
            title="Manage and configure university building blocks"
          >
            <Building2 className="w-4 h-4 text-emerald-400" />
            <span>Manage Buildings ({buildings.length})</span>
          </button>
          <button
            onClick={() => setIsAddModalOpen(true)}
            className="flex items-center gap-2 px-4 py-2.5 bg-emerald-500 hover:bg-emerald-600 text-slate-950 font-semibold rounded-xl text-xs shadow-lg shadow-emerald-500/20 transition-all cursor-pointer"
          >
            <Plus className="w-4 h-4" />
            <span>Add Physical Room</span>
          </button>
        </div>
      </div>

      {/* Filter Bar */}
      <div className="flex flex-wrap items-center gap-3 p-3.5 bg-slate-900/60 border border-slate-800/80 rounded-2xl">
        {/* Search */}
        <div className="relative flex-1 min-w-[200px]">
          <Search className="w-4 h-4 text-slate-500 absolute left-3 top-1/2 -translate-y-1/2" />
          <input
            type="text"
            value={search}
            onChange={(e) => setSearch(e.target.value)}
            onKeyDown={(e) => e.key === 'Enter' && fetchRooms()}
            placeholder="Search room (e.g. AI Lab, 5030)..."
            className="w-full pl-9 pr-3 py-1.5 bg-slate-950/60 border border-slate-800 rounded-xl text-xs text-slate-100 placeholder-slate-500 focus:outline-none focus:border-emerald-500"
          />
        </div>

        {/* Department Filter */}
        <div className="flex items-center gap-2">
          <Filter className="w-3.5 h-3.5 text-slate-500" />
          <select
            value={selectedDept}
            onChange={(e) => setSelectedDept(e.target.value)}
            className="px-3 py-1.5 bg-slate-950/60 border border-slate-800 rounded-xl text-xs text-slate-300 focus:outline-none cursor-pointer"
          >
            <option value="">All Departments</option>
            {depts.map((d) => (
              <option key={d.id} value={d.code} className="bg-slate-900">
                {d.code} - {d.name}
              </option>
            ))}
          </select>
        </div>

        {/* Status Filter */}
        <select
          value={selectedStatus}
          onChange={(e) => setSelectedStatus(e.target.value)}
          className="px-3 py-1.5 bg-slate-950/60 border border-slate-800 rounded-xl text-xs text-slate-300 focus:outline-none cursor-pointer"
        >
          <option value="">All Statuses</option>
          <option value="AVAILABLE" className="bg-slate-900">Available</option>
          <option value="RUNNING_CLASS" className="bg-slate-900">Running Class</option>
          <option value="RESERVED" className="bg-slate-900">Reserved</option>
          <option value="MAINTENANCE" className="bg-slate-900">Maintenance</option>
        </select>
      </div>

      {/* Instant Search / Filter Results Counter */}
      {!isLoading && rooms.length > 0 && (
        <div className="flex items-center justify-between text-xs text-slate-400 px-1">
          <span>
            Showing <span className="font-semibold text-white">{displayedRooms.length}</span> of{' '}
            <span className="font-semibold text-white">{rooms.length}</span> rooms
          </span>
          {search.trim() && (
            <button
              onClick={() => setSearch('')}
              className="text-emerald-400 hover:text-emerald-300 underline cursor-pointer text-xs"
            >
              Clear Search Filter
            </button>
          )}
        </div>
      )}

      {/* Rooms Grid */}
      {isLoading ? (
        <div className="py-20 text-center text-xs text-slate-500 bg-slate-900/40 rounded-3xl border border-slate-800">
          <RefreshCw className="w-6 h-6 animate-spin mx-auto mb-2 text-emerald-400" />
          Loading physical classrooms and labs...
        </div>
      ) : displayedRooms.length === 0 ? (
        <div className="py-20 text-center text-xs text-slate-400 bg-slate-900/40 rounded-3xl border border-slate-800 space-y-3">
          <DoorOpen className="w-10 h-10 mx-auto text-slate-600" />
          <div className="font-semibold text-slate-200 text-sm">
            {rooms.length === 0 ? 'No Physical Rooms Found' : 'No Matching Rooms'}
          </div>
          <p className="text-slate-500 max-w-sm mx-auto">
            {rooms.length === 0
              ? `No rooms match your filter criteria for ${selectedUniversity || 'the selected campus'}. Ingest a timetable routine or click "Add Physical Room" above.`
              : `No rooms found matching "${search}". Try searching for another room number, building, or clear the search filter.`}
          </p>
          {rooms.length > 0 && search.trim() && (
            <button
              onClick={() => setSearch('')}
              className="px-3 py-1.5 bg-slate-800 hover:bg-slate-700 text-xs text-emerald-400 rounded-xl transition-colors cursor-pointer"
            >
              Clear Search Filter
            </button>
          )}
        </div>
      ) : (
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4 gap-4">
          {displayedRooms.map((room) => (
            <div
              key={room.id}
              className="p-5 bg-slate-900/60 border border-slate-800/80 rounded-3xl flex flex-col justify-between hover:border-slate-700 transition-all shadow-lg group relative overflow-hidden"
            >
              {/* Top Bar */}
              <div>
                <div className="flex items-start justify-between gap-2 mb-2">
                  <span className="font-mono text-xs font-bold text-slate-400">
                    {room.department?.code || 'CSE'}
                  </span>
                  <span className="font-mono text-[10px] font-semibold px-2 py-0.5 rounded-full bg-slate-800 text-slate-400">
                    OCC v{room.version}
                  </span>
                </div>

                <h3 className="text-base font-bold text-slate-100 group-hover:text-emerald-400 transition-colors">
                  {room.roomNumber}
                </h3>

                <p className="text-xs text-slate-400 mt-1 flex items-center gap-1.5">
                  <Layers className="w-3.5 h-3.5 text-slate-500" />
                  <span>{room.building?.name || 'Building B'} • Floor {room.floor}</span>
                </p>
              </div>

              {/* Middle Occupancy Info */}
              <div className="my-4 py-3 border-y border-slate-800/60 space-y-2">
                <div className="flex items-center justify-between">
                  <span className="text-xs text-slate-400">Current Status:</span>
                  <StatusBadge status={room.currentStatus} />
                </div>

                <div className="flex items-center justify-between text-xs text-slate-400">
                  <span>Seating Capacity:</span>
                  <span className="font-mono font-bold text-slate-200 flex items-center gap-1">
                    <Users className="w-3.5 h-3.5 text-slate-500" />
                    {room.capacity} seats
                  </span>
                </div>
              </div>

              {/* Bottom Actions */}
              <div className="flex items-center justify-between pt-1">
                <button
                  onClick={() => openLogs(room)}
                  className="text-xs text-slate-500 hover:text-slate-300 flex items-center gap-1 cursor-pointer transition-colors"
                  title="View Audit History"
                >
                  <History className="w-3.5 h-3.5" />
                  <span>Audit Logs</span>
                </button>

                <button
                  onClick={() => openStatusModal(room)}
                  className="px-3 py-1.5 bg-slate-800 hover:bg-slate-700 text-emerald-400 rounded-xl text-xs font-semibold border border-slate-700/60 transition-colors cursor-pointer"
                >
                  Change State
                </button>
              </div>
            </div>
          ))}
        </div>
      )}

      {/* Modal: Change Room Status (OCC) */}
      <Modal
        isOpen={!!changingRoom}
        onClose={() => setChangingRoom(null)}
        title={`Change State: ${changingRoom?.roomNumber}`}
        subtitle={`Optimistic Concurrency Control Lock: Version ${changingRoom?.version}`}
      >
        <form onSubmit={handleUpdateStatus} className="space-y-4">
          <div>
            <label className="block text-xs font-medium text-slate-300 mb-1.5">New Room Status *</label>
            <div className="grid grid-cols-2 gap-2">
              {(['AVAILABLE', 'RUNNING_CLASS', 'RESERVED', 'MAINTENANCE'] as RoomStatusType[]).map((st) => (
                <button
                  type="button"
                  key={st}
                  onClick={() => setNewStatus(st)}
                  className={`p-3 rounded-xl border text-xs font-semibold text-left transition-all cursor-pointer ${
                    newStatus === st
                      ? 'bg-emerald-500/10 border-emerald-500 text-emerald-400'
                      : 'bg-slate-950/60 border-slate-800 text-slate-400 hover:border-slate-700'
                  }`}
                >
                  <StatusBadge status={st} showDot={false} size="sm" />
                </button>
              ))}
            </div>
          </div>

          {newStatus === 'RUNNING_CLASS' && (
            <div>
              <label className="block text-xs font-medium text-slate-300 mb-1">
                Lease Duration (Auto-release after minutes)
              </label>
              <select
                value={durationMinutes}
                onChange={(e) => setDurationMinutes(Number(e.target.value))}
                className="w-full px-3 py-2 bg-slate-950/60 border border-slate-800 rounded-xl text-xs text-slate-200"
              >
                <option value={45}>45 Minutes (Short Lab)</option>
                <option value={80}>80 Minutes (Standard Class)</option>
                <option value={90}>90 Minutes (Lecture Block)</option>
                <option value={120}>120 Minutes (Midterm Exam)</option>
              </select>
            </div>
          )}

          <div>
            <label className="block text-xs font-medium text-slate-300 mb-1">Audit Note (Optional)</label>
            <input
              type="text"
              value={statusNote}
              onChange={(e) => setStatusNote(e.target.value)}
              placeholder="e.g. Shifted from room 5030, faculty DNS"
              className="w-full px-3.5 py-2 bg-slate-950/60 border border-slate-800 rounded-xl text-xs text-slate-200 placeholder-slate-600 focus:outline-none focus:border-emerald-500"
            />
          </div>

          <div className="flex items-center justify-end gap-2.5 pt-4 border-t border-slate-800">
            <button
              type="button"
              onClick={() => setChangingRoom(null)}
              className="px-4 py-2 bg-slate-800 hover:bg-slate-700 text-slate-300 rounded-xl text-xs font-medium cursor-pointer"
            >
              Cancel
            </button>
            <button
              type="submit"
              disabled={isUpdatingStatus}
              className="px-5 py-2 bg-emerald-500 hover:bg-emerald-600 text-slate-950 font-bold rounded-xl text-xs shadow-md shadow-emerald-500/20 cursor-pointer"
            >
              {isUpdatingStatus ? 'Locking & Updating...' : 'Commit Status'}
            </button>
          </div>
        </form>
      </Modal>

      {/* Modal: Add Physical Room */}
      <Modal
        isOpen={isAddModalOpen}
        onClose={() => setIsAddModalOpen(false)}
        title="Add / Allocate Physical Room"
        subtitle="Provision a physical room or overwrite allocation details if the room already exists (no conflicts)."
      >
        <form onSubmit={handleAddRoom} className="space-y-4">
          <div className="p-2.5 bg-emerald-500/10 border border-emerald-500/20 rounded-xl text-[11px] text-emerald-400">
            💡 If this room number already exists, saving will automatically overwrite its department, floor, and capacity according to this allocation with zero conflict.
          </div>

          <div className="grid grid-cols-2 gap-3">
            <div>
              <label className="block text-xs font-medium text-slate-300 mb-1">Department *</label>
              <select
                value={newDeptId}
                onChange={(e) => setNewDeptId(e.target.value)}
                className="w-full px-3 py-2 bg-slate-950/60 border border-slate-800 rounded-xl text-xs text-slate-200"
              >
                {depts.map((d) => (
                  <option key={d.id} value={d.id}>
                    {d.code} ({d.name})
                  </option>
                ))}
              </select>
            </div>
            <div>
              <div className="flex items-center justify-between mb-1">
                <label className="block text-xs font-medium text-slate-300">Building Block *</label>
                <button
                  type="button"
                  onClick={() => {
                    setIsAddModalOpen(false);
                    openBuildingModal();
                  }}
                  className="text-[11px] text-emerald-400 hover:text-emerald-300 font-medium cursor-pointer"
                >
                  + Add Building
                </button>
              </div>
              <select
                value={newBuildingId}
                onChange={(e) => setNewBuildingId(e.target.value)}
                className="w-full px-3 py-2 bg-slate-950/60 border border-slate-800 rounded-xl text-xs text-slate-200"
              >
                {buildings.map((b) => (
                  <option key={b.id} value={b.id}>
                    {b.name} ({b.campusName})
                  </option>
                ))}
              </select>
            </div>
          </div>

          <div>
            <label className="block text-xs font-medium text-slate-300 mb-1">Room Number / Title *</label>
            <input
              type="text"
              required
              value={newRoomNumber}
              onChange={(e) => setNewRoomNumber(e.target.value)}
              placeholder="e.g. AI Lab 5210 (514)"
              className="w-full px-3.5 py-2 bg-slate-950/60 border border-slate-800 rounded-xl text-xs text-slate-100 placeholder-slate-600 focus:outline-none focus:border-emerald-500"
            />
          </div>

          <div className="grid grid-cols-2 gap-3">
            <div>
              <label className="block text-xs font-medium text-slate-300 mb-1">Floor Level</label>
              <input
                type="number"
                min={0}
                required
                value={newFloor}
                onChange={(e) => setNewFloor(Number(e.target.value))}
                className="w-full px-3.5 py-2 bg-slate-950/60 border border-slate-800 rounded-xl text-xs text-slate-100 focus:outline-none focus:border-emerald-500"
              />
            </div>
            <div>
              <label className="block text-xs font-medium text-slate-300 mb-1">Seating Capacity</label>
              <input
                type="number"
                min={1}
                required
                value={newCapacity}
                onChange={(e) => setNewCapacity(Number(e.target.value))}
                className="w-full px-3.5 py-2 bg-slate-950/60 border border-slate-800 rounded-xl text-xs text-slate-100 focus:outline-none focus:border-emerald-500"
              />
            </div>
          </div>

          <div className="flex items-center justify-end gap-2.5 pt-4 border-t border-slate-800">
            <button
              type="button"
              onClick={() => setIsAddModalOpen(false)}
              className="px-4 py-2 bg-slate-800 hover:bg-slate-700 text-slate-300 rounded-xl text-xs font-medium cursor-pointer"
            >
              Cancel
            </button>
            <button
              type="submit"
              disabled={isAddingRoom}
              className="px-5 py-2 bg-emerald-500 hover:bg-emerald-600 text-slate-950 font-bold rounded-xl text-xs shadow-md shadow-emerald-500/20 cursor-pointer"
            >
              {isAddingRoom ? 'Saving...' : 'Save / Overwrite Room'}
            </button>
          </div>
        </form>
      </Modal>

      {/* Modal: Room Audit Logs */}
      <Modal
        isOpen={auditLogsModalOpen}
        onClose={() => setAuditLogsModalOpen(false)}
        title={`Audit Trail: ${logRoomNumber}`}
        subtitle="Chronological status transitions recorded with Optimistic Concurrency Control"
      >
        {isLoadingLogs ? (
          <div className="py-8 flex flex-col items-center justify-center text-slate-400 gap-2">
            <div className="w-6 h-6 border-2 border-emerald-500 border-t-transparent rounded-full animate-spin" />
            <span className="text-xs">Loading audit entries...</span>
          </div>
        ) : selectedRoomLogs.length === 0 ? (
          <div className="py-8 text-center text-slate-500 text-xs">
            No status changes logged for this room yet.
          </div>
        ) : (
          <div className="space-y-3">
            {selectedRoomLogs.map((log) => (
              <div
                key={log.id}
                className="p-3.5 bg-slate-950/60 border border-slate-800/80 rounded-2xl flex items-center justify-between text-xs"
              >
                <div>
                  <div className="flex items-center gap-2">
                    <StatusBadge status={log.previousStatus} size="sm" showDot={false} />
                    <span className="text-slate-500">→</span>
                    <StatusBadge status={log.newStatus} size="sm" showDot={false} />
                  </div>
                  {log.note && <p className="text-xs text-slate-400 mt-1.5 italic">"{log.note}"</p>}
                </div>
                <div className="text-right text-[11px] text-slate-500">
                  <div className="flex items-center gap-1 justify-end">
                    <Clock className="w-3 h-3 text-slate-600" />
                    <span>{new Date(log.createdAt).toLocaleTimeString()}</span>
                  </div>
                  <span>{new Date(log.createdAt).toLocaleDateString()}</span>
                </div>
              </div>
            ))}
          </div>
        )}
      </Modal>

      {/* Modal: Campus Buildings Management */}
      <Modal
        isOpen={isBuildingModalOpen}
        onClose={() => setIsBuildingModalOpen(false)}
        title="Campus Building Blocks & Facilities"
        subtitle={`Configure and update physical buildings and campuses for ${selectedUniversity || 'All Universities'}`}
      >
        <div className="space-y-6">
          {bldgSuccess && (
            <div className="p-3 bg-emerald-500/10 border border-emerald-500/20 rounded-xl text-emerald-400 text-xs flex items-center justify-between">
              <span>{bldgSuccess}</span>
              <button onClick={() => setBldgSuccess(null)} className="text-emerald-400/80 hover:text-emerald-200">
                <X className="w-3.5 h-3.5" />
              </button>
            </div>
          )}

          {bldgError && (
            <div className="p-3 bg-rose-500/10 border border-rose-500/20 rounded-xl text-rose-400 text-xs flex items-center justify-between">
              <span>{bldgError}</span>
              <button onClick={() => setBldgError(null)} className="text-rose-400/80 hover:text-rose-200">
                <X className="w-3.5 h-3.5" />
              </button>
            </div>
          )}

          {/* Form: Add or Edit Building */}
          <form onSubmit={handleSaveBuilding} className="p-4 bg-slate-950/60 border border-slate-800 rounded-2xl space-y-3">
            <div className="flex items-center justify-between">
              <span className="text-xs font-bold text-slate-200">
                {editingBuilding ? `Edit Building: ${editingBuilding.name}` : 'Add New Building Block'}
              </span>
              {editingBuilding && (
                <button
                  type="button"
                  onClick={() => {
                    setEditingBuilding(null);
                    setBldgName('');
                    setBldgCampus('Main Campus');
                  }}
                  className="text-xs text-slate-400 hover:text-slate-200 cursor-pointer"
                >
                  Cancel Edit
                </button>
              )}
            </div>

            <div className="grid grid-cols-1 sm:grid-cols-3 gap-3">
              <div>
                <label className="block text-[11px] font-medium text-slate-400 mb-1">Building Name *</label>
                <input
                  type="text"
                  required
                  value={bldgName}
                  onChange={(e) => setBldgName(e.target.value)}
                  placeholder="e.g. Building A, Science Block"
                  className="w-full px-3 py-2 bg-slate-900 border border-slate-800 rounded-xl text-xs text-slate-100 placeholder-slate-600 focus:outline-none focus:border-emerald-500"
                />
              </div>

              <div>
                <label className="block text-[11px] font-medium text-slate-400 mb-1">Campus Name</label>
                <input
                  type="text"
                  value={bldgCampus}
                  onChange={(e) => setBldgCampus(e.target.value)}
                  placeholder="e.g. Permanent Campus"
                  className="w-full px-3 py-2 bg-slate-900 border border-slate-800 rounded-xl text-xs text-slate-100 placeholder-slate-600 focus:outline-none focus:border-emerald-500"
                />
              </div>

              <div>
                <label className="block text-[11px] font-medium text-slate-400 mb-1">Department *</label>
                <select
                  value={bldgDeptId}
                  onChange={(e) => setBldgDeptId(e.target.value)}
                  className="w-full px-3 py-2 bg-slate-900 border border-slate-800 rounded-xl text-xs text-slate-200 focus:outline-none focus:border-emerald-500 cursor-pointer"
                >
                  {depts.map((d) => (
                    <option key={d.id} value={d.id}>
                      {d.code} - {d.name}
                    </option>
                  ))}
                </select>
              </div>
            </div>

            <div className="flex justify-end pt-1">
              <button
                type="submit"
                disabled={isSubmittingBuilding}
                className="px-4 py-2 bg-emerald-500 hover:bg-emerald-600 disabled:opacity-50 text-slate-950 font-bold rounded-xl text-xs shadow-md shadow-emerald-500/20 cursor-pointer transition-all"
              >
                {isSubmittingBuilding
                  ? 'Saving...'
                  : editingBuilding
                  ? 'Update Building'
                  : '+ Save Building Block'}
              </button>
            </div>
          </form>

          {/* List of Registered Buildings */}
          <div>
            <h4 className="text-xs font-semibold text-slate-400 mb-2 uppercase tracking-wider">
              Registered Buildings ({buildings.length})
            </h4>

            {buildings.length === 0 ? (
              <div className="p-6 text-center text-xs text-slate-500 bg-slate-950/40 rounded-xl border border-slate-800/60">
                No buildings registered for this university yet. Add one above.
              </div>
            ) : (
              <div className="space-y-2 max-h-72 overflow-y-auto pr-1">
                {buildings.map((b) => (
                  <div
                    key={b.id}
                    className="p-3 bg-slate-950/60 border border-slate-800/80 rounded-xl flex items-center justify-between hover:border-slate-700 transition-colors"
                  >
                    <div className="space-y-0.5">
                      <div className="flex items-center gap-2">
                        <span className="text-xs font-bold text-slate-100">{b.name}</span>
                        <span className="text-[10px] font-semibold px-2 py-0.2 rounded-md bg-emerald-500/10 text-emerald-400 border border-emerald-500/20">
                          {b.department?.code || 'Dept'}
                        </span>
                      </div>
                      <p className="text-[11px] text-slate-400">
                        {b.campusName} • <span className="text-slate-300 font-medium">{b._count?.rooms ?? 0} room(s)</span>
                      </p>
                    </div>

                    <div className="flex items-center gap-2">
                      <button
                        type="button"
                        onClick={() => handleEditBuilding(b)}
                        className="p-1.5 text-slate-400 hover:text-emerald-400 hover:bg-slate-800 rounded-lg transition-colors cursor-pointer"
                        title="Edit Building"
                      >
                        <Edit2 className="w-3.5 h-3.5" />
                      </button>
                      <button
                        type="button"
                        onClick={() => handleDeleteBuilding(b)}
                        className="p-1.5 text-slate-400 hover:text-rose-400 hover:bg-slate-800 rounded-lg transition-colors cursor-pointer"
                        title="Delete Building"
                      >
                        <Trash2 className="w-3.5 h-3.5" />
                      </button>
                    </div>
                  </div>
                ))}
              </div>
            )}
          </div>
        </div>
      </Modal>
    </div>
  );
};
