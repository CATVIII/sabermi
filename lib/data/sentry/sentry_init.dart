import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:saber/data/prefs.dart';
import 'package:saber/data/sentry/sentry_filter.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:sentry_logging/sentry_logging.dart';

export 'package:sentry_flutter/sentry_flutter.dart' show SentryWidget;

/// Whether the Sentry SDK is available for use.
/// Also see [isSentryEnabled].
///
/// Always `false` in SaberMI. This fork must never send crash reports to the
/// upstream Saber Sentry project, so the SDK is never initialised, the consent
/// dialog is never shown and the settings entry is hidden.
/// See `NOTICE.md` for details.
const isSentryAvailable = false;

/// Whether Sentry was initialized when the app started.
///
/// This flag does not change after initialization. Changes to the user's consent
/// (mostly*) take place after restarting the app.
/// (*When revoked, [SentryFilter.beforeSend] discards all further events.)
bool get isSentryEnabled => _isSentryEnabled;
late bool _isSentryEnabled;

FutureOr<void> initSentry(FutureOr<void> Function() appRunner) async {
  SentryWidgetsFlutterBinding.ensureInitialized();
  Stows.markAsOnMainIsolate();
  await stows.sentryConsent.waitUntilRead();
  _isSentryEnabled = switch (stows.sentryConsent.value) {
    .unknown => false,
    .granted => true,
    .denied => false,
  };

  if (!isSentryAvailable || !isSentryEnabled) {
    return appRunner();
  }

  await SentryFlutter.init(populateSentryOptions, appRunner: appRunner);
}

@visibleForTesting
void populateSentryOptions(SentryFlutterOptions options) {
  // Intentionally empty. Upstream Saber hardcodes its own DSN here; sending
  // this fork's events there would leak our users' data into a Sentry project
  // we do not control. An empty DSN disables the transport entirely.
  options.dsn = '';
  options.addIntegration(LoggingIntegration());
  options.environment = kDebugMode ? 'debug' : 'release';
  // Filter data before sending
  options.beforeSend = SentryFilter.beforeSend;
  // Reduce data collection
  options.sendDefaultPii = false;
  options.enableAutoPerformanceTracing = false;
  options.enableUserInteractionTracing = false;
  options.reportViewHierarchyIdentifiers = false;
  options.useFlutterBreadcrumbTracking(); // disable native breadcrumbs
  options.enableAppLifecycleBreadcrumbs = false;
  options.enableBrightnessChangeBreadcrumbs = false;
  options.enableUserInteractionBreadcrumbs = false;
}

/// Tests typically don't use [initSentry] so this just sets the flag
/// so we don't get late initialization errors.
@visibleForTesting
void disableSentryForTesting() {
  _isSentryEnabled = false;
}
