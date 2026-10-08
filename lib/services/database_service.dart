import 'dart:math';
import '../models/models.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal() {
    resetDemoData();
  }

  // Collections
  List<Company> companies = [];
  List<AppUser> users = [];
  List<Client> clients = [];
  List<PackageModel> packages = [];
  List<RouteModel> routes = [];
  List<LiquidationModel> liquidations = [];

  void resetDemoData() {
    companies.clear();
    users.clear();
    clients.clear();
    packages.clear();
    routes.clear();
    liquidations.clear();

    final random = Random(42); // Seed for reproducibility

    // 1. Companies
    companies.addAll([
      Company(id: 'empresa_1', name: 'Courier Demo Express'),
      Company(id: 'empresa_2', name: 'Distribución Demo Costa'),
    ]);

    // 2. Users
    // Admin for Empresa 1
    users.add(AppUser(
      id: 'admin_1',
      name: 'Andrés Alarcón (Admin)',
      username: 'admin1',
      role: UserRole.admin,
      empresaId: 'empresa_1',
    ));
    // Admin for Empresa 2
    users.add(AppUser(
      id: 'admin_2',
      name: 'Beatriz Benítez (Admin)',
      username: 'admin2',
      role: UserRole.admin,
      empresaId: 'empresa_2',
    ));

    // Dispatchers (2 per company to show multi-user)
    users.addAll([
      AppUser(
        id: 'disp_1_1',
        name: 'Diego Delgado (Despacho)',
        username: 'disp_1_1',
        role: UserRole.dispatcher,
        empresaId: 'empresa_1',
      ),
      AppUser(
        id: 'disp_1_2',
        name: 'Daniela Díaz (Despacho)',
        username: 'disp_1_2',
        role: UserRole.dispatcher,
        empresaId: 'empresa_1',
      ),
      AppUser(
        id: 'disp_2_1',
        name: 'Darío Duarte (Despacho)',
        username: 'disp_2_1',
        role: UserRole.dispatcher,
        empresaId: 'empresa_2',
      ),
      AppUser(
        id: 'disp_2_2',
        name: 'Dulce Dávila (Despacho)',
        username: 'disp_2_2',
        role: UserRole.dispatcher,
        empresaId: 'empresa_2',
      ),
    ]);

    // Drivers: 8 drivers (4 for Empresa 1, 4 for Empresa 2)
    final driverNames = [
      // Empresa 1
      {'name': 'Carlos Castro', 'plate': 'GBA-1234', 'vehicle': 'Chevrolet Luv D-Max'},
      {'name': 'Eduardo Estrella', 'plate': 'PBA-5678', 'vehicle': 'Hino Dutro 300'},
      {'name': 'Franklin Flores', 'plate': 'ABA-9012', 'vehicle': 'Toyota Hilux'},
      {'name': 'Gabriel Gómez', 'plate': 'MBA-3456', 'vehicle': 'Kia Frontier'},
      // Empresa 2
      {'name': 'Hugo Herrera', 'plate': 'GBC-7890', 'vehicle': 'Suzuki Super Carry'},
      {'name': 'Iván Izquierdo', 'plate': 'PBC-2345', 'vehicle': 'Hyundai H100'},
      {'name': 'Jorge Jurado', 'plate': 'ABC-6789', 'vehicle': 'Foton Gratour'},
      {'name': 'Luis Luna', 'plate': 'MBC-0123', 'vehicle': 'Chevrolet N300 Max'},
    ];

    for (int i = 0; i < driverNames.length; i++) {
      final isEmpresa1 = i < 4;
      final empId = isEmpresa1 ? 'empresa_1' : 'empresa_2';
      users.add(AppUser(
        id: 'chofer_${i + 1}',
        name: driverNames[i]['name']!,
        username: 'chofer_${i + 1}',
        role: UserRole.driver,
        empresaId: empId,
        licensePlate: driverNames[i]['plate'],
        vehicleModel: driverNames[i]['vehicle'],
        commissionRate: 1.50 + (random.nextDouble() * 1.00), // Comisiones entre $1.50 y $2.50
      ));
    }

    // 3. 30 Clients with Ecuadorian context (15 per company)
    final cities = ['Guayaquil', 'Quito', 'Cuenca', 'Manta'];
    final clientFirstNames = [
      'Juan', 'María', 'José', 'Ana', 'Luis', 'Diana', 'Pedro', 'Laura', 'Carlos', 'Sofía',
      'Gabriel', 'Elena', 'Fernando', 'Carmen', 'Santiago', 'Mónica', 'Ricardo', 'Patricia', 'Roberto', 'Paola'
    ];
    final clientLastNames = [
      'Guerrero', 'Mendoza', 'Silva', 'Flores', 'Vera', 'Plaza', 'Espinoza', 'Ortega', 'Torres', 'Paredes',
      'Cevallos', 'Moreira', 'Castillo', 'Arias', 'Vargas', 'Reyes', 'Cárdenas', 'Guzmán', 'Maldonado', 'Salazar'
    ];

    for (int i = 0; i < 30; i++) {
      final fName = clientFirstNames[random.nextInt(clientFirstNames.length)];
      final lName = clientLastNames[random.nextInt(clientLastNames.length)];
      final phone = '099 ${random.nextInt(900) + 100} ${random.nextInt(9000) + 1000}';
      final city = cities[random.nextInt(cities.length)];
      final sector = random.nextInt(5) + 1;
      final address = 'Sector $sector, Av. Principal y Calle Secundaria N-${random.nextInt(100) + 1}';
      final empId = (i < 15) ? 'empresa_1' : 'empresa_2';

      clients.add(Client(
        id: 'cliente_${i + 1}',
        name: '$fName $lName',
        phone: phone,
        address: address,
        city: city,
        empresaId: empId,
      ));
    }

    // 4. 100 Packages distributed over 3 months
    // Let's create dates over the last 90 days
    final now = DateTime.now();
    final statuses = [
      PackageStatus.entregado,
      PackageStatus.recibido,
      PackageStatus.en_ruta,
      PackageStatus.fallido
    ];

    // Status distributions
    // Delivered: ~55%, Recibido: ~20%, En Ruta: ~15%, Fallido: ~10%
    final statusSelector = [
      ...List.filled(55, PackageStatus.entregado),
      ...List.filled(20, PackageStatus.recibido),
      ...List.filled(15, PackageStatus.en_ruta),
      ...List.filled(10, PackageStatus.fallido),
    ];

    final senders = [
      'Almacenes De Prati', 'Tiendas RM', 'Marathon Sports', 'Supermaxi GYE', 'Sukasa Quito',
      'Kywi Cuenca', 'Comandato Manta', 'Computron SA', 'Sony Center Ecuador', 'Etafashion'
    ];

    for (int i = 0; i < 100; i++) {
      final empId = (i < 50) ? 'empresa_1' : 'empresa_2';
      final companyClients = clients.where((c) => c.empresaId == empId).toList();
      final client = companyClients[random.nextInt(companyClients.length)];

      final trackingCode = 'EY-${empId == 'empresa_1' ? 'EXP' : 'COS'}-${100000 + i}';
      final sender = senders[random.nextInt(senders.length)];

      // Get drivers of this company
      final companyDrivers = users.where((u) => u.role == UserRole.driver && u.empresaId == empId).toList();
      final driver = companyDrivers[random.nextInt(companyDrivers.length)];

      // Status
      final status = statusSelector[random.nextInt(statusSelector.length)];

      // Package dates
      final daysAgo = random.nextInt(90); // Last 3 months
      final createdTime = now.subtract(Duration(days: daysAgo, hours: random.nextInt(12) + 1));

      final history = <StatusHistoryEntry>[
        StatusHistoryEntry(
          status: PackageStatus.recibido,
          timestamp: createdTime,
          details: 'Paquete recibido en centro de distribución por Despachador.',
        )
      ];

      DateTime? deliveryTime;
      String? recName;
      String? failReason;
      List<List<double>>? sigPoints;

      if (status == PackageStatus.en_ruta || status == PackageStatus.entregado || status == PackageStatus.fallido) {
        final enRutaTime = createdTime.add(Duration(hours: random.nextInt(4) + 1));
        history.add(StatusHistoryEntry(
          status: PackageStatus.en_ruta,
          timestamp: enRutaTime,
          details: 'Paquete asignado a Chofer ${driver.name} (Vehículo: ${driver.vehicleModel}, Placa: ${driver.licensePlate}) en ruta activa.',
        ));

        if (status == PackageStatus.entregado) {
          deliveryTime = enRutaTime.add(Duration(minutes: random.nextInt(120) + 30));
          recName = client.name;
          // Generate a dummy checkmark signature shape
          sigPoints = [
            [20.0, 50.0], [40.0, 80.0], [90.0, 20.0]
          ];
          history.add(StatusHistoryEntry(
            status: PackageStatus.entregado,
            timestamp: deliveryTime,
            details: 'Entregado con éxito a $recName. Firma digital registrada.',
          ));
        } else if (status == PackageStatus.fallido) {
          deliveryTime = enRutaTime.add(Duration(minutes: random.nextInt(120) + 30));
          final reasons = [
            'Cliente ausente en domicilio.',
            'Dirección incompleta o no localizada.',
            'Cliente rechazó la entrega.',
            'No se pudo contactar al cliente por teléfono.',
            'Zona inaccesible o de alto riesgo.'
          ];
          failReason = reasons[random.nextInt(reasons.length)];
          history.add(StatusHistoryEntry(
            status: PackageStatus.fallido,
            timestamp: deliveryTime,
            details: 'Entrega fallida. Motivo: $failReason',
          ));
        }
      }

      // Coordinate matching city roughly
      double lat = -2.1894; // GYE default
      double lng = -79.8890;
      if (client.city == 'Quito') {
        lat = -0.1807;
        lng = -78.4678;
      } else if (client.city == 'Cuenca') {
        lat = -2.9001;
        lng = -79.0059;
      } else if (client.city == 'Manta') {
        lat = -0.9677;
        lng = -80.7089;
      }

      // Add slight jitter
      lat += (random.nextDouble() - 0.5) * 0.05;
      lng += (random.nextDouble() - 0.5) * 0.05;

      packages.add(PackageModel(
        id: 'paquete_${i + 1}',
        trackingCode: trackingCode,
        senderName: sender,
        receiverName: client.name,
        receiverPhone: client.phone,
        deliveryAddress: client.address,
        city: client.city,
        empresaId: empId,
        driverId: (status == PackageStatus.recibido) ? null : driver.id,
        status: status,
        statusHistory: history,
        deliveryTime: deliveryTime,
        receiverConfirmedName: recName,
        failureReason: failReason,
        signaturePoints: sigPoints,
        lat: lat,
        lng: lng,
      ));
    }

    // 5. 5 Active Routes
    // Let's create 5 active/recent routes (3 for Empresa 1, 2 for Empresa 2)
    final routeCities = ['Guayaquil Norte', 'Quito Centro', 'Cuenca Urbana', 'Manta Puerto', 'Guayaquil Samborondón'];
    for (int i = 0; i < 5; i++) {
      final empId = (i < 3) ? 'empresa_1' : 'empresa_2';
      final companyDrivers = users.where((u) => u.role == UserRole.driver && u.empresaId == empId).toList();
      final driver = companyDrivers[i % companyDrivers.length];

      // Get packages that are recibido or en_ruta to assign to route
      final companyPackages = packages.where((p) => p.empresaId == empId && (p.status == PackageStatus.recibido || p.status == PackageStatus.en_ruta)).toList();
      final routePkgIds = companyPackages.take(5).map((p) => p.id).toList();

      final rId = 'ruta_${i + 1}';
      final route = RouteModel(
        id: rId,
        name: 'Ruta ${routeCities[i]} - ${driver.name.split(' ')[0]}',
        driverId: driver.id,
        empresaId: empId,
        status: (i == 4) ? RouteStatus.completada : RouteStatus.en_progreso,
        packageIds: routePkgIds,
        date: now.subtract(Duration(hours: i * 4)),
      );

      routes.add(route);

      // Link packages to this route
      for (var pId in routePkgIds) {
        final pIdx = packages.indexWhere((p) => p.id == pId);
        if (pIdx != -1) {
          packages[pIdx].routeId = rId;
          packages[pIdx].driverId = driver.id;
          if (packages[pIdx].status == PackageStatus.recibido) {
            packages[pIdx].status = PackageStatus.en_ruta;
            packages[pIdx].statusHistory.add(StatusHistoryEntry(
              status: PackageStatus.en_ruta,
              timestamp: now,
              details: 'Asignado a la ruta ${route.name} con Chofer ${driver.name}.',
            ));
          }
        }
      }
    }

    // 6. Liquidaciones: 2 weeks of calculated liquidations (recent)
    // Liquidations occur weekly. Let's build weekly liquidations for each driver for the past 2 weeks
    final weeks = [
      {'start': now.subtract(const Duration(days: 14)), 'end': now.subtract(const Duration(days: 7))},
      {'start': now.subtract(const Duration(days: 7)), 'end': now},
    ];

    int liqCounter = 1;
    final companyDrivers = users.where((u) => u.role == UserRole.driver).toList();

    for (var week in weeks) {
      final start = week['start']!;
      final end = week['end']!;

      for (var driver in companyDrivers) {
        // Count driver deliveries in this window
        final driverPkgs = packages.where((p) =>
            p.driverId == driver.id &&
            p.deliveryTime != null &&
            p.deliveryTime!.isAfter(start) &&
            p.deliveryTime!.isBefore(end)
        ).toList();

        final deliveredCount = driverPkgs.where((p) => p.status == PackageStatus.entregado).length;
        final failedCount = driverPkgs.where((p) => p.status == PackageStatus.fallido).length;

        if (deliveredCount > 0 || failedCount > 0) {
          final totalCommission = deliveredCount * driver.commissionRate;
          final bonus = deliveredCount > 8 ? 15.00 : 0.00; // Bonus por alta productividad
          final netPay = totalCommission + bonus;

          liquidations.add(LiquidationModel(
            id: 'liq_${liqCounter++}',
            driverId: driver.id,
            empresaId: driver.empresaId,
            startDate: start,
            endDate: end,
            totalDeliveries: deliveredCount,
            failedDeliveries: failedCount,
            commissionPerDelivery: driver.commissionRate,
            totalCommission: totalCommission,
            bonus: bonus,
            netPay: netPay,
            status: random.nextBool() ? LiquidationStatus.aprobada : LiquidationStatus.pendiente,
          ));
        }
      }
    }
  }

  // Database helper methods
  List<AppUser> getUsers(String empresaId) => users.where((u) => u.empresaId == empresaId).toList();

  List<Client> getClients(String empresaId) => clients.where((c) => c.empresaId == empresaId).toList();

  List<PackageModel> getPackages(String empresaId) => packages.where((p) => p.empresaId == empresaId).toList();

  List<RouteModel> getRoutes(String empresaId) => routes.where((r) => r.empresaId == empresaId).toList();

  List<LiquidationModel> getLiquidations(String empresaId) => liquidations.where((l) => l.empresaId == empresaId).toList();

  PackageModel? getPackageByTrackingCode(String trackingCode) {
    try {
      return packages.firstWhere((p) => p.trackingCode.toLowerCase().trim() == trackingCode.toLowerCase().trim());
    } catch (_) {
      return null;
    }
  }

  void addPackage(PackageModel package) {
    packages.add(package);
  }

  void addRoute(RouteModel route) {
    routes.add(route);
  }

  void approveLiquidation(String id) {
    final idx = liquidations.indexWhere((l) => l.id == id);
    if (idx != -1) {
      liquidations[idx].status = LiquidationStatus.aprobada;
    }
  }

  void updatePackageStatus(String id, PackageStatus status, {
    String? details,
    List<List<double>>? signature,
    String? receiverName,
    String? failureReason,
    String? photoBase64,
  }) {
    final idx = packages.indexWhere((p) => p.id == id);
    if (idx != -1) {
      final p = packages[idx];
      packages[idx] = p.copyWith(
        status: status,
        signaturePoints: signature,
        receiverConfirmedName: receiverName,
        failureReason: failureReason,
        photoBase64: photoBase64,
        deliveryTime: DateTime.now(),
        statusHistory: [
          ...p.statusHistory,
          StatusHistoryEntry(
            status: status,
            timestamp: DateTime.now(),
            details: details ?? 'Estado actualizado a ${status.name}.',
          )
        ],
      );
    }
  }
}
