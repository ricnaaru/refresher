import 'dart:async';

import 'package:flutter/material.dart';
import 'package:refresher/always_bouncing_physics.dart';
import 'package:refresher/infinite_list_view.dart';
import 'package:refresher/loading_animation.dart';
import 'package:refresher/not_bouncing_physics.dart';
import 'package:refresher/refresh_indicator_physics.dart';

typedef Future<void> RefreshCallback();
typedef int ItemCountGetter();

class RefresherBuilder extends StatefulWidget {
  final RefreshCallback onRefresh;
  final ScrollController scrollController;
  final bool vanishAfterDrag;
  final double loadingSize;
  final EdgeInsets margin;
  final EdgeInsets padding;
  final IndexedWidgetBuilder widgetBuilder;
  final ItemCountGetter itemCountGetter;
  final bool noMoreData;
  final double dividerHeight;

  RefresherBuilder({
    this.scrollController,
    this.onRefresh,
    bool vanishAfterDrag,
    double loadingSize,
    EdgeInsets margin,
    EdgeInsets padding,
    this.widgetBuilder,
    this.itemCountGetter,
    this.noMoreData,
    this.dividerHeight,
  })  : this.vanishAfterDrag = vanishAfterDrag ?? false,
        this.loadingSize = loadingSize ?? 50.0,
        this.margin = margin ?? EdgeInsets.all(16.0),
        this.padding = padding ?? EdgeInsets.all(16.0);

  @override
  _RefresherBuilderState createState() => _RefresherBuilderState();
}

class _RefresherBuilderState extends State<RefresherBuilder>
    with TickerProviderStateMixin {
  ScrollController _scrollController;
  double _height = 0.0;
  double _maxHeight;
  bool _refreshing = false;
  bool _aboutToRefresh = false;
  bool _show = false;
  bool _needRebuild = false;
  AnimationController _animationController;
  AnimationController _sizeAnimationController;
  bool _mayPerform = false;
  bool _mayRefresh = true;
  LoadingController _tempRefreshController = LoadingController();
  LoadingController _refreshController = LoadingController(thickness: 4.0);
  double percentage = 0.0;

  @override
  void initState() {
    super.initState();
    _maxHeight = widget.loadingSize + widget.margin.vertical;
    RefreshIndicatorPhysics.height = _maxHeight;
    _scrollController = widget.scrollController ?? ScrollController();
    _animationController = AnimationController(
        duration: Duration(milliseconds: 2000), vsync: this);
    _sizeAnimationController =
        AnimationController(duration: Duration(milliseconds: 200), vsync: this);

//    WidgetsBinding.instance.addPostFrameCallback((_) {
//      setState(() {
//        _refreshing = true;
//        _show = true;
//        _animationController.repeat();
//      });
//    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    _sizeAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_needRebuild) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        setState(() {
          _show = true;
          _height = 0.0;
          _needRebuild = false;
          _scrollController.jumpTo(0.0);
        });
      });
    }

    if (_show && _sizeAnimationController.value == 0.0)
      _sizeAnimationController.value = 1.0;
    _tempRefreshController.thickness = 4.0 * _height / _maxHeight;

    return Stack(children: [
      Column(children: [
        Visibility(
            visible: _show && !(_refreshing && widget.vanishAfterDrag),
            child: SizeTransition(
                sizeFactor: _sizeAnimationController,
                child: Container(
                  height: _show ? _maxHeight : 0.0,
                  width: double.infinity,
                  child: LoadingAnimation(
                      margin: widget.margin,
                      size: widget.loadingSize,
                      controller: _refreshController,
                      anim: _animationController),
                ))),
        Expanded(
            child: Container(
                constraints: BoxConstraints.expand(),
                child: GestureDetector(
                  child: NotificationListener<ScrollNotification>(
                    onNotification: _handleScrollNotification,
                    child: ListView.separated(
                      physics: _refreshing && !_show && !widget.vanishAfterDrag
                          ? RefreshIndicatorPhysics()
                          : _refreshing || _mayRefresh
                              ? AlwaysBouncingScrollPhysics()
                              : NotBouncingScrollPhysics(),
                      padding: widget.padding,
                      separatorBuilder: (context, i) =>
                          Divider(height: widget.dividerHeight ?? 0),
                      controller: _scrollController,
                      itemBuilder: widget.widgetBuilder,
                      itemCount: widget.itemCountGetter(),
                    ),
                  ),
                )))
      ]),
      Visibility(
        visible: !_show && !(_refreshing && widget.vanishAfterDrag),
        child: Positioned(
          top: 0.0,
          right: 0.0,
          left: 0.0,
          height: _height,
          child: Container(
              child: LoadingAnimation(
                  margin: EdgeInsets.only(
                    top: widget.margin.top * _height / _maxHeight,
                    left: widget.margin.left * _height / _maxHeight,
                    bottom: widget.margin.bottom * _height / _maxHeight,
                    right: widget.margin.right * _height / _maxHeight,
                  ),
                  size: widget.loadingSize,
                  controller: _tempRefreshController,
                  anim: _animationController)),
        ),
      ),
    ]);
  }

  bool _handleScrollNotification(ScrollNotification notification) {
    if (notification.metrics.axis != Axis.vertical) return false;

    if (notification is ScrollStartNotification) {
      if (!_show)
        try {
          //prevent error caused by infinite list view right after there is no more data while trying to refetch it
          if ((notification.metrics.pixels <
                      notification.metrics.maxScrollExtent &&
                  notification.metrics.maxScrollExtent > 0.0) ||
              notification.metrics.maxScrollExtent == 0.0)
            setState(() {
              _mayPerform = true;
            });
        } on FlutterError catch (e) {
          print("e => $e");
        }
    } else if (notification is ScrollUpdateNotification) {
      print("_mayPerform => $_mayPerform");
      print("notification.metrics.pixels => ${notification.metrics.pixels}");
      if (_mayPerform) {
        setState(() {
          if (notification.metrics.pixels < 0) {
            double scrollPosition = notification.metrics.pixels.abs();

            if (scrollPosition >= _maxHeight) {
              if (!_aboutToRefresh) {
                _animationController.repeat();
                _aboutToRefresh = true;
                if (!_refreshing) {
                  _refreshing = true;
                  _show = true;

                  _scrollController.jumpTo(0.0);

                  if (widget.onRefresh != null)
                    widget.onRefresh().then((_) {
                      if (this.mounted) _animationController.stop();

                      if (this.mounted)
                        _sizeAnimationController.reverse(from: 1.0).then((_) {
                          if (this.mounted)
                            setState(() {
                              _show = false;
                              _refreshing = false;
                            });
                        });
                    });
                }
              }
            } else {
              if (_aboutToRefresh && !_refreshing) {
                _animationController.stop();
              }
              _aboutToRefresh = false;
              _tempRefreshController.percentage =
                  scrollPosition / _maxHeight * widget.loadingSize;
            }

            _height = scrollPosition.clamp(0.0, _maxHeight);
          } else if (notification.metrics.pixels > 0) {
            _height = 0.0;
          }
        });
      }
    } else if (notification is ScrollEndNotification) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        setState(() {
          if (_mayPerform) {
            if (_refreshing) {
              _needRebuild = true;
            }

            _mayPerform = false;
          }

          if (notification.metrics.pixels == 0.0) {
            _mayRefresh = true;
          } else {
            _mayRefresh = false;
          }
        });
      });
    }

    return true;
  }
}
