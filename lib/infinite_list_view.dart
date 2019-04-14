import 'dart:async';

import 'package:flutter/material.dart';
import 'package:refresher/loading_animation.dart';
import 'package:refresher/not_bouncing_physics.dart';

typedef void ResetFunction();
typedef Future<bool> Fetcher(BuildContext context, int cursor);

class InfiniteListRemote {
  ResetFunction reset;
  ResetFunction resetWithoutFetch;
}

class InfiniteListView extends StatefulWidget {
  final InfiniteListRemote remote;
  final WidgetBuilder widgetBuilder;
  final Fetcher fetcher;
  final ScrollController scrollController;
  final ScrollPhysics scrollPhysics;
  final bool isRefreshing;

  InfiniteListView({
    this.remote,
    this.widgetBuilder,
    this.fetcher,
    this.scrollController,
    this.scrollPhysics,
    bool isRefreshing,
  })  : assert(widgetBuilder != null),
        assert(fetcher != null),
        this.isRefreshing = isRefreshing ?? false;

  @override
  _InfiniteListViewState createState() => _InfiniteListViewState();
}

class _InfiniteListViewState extends State<InfiniteListView> with SingleTickerProviderStateMixin {
  ScrollController _scrollController;
  bool isPerformingRequest = false;
  int _cursor = 0;
  bool _noMoreData = false;
  bool enableOverScroll = true;
  AnimationController anim;
  bool firstBuild = true;
  bool _mayRefresh = true;

  @override
  void initState() {
    super.initState();

    anim = AnimationController(duration: Duration(seconds: 2), vsync: this);

    _scrollController = widget.scrollController ??
        ScrollController(keepScrollOffset: false, initialScrollOffset: 0.0);
  }

  _reset(BuildContext context) {
    if (this.mounted)
      setState(() {
        _noMoreData = false;
        _cursor = 0;
        _tryFetchMore(context);
      });
  }

  @override
  void dispose() {
    anim.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  _tryFetchMore(BuildContext context) async {
    if (!isPerformingRequest && !_noMoreData) {
      setState(() {
        _mayRefresh = false;
        isPerformingRequest = true;
      });

      bool hasData = await widget.fetcher(context, _cursor);

      if (this.mounted)
        setState(() {
          if (!hasData) {
            _noMoreData = true;
          } else {
            _cursor++;
          }
          isPerformingRequest = false;
          _mayRefresh = true;
        });
    }
  }

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (isPerformingRequest && _scrollController.hasClients && !anim.isAnimating) {
        anim.repeat();

        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          curve: Curves.easeOut,
          duration: const Duration(milliseconds: 200),
        );
      }
    });

    if (firstBuild) {
      _scrollController.addListener(() {
        if (!widget.isRefreshing &&
            _scrollController.position.maxScrollExtent > 0.0 &&
            _scrollController.position.pixels == _scrollController.position.maxScrollExtent) {
          _tryFetchMore(context);
        }
      });

      if (widget.remote != null) {
        widget.remote.reset = () {
          _reset(context);
        };

        widget.remote.resetWithoutFetch = () {
          _noMoreData = false;
          _cursor = 1;
        };
      }

      _tryFetchMore(context);
      firstBuild = false;
    }

    List<Widget> children = [widget.widgetBuilder(context)];

    if (isPerformingRequest) {
      children.add(_buildProgressIndicator());
    } else {
      anim.stop();
    }

    return SingleChildScrollView(
      child: Column(children: children),
      controller: _scrollController,
      physics: _mayRefresh ? widget.scrollPhysics : NotBouncingScrollPhysics(),
    );
  }

  Widget _buildProgressIndicator() {
    return isPerformingRequest
        ? Container(
            margin: EdgeInsets.all(8.0),
            child: LoadingAnimation(
              anim: anim,
              thickness: 4.0,
              size: 50.0,
            ))
        : Container();
  }
}
