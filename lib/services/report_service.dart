import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:excel/excel.dart' as ex;
import 'package:printing/printing.dart';
import '../models/models.dart';
import 'file_saver.dart';

class ReportService {
  static Future<void> exportPackagesToExcel(List<PackageModel> packages, String companyName) async {
    var excel = ex.Excel.createExcel();
    // Remove default sheet
    excel.rename('Sheet1', 'Reporte de Paquetes');
    var sheet = excel['Reporte de Paquetes'];

    // Header styling
    sheet.appendRow([
      ex.CellValue.withValue('REPORTE DE PAQUETES - $companyName'),
    ]);
    sheet.appendRow([
      ex.CellValue.withValue('Generado el: ${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}'),
    ]);
    sheet.appendRow([]); // Empty row

    // Table Headers
    sheet.appendRow([
      ex.CellValue.withValue('Código de Tracking'),
      ex.CellValue.withValue('Remitente'),
      ex.CellValue.withValue('Destinatario'),
      ex.CellValue.withValue('Teléfono Dest.'),
      ex.CellValue.withValue('Dirección de Entrega'),
      ex.CellValue.withValue('Ciudad'),
      ex.CellValue.withValue('Estado'),
      ex.CellValue.withValue('Chofer ID'),
      ex.CellValue.withValue('Fecha Entrega/Fallo'),
      ex.CellValue.withValue('Motivo de Fallo/Receptor'),
    ]);

    for (var p in packages) {
      String dateStr = p.deliveryTime != null
          ? '${p.deliveryTime!.day}/${p.deliveryTime!.month}/${p.deliveryTime!.year}'
          : 'N/A';
          
      String secondaryInfo = '';
      if (p.status == PackageStatus.entregado) {
        secondaryInfo = 'Recibido por: ${p.receiverConfirmedName ?? "N/A"}';
      } else if (p.status == PackageStatus.fallido) {
        secondaryInfo = 'Fallo: ${p.failureReason ?? "N/A"}';
      }

      sheet.appendRow([
        ex.CellValue.withValue(p.trackingCode),
        ex.CellValue.withValue(p.senderName),
        ex.CellValue.withValue(p.receiverName),
        ex.CellValue.withValue(p.receiverPhone),
        ex.CellValue.withValue(p.deliveryAddress),
        ex.CellValue.withValue(p.city),
        ex.CellValue.withValue(p.status.name.toUpperCase()),
        ex.CellValue.withValue(p.driverId ?? 'No asignado'),
        ex.CellValue.withValue(dateStr),
        ex.CellValue.withValue(secondaryInfo),
      ]);
    }

    final bytes = excel.save();
    if (bytes != null) {
      final fileName = 'Reporte_Paquetes_${companyName.replaceAll(' ', '_')}.xlsx';
      await saveAndLaunchFile(bytes, fileName);
    }
  }

