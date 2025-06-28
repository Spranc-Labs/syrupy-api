import { Suspense } from 'react'
import { QueryClientProvider } from '@tanstack/react-query'
import { ReactQueryDevtools } from '@tanstack/react-query-devtools'
import { BrowserRouter } from 'react-router-dom'
import { ToastContainer } from 'react-toastify'
import 'react-toastify/dist/ReactToastify.css'

import { FullscreenSpinner } from 'src/components/Loading/Spinner'
import { AppRoutes } from 'src/router/routes'
import { queryClient } from 'src/utils/queryClient'
import { ThemeProvider } from 'src/providers/ThemeProvider'

function App() {
  return (
    <ThemeProvider>
      <QueryClientProvider client={queryClient}>
        <QueryClientApp />
      </QueryClientProvider>
    </ThemeProvider>
  )
}

function QueryClientApp() {
  return (
    <>
      <BrowserRouter>
        <Suspense fallback={<FullscreenSpinner isLoading={true} />}>
          <AppRoutes />
        </Suspense>
        <ToastContainer 
          stacked 
          theme="colored"
          position="top-right"
          className="!z-50"
        />
      </BrowserRouter>
      <ReactQueryDevtools />
    </>
  )
}

export default App 