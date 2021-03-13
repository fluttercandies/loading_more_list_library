import 'dart:async';

import 'dart:collection';
import 'package:meta/meta.dart';

abstract class RefreshBase {
  Future<bool> refresh([bool notifyStateChanged = false]);
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
  final List<T> _array = <T>[];

  @override
  T operator [](int index) => _array[index];

  @override
  void operator []=(int index, T value) => _array[index] = value;

  bool get hasMore => true;
  bool isLoading = false;

  //do not change this in out side
  IndicatorStatus indicatorStatus = IndicatorStatus.fullScreenBusying;

  @mustCallSuper
  Future<bool> loadMore() async {
    final IndicatorStatus preStatus = indicatorStatus;
    indicatorStatus = IndicatorStatus.loadingMoreBusying;
    if (preStatus != indicatorStatus) {
      onStateChanged(this);
    }
    return await _innerloadData(true);
  }

  Future<bool> _innerloadData([bool isloadMoreAction = false]) async {
    if (isLoading || !hasMore) {
      return true;
    }
    isLoading = true;
    final bool isSuccess = await loadData(isloadMoreAction);
    isLoading = false;
    if (isSuccess) {
      indicatorStatus = IndicatorStatus.none;
      if (isEmpty) {
        indicatorStatus = IndicatorStatus.empty;
      }
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
      clear();
      indicatorStatus = IndicatorStatus.fullScreenBusying;
      onStateChanged(this);
    }
    return await _innerloadData();
  }

  @override
  @mustCallSuper
  Future<bool> errorRefresh() async {
    if (isEmpty) {
      return await refresh(true);
    }
    return await loadMore();
  }

  @override
  int get length => _array.length;
  @override
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

  @override
  void add(T element) {
    _array.add(element);
  }
}

class _LoadingMoreBloc<T> {
  final StreamController<LoadingMoreBase<T>> _rebuild =
      StreamController<LoadingMoreBase<T>>.broadcast();
  Stream<LoadingMoreBase<T>> get rebuild => _rebuild.stream;

  void onStateChanged(LoadingMoreBase<T> source) {
    if (!_rebuild.isClosed) {
      _rebuild.sink.add(source);
    }
  }

  void dispose() {
    _rebuild.close();
  }
}
