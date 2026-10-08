import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/models.dart';
import '../../providers/app_state.dart';
import '../../services/report_service.dart';
import '../public_tracking_view.dart';

class DispatcherDashboard extends StatefulWidget {
  const DispatcherDashboard({super.key});

  @override
  State<DispatcherDashboard> createState() => _DispatcherDashboardState();
}

class _DispatcherDashboardState extends State<DispatcherDashboard> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Package Registration Form State
  final _formKey = GlobalKey<FormState>();
  final _senderController = TextEditingController();
  final _receiverController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  String _selectedCity = 'Guayaquil';

  // Route Creator State
  final List<String> _selectedPackageIds = [];
  AppUser? _selectedDriver;
  final _routeNameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _senderController.dispose();
    _receiverController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _routeNameController.dispose();
    super.dispose();
  }

  void _clearRegistrationForm() {
    _senderController.clear();
    _receiverController.clear();
    _phoneController.clear();
    _addressController.clear();
    _selectedCity = 'Guayaquil';
  }

  void _submitRegistration() {
    if (!_formKey.currentState!.validate()) return;

    final state = Provider.of<AppState>(context, listen: false);
    final trackingCode = state.registerNewPackage(
      senderName: _senderController.text.trim(),
      receiverName: _receiverController.text.trim(),
      receiverPhone: _phoneController.text.trim(),
      deliveryAddress: _addressController.text.trim(),
      city: _selectedCity,
    );

    _clearRegistrationForm();

    // Show tracking link generated dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.green, size: 28),
            const SizedBox(width: 8),
            const Text('Paquete Registrado'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'El paquete se ha registrado en el sistema. Se generó el siguiente código único de tracking:',
              style: TextStyle(fontSize: 13),
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                border: Border.all(color: Colors.blue[100]!),
                borderRadius: BorderRadius.circular(10),
              ),
              child: SelectableText(
                trackingCode,
                textAlign: TextAlign.center,
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: Colors.blue[900]),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Enlace simulado: entregana.com/track/$trackingCode',
              style: const TextStyle(fontSize: 11, color: Colors.grey, fontStyle: FontStyle.italic),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text('Cerrar'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(context);
              _openSimulatedTracking(trackingCode);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue[900],
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            icon: const Icon(Icons.open_in_new, size: 16),
            label: const Text('Rastrear en Vivo'),
          )
        ],
      ),
    );
  }

  void _openSimulatedTracking(String trackingCode) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.grey[100],
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(topLeft: Radius.circular(20), topRight: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.85,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) => Column(
          children: [
            AppBar(
              title: Text('Seguimiento Público - $trackingCode'),
              backgroundColor: Colors.white,
              elevation: 1,
              automaticallyImplyLeading: false,
              actions: [
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                )
              ],
            ),
            Expanded(
              child: PublicTrackingView(initialTrackingCode: trackingCode),
            ),
          ],
        ),
      ),
    );
  }

  void _submitRoute() {
    final state = Provider.of<AppState>(context, listen: false);

    if (_routeNameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Escriba un nombre para la ruta.')),
      );
      return;
    }
    if (_selectedDriver == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Seleccione un chofer para realizar la entrega.')),
      );
      return;
    }
    if (_selectedPackageIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Seleccione al menos 1 paquete de la lista.')),
      );
      return;
    }

    state.createRoute(
      name: _routeNameController.text.trim(),
      driverId: _selectedDriver!.id,
      packageIds: List.from(_selectedPackageIds),
    );

    setState(() {
      _selectedPackageIds.clear();
      _routeNameController.clear();
      _selectedDriver = null;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.white),
            SizedBox(width: 8),
            Text('¡Ruta asignada e iniciada exitosamente!'),
          ],
        ),
        backgroundColor: Colors.green[800],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = Provider.of<AppState>(context);
    final currentCompany = state.currentCompany;
    final currentUser = state.currentUser;

    if (currentCompany == null || currentUser == null) {
      return const Scaffold(body: Center(child: Text('Acceso Denegado. Por favor inicie sesión.')));
    }

    // Get packages that are recibido
    final pendingPackages = state.filteredPackages.where((p) => p.status == PackageStatus.recibido).toList();
    // Get drivers
    final drivers = state.filteredUsers.where((u) => u.role == UserRole.driver).toList();

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              currentUser.name,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            Text(
              'Despachador • ${currentCompany.name}',
              style: const TextStyle(fontSize: 12, color: Colors.white70),
            ),
          ],
        ),
        backgroundColor: Colors.blue[900],
        foregroundColor: Colors.white,
        elevation: 2,
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          tabs: const [
            Tab(icon: Icon(Icons.post_add), text: 'Registrar Paquete'),
            Tab(icon: Icon(Icons.alt_route), text: 'Armar Ruta'),
            Tab(icon: Icon(Icons.payments_outlined), text: 'Liquidaciones'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              state.logout();
              Navigator.pop(context);
            },
          )
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // TAB 1: REGISTRAR PAQUETE
          _buildPackageRegistrationTab(),

          // TAB 2: ARMAR RUTA
          _buildArmarRutasTab(pendingPackages, drivers),

          // TAB 3: LIQUIDACIONES
          _buildLiquidacionesTab(state),
        ],
      ),
    );
  }

  Widget _buildPackageRegistrationTab() {
    final cities = ['Guayaquil', 'Quito', 'Cuenca', 'Manta'];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20.0),
      child: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 600),
          child: Card(
            elevation: 3,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.add_box, color: Colors.blue[900], size: 28),
                        const SizedBox(width: 8),
                        const Text(
                          'Nuevo Paquete Courier',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                        ),
                      ],
                    ),
                    const Divider(height: 24),

                    // Sender
                    TextFormField(
                      controller: _senderController,
                      decoration: const InputDecoration(
                        labelText: 'Remitente / Empresa de Origen',
                        prefixIcon: Icon(Icons.store),
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) => value == null || value.trim().isEmpty ? 'Ingrese el remitente' : null,
                    ),
                    const SizedBox(height: 16),

                    // Receiver
                    TextFormField(
                      controller: _receiverController,
                      decoration: const InputDecoration(
                        labelText: 'Nombre del Destinatario',
                        prefixIcon: Icon(Icons.person),
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) => value == null || value.trim().isEmpty ? 'Ingrese el destinatario' : null,
                    ),
                    const SizedBox(height: 16),

                    // Phone
                    TextFormField(
                      controller: _phoneController,
                      decoration: const InputDecoration(
                        labelText: 'Teléfono del Destinatario',
                        prefixIcon: Icon(Icons.phone),
                        hintText: '099 000 0000',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.phone,
                      validator: (value) => value == null || value.trim().isEmpty ? 'Ingrese un número telefónico' : null,
                    ),
                    const SizedBox(height: 16),

                    // City Dropdown
                    DropdownButtonFormField<String>(
                      value: _selectedCity,
                      decoration: const InputDecoration(
                        labelText: 'Ciudad de Destino',
                        prefixIcon: Icon(Icons.location_city),
                        border: OutlineInputBorder(),
                      ),
                      items: cities.map((city) => DropdownMenuItem(
                        value: city,
                        child: Text(city),
                      )).toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setState(() {
                            _selectedCity = val;
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 16),

                    // Address
                    TextFormField(
                      controller: _addressController,
                      decoration: const InputDecoration(
                        labelText: 'Dirección Completa de Entrega',
                        prefixIcon: Icon(Icons.home),
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 2,
                      validator: (value) => value == null || value.trim().isEmpty ? 'Ingrese la dirección física' : null,
                    ),
                    const SizedBox(height: 24),

                    // Submit Button
                    ElevatedButton(
                      onPressed: _submitRegistration,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue[900],
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text(
                        'Registrar y Generar Código',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildArmarRutasTab(List<PackageModel> pendingPackages, List<AppUser> drivers) {
    if (pendingPackages.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inventory, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 12),
            const Text(
              'No hay paquetes recibidos pendientes de ruta.',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            const Text('Registre un nuevo paquete en la primera pestaña.'),
          ],
        ),
      );
    }

    return Row(
      children: [
        // LEFT COLUMN: Package Selection
        Expanded(
          flex: 3,
          child: Container(
            padding: const EdgeInsets.all(16),
            border: Border(right: BorderSide(color: Colors.grey[200]!)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Paquetes en Bodega (${pendingPackages.length})',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    TextButton(
                      onPressed: () {
                        setState(() {
                          if (_selectedPackageIds.length == pendingPackages.length) {
                            _selectedPackageIds.clear();
                          } else {
                            _selectedPackageIds.clear();
                            _selectedPackageIds.addAll(pendingPackages.map((p) => p.id));
                          }
                        });
                      },
                      child: Text(_selectedPackageIds.length == pendingPackages.length ? 'Deseleccionar todo' : 'Seleccionar todo'),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: ListView.builder(
                    itemCount: pendingPackages.length,
                    itemBuilder: (context, index) {
                      final p = pendingPackages[index];
                      final isSelected = _selectedPackageIds.contains(p.id);

                      return Card(
                        color: isSelected ? Colors.blue[50] : Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                          side: BorderSide(color: isSelected ? Colors.blue[300]! : Colors.grey[200]!),
                        ),
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        child: CheckboxListTile(
                          value: isSelected,
                          onChanged: (checked) {
                            setState(() {
                              if (checked == true) {
                                _selectedPackageIds.add(p.id);
                              } else {
                                _selectedPackageIds.remove(p.id);
                              }
                            });
                          },
                          title: Text(
                            p.trackingCode,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                          subtitle: Text(
                            'Dest.: ${p.receiverName} (${p.city})\nDir: ${p.deliveryAddress}',
                            style: const TextStyle(fontSize: 11),
                          ),
                          secondary: CircleAvatar(
                            backgroundColor: Colors.blue[100],
                            child: const Icon(Icons.archive, size: 18, color: Colors.blue),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),

        // RIGHT COLUMN: Route assembly & assignment
        Expanded(
          flex: 2,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'Asignar a Conductor',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    const Divider(height: 24),

                    // Route Name
                    TextField(
                      controller: _routeNameController,
                      decoration: const InputDecoration(
                        labelText: 'Nombre de la Ruta / Sector',
                        hintText: 'ej. Ruta Norte GYE',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.map_outlined),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Driver Selection
                    DropdownButtonFormField<AppUser>(
                      value: _selectedDriver,
                      decoration: const InputDecoration(
                        labelText: 'Chofer Asignado',
                        prefixIcon: Icon(Icons.directions_car),
                        border: OutlineInputBorder(),
                      ),
                      hint: const Text('Seleccionar Chofer...'),
                      items: drivers.map((driver) => DropdownMenuItem(
                        value: driver,
                        child: Text('${driver.name} (${driver.licensePlate})'),
                      )).toList(),
                      onChanged: (val) {
                        setState(() {
                          _selectedDriver = val;
                          // Suggest a default route name if empty
                          if (_routeNameController.text.isEmpty && val != null) {
                            final city = pendingPackages.isNotEmpty ? pendingPackages.first.city : 'Norte';
                            _routeNameController.text = 'Ruta $city - ${val.name.split(' ')[0]}';
                          }
                        });
                      },
                    ),
                    const SizedBox(height: 24),

                    // Selection Summary
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Resumen de Selección:',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.grey[700]),
                          ),
                          const SizedBox(height: 4),
                          Text('• Paquetes seleccionados: ${_selectedPackageIds.length}', style: const TextStyle(fontSize: 12)),
                          Text('• Chofer: ${_selectedDriver?.name ?? "Ninguno"}', style: const TextStyle(fontSize: 12)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Dispatch button
                    ElevatedButton(
                      onPressed: _submitRoute,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue[900],
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.local_shipping),
                          SizedBox(width: 8),
                          Text(
                            'Despachar Ruta',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLiquidacionesTab(AppState state) {
    final liquidations = state.filteredLiquidations;
    final drivers = state.filteredUsers.where((u) => u.role == UserRole.driver).toList();

    if (liquidations.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.payments, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 12),
            const Text(
              'No hay liquidaciones disponibles.',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      );
    }

    final df = (DateTime d) => '${d.day}/${d.month}/${d.year}';

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Liquidaciones Semanales de Choferes',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              Text(
                'Total: ${liquidations.length}',
                style: const TextStyle(color: Colors.grey, fontSize: 13),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Expanded(
            child: ListView.builder(
              itemCount: liquidations.length,
              itemBuilder: (context, index) {
                final liq = liquidations[index];
                final driver = drivers.firstWhere((d) => d.id == liq.driverId, orElse: () => AppUser(id: '', name: 'Chofer Desconocido', username: '', role: UserRole.driver, empresaId: ''));

                final isApproved = liq.status == LiquidationStatus.aprobada;

                return Card(
                  elevation: 1,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              driver.name,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: isApproved ? Colors.green[50] : Colors.orange[50],
                                border: Border.all(color: isApproved ? Colors.green[200]! : Colors.orange[200]!),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                liq.status.name.toUpperCase(),
                                style: TextStyle(
                                  color: isApproved ? Colors.green[800] : Colors.orange[800],
                                  fontWeight: FontWeight.bold,
                                  fontSize: 11,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Período: ${df(liq.startDate)} - ${df(liq.endDate)}',
                          style: TextStyle(color: Colors.grey[600], fontSize: 12),
                        ),
                        const Divider(height: 20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Entregas exitosas: ${liq.totalDeliveries}', style: const TextStyle(fontSize: 12)),
                                Text('Entregas fallidas: ${liq.failedDeliveries}', style: const TextStyle(fontSize: 12)),
                                Text('Bono: \$${liq.bonus.toStringAsFixed(2)}', style: const TextStyle(fontSize: 12)),
                              ],
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                const Text('Total Comisión:', style: TextStyle(fontSize: 11, color: Colors.grey)),
                                Text(
                                  '\$${liq.netPay.toStringAsFixed(2)}',
                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.blue[900]),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            ElevatedButton.icon(
                              onPressed: () {
                                ReportService.exportLiquidationToPdf(liq, driver, state.currentCompany!.name);
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white,
                                foregroundColor: Colors.blue[900],
                                side: BorderSide(color: Colors.blue[900]!),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                              icon: const Icon(Icons.picture_as_pdf, size: 16),
                              label: const Text('Exportar PDF'),
                            ),
                            const SizedBox(width: 12),
                            if (!isApproved)
                              ElevatedButton(
                                onPressed: () {
                                  state.approveLiquidation(liq.id);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Liquidación aprobada con éxito.')),
                                  );
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.blue[900],
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                ),
                                child: const Text('Aprobar'),
                              ),
                          ],
                        ),
                      ],
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
}
