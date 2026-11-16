import 'dart:convert';
import 'dart:io';

import 'package:integration_test/integration_test_driver_extended.dart';

Future<void> main() async {
  final output = Directory(
    Platform.environment['TESITURA_EVIDENCE_DIR'] ??
        '../evidencias/android',
  );
  await output.create(recursive: true);
  await integrationDriver(
    onScreenshot: (name, bytes, [args]) async {
      await File('${output.path}/$name.png').writeAsBytes(bytes);
      return true;
    },
    responseDataCallback: (data) async {
      final summary = Map<String, dynamic>.from(data ?? {});
      final screenshots = summary.remove('screenshots') as List? ?? [];
      summary['capturas'] = screenshots
          .map((s) => s['screenshotName'])
          .toList();
      summary['resultado'] = 'correcto';
      summary['fecha'] = DateTime.now().toUtc().toIso8601String();
      await File('${output.path}/resultado.json').writeAsString(
        '${const JsonEncoder.withIndent('  ').convert(summary)}\n',
      );
    },
  );
}
