import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/models.dart';
import '../../providers/app_state.dart';
import '../widgets/custom_signature_pad.dart';
import '../widgets/open_street_map_widget.dart';

class DriverDashboard extends StatefulWidget {
  const DriverDashboard({super.key});

  @override
  State<DriverDashboard> createState() => _DriverDashboardState();
}

class _DriverDashboardState extends State<DriverDashboard> {
  PackageModel? _selectedPackage;

  @override
  Widget build(BuildContext context) {
    final state = Provider.of<AppState>(context);
    final currentUser = state.currentUser;

    if (currentUser == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('EntregaYa - Chofer')),
        body: const Center(child: Text('Sesión no iniciada.')),
      );
    }

    final driverRoutes = state.filteredRoutes
        .where((r) => r.driverId == currentUser.id)
        .toList();

    // Packages assigned to this driver
    final driverPackages = state.filteredPackages
        .where((p) => p.driverId == currentUser.id)
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('EntregaYa - Chofer', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            Text(
              'Chofer: ${currentUser.name} (${currentUser.licensePlate ?? "Sin Placa"})',
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.normal),
            ),
          ],
        ),
        backgroundColor: Colors.green[800],
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Cerrar Sesión',
            onPressed: () {
              state.logout();
              Navigator.of(context).popUntil((route) => route.isFirst);
            },
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth > 700;

          if (isWide) {
            return Row(
              children: [
                SizedBox(
                  width: 360,
                  child: _buildRouteAndPackageList(state, driverRoutes, driverPackages),
                ),
                const VerticalDivider(width: 1),
                Expanded(
                  child: _selectedPackage == null
                      ? const Center(
                          child: Text(
                            'Seleccione un paquete para realizar la entrega o ver el mapa.',
                            style: TextStyle(color: Colors.grey),
                          ),
                        )
                      : _buildPackageDetailView(context, state, _selectedPackage!),
                ),
              ],
            );
          }

          if (_selectedPackage != null) {
            return PopScope(
              canPop: false,
              onPopInvokedWithResult: (didPop, result) {
                if (didPop) return;
                setState(() {
                  _selectedPackage = null;
                });
              },
              child: Scaffold(
                appBar: AppBar(
                  title: Text(_selectedPackage!.trackingCode),
                  backgroundColor: Colors.green[800],
                  foregroundColor: Colors.white,
                  leading: IconButton(
                    icon: const Icon(Icons.arrow_back),
                    onPressed: () {
                      setState(() {
                        _selectedPackage = null;
                      });
                    },
                  ),
                ),
                body: _buildPackageDetailView(context, state, _selectedPackage!),
              ),
            );
          }

          return _buildRouteAndPackageList(state, driverRoutes, driverPackages);
        },
      ),
    );
  }

  Widget _buildRouteAndPackageList(
    AppState state,
    List<RouteModel> driverRoutes,
    List<PackageModel> driverPackages,
  ) {
    return Column(
      children: [
        // Summary Header Card
        Container(
          color: Colors.green[50],
          padding: const EdgeInsets.all(16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatChip('Rutas Activas', driverRoutes.length.toString(), Colors.green[800]!),
              _buildStatChip(
                'Pendientes',
                driverPackages
                    .where((p) => p.status == PackageStatus.en_ruta || p.status == PackageStatus.recibido)
                    .length
                    .toString(),
                Colors.orange[800]!,
              ),
              _buildStatChip(
                'Entregados',
                driverPackages.where((p) => p.status == PackageStatus.entregado).length.toString(),
                Colors.blue[800]!,
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: driverPackages.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.local_shipping, size: 64, color: Colors.grey[400]),
                      const SizedBox(height: 12),
                      const Text(
                        'No tienes paquetes asignados en ruta.',
                        style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(8.0),
                  itemCount: driverPackages.length,
                  itemBuilder: (context, index) {
                    final p = driverPackages[index];
                    final isSelected = _selectedPackage?.id == p.id;

                    Color statusColor = Colors.orange;
                    if (p.status == PackageStatus.entregado) statusColor = Colors.green;
                    if (p.status == PackageStatus.fallido) statusColor = Colors.red;

                    return Card(
                      elevation: isSelected ? 3 : 1,
                      color: isSelected ? Colors.green[50] : Colors.white,
                      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(
                          color: isSelected ? Colors.green[700]! : Colors.grey[200]!,
                          width: isSelected ? 2 : 1,
                        ),
                      ),
                      child: ListTile(
                        onTap: () {
                          setState(() {
                            _selectedPackage = p;
                          });
                        },
                        title: Text(
                          p.trackingCode,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 2),
                            Text('Destino: ${p.receiverName}', style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 12)),
                            Text('${p.deliveryAddress} (${p.city})', style: TextStyle(color: Colors.grey[600], fontSize: 11)),
                          ],
                        ),
                        trailing: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: statusColor.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: statusColor),
                          ),
                          child: Text(
                            p.status.name.toUpperCase(),
                            style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 10),
                          ),
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildStatChip(String label, String value, Color color) {
    return Column(
      children: [
        Text(value, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: color)),
        Text(label, style: TextStyle(fontSize: 11, color: Colors.grey[700])),
      ],
    );
  }

  Widget _buildPackageDetailView(BuildContext context, AppState state, PackageModel package) {
    final currentPkg = state.filteredPackages.firstWhere(
      (p) => p.id == package.id,
      orElse: () => package,
    );

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Card(
            elevation: 2,
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
                        currentPkg.trackingCode,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                      ),
                      Chip(
                        label: Text(
                          currentPkg.status.name.toUpperCase(),
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11),
                        ),
                        backgroundColor: currentPkg.status == PackageStatus.entregado
                            ? Colors.green[700]
                            : currentPkg.status == PackageStatus.fallido
                                ? Colors.red[700]
                                : Colors.orange[800],
                      ),
                    ],
                  ),
                  const Divider(height: 20),
                  _infoRow(Icons.person, 'Destinatario:', currentPkg.receiverName),
                  _infoRow(Icons.phone, 'Teléfono:', currentPkg.receiverPhone),
                  _infoRow(Icons.location_on, 'Dirección:', '${currentPkg.deliveryAddress}, ${currentPkg.city}'),
                  _infoRow(Icons.business, 'Remitente:', currentPkg.senderName),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Map View
          if (currentPkg.lat != null && currentPkg.lng != null)
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.all(12.0),
                    child: Row(
                      children: [
                        Icon(Icons.map, color: Colors.green),
                        SizedBox(width: 8),
                        Text('Ubicación de Entrega (OpenStreetMap)', style: TextStyle(fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                  SizedBox(
                    height: 220,
                    child: ClipRRect(
                      borderRadius: const BorderRadius.vertical(bottom: Radius.circular(12)),
                      child: OpenStreetMapWidget(
                        packages: [currentPkg],
                        initialLat: currentPkg.lat!,
                        initialLng: currentPkg.lng!,
                        zoom: 14.0,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 16),

          // Delivery Action Section if not delivered yet
          if (currentPkg.status == PackageStatus.en_ruta || currentPkg.status == PackageStatus.recibido) ...[
            ElevatedButton.icon(
              onPressed: () => _showDeliveryDialog(context, state, currentPkg),
              icon: const Icon(Icons.gesture, size: 20),
              label: const Text('Completar Entrega con Firma Táctil', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green[800],
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () => _showFailureDialog(context, state, currentPkg),
              icon: const Icon(Icons.report_problem, size: 20),
              label: const Text('Registrar Entrega Fallida', style: TextStyle(fontWeight: FontWeight.bold)),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.red[800],
                side: BorderSide(color: Colors.red[800]!),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ] else ...[
            Card(
              elevation: 2,
              color: currentPkg.status == PackageStatus.entregado ? Colors.green[50] : Colors.red[50],
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          currentPkg.status == PackageStatus.entregado ? Icons.check_circle : Icons.error,
                          color: currentPkg.status == PackageStatus.entregado ? Colors.green[800] : Colors.red[800],
                        ),
                        const SizedBox(width: 8),
                        Text(
                          currentPkg.status == PackageStatus.entregado ? 'Entrega Registrada Exitosamente' : 'Registro de Fallo de Entrega',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: currentPkg.status == PackageStatus.entregado ? Colors.green[900] : Colors.red[900],
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 16),
                    if (currentPkg.status == PackageStatus.entregado) ...[
                      Text('Receptor: ${currentPkg.receiverConfirmedName ?? currentPkg.receiverName}'),
                      const SizedBox(height: 8),
                      const Text('Firma Digital Capturada:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      if (currentPkg.signaturePoints != null && currentPkg.signaturePoints!.isNotEmpty)
                        Container(
                          height: 120,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.grey[300]!),
                          ),
                          child: CustomPaint(
                            painter: StaticSignaturePainter(currentPkg.signaturePoints!),
                            size: Size.infinite,
                          ),
                        ),
                    ] else ...[
                      Text('Motivo: ${currentPkg.failureReason ?? "No especificado"}', style: TextStyle(color: Colors.red[900])),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: Colors.grey[600]),
          const SizedBox(width: 8),
          Text('$label ', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey[700], fontSize: 13)),
          Expanded(
            child: Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
          ),
        ],
      ),
    );
  }

  void _showDeliveryDialog(BuildContext context, AppState state, PackageModel package) {
    final receiverController = TextEditingController(text: package.receiverName);
    List<List<double>>? capturedSignature;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.draw, color: Colors.green),
              SizedBox(width: 8),
              Text('Captura de Firma Digital'),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: receiverController,
                  decoration: const InputDecoration(
                    labelText: 'Nombre Completo del Receptor',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                const Text('Firme con el dedo o cursor:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                const SizedBox(height: 8),
                CustomSignaturePad(
                  onSigned: (points) {
                    capturedSignature = points;
                  },
                  onClear: () {
                    capturedSignature = null;
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green[800],
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                if (receiverController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Por favor ingrese el nombre del receptor.')),
                  );
                  return;
                }
                if (capturedSignature == null || capturedSignature!.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Por favor dibuje la firma antes de confirmar.')),
                  );
                  return;
                }

                state.updatePackageDelivery(
                  id: package.id,
                  status: PackageStatus.entregado,
                  receiverName: receiverController.text.trim(),
                  signaturePoints: capturedSignature!,
                );

                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('¡Paquete entregado y firma registrada exitosamente!')),
                );
                setState(() {
                  _selectedPackage = state.filteredPackages.firstWhere((p) => p.id == package.id);
                });
              },
              child: const Text('Confirmar Entrega'),
            ),
          ],
        );
      },
    );
  }

  void _showFailureDialog(BuildContext context, AppState state, PackageModel package) {
    String selectedReason = 'Cliente ausente en domicilio.';

    final reasons = [
      'Cliente ausente en domicilio.',
      'Dirección incompleta o no localizada.',
      'Cliente rechazó la entrega.',
      'No se pudo contactar al cliente por teléfono.',
      'Zona inaccesible o de alto riesgo.'
    ];

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Row(
                children: [
                  Icon(Icons.warning, color: Colors.red),
                  SizedBox(width: 8),
                  Text('Registrar Fallo de Entrega'),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Seleccione el motivo principal del fallo:'),
                    const SizedBox(height: 8),
                    ...reasons.map((r) {
                      return RadioListTile<String>(
                        title: Text(r, style: const TextStyle(fontSize: 13)),
                        value: r,
                        groupValue: selectedReason,
                        onChanged: (val) {
                          if (val != null) {
                            setDialogState(() {
                              selectedReason = val;
                            });
                          }
                        },
                      );
                    }),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancelar'),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red[800],
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () {
                    state.updatePackageDelivery(
                      id: package.id,
                      status: PackageStatus.fallido,
                      receiverName: package.receiverName,
                      signaturePoints: [],
                      failureReason: selectedReason,
                    );
                    Navigator.of(context).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Intento fallido registrado.')),
                    );
                    setState(() {
                      _selectedPackage = state.filteredPackages.firstWhere((p) => p.id == package.id);
                    });
                  },
                  child: const Text('Guardar Fallo'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
