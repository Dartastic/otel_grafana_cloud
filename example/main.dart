// Licensed under the Apache License, Version 2.0
// Copyright 2025-2026 Mindful Software LLC d/b/a Dartastic.io, All rights reserved.

import 'package:dartastic_opentelemetry/dartastic_opentelemetry.dart';
import 'package:otel_grafana_cloud/otel_grafana_cloud.dart';

/// Traces Grafana Cloud calls with OpenTelemetry.
///
/// `otel_grafana_cloud` depends on the OpenTelemetry API only, so the application
/// initializes an SDK once at startup. Wrap each Grafana Cloud call in
/// [tracedGrafanaLokiPush]; the `invoke` callback makes the real call and reports what
/// came back, which is recorded on the span.
Future<void> main() async {
  await OTel.initialize(serviceName: 'grafana-cloud-example');

  // Wraps a Loki push (log batch) in a PRODUCER span.
  final grafanaLokiPushId = await tracedGrafanaLokiPush<String>(
    stackName: 'example',
    streamCount: 3,
    entryCount: 3,
    invoke: () async {
      // Make the Grafana Cloud call here, then report what it returned.
      return 'grafana_cloud_8f3a2c';
    },
  );
  OTelLog.info('tracedGrafanaLokiPush returned $grafanaLokiPushId');

  // Wraps a Mimir / Prometheus remote-write push in a PRODUCER span.
  final grafanaMimirPushId = await tracedGrafanaMimirPush<String>(
    stackName: 'example',
    sampleCount: 3,
    seriesCount: 3,
    invoke: () async {
      // Make the Grafana Cloud call here, then report what it returned.
      return 'grafana_cloud_8f3a2c';
    },
  );
  OTelLog.info('tracedGrafanaMimirPush returned $grafanaMimirPushId');

  // Calls that should not be traced, such as health checks, run inside
  // runWithoutGrafanaCloudInstrumentationAsync.
  await runWithoutGrafanaCloudInstrumentationAsync(
    () => tracedGrafanaLokiPush<String>(
      stackName: 'example',
      streamCount: 3,
      entryCount: 3,
      invoke: () async {
        return 'grafana_cloud_8f3a2c';
      },
    ),
  );

  await OTel.shutdown();
}
