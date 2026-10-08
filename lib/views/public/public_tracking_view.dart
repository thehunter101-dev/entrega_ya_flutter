import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/models.dart';
import '../../providers/app_state.dart';
import '../widgets/custom_signature_pad.dart';

class PublicTrackingView extends StatefulWidget {
  final String? initialTrackingCode;

  const PublicTrackingView({super.key, this.initialTrackingCode});

  @override
  State<PublicTrackingView> createState() => _PublicTrackingViewState();
}

class _PublicTrackingViewState extends State<PublicTrackingView> {
  final TextEditingController _searchController = TextEditingController();
  PackageModel? _searchedPackage;
  bool _hasSearched = false;

  @override
  void initState() {
    super.initState();
    if (widget.initialTrackingCode != null) {
      _searchController.text = widget.initialTrackingCode!;
      _doSearch();
    }
  }

  void _doSearch() {
    if (_searchController.text.trim().isEmpty) return;
    
    final state = Provider.of<AppState>(context, listen: false);
    final pkg = state.db.getPackageByTrackingCode(_searchController.text.trim());
    
    setState(() {
      _searchedPackage = pkg;
      _hasSearched = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Search Header Card
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.search, color: Colors.blue[900], size: 28),
                        const SizedBox(width: 8),
                        const Text(
                          'Rastreo Público de Paquetes',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Ingrese el código de tracking único (ej. EY-EXP-100005) para consultar el estado en tiempo real sin iniciar sesión.',
                      style: TextStyle(color: Colors.grey[600], fontSize: 13),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _searchController,
                            decoration: InputDecoration(
                              hintText: 'Código de Tracking...',
                              prefixIcon: const Icon(Icons.tag),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            ),
                            textCapitalization: TextCapitalization.characters,
                            onSubmitted: (_) => _doSearch(),
                          ),
                        ),
                        const SizedBox(width: 12),
                        ElevatedButton(
                          onPressed: _doSearch,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue[900],
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: const Icon(Icons.arrow_forward),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            if (_hasSearched)
              _searchedPackage == null
                  ? Card(
                      color: Colors.red[50],
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      child: Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Row(
                          children: [
                            const Icon(Icons.error_outline, color: Colors.red, size: 36),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Código no encontrado',
                                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.red),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'El código "${_searchController.text}" no está registrado en ninguna empresa. Verifique que esté bien escrito.',
                                    style: TextStyle(color: Colors.red[900], fontSize: 13),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  : _buildPackageDetails(_searchedPackage!)
          ],
        ),
      ),
    );
  }

  Widget _buildPackageDetails(PackageModel p) {
    Color statusColor = Colors.orange;
    String statusLabel = 'Recibido';
    IconData statusIcon = Icons.archive;

    switch (p.status) {
      case PackageStatus.recibido:
        statusColor = Colors.orange;
        statusLabel = 'Recibido';
        statusIcon = Icons.archive;
        break;
      case PackageStatus.en_ruta:
        statusColor = Colors.blue;
        statusLabel = 'En Ruta';
        statusIcon = Icons.local_shipping;
        break;
      case PackageStatus.entregado:
        statusColor = Colors.green;
        statusLabel = 'Entregado';
        statusIcon = Icons.check_circle;
        break;
      case PackageStatus.fallido:
        statusColor = Colors.red;
        statusLabel = 'Intento Fallido';
        statusIcon = Icons.error;
        break;
    }

    final df = (DateTime d) => '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year} a las ${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Main Info Card
        Card(
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          p.trackingCode,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Empresa: ${p.trackingCode.contains('EXP') ? 'Courier Demo Express' : 'Distribución Demo Costa'}',
                          style: TextStyle(color: Colors.grey[600], fontSize: 12),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: statusColor, width: 1.5),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(statusIcon, color: statusColor, size: 18),
                          const SizedBox(width: 6),
                          Text(
                            statusLabel,
                            style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const Divider(height: 30),
                
                // Package Specs
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _packageSpecRow('Remitente:', p.senderName),
                          _packageSpecRow('Destinatario:', p.receiverName),
                          _packageSpecRow('Teléfono Dest.:', p.receiverPhone),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _packageSpecRow('Ciudad de Destino:', p.city),
                          _packageSpecRow('Dirección de Entrega:', p.deliveryAddress),
                          if (p.status == PackageStatus.fallido && p.failureReason != null)
                            _packageSpecRow('Motivo del Fallo:', p.failureReason!, isDanger: true),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Signature display if Delivered
        if (p.status == PackageStatus.entregado)
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.assignment_turned_in, color: Colors.green[800], size: 24),
                      const SizedBox(width: 8),
                      const Text(
                        'Comprobante de Entrega Digital',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                    ],
                  ),
                  const Divider(height: 24),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _packageSpecRow('Receptor Confirmado:', p.receiverConfirmedName ?? p.receiverName),
                            if (p.deliveryTime != null)
                              _packageSpecRow('Fecha de Recepción:', df(p.deliveryTime!)),
                            const SizedBox(height: 8),
                            const Text(
                              'Este comprobante digital tiene validez comercial y legal interna.',
                              style: TextStyle(color: Colors.grey, fontSize: 11, fontStyle: FontStyle.italic),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 20),
                      if (p.signaturePoints != null && p.signaturePoints!.isNotEmpty)
                        Container(
                          width: 180,
                          height: 110,
                          decoration: BoxDecoration(
                            color: Colors.grey[50],
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey[200]!, width: 2),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: CustomPaint(
                              painter: StaticSignaturePainter(p.signaturePoints!),
                              size: Size.infinite,
                            ),
                          ),
                        )
                      else
                        Container(
                          width: 180,
                          height: 110,
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Center(
                            child: Text(
                              'Sin firma registrada',
                              style: TextStyle(color: Colors.grey, fontSize: 11),
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        const SizedBox(height: 16),

        // Timeline Timeline
        Card(
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.history, color: Colors.blueGrey, size: 24),
                    const SizedBox(width: 8),
                    Text(
                      'Historial de Tracking (Línea de Tiempo)',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                  ],
                ),
                const Divider(height: 24),
                
                // Timeline List
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: p.statusHistory.length,
                  itemBuilder: (context, index) {
                    final entry = p.statusHistory[p.statusHistory.length - 1 - index]; // Show latest first
                    
                    Color itemColor = Colors.orange;
                    IconData itemIcon = Icons.archive;

                    switch (entry.status) {
                      case PackageStatus.recibido:
                        itemColor = Colors.orange;
                        itemIcon = Icons.archive;
                        break;
                      case PackageStatus.en_ruta:
                        itemColor = Colors.blue;
                        itemIcon = Icons.local_shipping;
                        break;
                      case PackageStatus.entregado:
                        itemColor = Colors.green;
                        itemIcon = Icons.check_circle;
                        break;
                      case PackageStatus.fallido:
                        itemColor = Colors.red;
                        itemIcon = Icons.error;
                        break;
                    }

                    return IntrinsicHeight(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Column(
                            children: [
                              Container(
                                width: 28,
                                height: 28,
                                decoration: BoxDecoration(
                                  color: itemColor.withOpacity(0.15),
                                  shape: BoxShape.circle,
                                  border: Border.all(color: itemColor, width: 2),
                                ),
                                child: Center(
                                  child: Icon(itemIcon, color: itemColor, size: 14),
                                ),
                              ),
                              if (index < p.statusHistory.length - 1)
                                Expanded(
                                  child: Container(
                                    width: 2,
                                    color: Colors.grey[300],
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.only(bottom: 20.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        entry.status.name.toUpperCase(),
                                        style: TextStyle(fontWeight: FontWeight.bold, color: itemColor, fontSize: 13),
                                      ),
                                      Text(
                                        df(entry.timestamp),
                                        style: TextStyle(color: Colors.grey[500], fontSize: 11),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    entry.details,
                                    style: const TextStyle(color: Colors.black87, fontSize: 13),
                                  ),
                                ],
                              ),
                            ),
                          ),
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
    );
  }

  Widget _packageSpecRow(String label, String value, {bool isDanger = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(color: Colors.grey[600], fontSize: 11, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: isDanger ? FontWeight.bold : FontWeight.w500,
              color: isDanger ? Colors.red[800] : Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}
