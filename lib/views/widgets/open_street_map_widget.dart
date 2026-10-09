import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../models/models.dart';

class OpenStreetMapWidget extends StatelessWidget {
  final List<PackageModel> packages;
  final double initialLat;
  final double initialLng;
  final double zoom;
  final String? title;

  const OpenStreetMapWidget({
    super.key,
    required this.packages,
    this.initialLat = -2.1894, // Guayaquil default
    this.initialLng = -79.8890,
    this.zoom = 12.0,
    this.title,
  });

  @override
  Widget build(BuildContext context) {
    // Collect active coordinates
    final List<Marker> markers = [];
    
    for (var p in packages) {
      if (p.lat != null && p.lng != null) {
        Color markerColor = Colors.grey;
        IconData markerIcon = Icons.location_on;

        switch (p.status) {
          case PackageStatus.recibido:
            markerColor = Colors.orange;
            markerIcon = Icons.archive;
            break;
          case PackageStatus.en_ruta:
            markerColor = Colors.blue;
            markerIcon = Icons.local_shipping;
            break;
          case PackageStatus.entregado:
            markerColor = Colors.green;
            markerIcon = Icons.check_circle;
            break;
          case PackageStatus.fallido:
            markerColor = Colors.red;
            markerIcon = Icons.error;
            break;
        }

        markers.add(
          Marker(
            point: LatLng(p.lat!, p.lng!),
            width: 50,
            height: 50,
            child: GestureDetector(
              onTap: () {
                _showPackageDialog(context, p);
              },
              child: MouseRegion(
                cursor: SystemMouseCursors.click,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: markerColor, width: 1),
                        boxShadow: const [
                          BoxShadow(color: Colors.black12, blurRadius: 2, offset: Offset(0, 1))
                        ],
                      ),
                      child: Text(
                        p.trackingCode.split('-').last,
                        style: TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: markerColor),
                      ),
                    ),
                    Icon(
                      markerIcon,
                      color: markerColor,
                      size: 26,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }
    }

    final double centerLat = packages.isNotEmpty && packages.first.lat != null ? packages.first.lat! : initialLat;
    final double centerLng = packages.isNotEmpty && packages.first.lng != null ? packages.first.lng! : initialLng;

    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(15),
        child: Stack(
          children: [
            FlutterMap(
              options: MapOptions(
                initialCenter: LatLng(centerLat, centerLng),
                initialZoom: zoom,
                minZoom: 4,
                maxZoom: 18,
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.example.entrega_ya',
                ),
                MarkerLayer(markers: markers),
              ],
            ),
            if (title != null)
              Positioned(
                top: 10,
                left: 10,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: const [
                      BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 2))
                    ],
                  ),
                  child: Text(
                    title!,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.black87),
                  ),
                ),
              ),
            Positioned(
              bottom: 10,
              right: 10,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white70,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  '© OpenStreetMap',
                  style: TextStyle(fontSize: 8, color: Colors.black54),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showPackageDialog(BuildContext context, PackageModel p) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              p.status == PackageStatus.entregado
                  ? Icons.check_circle
                  : p.status == PackageStatus.en_ruta
                      ? Icons.local_shipping
                      : p.status == PackageStatus.fallido
                          ? Icons.error
                          : Icons.archive,
              color: p.status == PackageStatus.entregado
                  ? Colors.green
                  : p.status == PackageStatus.en_ruta
                      ? Colors.blue
                      : p.status == PackageStatus.fallido
                          ? Colors.red
                          : Colors.orange,
            ),
            const SizedBox(width: 8),
            Text(p.trackingCode),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _detailRow('Destinatario:', p.receiverName),
            _detailRow('Ciudad:', p.city),
            _detailRow('Dirección:', p.deliveryAddress),
            _detailRow('Estado actual:', p.status.name.toUpperCase()),
            if (p.status == PackageStatus.fallido && p.failureReason != null)
              _detailRow('Motivo Fallo:', p.failureReason!, isDanger: true),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cerrar'),
          )
        ],
      ),
    );
  }

  Widget _detailRow(String label, String value, {bool isDanger = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: RichText(
        text: TextSpan(
          style: const TextStyle(color: Colors.black87, fontSize: 13),
          children: [
            TextSpan(text: '$label ', style: const TextStyle(fontWeight: FontWeight.bold)),
            TextSpan(
              text: value,
              style: TextStyle(
                color: isDanger ? Colors.red : Colors.black87,
                fontWeight: isDanger ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
