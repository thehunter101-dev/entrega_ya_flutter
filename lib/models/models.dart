import 'dart:convert';

class Company {
  final String id;
  final String name;

  Company({required this.id, required this.name});
}

enum UserRole { admin, dispatcher, driver }

class AppUser {
  final String id;
  final String name;
  final String username;
  final UserRole role;
  final String empresaId;
  final String? licensePlate;
  final String? vehicleModel;
  final double commissionRate; // USD per delivery

  AppUser({
    required this.id,
    required this.name,
    required this.username,
    required this.role,
    required this.empresaId,
    this.licensePlate,
    this.vehicleModel,
    this.commissionRate = 1.50,
  });
}

class Client {
  final String id;
  final String name;
  final String phone;
  final String address;
  final String city;
  final String empresaId;

  Client({
    required this.id,
    required this.name,
    required this.phone,
    required this.address,
    required this.city,
    required this.empresaId,
  });
}

enum PackageStatus { recibido, en_ruta, entregado, fallido }

class StatusHistoryEntry {
  final PackageStatus status;
  final DateTime timestamp;
  final String details;

  StatusHistoryEntry({
    required this.status,
    required this.timestamp,
    required this.details,
  });

  Map<String, dynamic> toMap() => {
    'status': status.name,
    'timestamp': timestamp.toIso8601String(),
    'details': details,
  };

  factory StatusHistoryEntry.fromMap(Map<String, dynamic> map) => StatusHistoryEntry(
    status: PackageStatus.values.firstWhere((e) => e.name == map['status']),
    timestamp: DateTime.parse(map['timestamp']),
    details: map['details'],
  );
}

class PackageModel {
  final String id;
  final String trackingCode;
  final String senderName;
  final String receiverName;
  final String receiverPhone;
  final String deliveryAddress;
  final String city;
  final String empresaId;
  String? driverId;
  PackageStatus status;
  List<StatusHistoryEntry> statusHistory;
  List<List<double>>? signaturePoints; // Points of the tactile signature
  String? receiverConfirmedName;
  String? failureReason;
  String? photoBase64;
  String? routeId;
  DateTime? deliveryTime;
  double? lat;
  double? lng;

  PackageModel({
    required this.id,
    required this.trackingCode,
    required this.senderName,
    required this.receiverName,
    required this.receiverPhone,
    required this.deliveryAddress,
    required this.city,
    required this.empresaId,
    this.driverId,
    required this.status,
    required this.statusHistory,
    this.signaturePoints,
    this.receiverConfirmedName,
    this.failureReason,
    this.photoBase64,
    this.routeId,
    this.deliveryTime,
    this.lat,
    this.lng,
  });

  PackageModel copyWith({
    String? driverId,
    PackageStatus? status,
    List<StatusHistoryEntry>? statusHistory,
    List<List<double>>? signaturePoints,
    String? receiverConfirmedName,
    String? failureReason,
    String? photoBase64,
    String? routeId,
    DateTime? deliveryTime,
  }) {
    return PackageModel(
      id: this.id,
      trackingCode: this.trackingCode,
      senderName: this.senderName,
      receiverName: this.receiverName,
      receiverPhone: this.receiverPhone,
      deliveryAddress: this.deliveryAddress,
      city: this.city,
      empresaId: this.empresaId,
      driverId: driverId ?? this.driverId,
      status: status ?? this.status,
      statusHistory: statusHistory ?? List.from(this.statusHistory),
      signaturePoints: signaturePoints ?? this.signaturePoints,
      receiverConfirmedName: receiverConfirmedName ?? this.receiverConfirmedName,
      failureReason: failureReason ?? this.failureReason,
      photoBase64: photoBase64 ?? this.photoBase64,
      routeId: routeId ?? this.routeId,
      deliveryTime: deliveryTime ?? this.deliveryTime,
      lat: this.lat,
      lng: this.lng,
    );
  }
}

enum RouteStatus { pendiente, en_progreso, completada }

class RouteModel {
  final String id;
  final String name;
  final String driverId;
  final String empresaId;
  RouteStatus status;
  final List<String> packageIds;
  final DateTime date;

  RouteModel({
    required this.id,
    required this.name,
    required this.driverId,
    required this.empresaId,
    required this.status,
    required this.packageIds,
    required this.date,
  });
}

enum LiquidationStatus { pendiente, aprobada }

class LiquidationModel {
  final String id;
  final String driverId;
  final String empresaId;
  final DateTime startDate;
  final DateTime endDate;
  final int totalDeliveries;
  final int failedDeliveries;
  final double commissionPerDelivery;
  final double totalCommission;
  final double bonus;
  final double netPay;
  LiquidationStatus status;

  LiquidationModel({
    required this.id,
    required this.driverId,
    required this.empresaId,
    required this.startDate,
    required this.endDate,
    required this.totalDeliveries,
    required this.failedDeliveries,
    required this.commissionPerDelivery,
    required this.totalCommission,
    required this.bonus,
    required this.netPay,
    required this.status,
  });
}
