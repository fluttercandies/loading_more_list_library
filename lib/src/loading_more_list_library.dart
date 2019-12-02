import 'dart:async';

import 'dart:collection';
import 'package:meta/meta.dart';

abstract class RefreshBase {
  //if clear is true, it will clear list,before request
  Future<bool> refresh([bool clearBeforeRequest = false]);
  Future<bool> errorRefresh();
}

enum IndicatorStatus {
  none,
  loadingMoreBusying,
  fullScreenBusying,
  error,
  fullScreenError,
  noMoreLoad,
  empty
}

abstract class LoadingMoreBase<T> extends ListBase<T>
    with _LoadingMoreBloc<T>, RefreshBase {
  var _array = <T>[];

  @override
  T operator [](int index) {
    if (0 <= index && index < _array.length) return _array[index];
    return null;
  }

  @override
  void operator []=(int index, T value) {
    if (0 <= index && index < _array.length) _array[index] = value;
  }

  bool get hasMore => true;
  bool isLoading = false;

  //do not change this in out side
  IndicatorStatus indicatorStatus = IndicatorStatus.fullScreenBusying;

  
  @mustCallSuper
  Future<bool> loadMore() async {
    var preStatus = indicatorStatus;
    indicatorStatus = IndicatorStatus.loadingMoreBusying;
    if (preStatus != indicatorStatus) {
      onStateChanged(this);
    }
    return await _innerloadData(true);
  }

  Future<bool> _innerloadData([bool isloadMoreAction = false]) async {
    if (isLoading || !hasMore) return true;
    isLoading = true;
    var isSuccess = await loadData(isloadMoreAction);
    isLoading = false;
    if (isSuccess) {
      indicatorStatus = IndicatorStatus.none;
      if (this.isEmpty) indicatorStatus = IndicatorStatus.empty;
    } else {
      if (indicatorStatus == IndicatorStatus.fullScreenBusying) {
        indicatorStatus = IndicatorStatus.fullScreenError;
      } else if (indicatorStatus == IndicatorStatus.loadingMoreBusying) {
        indicatorStatus = IndicatorStatus.error;
      }
    }
    onStateChanged(this);
    return isSuccess;
  }

  Future<bool> loadData([bool isloadMoreAction = false]);

  @override
  @mustCallSuper
  Future<bool> refresh([bool notifyStateChanged = false]) async {
    if (notifyStateChanged) {
      this.clear();
      indicatorStatus = IndicatorStatus.fullScreenBusying;
      onStateChanged(this);
    }
    return await _innerloadData();
  }

  @override
  @mustCallSuper
  Future<bool> errorRefresh() async {
    if (this.isEmpty) return await refresh(true);
    return await loadMore();
  }

  @override
  int get length => _array.length;
  set length(int newLength) => _array.length = newLength;

  @override
  //@protected
  @mustCallSuper
  void onStateChanged(LoadingMoreBase<T> source) {
    super.onStateChanged(source);
  }

  bool get hasError {
    return indicatorStatus == IndicatorStatus.fullScreenError ||
        indicatorStatus == IndicatorStatus.error;
  }

  /// update ui
  void setState() {
    super.onStateChanged(this);
  }
}

class _LoadingMoreBloc<T> {
  final _rebuild =  StreamController<LoadingMoreBase<T>>.broadcast();
  Stream<LoadingMoreBase<T>> get rebuild => _rebuild.stream;

  void onStateChanged(LoadingMoreBase<T> source) {
    if (!_rebuild.isClosed) _rebuild.sink.add(source);
  }

  void dispose() {
    _rebuild.close();
  }
}
