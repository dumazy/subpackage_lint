import 'dart:isolate';

import 'package:analyzer/file_system/physical_file_system.dart';
import 'package:analyzer_plugin/starter.dart';
import 'plugin.dart';

void start(SendPort sendPort) {
  ServerPluginStarter(
    SubpackageLintPlugin(resourceProvider: PhysicalResourceProvider.INSTANCE),
  ).start(sendPort);
}