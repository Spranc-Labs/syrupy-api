import { Suspense } from 'react'
import { QueryClientProvider } from '@tanstack/react-query'
import { ReactQueryDevtools } from '@tanstack/react-query-devtools'
import { BrowserRouter } from 'react-router-dom'
import { ToastContainer } from 'react-toastify'
import 'react-toastify/dist/ReactToastify.css'

import { FullscreenSpinner } from 'src/components/Loading/Spinner'
import { AppRoutes } from 'src/router/routes'
import { queryClient } from 'src/utils/queryClient'

function App() {
  return (
    <QueryClientProvider client={queryClient}>
      <QueryClientApp />
    </QueryClientProvider>
  )
}

function QueryClientApp() {
  return (
    <>
      <BrowserRouter>
        <Suspense fallback={<FullscreenSpinner isLoading={true} />}>
          <AppRoutes />
        </Suspense>
        <ToastContainer stacked />
      </BrowserRouter>
      <ReactQueryDevtools />
    </>
  )
}

export default App 