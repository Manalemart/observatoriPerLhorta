import { StrictMode } from 'react';
import { createRoot } from 'react-dom/client';
import { BrowserRouter } from 'react-router-dom';
import '@fontsource-variable/montserrat/index.css';
import '@fontsource-variable/source-serif-4/index.css';
import './lib/i18n';
import './index.css';
import { App } from './App';
import { AuthProvider } from './auth/AuthContext';

createRoot(document.getElementById('root')!).render(
  <StrictMode>
    <BrowserRouter>
      <AuthProvider>
        <App />
      </AuthProvider>
    </BrowserRouter>
  </StrictMode>,
);
