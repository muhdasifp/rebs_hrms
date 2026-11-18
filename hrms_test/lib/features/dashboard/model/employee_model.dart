class EmployeeModel {
  final String id;
  final String name;
  final String code;
  final String department;
  final double latitude;
  final double longitude;
  final double radius;

  const EmployeeModel({
    required this.id,
    required this.name,
    required this.code,
    required this.department,
    required this.latitude,
    required this.longitude,
    required this.radius,
  });

  factory EmployeeModel.fromJson(Map<String, dynamic> json) {
    final office = Map<String, dynamic>.from(json['office']);
    return EmployeeModel(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      code: json['employee_code']?.toString() ?? '',
      department: json['department']?.toString() ?? '',
      latitude: (office['latitude'] as num).toDouble(),
      longitude: (office['longitude'] as num).toDouble(),
      radius: (office['allowed_radius'] as num).toDouble(),
    );
  }
}
