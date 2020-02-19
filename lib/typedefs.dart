import 'dart:async';

import 'package:flutter/material.dart';

typedef int ItemCountGetter();
typedef void ResetFunction();
typedef Future<bool> Fetcher(BuildContext context, int cursor);