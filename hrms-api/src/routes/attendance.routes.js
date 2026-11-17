const express = require('express');
const router = express.Router();
const { attendance, attendanceEvents } = require('../data/database');

router.get('/', (req, res) => {
  const month = req.query.month;
  const records = attendance.filter(item => item.date.startsWith(month || ''));
  return res.status(200).json({ success: true, data: records });
});

router.post('/events', (req, res) => {
  const { event_id, type, timestamp, latitude, longitude } = req.body;

  if (!event_id || !['check_in', 'check_out'].includes(type) ||
      !timestamp || latitude == null || longitude == null) {
    return res.status(422).json({ success: false, message: 'Invalid attendance event' });
  }

  if (attendanceEvents.has(event_id)) {
    return res.status(200).json({
      success: true,
      message: 'Event already processed (idempotent)',
      data: attendanceEvents.get(event_id)
    });
  }

  if (req.mockScenario === 'duplicate') {
    return res.status(409).json({
      success: false,
      message: 'Attendance already exists',
      code: 'DUPLICATE_ATTENDANCE'
    });
  }

  const date = timestamp.slice(0, 10);
  let record = attendance.find(item => item.date === date);

  if (type === 'check_in') {
    if (record) {
      return res.status(409).json({
        success: false,
        message: 'Attendance already exists for this date',
        code: 'DUPLICATE_ATTENDANCE'
      });
    }
    record = {
      id: attendance.length + 1,
      date,
      check_in: timestamp,
      check_out: null,
      status: 'checked_in'
    };
    attendance.push(record);
  } else if (type === 'check_out') {
    if (!record || !record.check_in) {
      return res.status(409).json({
        success: false,
        message: 'Check-in required before checkout',
        code: 'CHECK_IN_REQUIRED'
      });
    }
    if (record.check_out) {
      return res.status(409).json({
        success: false,
        message: 'Already checked out',
        code: 'ALREADY_CHECKED_OUT'
      });
    }
    record.check_out = timestamp;
    record.status = 'completed';
  }

  const result = { event_id, attendance_id: record.id, status: 'synced' };
  attendanceEvents.set(event_id, result);
  return res.status(200).json({
    success: true,
    message: 'Attendance event recorded',
    data: result
  });
});

module.exports = router;
