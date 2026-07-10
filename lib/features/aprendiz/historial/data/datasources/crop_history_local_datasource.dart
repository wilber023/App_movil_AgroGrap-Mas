import 'package:hive/hive.dart';
import 'dart:convert';
import '../models/crop_event_model.dart';

abstract class CropHistoryLocalDataSource {
  Future<void> cacheCropHistory(List<CropEventModel> history);
  Future<List<CropEventModel>?> getCachedCropHistory();
}

class CropHistoryLocalDataSourceImpl implements CropHistoryLocalDataSource {
  final Box<String> box;
  static const _cachedHistoryKey = 'CACHED_CROP_HISTORY';

  CropHistoryLocalDataSourceImpl({required this.box});

  @override
  Future<void> cacheCropHistory(List<CropEventModel> history) async {
    final jsonList = history.map((e) => e.toJson()).toList();
    await box.put(_cachedHistoryKey, jsonEncode(jsonList));
  }

  @override
  Future<List<CropEventModel>?> getCachedCropHistory() async {
    final jsonString = box.get(_cachedHistoryKey);
    if (jsonString != null) {
      final List<dynamic> decoded = jsonDecode(jsonString);
      return decoded.map((e) => CropEventModel.fromJson(e)).toList();
    }
    return null;
  }
}
