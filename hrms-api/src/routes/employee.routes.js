const express = require('express');
const router = express.Router();
const { employee } = require('../data/database');

router.get('/me', (req, res) => {
  return res.json({ success: true, data: employee });
});

module.exports = router;
