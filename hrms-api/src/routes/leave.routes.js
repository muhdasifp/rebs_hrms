const express = require('express');
const router = express.Router();
const { leaveBalance, leaveRequests } = require('../data/database');

router.get('/balance', (req, res) => {
  return res.status(200).json({ success: true, data: leaveBalance });
});

router.get('/requests', (req, res) => {
  return res.status(200).json({ success: true, data: leaveRequests });
});

router.post('/requests', (req, res) => {
  const { type, start_date, end_date, reason } = req.body;

  if (req.mockScenario === 'validation_error') {
    return res.status(422).json({
      success: false,
      message: 'Leave validation failed',
      errors: { reason: ['Reason is invalid per server rules'] }
    });
  }

  const errors = {};
  if (!['casual', 'sick'].includes(type)) errors.type = ['Invalid leave type'];

  const today = new Intl.DateTimeFormat('en-CA', { timeZone: 'Asia/Kolkata' }).format(new Date());
  if (!start_date || start_date < today) errors.start_date = ['Start date cannot be before today'];
  if (!end_date || end_date < (start_date || today)) errors.end_date = ['End date cannot be before start date'];
  if (!reason || reason.replace(/\s/g, '').length < 10) errors.reason = ['Reason must have at least 10 non-whitespace characters'];

  if (Object.keys(errors).length) {
    return res.status(422).json({ success: false, message: 'Validation failed', errors });
  }

  const start = new Date(`${start_date}T00:00:00Z`);
  const end = new Date(`${end_date}T00:00:00Z`);
  const days = Math.round((end - start) / 86400000) + 1;

  const overlapping = leaveRequests.some(item =>
    ['pending', 'approved'].includes(item.status) &&
    start_date <= item.end_date && end_date >= item.start_date
  );

  if (overlapping) {
    return res.status(422).json({ success: false, message: 'Leave dates overlap with an existing request' });
  }

  if (days > leaveBalance[type]) {
    return res.status(422).json({
      success: false,
      message: `Insufficient ${type} leave balance (${days} requested, ${leaveBalance[type]} available)`
    });
  }

  const request = { id: leaveRequests.length + 1, type, start_date, end_date, days, reason, status: 'pending' };
  leaveRequests.push(request);
  leaveBalance[type] -= days;

  return res.status(201).json({ success: true, message: 'Leave application submitted', data: request });
});

module.exports = router;
