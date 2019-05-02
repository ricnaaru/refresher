import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:refresher/refresher_infinite.dart';

class InfiniteRefresherDemo extends StatefulWidget {
  @override
  _InfiniteRefresherDemoState createState() => _InfiniteRefresherDemoState();
}

class _InfiniteRefresherDemoState extends State<InfiniteRefresherDemo>
    with SingleTickerProviderStateMixin {
  String _title = "Infinite Refresher Demo";
  List<Widget> _children = [];
  double percentage = 0.0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        // Here we take the value from the MyHomePage object that was created by
        // the App.build method, and use it to set our appbar title.
        title: Text(_title),
      ),
      body: InfiniteRefresher(
        loadingSize: 50.0,
        margin: EdgeInsets.all(8.0),
        onRefresh: () async {
          int counter = 0;
          Timer.periodic(Duration(milliseconds: 1000), (t) {
            counter++;
            if (this.mounted)
              setState(() {
                _title = "Fetching${List.filled(counter, ".").join()}";
                if (counter == 5) t.cancel();
              });
          });
          await Future.delayed(new Duration(milliseconds: 1000));
          _children.clear();
          _children.addAll(List.generate(
            Random().nextInt(100),
                (index) => Text("Here is $index"),
          ));
          if (this.mounted)
            setState(() {
              _title = "Infinite Refresher Demo";
            });
        },
        widgetBuilder: (context) {
          return Column(children: _children);
        },
        fetcher: (context, cursor) async {
          await Future.delayed(Duration(milliseconds: 3000));

          _children.addAll(List.generate(
            Random().nextInt(100),
            (index) => Text("Here is $index"),
          ));

          return true;
        },
      ),
    );
  }
}
