const express = require('express');
const cors = require('cors');

const employeeRoutes = require('./routes/employee.routes');
const attendanceRoutes = require('./routes/attendance.routes');
const leaveRoutes = require('./routes/leave.routes');

const app = express();

app.use(cors());
app.use(express.json());

app.use((req, res, next) => {
  req.mockScenario = req.headers['x-mock-scenario'] || 'success';

  if (req.mockScenario === 'slow') {
    return setTimeout(next, 5000);
  }
  if (req.mockScenario === 'timeout') {
    return; // Never responds
  }
  if (req.mockScenario === 'server_error') {
    return res.status(500).json({ success: false, message: 'Internal server error' });
  }
  next();
});

app.use('/api/employee', employeeRoutes);
app.use('/api/attendance', attendanceRoutes);
app.use('/api/leave', leaveRoutes);

app.get('/', (req, res) => {
  return res.json({ message: 'REBS HRMS Mock API is running' });
});

const PORT = 3000;
const HOST = '0.0.0.0';

app.listen(PORT, HOST, () => {
  console.log(`Mock API running on http://0.0.0.0:${PORT}`);
  console.log('Scenarios: success (default), slow, timeout, server_error, duplicate, validation_error');
});
