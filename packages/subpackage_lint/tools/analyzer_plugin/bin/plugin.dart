import 'dart:isolate';
import 'package:subpackage_lint/subpackage_lint.dart';

void main(List<String> args, SendPort sendPort) {
  start(sendPort);
}
