import React from 'react';
import { BrowserRouter, Routes, Route, Navigate } from 'react-router-dom';
import { AuthProvider } from './context/AuthContext';
import { AdminLayout } from './components/layout/AdminLayout';
import { LoginPage } from './pages/LoginPage';
import { DashboardPage } from './pages/DashboardPage';
import { UniversitiesPage } from './pages/UniversitiesPage';
import { DepartmentsPage } from './pages/DepartmentsPage';
import { CohortsPage } from './pages/CohortsPage';
import { RoomsPage } from './pages/RoomsPage';
import { RoutinePage } from './pages/RoutinePage';

export const App: React.FC = () => {
  return (
    <BrowserRouter>
      <AuthProvider>
        <Routes>
          {/* Public Auth Route */}
          <Route path="/login" element={<LoginPage />} />

          {/* Protected Admin Shell */}
          <Route path="/" element={<AdminLayout />}>
            <Route index element={<DashboardPage />} />
            <Route path="universities" element={<UniversitiesPage />} />
            <Route path="departments" element={<DepartmentsPage />} />
            <Route path="cohorts" element={<CohortsPage />} />
            <Route path="batches" element={<Navigate to="/cohorts" replace />} />
            <Route path="rooms" element={<RoomsPage />} />
            <Route path="routine" element={<RoutinePage />} />
            <Route path="schedules" element={<Navigate to="/routine" replace />} />
          </Route>

          {/* Fallback */}
          <Route path="*" element={<Navigate to="/" replace />} />
        </Routes>
      </AuthProvider>
    </BrowserRouter>
  );
};

export default App;
