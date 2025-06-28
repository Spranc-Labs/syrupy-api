import { Routes, Route, Navigate } from 'react-router-dom'
import { Layout } from 'src/components/Layout'
import { AuthProvider } from 'src/features/auth/providers/AuthProvider'
import { ProtectedRoute } from 'src/features/auth/components/ProtectedRoute'
import { Login } from 'src/features/auth/pages/Login'
import { Register } from 'src/features/auth/pages/Register'
import { Dashboard } from 'src/features/dashboard/pages/Dashboard'
import { JournalEntries } from 'src/features/journal/pages/JournalEntries'
import { JournalEditor } from 'src/features/journal/pages/JournalEditor'
import { Goals } from 'src/features/goals/pages/Goals'
import { Habits } from 'src/features/habits/pages/Habits'
import { MoodLogs } from 'src/features/mood/pages/MoodLogs'

export function AppRoutes() {
  return (
    <AuthProvider>
      <Routes>
        {/* Public routes */}
        <Route path="/login" element={<Login />} />
        <Route path="/register" element={<Register />} />
        
        {/* Protected routes */}
        <Route path="/" element={<ProtectedRoute><Layout /></ProtectedRoute>}>
          <Route index element={<Navigate to="/dashboard" replace />} />
          <Route path="dashboard" element={<Dashboard />} />
          <Route path="journal" element={<JournalEntries />} />
          <Route path="journal/new" element={<JournalEditor />} />
          <Route path="journal/:id/edit" element={<JournalEditor />} />
          <Route path="goals" element={<Goals />} />
          <Route path="habits" element={<Habits />} />
          <Route path="mood" element={<MoodLogs />} />
        </Route>
      </Routes>
    </AuthProvider>
  )
} 