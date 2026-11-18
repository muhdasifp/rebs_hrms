import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hrms_test/core/storage/local_database.dart';
import 'package:hrms_test/data/services/location_service.dart';

final firestoreProvider = Provider<FirebaseFirestore>(
  (ref) => FirebaseFirestore.instance,
);
final databaseProvider = Provider((ref) => LocalDatabase());
final locationProvider = Provider((ref) => LocationService());
