import 'package:integration_test/integration_test_driver.dart';

Future<void> main() => integrationDriver(
      responseDataCallback: (data) async {
        if (data == null) return;

        await writeResponseData(data);
        for (final entry in data.entries) {
          if (!entry.key.endsWith('Timeline')) continue;
          await writeResponseData(
            Map<String, dynamic>.from(entry.value as Map),
            testOutputFilename: entry.key,
          );
        }
      },
    );
