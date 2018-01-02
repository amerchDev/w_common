import 'dart:async';

import 'package:test/test.dart';
import 'package:w_common/src/common/cache/cache.dart';
import 'package:w_common/src/common/cache/least_recently_used_strategy.dart';
import 'package:w_common/src/common/cache/reference_counting_strategy.dart';

typedef CachingStrategy<String, Object> CachingStrategyFactory();

// A set of unit tests that should pass for all caching strategies
void main() {
  <String, CachingStrategyFactory>{
    'ReferenceCountingStrategy': () =>
        new ReferenceCountingStrategy<String, Object>(),
    'MostRecentlyUsedStrategy keep = 0': () => new LeastRecentlyUsedStrategy(0),
    'MostRecentlyUsedStrategy keep = 1': () => new LeastRecentlyUsedStrategy(1),
    'MostRecentlyUsedStrategy keep = 2': () => new LeastRecentlyUsedStrategy(2),
  }.forEach((name, strategyFactory) {
    group('$name', () {
      Cache<String, Object> cache;
      setUp(() {
        cache = new Cache(strategyFactory());
      });

      test(
          'synchronous get release get should not unnecessarily '
          'remove item from cache', () async {
        var valueFactoryCalled = 0;
        var valueFactory = () async {
          valueFactoryCalled++;
          return new Object();
        };
        var firstGetCall = cache.getAsync('id', valueFactory);
        var release = cache.release('id');
        var secondGetCall = cache.getAsync('id', valueFactory);

        await release;

        var thirdGetCall = cache.getAsync('id', valueFactory);

        expect(await firstGetCall, await secondGetCall);
        expect(await secondGetCall, await thirdGetCall);
        // This should be checked after gets and releases are awaited
        expect(valueFactoryCalled, 1);
      });

      test(
          'synchronous get release release get should not unnecessarily '
          'remove item from cache', () async {
        var valueFactoryCalled = 0;
        var valueFactory = () async {
          valueFactoryCalled++;
          return new Object();
        };
        var firstGetCall = cache.getAsync('id', valueFactory);
        var releases = Future.wait([cache.release('id'), cache.release('id')]);
        var secondGetCall = cache.getAsync('id', valueFactory);

        await releases;

        var thirdGetCall = cache.getAsync('id', valueFactory);

        expect(await firstGetCall, await secondGetCall);
        expect(await secondGetCall, await thirdGetCall);
        // This should be checked after gets and releases are awaited
        expect(valueFactoryCalled, 1);
      });
    });
  });
}
