## 15 februari 2020

* add refresher builder

## 1.0.0+1

* Fix scroll to the max
* Fix refresher

## 1.0.0

* Stable version
* Add cursor and noMoreData arguments on InfiniteListView and RefresherInfinite to resume progress whenever changing tab
* Add flag should scroll to the max whenever scrolling to bottom most

## 0.0.4+2

* Refresher and Infinite Refresher only supports vertical axis
* Because NotificationListener<ScrollNotification> will be triggered too when its child/ren scroll
* Ideally there will be no vertical scrollable inside another vertical scrollable
* that's why to prevent this issue, _handleScrollNotification only fired when it's vertical scrolling

## 0.0.4+1

* Documentation fix

## 0.0.4

* Fix Android AlwaysScrollPhysics clamping problem.

## 0.0.3+2

* Disable Refresh when doing Fetch More Data and vice versa.

## 0.0.3+1

* Add new reset function without fetch new data (because it's handled at the front).

## 0.0.3

* Add Refresher combined with InfiniteListView (InfiniteRefresher).

## 0.0.2

* Add margin and loading size to argument, also scrollController is injectable from the outside world.
* Temporarily scroll functionality is disabled after it reaches for refresh height.

## 0.0.1+1

* Minor bug fix.

## 0.0.1

* Initial release.
