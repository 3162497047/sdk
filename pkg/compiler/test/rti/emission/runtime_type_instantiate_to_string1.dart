// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.7

main() {
  /*spec:nnbd-off|spec:nnbd-sdk.checks=[$signature],instance*/
  /*prod:nnbd-off|prod:nnbd-sdk.checks=[],instance*/
  T id<T>(T t) => t;
  int Function(int) x = id;
  print("${x.runtimeType}");
}
