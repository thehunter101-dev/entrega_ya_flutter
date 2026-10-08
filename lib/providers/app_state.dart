import 'dart:math';
import 'package:flutter/material.dart';
import '../models/models.dart';
import '../services/database_service.dart';

class AppState extends ChangeNotifier {
  final DatabaseService db = DatabaseService();

  Company? _currentCompany;
  AppUser? _currentUser;

  Company? get currentCompany => _currentCompany;
  AppUser? get currentUser => _currentUser;

  AppState() {
    // Select first company by default
    if (db.companies.isNotEmpty) {
      _currentCompany = db.companies.first;
    }
  }

  void selectCompany(Company company) {
    _currentCompany = company;
    notifyListeners();
  }

  void login(AppUser user) {
    _currentUser = user;
    // Set current company to user's company
    _currentCompany = db.companies.firstWhere((c) => c.id == user.empresaId);
    notifyListeners();
  }

  void logout() {
    _currentUser = null;
    notifyListeners();
  }

  void resetDemoData() {
    db.resetDemoData();
    // Re-verify the current company exists
    if (_currentCompany != null) {
      _currentCompany = db.companies.firstWhere((c) => c.id == _currentCompany!.id);
    } else if (db.companies.isNotEmpty) {
      _currentCompany = db.companies.first;
    }
    // Re-verify logged in user
    if (_currentUser != null) {
      try {
        _currentUser = db.users.firstWhere((u) => u.id == _currentUser!.id);
      } catch (_) {
        _currentUser = null;
      }
    }
    notifyListeners();
  }

  // Multi-tenant getters based on _currentCompany
  List<AppUser> get filteredUsers => _currentCompany != null ? db.getUsers(_currentCompany!.id) : [];
  List<Client> get filteredClients => _currentCompany != null ? db.getClients(_currentCompany!.id) : [];
  List<PackageModel> get filteredPackages => _currentCompany != null ? db.getPackages(_currentCompany!.id) : [];
  List<RouteModel> get filteredRoutes => _currentCompany != null ? db.getRoutes(_currentCompany!.id) : [];
  List<LiquidationModel> get filteredLiquidations => _currentCompany != null ? db.getLiquidations(_currentCompany!.id) : [];

  // Actions
  String registerNewPackage({
    required String senderName,
    required String receiverName,
    required String receiverPhone,
    required String deliveryAddress,
    required String city,
  }) {
    if (_currentCompany == null) return '';

    final random = Random();
    final trackingCode = 'EY-${_currentCompany!.id == 'empresa_1' ? 'EXP' : 'COS'}-${100000 + db.packages.length + 1}';
    final id = 'paquete_${db.packages.length + 1}';

    // Coordinates roughly centered in selected city
    double lat = -2.1894;
    double lng = -79.8890;
    if (city == 'Quito') {
      lat = -0.1807;
      lng = -78.4678;
    } else if (city == 'Cuenca') {
      lat = -2.9001;
      lng = -79.0059;
    } else if (city == 'Manta') {
      lat = -0.9677;
      lng = -80.7089;
    }
    lat += (random.nextDouble() - 0.5) * 0.03;
    lng += (random.nextDouble() - 0.5) * 0.03;

    final newPkg = PackageModel(
      id: id,
      trackingCode: trackingCode,
      senderName: senderName,
      receiverName: receiverName,
      receiverPhone: receiverPhone,
      deliveryAddress: deliveryAddress,
      city: city,
      empresaId: _currentCompany!.id,
      status: PackageStatus.recibido,
      statusHistory: [
        StatusHistoryEntry(
          status: PackageStatus.recibido,
          timestamp: DateTime.now(),
          details: 'Paquete registrado en oficina por despacho de ${_currentCompany!.name}.',
        )
      ],
      lat: lat,
      lng: lng,
    );

    db.addPackage(newPkg);
    notifyListeners();
    return trackingCode;
  }

  void createRoute({
    required String name,
    required String driverId,
    required List<String> packageIds,
  }) {
    if (_currentCompany == null) return;

    final id = 'ruta_${db.routes.length + 1}';
    final newRoute = RouteModel(
      id: id,
      name: name,
      driverId: driverId,
      empresaId: _currentCompany!.id,
      status: RouteStatus.pendiente,
      packageIds: packageIds,
      date: DateTime.now(),
    );

    db.addRoute(newRoute);

    // Update status of packages to "en_ruta" and assign driver
    for (var pId in packageIds) {
      final pIdx = db.packages.indexWhere((p) => p.id == pId);
      if (pIdx != -1) {
        db.packages[pIdx].routeId = id;
        db.packages[pIdx].driverId = driverId;
        db.packages[pIdx].status = PackageStatus.en_ruta;
        db.packages[pIdx].statusHistory.add(StatusHistoryEntry(
          status: PackageStatus.en_ruta,
          timestamp: DateTime.now(),
          details: 'Paquete asignado a Chofer y puesto en Ruta.',
        ));
      }
    }

    notifyListeners();
  }

  void updatePackageDelivery({
    required String id,
    required PackageStatus status,
    required String receiverName,
    required List<List<double>> signaturePoints,
    String? failureReason,
    String? photoBase64,
  }) {
    String details = '';
    if (status == PackageStatus.entregado) {
      details = 'Entregado con éxito a $receiverName. Firma táctil digital guardada.';
    } else {
      details = 'Entrega fallida. Motivo: ${failureReason ?? "Cliente ausente"}.';
    }

    db.updatePackageStatus(
      id,
      status,
      details: details,
      signature: signaturePoints,
      receiverName: receiverName,
      failureReason: failureReason,
      photoBase64: photoBase64,
    );

    // If package was part of a route, and all packages in that route are processed, we can complete the route.
    final pkg = db.packages.firstWhere((p) => p.id == id);
    if (pkg.routeId != null) {
      final rId = pkg.routeId!;
      final rIdx = db.routes.indexWhere((r) => r.id == rId);
      if (rIdx != -1) {
        final route = db.routes[rIdx];
        // Check if all packages on this route are either entregado or fallido
        bool allProcessed = true;
        for (var pId in route.packageIds) {
          try {
            final p = db.packages.firstWhere((p) => p.id == pId);
            if (p.status == PackageStatus.recibido || p.status == PackageStatus.en_ruta) {
              allProcessed = false;
              break;
            }
          } catch (_) {}
        }
        if (allProcessed) {
          db.routes[rIdx].status = RouteStatus.completada;
        } else {
          db.routes[rIdx].status = RouteStatus.en_progreso;
        }
      }
    }

    notifyListeners();
  }

  void approveLiquidation(String liquidationId) {
    db.approveLiquidation(liquidationId);
    notifyListeners();
  }
}
