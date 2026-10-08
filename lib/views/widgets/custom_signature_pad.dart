import 'package:flutter/material.dart';

class CustomSignaturePad extends StatefulWidget {
  final Function(List<List<double>> points) onSigned;
  final VoidCallback onClear;

  const CustomSignaturePad({
    super.key,
    required this.onSigned,
    required this.onClear,
  });

  @override
  State<CustomSignaturePad> createState() => _CustomSignaturePadState();
}

class _CustomSignaturePadState extends State<CustomSignaturePad> {
  final List<Offset> _points = [];

  void _clear() {
    setState(() {
      _points.clear();
    });
    widget.onClear();
  }

  void _onPanUpdate(DragUpdateDetails details) {
    final RenderBox renderBox = context.findRenderObject() as RenderBox;
    final Offset localPosition = renderBox.globalToLocal(details.globalPosition);
    setState(() {
      _points.add(localPosition);
    });
    
    // Periodically notify points
    _notifyPoints();
  }

  void _onPanEnd(DragEndDetails details) {
    // Add an empty point to indicate a break in line
    setState(() {
      _points.add(const Offset(-1, -1));
    });
    _notifyPoints();
  }

  void _notifyPoints() {
    final List<List<double>> serialized = _points
        .map((p) => [p.dx, p.dy])
        .toList();
    widget.onSigned(serialized);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          height: 180,
          decoration: BoxDecoration(
            color: Colors.grey[50],
            border: Border.all(color: Colors.grey[300]!, width: 2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: GestureDetector(
              onPanUpdate: _onPanUpdate,
              onPanEnd: _onPanEnd,
              child: CustomPaint(
                painter: SignaturePainter(_points),
                size: Size.infinite,
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Firme dentro del cuadro',
              style: TextStyle(color: Colors.grey[600], fontSize: 13, fontStyle: FontStyle.italic),
            ),
            TextButton.icon(
              onPressed: _clear,
              icon: const Icon(Icons.clear, size: 16, color: Colors.red),
              label: const Text(
                'Limpiar Firma',
                style: TextStyle(color: Colors.red, fontSize: 13),
              ),
            ),
          ],
        )
      ],
    );
  }
}

class SignaturePainter extends CustomPainter {
  final List<Offset> points;

  SignaturePainter(this.points);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.blue[900]!
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 3.5;

    for (int i = 0; i < points.length - 1; i++) {
      if (points[i] != const Offset(-1, -1) && points[i + 1] != const Offset(-1, -1)) {
        canvas.drawLine(points[i], points[i + 1], paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant SignaturePainter oldDelegate) => true;
}

// Separate read-only painter to render points captured in detail view
class StaticSignaturePainter extends CustomPainter {
  final List<List<double>> points;

  StaticSignaturePainter(this.points);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.blue[900]!
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 3.5;

    for (int i = 0; i < points.length - 1; i++) {
      final p1 = Offset(points[i][0], points[i][1]);
      final p2 = Offset(points[i + 1][0], points[i + 1][1]);
      if (p1 != const Offset(-1, -1) && p2 != const Offset(-1, -1)) {
        canvas.drawLine(p1, p2, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant StaticSignaturePainter oldDelegate) => false;
}
