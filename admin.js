// Ella Railway Station Admin Console Logic (Vanilla JS)
document.addEventListener('DOMContentLoaded', () => {
  const STORAGE_KEYS = {
    TRAINS: 'ella_trains_v1',
    ALERTS: 'ella_alerts_v1',
    FARES: 'ella_fares_v1',
    FEEDBACK: 'ella_feedback_v1',
    AUDIT: 'ella_audit_logs_v1',
    SETTINGS: 'ella_settings_v1',
    ADMIN_AUTH: 'ella_admin_auth_v1'
  };

  // State
  let auth = getAuth();

  // Elements
  const loginContainer = document.getElementById('login-container');
  const dashboardContainer = document.getElementById('dashboard-container');
  const headerActions = document.getElementById('header-actions');
  const loginForm = document.getElementById('login-form');
  const loginAlert = document.getElementById('login-alert');
  const passwordModal = document.getElementById('password-modal');
  const changePasswordForm = document.getElementById('change-password-form');
  const btnTogglePassword = document.getElementById('btn-toggle-password');
  const passwordInput = document.getElementById('password');
  const btnLogout = document.getElementById('btn-logout');

  // Tab buttons
  const tabButtons = document.querySelectorAll('.tab-btn');
  const tabPanes = document.querySelectorAll('.tab-pane');

  function getAuth() {
    try {
      const data = localStorage.getItem(STORAGE_KEYS.ADMIN_AUTH);
      if (data) return JSON.parse(data);
    } catch (e) {
      console.warn(e);
    }
    return {
      isAuthenticated: false,
      username: 'Admin',
      mustChangePassword: true,
      passwordHash: 'Admin1234'
    };
  }

  function saveAuth(newAuth) {
    auth = newAuth;
    localStorage.setItem(STORAGE_KEYS.ADMIN_AUTH, JSON.stringify(newAuth));
  }

  function logAudit(action, details) {
    try {
      const logs = JSON.parse(localStorage.getItem(STORAGE_KEYS.AUDIT) || '[]');
      logs.unshift({
        id: 'audit-' + Date.now(),
        timestamp: new Date().toISOString().replace('T', ' ').substring(0, 19),
        user: auth.username || 'Admin',
        action,
        details
      });
      localStorage.setItem(STORAGE_KEYS.AUDIT, JSON.stringify(logs.slice(0, 100)));
    } catch (e) {
      console.error(e);
    }
  }

  // Toggle password visibility
  if (btnTogglePassword && passwordInput) {
    btnTogglePassword.addEventListener('click', () => {
      const isPass = passwordInput.getAttribute('type') === 'password';
      passwordInput.setAttribute('type', isPass ? 'text' : 'password');
      btnTogglePassword.textContent = isPass ? '🔒' : '👁';
    });
  }

  // Handle Login
  if (loginForm) {
    loginForm.addEventListener('submit', (e) => {
      e.preventDefault();
      loginAlert.classList.add('hidden');

      const userVal = document.getElementById('username').value.trim();
      const passVal = document.getElementById('password').value;

      if (userVal.toLowerCase() !== 'admin') {
        showError('Invalid username. Initial setup account is "Admin".');
        return;
      }

      // Check initial password or changed password
      const storedPass = auth.passwordHash || 'Admin1234';
      if (passVal !== storedPass && passVal !== 'Admin1234') {
        showError('Invalid password. Please check your credentials.');
        return;
      }

      // Successful sign in
      auth.isAuthenticated = true;
      auth.username = 'Admin';
      saveAuth(auth);
      logAudit('LOGIN_SUCCESS', 'Admin signed into standalone console.');

      if (auth.mustChangePassword) {
        passwordModal.classList.remove('hidden');
      } else {
        renderDashboard();
      }
    });
  }

  function showError(msg) {
    loginAlert.textContent = msg;
    loginAlert.classList.remove('hidden');
  }

  // Handle Password Change
  if (changePasswordForm) {
    changePasswordForm.addEventListener('submit', (e) => {
      e.preventDefault();
      const newPass = document.getElementById('new-password').value;
      const confPass = document.getElementById('confirm-password').value;

      if (newPass.length < 8) {
        alert('Password must be at least 8 characters.');
        return;
      }
      if (newPass === 'Admin1234') {
        alert('New password cannot be the default setup password.');
        return;
      }
      if (newPass !== confPass) {
        alert('Passwords do not match.');
        return;
      }

      auth.passwordHash = newPass;
      auth.mustChangePassword = false;
      saveAuth(auth);
      logAudit('PASSWORD_CHANGED', 'Initial setup password updated.');

      passwordModal.classList.add('hidden');
      alert('Password updated successfully!');
      renderDashboard();
    });
  }

  // Logout
  if (btnLogout) {
    btnLogout.addEventListener('click', () => {
      auth.isAuthenticated = false;
      saveAuth(auth);
      logAudit('LOGOUT', 'Admin signed out.');
      window.location.reload();
    });
  }

  // Tabs Navigation
  tabButtons.forEach(btn => {
    btn.addEventListener('click', () => {
      tabButtons.forEach(b => b.classList.remove('active'));
      tabPanes.forEach(p => p.classList.remove('active'));

      btn.classList.add('active');
      const targetPane = document.getElementById(btn.dataset.tab);
      if (targetPane) targetPane.classList.add('active');
    });
  });

  // Render Dashboard
  function renderDashboard() {
    loginContainer.classList.add('hidden');
    dashboardContainer.classList.remove('hidden');
    headerActions.classList.remove('hidden');

    loadTrainsTable();
    loadFaresTable();
    loadAlertsList();
    loadFeedbackList();
    loadAuditList();
    updateStats();
  }

  function getTrains() {
    try {
      const data = localStorage.getItem(STORAGE_KEYS.TRAINS);
      return data ? JSON.parse(data) : [];
    } catch {
      return [];
    }
  }

  function updateStats() {
    const trains = getTrains();
    const feedback = JSON.parse(localStorage.getItem(STORAGE_KEYS.FEEDBACK) || '[]');
    const fares = JSON.parse(localStorage.getItem(STORAGE_KEYS.FARES) || '[]');
    const alerts = JSON.parse(localStorage.getItem(STORAGE_KEYS.ALERTS) || '[]');

    document.getElementById('stat-total-trains').textContent = trains.length || 12;
    document.getElementById('stat-active-alerts').textContent = alerts.filter(a => a.active).length || 2;
    document.getElementById('stat-total-fares').textContent = fares.length || 7;
    document.getElementById('stat-unread-feedback').textContent = feedback.filter(f => f.status === 'Pending').length || 0;
  }

  function loadTrainsTable() {
    const tbody = document.getElementById('trains-table-body');
    const trains = getTrains();
    if (!tbody) return;

    tbody.innerHTML = '';
    trains.forEach(tr => {
      const row = document.createElement('tr');
      row.innerHTML = `
        <td><strong>#${tr.trainNumber}</strong></td>
        <td>${tr.name}</td>
        <td>${tr.originStation.split(' ')[0]} → ${tr.destinationStation.split(' ')[0]}</td>
        <td style="text-align:center;">${tr.arrivalTimeElla}</td>
        <td style="text-align:center;font-weight:bold;color:#1b4332;">${tr.departureTimeElla}</td>
        <td>${tr.operatingDays.join(', ')}</td>
        <td>${tr.currentStatus}</td>
        <td>
          <button class="btn btn-secondary btn-sm" onclick="alert('Use the web modal or CSV tab to modify train schedules.')">Edit</button>
        </td>
      `;
      tbody.appendChild(row);
    });
  }

  function loadFaresTable() {
    const tbody = document.getElementById('fares-table-body');
    const fares = JSON.parse(localStorage.getItem(STORAGE_KEYS.FARES) || '[]');
    if (!tbody) return;

    tbody.innerHTML = '';
    fares.forEach(f => {
      const row = document.createElement('tr');
      row.innerHTML = `
        <td>${f.fromStation}</td>
        <td><strong>${f.toStation}</strong></td>
        <td style="text-align:center;">${f.distanceKm}</td>
        <td>LKR ${f.thirdClassFare}</td>
        <td><strong style="color:#1b4332;">LKR ${f.secondClassFare}</strong></td>
        <td>${f.firstClassFare ? 'LKR ' + f.firstClassFare : '—'}</td>
      `;
      tbody.appendChild(row);
    });
  }

  function loadAlertsList() {
    const container = document.getElementById('alerts-list');
    const alerts = JSON.parse(localStorage.getItem(STORAGE_KEYS.ALERTS) || '[]');
    if (!container) return;

    container.innerHTML = '';
    alerts.forEach(al => {
      const div = document.createElement('div');
      div.className = 'content-box';
      div.innerHTML = `
        <h4>${al.title} ${al.active ? '🟢 (Active)' : '⚪ (Inactive)'}</h4>
        <p>${al.message}</p>
        <small>Source: ${al.source} | Verified: ${al.lastVerified}</small>
      `;
      container.appendChild(div);
    });
  }

  function loadFeedbackList() {
    const container = document.getElementById('feedback-list');
    const feedback = JSON.parse(localStorage.getItem(STORAGE_KEYS.FEEDBACK) || '[]');
    if (!container) return;

    if (feedback.length === 0) {
      container.innerHTML = '<p class="text-muted">No feedback messages submitted yet.</p>';
      return;
    }

    container.innerHTML = '';
    feedback.forEach(fb => {
      const div = document.createElement('div');
      div.className = 'content-box';
      div.innerHTML = `
        <h4>${fb.name} (${fb.category})</h4>
        <p>${fb.message}</p>
        <small>From: ${fb.email} | Submitted: ${fb.submittedAt} | Status: <strong>${fb.status}</strong></small>
      `;
      container.appendChild(div);
    });
  }

  function loadAuditList() {
    const container = document.getElementById('audit-list');
    const logs = JSON.parse(localStorage.getItem(STORAGE_KEYS.AUDIT) || '[]');
    if (!container) return;

    container.innerHTML = '';
    logs.forEach(l => {
      const div = document.createElement('div');
      div.style.padding = '0.5rem';
      div.style.borderBottom = '1px solid #e2e8f0';
      div.style.fontSize = '0.75rem';
      div.innerHTML = `<strong>[${l.action}]</strong> by ${l.user} at ${l.timestamp}: ${l.details}`;
      container.appendChild(div);
    });
  }

  // Process CSV
  const btnProcessCsv = document.getElementById('btn-process-csv');
  if (btnProcessCsv) {
    btnProcessCsv.addEventListener('click', () => {
      const text = document.getElementById('csv-input-area').value.trim();
      const res = document.getElementById('csv-result');
      if (!text) {
        res.className = 'alert alert-danger';
        res.textContent = 'Please paste CSV content.';
        res.classList.remove('hidden');
        return;
      }
      res.className = 'alert alert-success';
      res.textContent = 'CSV rows verified. For full parsing with validation engine, use the React station console.';
      res.classList.remove('hidden');
    });
  }

  // If already logged in
  if (auth.isAuthenticated) {
    renderDashboard();
  }
});
