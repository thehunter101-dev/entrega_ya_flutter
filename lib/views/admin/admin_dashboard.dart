import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/models.dart';
import '../../providers/app_state.dart';
import '../../services/report_service.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = Provider.of<AppState>(context);
    final company = state.currentCompany;
    final user = state.currentUser;

    if (user == null || company == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('EntregaYa - Administrador')),
        body: const Center(child: Text('Sesión no iniciada.')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('EntregaYa - Panel de Administrador', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            Text(
              '${company.name} | Admin: ${user.name}',
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.normal),
            ),
          ],
        ),
        backgroundColor: Colors.deepPurple[900],
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Restablecer Datos Demo',
            onPressed: () {
              state.resetDemoData();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Datos demo restablecidos al estado original.')),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Cerrar Sesión',
            onPressed: () {
              state.logout();
              Navigator.of(context).popUntil((route) => route.isFirst);
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.amber,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(icon: Icon(Icons.dashboard), text: 'Resumen'),
            Tab(icon: Icon(Icons.directions_car), text: 'Choferes y Flota'),
            Tab(icon: Icon(Icons.payments), text: 'Liquidaciones'),
            Tab(icon: Icon(Icons.bar_chart), text: 'Reportes'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildSummaryTab(state),
          _buildDriversTab(state),
          _buildLiquidacionesTab(state),
          _buildReportsTab(state),
        ],
      ),
    );
  }

  Widget _buildSummaryTab(AppState state) {
    final packages = state.filteredPackages;
    final totalPkgs = packages.length;
    final deliveredPkgs = packages.where((p) => p.status == PackageStatus.entregado).length;
    final failedPkgs = packages.where((p) => p.status == PackageStatus.fallido).length;
    final activePkgs = packages.where((p) => p.status == PackageStatus.en_ruta || p.status == PackageStatus.recibido).length;

    final drivers = state.filteredUsers.where((u) => u.role == UserRole.driver).toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Stat Cards Row
          Wrap(
            spacing: 16,
            runSpacing: 16,
            children: [
              _metricCard('Total Paquetes (Histórico)', totalPkgs.toString(), Icons.inventory_2, Colors.blue[800]!),
              _metricCard('Entregados con Éxito', deliveredPkgs.toString(), Icons.check_circle, Colors.green[800]!),
              _metricCard('En Ruta / Pendientes', activePkgs.toString(), Icons.local_shipping, Colors.orange[800]!),
              _metricCard('Entregas Fallidas', failedPkgs.toString(), Icons.error, Colors.red[800]!),
            ],
          ),
          const SizedBox(height: 24),

          // Drivers Summary
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Estado Operativo de la Flota',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      Chip(
                        label: Text('${drivers.length} Choferes Activos'),
                        backgroundColor: Colors.deepPurple[50],
                      ),
                    ],
                  ),
                  const Divider(height: 20),
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: drivers.length,
                    itemBuilder: (context, index) {
                      final driver = drivers[index];
                      final dPkgs = packages.where((p) => p.driverId == driver.id).toList();
                      final dDelivered = dPkgs.where((p) => p.status == PackageStatus.entregado).length;

                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.deepPurple[100],
                          child: Icon(Icons.person, color: Colors.deepPurple[900]),
                        ),
                        title: Text(driver.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text('Vehículo: ${driver.vehicleModel ?? "N/A"} | Placa: ${driver.licensePlate ?? "N/A"}'),
                        trailing: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text('\$${driver.commissionRate.toStringAsFixed(2)} / entrega', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                            Text('$dDelivered entregas realizadas', style: TextStyle(color: Colors.grey[600], fontSize: 11)),
                          ],
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _metricCard(String title, String value, IconData icon, Color color) {
    return Container(
      width: 220,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8, offset: const Offset(0, 2)),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: color.withOpacity(0.12),
            radius: 24,
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(value, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22, color: color)),
                Text(title, style: TextStyle(color: Colors.grey[700], fontSize: 11)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDriversTab(AppState state) {
    final drivers = state.filteredUsers.where((u) => u.role == UserRole.driver).toList();

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Gestión de Choferes y Tarifas de Comisión',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: ListView.builder(
              itemCount: drivers.length,
              itemBuilder: (context, index) {
                final d = drivers[index];
                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 6),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(16),
                    leading: CircleAvatar(
                      radius: 24,
                      backgroundColor: Colors.deepPurple[100],
                      child: Icon(Icons.directions_car, color: Colors.deepPurple[900]),
                    ),
                    title: Text(d.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 4),
                        Text('Vehículo: ${d.vehicleModel ?? "N/A"}'),
                        Text('Placa: ${d.licensePlate ?? "N/A"}'),
                        Text('Comisión por Entrega: \$${d.commissionRate.toStringAsFixed(2)} USD'),
                      ],
                    ),
                    trailing: Chip(
                      label: const Text('ACTIVO', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 10)),
                      backgroundColor: Colors.green[700],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLiquidacionesTab(AppState state) {
    final liquidations = state.filteredLiquidations;
    final drivers = state.filteredUsers.where((u) => u.role == UserRole.driver).toList();

    if (liquidations.isEmpty) {
      return const Center(child: Text('No hay liquidaciones registradas.'));
    }

    final df = (DateTime d) => '${d.day}/${d.month}/${d.year}';

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: liquidations.length,
      itemBuilder: (context, index) {
        final liq = liquidations[index];
        final driver = drivers.firstWhere(
          (d) => d.id == liq.driverId,
          orElse: () => AppUser(id: '', name: 'Chofer Desconocido', username: '', role: UserRole.driver, empresaId: ''),
        );

        final isApproved = liq.status == LiquidationStatus.aprobada;

        return Card(
          elevation: 2,
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(driver.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    Chip(
                      label: Text(
                        liq.status.name.toUpperCase(),
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 10),
                      ),
                      backgroundColor: isApproved ? Colors.green[700] : Colors.orange[800],
                    ),
                  ],
                ),
                Text('Período: ${df(liq.startDate)} - ${df(liq.endDate)}', style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                const Divider(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Entregas exitosas: ${liq.totalDeliveries}'),
                        Text('Entregas fallidas: ${liq.failedDeliveries}'),
                        Text('Bono productividad: \$${liq.bonus.toStringAsFixed(2)}'),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const Text('Neto a Pagar:', style: TextStyle(fontSize: 11, color: Colors.grey)),
                        Text(
                          '\$${liq.netPay.toStringAsFixed(2)} USD',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.deepPurple[900]),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    OutlinedButton.icon(
                      onPressed: () {
                        ReportService.exportLiquidationToPdf(liq, driver, state.currentCompany!.name);
                      },
                      icon: const Icon(Icons.picture_as_pdf, size: 16),
                      label: const Text('Exportar PDF'),
                    ),
                    const SizedBox(width: 8),
                    if (!isApproved)
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.deepPurple[900],
                          foregroundColor: Colors.white,
                        ),
                        onPressed: () {
                          state.approveLiquidation(liq.id);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Liquidación aprobada con éxito.')),
                          );
                        },
                        child: const Text('Aprobar Liquidación'),
                      ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildReportsTab(AppState state) {
    final companyName = state.currentCompany?.name ?? 'EntregaYa';
    final packages = state.filteredPackages;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 500),
          child: Card(
            elevation: 3,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.description, size: 48, color: Colors.deepPurple[900]),
                  const SizedBox(height: 12),
                  const Text(
                    'Exportación de Reportes Ejecutivos',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Genere reportes consolidados en PDF y Excel con todo el historial de entregas de la empresa.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey[600], fontSize: 13),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepPurple[900],
                      foregroundColor: Colors.white,
                      minimumSize: const Size.fromHeight(48),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () {
                      ReportService.exportPackagesToPdf(packages, companyName);
                    },
                    icon: const Icon(Icons.picture_as_pdf),
                    label: const Text('Exportar Historial a PDF', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green[800],
                      foregroundColor: Colors.white,
                      minimumSize: const Size.fromHeight(48),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () {
                      ReportService.exportPackagesToExcel(packages, companyName);
                    },
                    icon: const Icon(Icons.table_chart),
                    label: const Text('Exportar Historial a Excel (.xlsx)', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