  static Future<void> exportPackagesToPdf(List<PackageModel> packages, String companyName) async {
    final pdf = pw.Document();

    final List<List<String>> tableData = [
      ['Código', 'Remitente', 'Destinatario', 'Ciudad', 'Estado', 'Fecha/Hora']
    ];

    for (var p in packages.take(30)) { // Limit to top 30 to avoid extremely long PDF for demo
      String dateStr = p.deliveryTime != null
          ? '${p.deliveryTime!.day}/${p.deliveryTime!.month}/${p.deliveryTime!.year}'
          : 'N/A';
      tableData.add([
        p.trackingCode,
        p.senderName,
        p.receiverName,
        p.city,
        p.status.name.toUpperCase(),
        dateStr
      ]);
    }

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return [
            pw.Header(
              level: 0,
              child: pw.Row(
                mainpw: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('EntregaYa - Reporte Ejecutivo', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 18)),
                  pw.Text(companyName, style: pw.TextStyle(color: PdfColors.grey700, fontSize: 12)),
                ],
              ),
            ),
            pw.SizedBox(height: 10),
            pw.Row(
              mainpw: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text('Total Paquetes: ${packages.length}', style: const pw.TextStyle(fontSize: 10)),
                pw.Text('Generado el: ${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}', style: const pw.TextStyle(fontSize: 10)),
              ],
            ),
            pw.SizedBox(height: 20),
            pw.TableHelper.fromTextArray(
              headers: tableData[0],
              data: tableData.sublist(1),
              border: pw.TableBorder.all(width: 0.5, color: PdfColors.grey400),
              headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white),
              headerDecoration: const pw.BoxDecoration(color: PdfColors.blue900),
              cellHeight: 20,
              cellAlignments: {
                0: pw.Alignment.centerLeft,
                1: pw.Alignment.centerLeft,
                2: pw.Alignment.centerLeft,
                3: pw.Alignment.centerLeft,
                4: pw.Alignment.center,
                5: pw.Alignment.center,
              },
            ),
            pw.SizedBox(height: 20),
            pw.Text(
              'Nota: Este documento es un reporte generado automáticamente por el sistema EntregaYa. Para ver firmas digitales completas u otra documentación de respaldo, consulte la plataforma en línea.',
              style: pw.TextStyle(fontSize: 8, fontStyle: pw.FontStyle.italic, color: PdfColors.grey600),
            )
          ];
        },
      ),
    );

    final bytes = await pdf.save();
    
    // Save locally or use printing package to preview/print
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => bytes,
      name: 'Reporte_Entregas_${companyName.replaceAll(' ', '_')}.pdf',
    );
  }

  static Future<void> exportLiquidationToPdf(LiquidationModel liq, AppUser driver, String companyName) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        build: (pw.Context context) {
          final df = (DateTime d) => '${d.day}/${d.month}/${d.year}';
          return pw.Column(
            crosspw: pw.CrossAxisAlignment.start,
            children: [
              pw.Row(
                mainpw: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('EntregaYa', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 24, color: PdfColors.blue900)),
                  pw.Text('DETALLE DE LIQUIDACIÓN', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 14, color: PdfColors.grey700)),
                ],
              ),
              pw.Divider(thickness: 2, color: PdfColors.blue900),
              pw.SizedBox(height: 20),
              
              pw.Text('Información de la Empresa:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12)),
              pw.Text(companyName, style: const pw.TextStyle(fontSize: 11)),
              pw.SizedBox(height: 15),

              pw.Text('Información del Chofer:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12)),
              pw.Text('Chofer: ${driver.name}', style: const pw.TextStyle(fontSize: 11)),
              pw.Text('Vehículo: ${driver.vehicleModel ?? "N/A"} | Placa: ${driver.licensePlate ?? "N/A"}', style: const pw.TextStyle(fontSize: 11)),
              pw.SizedBox(height: 15),

              pw.Text('Período de Liquidación:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12)),
              pw.Text('Desde: ${df(liq.startDate)} | Hasta: ${df(liq.endDate)}', style: const pw.TextStyle(fontSize: 11)),
              pw.Text('Estado: ${liq.status.name.toUpperCase()}', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: liq.status == LiquidationStatus.aprobada ? PdfColors.green800 : PdfColors.orange800, fontSize: 11)),
              pw.SizedBox(height: 25),

              pw.Text('Resumen Financiero:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 14)),
              pw.SizedBox(height: 10),
              
              pw.Table(
                border: pw.TableBorder.all(width: 0.5, color: PdfColors.grey300),
                children: [
                  _pdfTableRow('Entregas Exitosas', '${liq.totalDeliveries}', isBold: false),
                  _pdfTableRow('Entregas Fallidas', '${liq.failedDeliveries}', isBold: false),
                  _pdfTableRow('Comisión por Entrega', '\$${liq.commissionPerDelivery.toStringAsFixed(2)}', isBold: false),
                  _pdfTableRow('Total Comisiones', '\$${liq.totalCommission.toStringAsFixed(2)}', isBold: false),
                  _pdfTableRow('Bono de Productividad', '\$${liq.bonus.toStringAsFixed(2)}', isBold: false),
                  _pdfTableRow('Total Neto a Pagar', '\$${liq.netPay.toStringAsFixed(2)}', isBold: true),
                ]
              ),

              pw.SizedBox(height: 50),
              pw.Row(
                mainpw: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    children: [
                      pw.Container(width: 150, border: const pw.Border(top: pw.BorderSide(width: 1, color: PdfColors.black))),
                      pw.SizedBox(height: 4),
                      pw.Text('Firma del Chofer', style: const pw.TextStyle(fontSize: 10)),
                    ]
                  ),
                  pw.Column(
                    children: [
                      pw.Container(width: 150, border: const pw.Border(top: pw.BorderSide(width: 1, color: PdfColors.black))),
                      pw.SizedBox(height: 4),
                      pw.Text('Firma de Aprobación', style: const pw.TextStyle(fontSize: 10)),
                    ]
                  )
                ]
              )
            ],
          );
        }
      )
    );

    final bytes = await pdf.save();
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => bytes,
      name: 'Liquidacion_${driver.name.replaceAll(' ', '_')}.pdf',
    );
  }

  static pw.TableRow _pdfTableRow(String label, String value, {required bool isBold}) {
    return pw.TableRow(
      children: [
        pw.Padding(
          padding: const pw.EdgeInsets.all(6),
          child: pw.Text(label, style: pw.TextStyle(fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal, fontSize: 11)),
        ),
        pw.Padding(
          padding: const pw.EdgeInsets.all(6),
          child: pw.Align(
            alignment: pw.Alignment.centerRight,
            child: pw.Text(value, style: pw.TextStyle(fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal, fontSize: 11)),
          ),
        ),
      ]
    );
  }
}
