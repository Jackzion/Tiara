// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'main_nav_index.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// 主框架导航下标（Home / Genre / Favorites）

@ProviderFor(CurrentNavIndex)
final currentNavIndexProvider = CurrentNavIndexProvider._();

/// 主框架导航下标（Home / Genre / Favorites）
final class CurrentNavIndexProvider
    extends $NotifierProvider<CurrentNavIndex, int> {
  /// 主框架导航下标（Home / Genre / Favorites）
  CurrentNavIndexProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'currentNavIndexProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$currentNavIndexHash();

  @$internal
  @override
  CurrentNavIndex create() => CurrentNavIndex();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(int value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<int>(value),
    );
  }
}

String _$currentNavIndexHash() => r'72a235c8333c8a9f406f787ae86d3484c68967ce';

/// 主框架导航下标（Home / Genre / Favorites）

abstract class _$CurrentNavIndex extends $Notifier<int> {
  int build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<int, int>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<int, int>,
              int,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
