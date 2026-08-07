import 'dart:typed_data';

import 'package:excel/excel.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../models/auction_model.dart';
import '../models/user_model.dart';
import '../core/admin_report.dart';
import '../core/utils/formatters.dart';

class AdminReportFileExporter {
  AdminReportFileExporter._();

  static Uint8List toExcelBytes(
    AdminReportData report, {
    required Map<String, UserModel> usersById,
  }) {
    final excel = Excel.createExcel();
    final summary = excel['Тайлан'];
    excel.delete('Sheet1');

    void addRow(Sheet sheet, int row, List<String> values) {
      for (var i = 0; i < values.length; i++) {
        sheet
            .cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: row))
            .value = TextCellValue(values[i]);
      }
    }

    var row = 0;
    addRow(summary, row++, ['ДЭМБЭЭ Админ тайлан']);
    addRow(summary, row++, ['Хугацаа', report.periodLabel]);
    addRow(summary, row++, ['Үүсгэсэн', formatDateTime(report.generatedAt)]);
    row++;
    addRow(summary, row++, ['Үзүүлэлт', 'Утга']);
    addRow(summary, row++, ['Нийт орлого (₮)', '${report.grossRevenue}']);
    addRow(summary, row++, ['Буцаалт (₮)', '${report.refundedAmount}']);
    addRow(summary, row++, ['Цэвэр орлого (₮)', '${report.netRevenue}']);
    addRow(summary, row++, ['Борлуулсан санал', '${report.bidsSold}']);
    addRow(summary, row++, ['Шинэ хэрэглэгч', '${report.newUsers}']);

    if (report.packageSales.isNotEmpty) {
      final sheet = excel['Багц борлуулалт'];
      addRow(sheet, 0, ['Багц', 'Тоо']);
      var i = 1;
      final sorted = report.packageSales.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      for (final entry in sorted) {
        addRow(sheet, i++, [entry.key, '${entry.value}']);
      }
    }

    if (report.newUsersList.isNotEmpty) {
      final sheet = excel['Шинэ хэрэглэгч'];
      addRow(sheet, 0, ['Нэр', 'Имэйл', 'Утас', 'Огноо']);
      for (var i = 0; i < report.newUsersList.length; i++) {
        final u = report.newUsersList[i];
        addRow(sheet, i + 1, [
          u.name,
          u.email,
          u.phone,
          formatDateTime(u.createdAt),
        ]);
      }
    }

    _writeAuctionSheet(
      excel: excel,
      title: 'Амжилттай бараа',
      auctions: report.successfulAuctions,
      includeWinner: true,
    );
    _writeAuctionSheet(
      excel: excel,
      title: 'Амжилтгүй бараа',
      auctions: report.failedAuctions,
      includeWinner: false,
    );

    if (report.refundsList.isNotEmpty) {
      final sheet = excel['Буцаалт'];
      addRow(sheet, 0, ['Огноо', 'Хэрэглэгч', 'Багц', 'Дүн (₮)']);
      for (var i = 0; i < report.refundsList.length; i++) {
        final p = report.refundsList[i];
        final user = usersById[p.userUid];
        final name = user?.name.isNotEmpty == true ? user!.name : p.userUid;
        addRow(sheet, i + 1, [
          formatDateTime(p.refundedAt ?? p.createdAt),
          name,
          p.packageLabel,
          '${p.amount}',
        ]);
      }
    }

    final encoded = excel.encode();
    return Uint8List.fromList(encoded ?? []);
  }

  static void _writeAuctionSheet({
    required Excel excel,
    required String title,
    required List<AuctionModel> auctions,
    required bool includeWinner,
  }) {
    if (auctions.isEmpty) return;

    final sheet = excel[title];
    final headers = includeWinner
        ? ['Бараа', 'Үнэ (₮)', 'Ялагч', 'Санал', 'Зураг URL']
        : ['Бараа', 'Үнэ (₮)', 'Санал', 'Зураг URL'];

    for (var col = 0; col < headers.length; col++) {
      sheet
          .cell(CellIndex.indexByColumnRow(columnIndex: col, rowIndex: 0))
          .value = TextCellValue(headers[col]);
    }

    for (var i = 0; i < auctions.length; i++) {
      final a = auctions[i];
      final row = i + 1;
      if (includeWinner) {
        sheet
            .cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row))
            .value = TextCellValue(a.title);
        sheet
            .cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: row))
            .value = TextCellValue('${a.finalPrice ?? a.price}');
        sheet
            .cell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: row))
            .value = TextCellValue(a.winnerName ?? '');
        sheet
            .cell(CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: row))
            .value = TextCellValue('${a.totalBids}');
        sheet
            .cell(CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: row))
            .value = TextCellValue(a.image ?? '');
      } else {
        sheet
            .cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row))
            .value = TextCellValue(a.title);
        sheet
            .cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: row))
            .value = TextCellValue('${a.finalPrice ?? a.price}');
        sheet
            .cell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: row))
            .value = TextCellValue('${a.totalBids}');
        sheet
            .cell(CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: row))
            .value = TextCellValue(a.image ?? '');
      }
    }
  }

  static Future<Uint8List> toPdfBytes(
    AdminReportData report, {
    required Map<String, UserModel> usersById,
  }) async {
    final doc = pw.Document();
    final baseStyle = pw.TextStyle(fontSize: 10);
    final headerStyle = pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold);

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (context) => [
          pw.Text('ДЭМБЭЭ — Админ тайлан', style: headerStyle),
          pw.SizedBox(height: 8),
          pw.Text('Хугацаа: ${report.periodLabel}', style: baseStyle),
          pw.Text('Үүсгэсэн: ${formatDateTime(report.generatedAt)}', style: baseStyle),
          pw.SizedBox(height: 16),
          _pdfTable(
            title: 'Орлого',
            headers: const ['Үзүүлэлт', 'Утга'],
            rows: [
              ['Нийт орлого', formatPrice(report.grossRevenue)],
              ['Буцаалт', formatPrice(report.refundedAmount)],
              ['Цэвэр орлого', formatPrice(report.netRevenue)],
              ['Борлуулсан санал', formatNumber(report.bidsSold)],
              ['Шинэ хэрэглэгч', '${report.newUsers}'],
            ],
            baseStyle: baseStyle,
          ),
          if (report.packageSales.isNotEmpty)
            _pdfTable(
              title: 'Багц борлуулалт',
              headers: const ['Багц', 'Тоо'],
              rows: report.packageSales.entries
                  .map((e) => [e.key, '${e.value}'])
                  .toList(),
              baseStyle: baseStyle,
            ),
          if (report.successfulAuctions.isNotEmpty)
            _pdfAuctionTable(
              title: 'Амжилттай дууссан бараа',
              auctions: report.successfulAuctions,
              includeWinner: true,
              baseStyle: baseStyle,
            ),
          if (report.failedAuctions.isNotEmpty)
            _pdfAuctionTable(
              title: 'Амжилтгүй дууссан бараа',
              auctions: report.failedAuctions,
              includeWinner: false,
              baseStyle: baseStyle,
            ),
          if (report.refundsList.isNotEmpty)
            _pdfRefundTable(
              report: report,
              usersById: usersById,
              baseStyle: baseStyle,
            ),
        ],
      ),
    );

    return doc.save();
  }

  static pw.Widget _pdfTable({
    required String title,
    required List<String> headers,
    required List<List<String>> rows,
    required pw.TextStyle baseStyle,
  }) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.SizedBox(height: 12),
        pw.Text(title, style: baseStyle.copyWith(fontWeight: pw.FontWeight.bold)),
        pw.Table.fromTextArray(
          headers: headers,
          data: rows,
          cellStyle: baseStyle,
          headerStyle: baseStyle.copyWith(fontWeight: pw.FontWeight.bold),
          border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
        ),
      ],
    );
  }

  static pw.Widget _pdfAuctionTable({
    required String title,
    required List<AuctionModel> auctions,
    required bool includeWinner,
    required pw.TextStyle baseStyle,
  }) {
    final headers = includeWinner
        ? ['Бараа', 'Үнэ', 'Ялагч', 'Санал']
        : ['Бараа', 'Үнэ', 'Санал'];
    final rows = auctions.map((a) {
      if (includeWinner) {
        return [
          a.title,
          formatPrice(a.finalPrice ?? a.price),
          a.winnerName ?? '',
          '${a.totalBids}',
        ];
      }
      return [
        a.title,
        formatPrice(a.finalPrice ?? a.price),
        '${a.totalBids}',
      ];
    }).toList();

    return _pdfTable(
      title: title,
      headers: headers,
      rows: rows,
      baseStyle: baseStyle,
    );
  }

  static pw.Widget _pdfRefundTable({
    required AdminReportData report,
    required Map<String, UserModel> usersById,
    required pw.TextStyle baseStyle,
  }) {
    final rows = report.refundsList.map((p) {
      final user = usersById[p.userUid];
      final name = user?.name.isNotEmpty == true ? user!.name : p.userUid;
      return [
        formatDateTime(p.refundedAt ?? p.createdAt),
        name,
        p.packageLabel,
        formatPrice(p.amount),
      ];
    }).toList();

    return _pdfTable(
      title: 'Буцаалт',
      headers: const ['Огноо', 'Хэрэглэгч', 'Багц', 'Дүн'],
      rows: rows,
      baseStyle: baseStyle,
    );
  }
}
