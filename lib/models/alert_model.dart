import 'package:cloud_firestore/cloud_firestore.dart';

enum AlertStatus { pending, acknowledged, resolved, cancelled }

class LocationData {
  final double latitude;
  final double longitude;

  LocationData({
    required this.latitude,
    required this.longitude,
  });

  Map<String, dynamic> toMap() {
    return {
      'latitude': latitude,
      'longitude': longitude,
    };
  }

  factory LocationData.fromMap(Map<String, dynamic> map) {
    return LocationData(
      latitude: map['latitude']?.toDouble() ?? 0.0,
      longitude: map['longitude']?.toDouble() ?? 0.0,
    );
  }
}

class AlertModel {
  final String alertId;
  final String personId;
  final String personName;
  final DateTime timestamp;
  final LocationData location;
  final AlertStatus status;
  final String? acknowledgedBy;
  final DateTime? acknowledgedAt;

  AlertModel({
    required this.alertId,
    required this.personId,
    required this.personName,
    required this.timestamp,
    required this.location,
    this.status = AlertStatus.pending,
    this.acknowledgedBy,
    this.acknowledgedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'alertId': alertId,
      'personId': personId,
      'personName': personName,
      'timestamp': Timestamp.fromDate(timestamp),
      'location': location.toMap(),
      'status': _statusToString(status),
      'acknowledgedBy': acknowledgedBy,
      'acknowledgedAt': acknowledgedAt != null
          ? Timestamp.fromDate(acknowledgedAt!)
          : null,
    };
  }

  factory AlertModel.fromMap(Map<String, dynamic> map, String docId) {
    return AlertModel(
      alertId: docId,
      personId: map['personId'] ?? '',
      personName: map['personName'] ?? '',
      timestamp: (map['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      location: LocationData.fromMap(map['location'] ?? {}),
      status: _stringToStatus(map['status']),
      acknowledgedBy: map['acknowledgedBy'],
      acknowledgedAt: (map['acknowledgedAt'] as Timestamp?)?.toDate(),
    );
  }

  static String _statusToString(AlertStatus status) {
    switch (status) {
      case AlertStatus.pending:
        return 'pending';
      case AlertStatus.acknowledged:
        return 'acknowledged';
      case AlertStatus.resolved:
        return 'resolved';
      case AlertStatus.cancelled:
        return 'cancelled';
    }
  }

  static AlertStatus _stringToStatus(String? status) {
    switch (status) {
      case 'acknowledged':
        return AlertStatus.acknowledged;
      case 'resolved':
        return AlertStatus.resolved;
      case 'cancelled':
        return AlertStatus.cancelled;
      default:
        return AlertStatus.pending;
    }
  }

  AlertModel copyWith({
    String? alertId,
    String? personId,
    String? personName,
    DateTime? timestamp,
    LocationData? location,
    AlertStatus? status,
    String? acknowledgedBy,
    DateTime? acknowledgedAt,
  }) {
    return AlertModel(
      alertId: alertId ?? this.alertId,
      personId: personId ?? this.personId,
      personName: personName ?? this.personName,
      timestamp: timestamp ?? this.timestamp,
      location: location ?? this.location,
      status: status ?? this.status,
      acknowledgedBy: acknowledgedBy ?? this.acknowledgedBy,
      acknowledgedAt: acknowledgedAt ?? this.acknowledgedAt,
    );
  }
}
