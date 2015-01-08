// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';
import 'dart:convert';

import 'dart:mirrors';

import 'package:_internal/libraries.dart'
    show LIBRARIES, LibraryInfo;

import '../../lib/src/mirrors/analyze.dart'
    show analyze;
import '../../lib/src/mirrors/dart2js_mirrors.dart'
    show BackDoor;

import '../../lib/src/filenames.dart';
import '../../lib/src/source_file.dart';
import '../../lib/src/source_file_provider.dart';
import '../../lib/src/util/uri_extras.dart';

const DART2JS = '../../lib/src/dart2js.dart';
const DART2JS_MIRROR = '../../lib/src/mirrors/dart2js_mirror.dart';
const SDK_ROOT = '../../../../sdk/';

bool isPublicDart2jsLibrary(String name) {
  return !name.startsWith('_') && LIBRARIES[name].isDart2jsLibrary;
}

var handler;
RandomAccessFile output;
Uri outputUri;
Uri sdkRoot;
const bool outputJson =
    const bool.fromEnvironment('outputJson', defaultValue: false);

main(List<String> arguments) {
  handler = new FormattingDiagnosticHandler()
      ..throwOnError = true;

  outputUri =
      handler.provider.cwd.resolve(nativeToUriPath(arguments.first));
  output = new File(arguments.first).openSync(mode: FileMode.WRITE);

  Uri myLocation =
      handler.provider.cwd.resolveUri(Platform.script);

  Uri packageRoot =
      handler.provider.cwd.resolve(Platform.packageRoot);

  Uri libraryRoot = myLocation.resolve(SDK_ROOT);

  sdkRoot = libraryRoot.resolve('../');

  // Get the names of public dart2js libraries.
  Iterable<String> names = LIBRARIES.keys.where(isPublicDart2jsLibrary);

  // Turn the names into uris by prepending dart: to them.
  List<Uri> uris = names.map((String name) => Uri.parse('dart:$name')).toList();

  analyze(uris, libraryRoot, packageRoot, handler.provider, handler)
      .then(jsonify);
}

jsonify(MirrorSystem mirrors) {
  var map = <String, String>{};

  mirrors.libraries.forEach((_, LibraryMirror library) {
    BackDoor.compilationUnitsOf(library).forEach((compilationUnit) {
      Uri uri = compilationUnit.uri;
      String filename = relativize(sdkRoot, uri, false);
      SourceFile file = handler.provider.sourceFiles['$uri'];
      map['sdk:/$filename'] = file.slowText();
    });
  });

  LIBRARIES.forEach((name, info) {
    var patch = info.dart2jsPatchPath;
    if (patch != null) {
      Uri uri = sdkRoot.resolve('sdk/lib/$patch');
      String filename = relativize(sdkRoot, uri, false);
      SourceFile file = handler.provider.sourceFiles['$uri'];
      map['sdk:/$filename'] = file.slowText();
    }
  });

  if (outputJson) {
    output.writeStringSync(JSON.encode(map));
  } else {
    output.writeStringSync('''
// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// DO NOT EDIT.
// This file is generated by jsonify.dart.

library dart.sdk_sources;

const Map<String, String> SDK_SOURCES = const <String, String>''');
    output.writeStringSync(JSON.encode(map).replaceAll(r'$', r'\$'));
    output.writeStringSync(';\n');
  }
  output.closeSync();
}
