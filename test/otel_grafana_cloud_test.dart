// Licensed under the Apache License, Version 2.0
// Copyright 2025-2026 Mindful Software LLC d/b/a Dartastic.io, All rights reserved.

import 'package:dartastic_opentelemetry/dartastic_opentelemetry.dart';
import 'package:dartastic_opentelemetry/testing.dart';
import 'package:otel_grafana_cloud/otel_grafana_cloud.dart';
import 'package:test/test.dart';

void main() {
  late TestHarness harness;
  late InMemorySpanExporter spans;

  setUpAll(() async {
    harness = await maybeInitializeOtelForTest(
      serviceName: 'otel_grafana_cloud-test',
    );
    spans = harness.spans;
  });

  setUp(() => harness.clear());

  Map<String, Object> attrsOf(Span s) =>
      {for (final a in s.attributes.toList()) a.key: a.value};

  test('Loki push records PRODUCER span', () async {
    await tracedGrafanaLokiPush<String>(
      stackName: 'prod-us',
      streamCount: 4,
      entryCount: 100,
      invoke: () async => 'ok',
    );
    final a = attrsOf(spans.findSpanByName('grafana loki push')!);
    expect(a['grafana.product'], 'loki');
    expect(a['grafana.stack.name'], 'prod-us');
    expect(a['grafana.loki.stream_count'], 4);
    expect(a['messaging.batch.message_count'], 100);
  });

  test('Mimir push records PRODUCER span', () async {
    await tracedGrafanaMimirPush<String>(
      sampleCount: 1000,
      seriesCount: 10,
      invoke: () async => 'ok',
    );
    final a = attrsOf(spans.findSpanByName('grafana mimir push')!);
    expect(a['messaging.system'], 'prometheus_remote_write');
    expect(a['grafana.mimir.sample_count'], 1000);
    expect(a['grafana.mimir.series_count'], 10);
  });

  test('suppression skips spans', () async {
    await runWithoutGrafanaCloudInstrumentationAsync(() async {
      await tracedGrafanaLokiPush<String>(invoke: () async => 'ok');
    });
    expect(spans.findSpansStartingWith('grafana '), isEmpty);
  });
}
