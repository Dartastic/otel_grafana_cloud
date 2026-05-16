// Licensed under the Apache License, Version 2.0
// Copyright 2025, Mindful Software LLC, All rights reserved.

import 'package:dartastic_opentelemetry/dartastic_opentelemetry.dart';

import 'otel_grafana_cloud_suppression.dart';

const _tracerName = 'dartastic_otel_libs_grafana_cloud';

Tracer _tracer() => OTel.tracerProvider().getTracer(_tracerName);

/// Wraps a Loki `push` (log batch) in a PRODUCER span.
Future<T> tracedGrafanaLokiPush<T>({
  required Future<T> Function() invoke,
  String? stackName,
  int? streamCount,
  int? entryCount,
}) async {
  if (grafanaCloudInstrumentationSuppressed()) {
    return invoke();
  }
  final m = <String, Object>{
    'grafana.product': 'loki',
    'messaging.system': 'grafana_loki',
    'messaging.operation': 'publish',
    'messaging.destination.name': 'loki',
  };
  if (stackName != null) m['grafana.stack.name'] = stackName;
  if (streamCount != null) m['grafana.loki.stream_count'] = streamCount;
  if (entryCount != null) m['messaging.batch.message_count'] = entryCount;

  final span = _tracer().startSpan(
    'grafana loki push',
    kind: SpanKind.producer,
    attributes: OTel.attributesFromMap(m),
  );
  try {
    return await invoke();
  } catch (e, st) {
    span.addAttributes(OTel.attributes([
      OTel.attributeString(
        ErrorResource.errorType.key,
        e.runtimeType.toString(),
      ),
    ]));
    span.recordException(e, stackTrace: st);
    span.setStatus(SpanStatusCode.Error, e.toString());
    rethrow;
  } finally {
    span.end();
  }
}

/// Wraps a Mimir / Prometheus remote-write push in a PRODUCER span.
Future<T> tracedGrafanaMimirPush<T>({
  required Future<T> Function() invoke,
  String? stackName,
  int? sampleCount,
  int? seriesCount,
}) async {
  if (grafanaCloudInstrumentationSuppressed()) {
    return invoke();
  }
  final m = <String, Object>{
    'grafana.product': 'mimir',
    'messaging.system': 'prometheus_remote_write',
    'messaging.operation': 'publish',
    'messaging.destination.name': 'mimir',
  };
  if (stackName != null) m['grafana.stack.name'] = stackName;
  if (sampleCount != null) m['grafana.mimir.sample_count'] = sampleCount;
  if (seriesCount != null) m['grafana.mimir.series_count'] = seriesCount;

  final span = _tracer().startSpan(
    'grafana mimir push',
    kind: SpanKind.producer,
    attributes: OTel.attributesFromMap(m),
  );
  try {
    return await invoke();
  } catch (e, st) {
    span.addAttributes(OTel.attributes([
      OTel.attributeString(
        ErrorResource.errorType.key,
        e.runtimeType.toString(),
      ),
    ]));
    span.recordException(e, stackTrace: st);
    span.setStatus(SpanStatusCode.Error, e.toString());
    rethrow;
  } finally {
    span.end();
  }
}
