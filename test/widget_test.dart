import 'package:flutter_test/flutter_test.dart';
import 'package:entrega_ya/services/database_service.dart';
import 'package:entrega_ya/providers/app_state.dart';
import 'package:entrega_ya/models/models.dart';

void main() {
  group('EntregaYa - Tests de Modelo y Servicios', () {
    test('Inicialización de Seed Data', () {
      final db = DatabaseService();
      db.resetDemoData();

      expect(db.companies.length, equals(2));
      expect(db.users.where((u) => u.role == UserRole.driver).length, equals(8));
      expect(db.packages.length, equals(100));
      expect(db.routes.length, equals(5));
      expect(db.liquidations.isNotEmpty, isTrue);
    });

    test('Multi-tenant - Filtro de datos por Empresa', () {
      final state = AppState();
      final company1 = state.db.companies[0];
      final company2 = state.db.companies[1];

      state.selectCompany(company1);
      final pkgsCompany1 = state.filteredPackages;
      expect(pkgsCompany1.every((p) => p.empresaId == company1.id), isTrue);

      state.selectCompany(company2);
      final pkgsCompany2 = state.filteredPackages;
      expect(pkgsCompany2.every((p) => p.empresaId == company2.id), isTrue);
    });

    test('Flujo de Registro y Entrega de Paquete con Firma Táctil', () {
      final state = AppState();
      state.selectCompany(state.db.companies[0]);

      // 1. Despachador registra nuevo paquete
      final trackingCode = state.registerNewPackage(
        senderName: 'Prueba Remitente',
        receiverName: 'Prueba Destinatario',
        receiverPhone: '0991234567',
        deliveryAddress: 'Av. Samborondón Km 2',
        city: 'Guayaquil',
      );

      expect(trackingCode.isNotEmpty, isTrue);

      final pkg = state.filteredPackages.firstWhere((p) => p.trackingCode == trackingCode);
      expect(pkg.status, equals(PackageStatus.recibido));

      // 2. Chofer completa la entrega y firma
      final testSignature = [
        [10.0, 10.0],
        [20.0, 20.0],
        [30.0, 10.0]
      ];

      state.updatePackageDelivery(
        id: pkg.id,
        status: PackageStatus.entregado,
        receiverName: 'Carlos Receptor',
        signaturePoints: testSignature,
      );

      final updatedPkg = state.filteredPackages.firstWhere((p) => p.id == pkg.id);
      expect(updatedPkg.status, equals(PackageStatus.entregado));
      expect(updatedPkg.receiverConfirmedName, equals('Carlos Receptor'));
      expect(updatedPkg.signaturePoints, equals(testSignature));
    });
  });
}
