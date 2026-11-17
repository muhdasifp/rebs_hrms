import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hrms_test/core/network/api_client.dart';
import 'package:hrms_test/core/storage/local_database.dart';
import 'package:hrms_test/data/services/connectivity_service.dart';
import 'package:hrms_test/data/services/location_service.dart';

final apiProvider = Provider((ref) => ApiClient());
final databaseProvider = Provider((ref) => LocalDatabase());
final connectivityProvider = Provider((ref) => ConnectivityService());
final locationProvider = Provider((ref) => LocationService());
