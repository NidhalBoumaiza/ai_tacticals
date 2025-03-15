// core/utils/cache_manager.dart
import 'package:flutter_cache_manager/flutter_cache_manager.dart';

const String kCacheKey = 'customCacheKey';

final customCacheManager = CacheManager(
  Config(
    kCacheKey,
    stalePeriod: const Duration(days: 7),
    maxNrOfCacheObjects: 200,
    repo: JsonCacheInfoRepository(databaseName: kCacheKey),
    fileService: HttpFileService(),
  ),
);
