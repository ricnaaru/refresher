import 'dart:async';

import 'package:flutter/material.dart';
import 'package:refresher/refresher.dart';
import 'package:refresher_example/infinite_demo.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: RefresherDemo(),
    );
  }
}

class RefresherDemo extends StatefulWidget {
  @override
  _RefresherDemoState createState() => _RefresherDemoState();
}

class _RefresherDemoState extends State<RefresherDemo> with SingleTickerProviderStateMixin {
  String _title = "Refresher Demo";

  double percentage = 0.0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_title), actions: [
        IconButton(
          icon: Icon(Icons.navigate_next),
          onPressed: () {
            Navigator.push(context,
                MaterialPageRoute(builder: (BuildContext context) => InfiniteRefresherDemo()));
          },
        )
      ]),
      body: Refresher(
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
            await Future.delayed(new Duration(milliseconds: 6000));
            if (this.mounted)
              setState(() {
                _title = "Refresher Demo";
              });
          },
          child: Column(
              children: List.generate(
            100,
            (index) => Text("Here is $index"),
          ))),
    );
  }
}
