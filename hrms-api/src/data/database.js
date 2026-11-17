const employee = {
    id: 101,
    name: "Asif",
    employee_code: "REBS001",
    department: "Development",
    office: {
        name: "REBS Office",
        latitude: 10.0159,
        longitude: 76.3419,
        allowed_radius: 200
    },
    timezone: "Asia/Kolkata"
};

const attendance = [];

const attendanceEvents = new Map();

const leaveBalance = {
    casual: 8,
    sick: 5,
    total: 13
};

const leaveRequests = [];

module.exports = {
    employee,
    attendance,
    attendanceEvents,
    leaveBalance,
    leaveRequests
};