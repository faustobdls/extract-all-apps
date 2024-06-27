import 'dart:io';

import 'package:process_run/shell.dart';

Future<void> entrypoint() async {
  var shell = Shell();

  print('fetch all packages');
  List<ProcessResult> results1CMD =
      await shell.run('adb shell pm list packages -3');
  if (results1CMD.isEmpty ||
      (results1CMD.firstOrNull?.stdout.isEmpty ?? true)) {
    return;
  }
  final String result1CMD = results1CMD.firstOrNull?.stdout;
  final List<String> allInstaledPackages = result1CMD.split('package:');

  print('create destination folder');
  List<ProcessResult> results2CMD = await shell.run('mkdir -p extracted-apps');
  if (results2CMD.isEmpty || (results2CMD.firstOrNull?.exitCode != 0)) {
    return;
  }

  print('filter instaled packages ( remove system and google apps )');
  final List<String> filterInstaledPackages =
      allInstaledPackages.where(filterPackages).toList();

  for (var instaledPackages in filterInstaledPackages) {
    print('path app apk: $instaledPackages');
    List<ProcessResult> results3CMD =
        await shell.run('adb shell pm path $instaledPackages');
    if (results3CMD.isEmpty ||
        (results3CMD.firstOrNull?.stdout.isEmpty ?? true)) {
      return;
    }
    String appPath = results3CMD.firstOrNull?.stdout;
    appPath = appPath.trim();
    appPath = appPath.split('package:').elementAt(1);
    appPath = appPath.replaceAll('/base.apk', '');
    appPath = appPath.replaceAll('\n', '');
    print('init pull app: $instaledPackages');
    print('adb pull $appPath extracted-apps/$instaledPackages');
    List<ProcessResult> results4CMD = await shell
        .run('adb pull $appPath extracted-apps/$instaledPackages');
    if (results4CMD.isEmpty ||
        (results4CMD.firstOrNull?.stdout.isEmpty ?? true)) {
      return;
    }
    print('finish pull app: $instaledPackages');
    print(' - - - - - - - - - - - - - - - - - - - -');
  }
}

bool filterPackages(String package) {
  return ![
    package.isEmpty,
    package.contains('com.android'),
    package.contains('com.google'),
  ].contains(true);
}
