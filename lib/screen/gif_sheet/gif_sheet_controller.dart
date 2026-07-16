import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:krimson/common/controller/base_controller.dart';
import 'package:krimson/common/functions/debounce_action.dart';
import 'package:krimson/common/manager/logger.dart';
import 'package:krimson/common/manager/session_manager.dart';
import 'package:krimson/common/service/api/giphy_service.dart';
import 'package:krimson/model/general/settings_model.dart';
import 'package:krimson/model/giphy/giphy_model.dart';

class GifSheetController extends BaseController {
  RxList<GiphyData> trendingList = <GiphyData>[].obs;
  RxList<GiphyData> searchingGiphyList = <GiphyData>[].obs;
  final Setting? setting = SessionManager.instance.getSettings();
  RxBool isTrendingLoading = false.obs;
  RxBool isSearchLoading = false.obs;
  TextEditingController searchTextController = TextEditingController();
  RxBool isTextEmpty = true.obs;
  RxnString emptyMessage = RxnString();

  @override
  void onInit() {
    super.onInit();
    fetchTrendingGiphy();
  }

  Future<void> fetchTrendingGiphy({bool isEmpty = false}) async {
    if (isTrendingLoading.value || (!isEmpty && trendingList.length > 89)) {
      return;
    }
    String apiKey = setting?.giphyKey ?? '';
    if (apiKey.trim().isEmpty) {
      emptyMessage.value =
          'GIPHY no configurado. Activa gif_support y giphy_key en el panel admin.';
      Loggers.warning('GIPHY key empty — configure giphy_key in settings');
      return;
    }
    isTrendingLoading.value = true;
    emptyMessage.value = null;
    try {
      List<GiphyData> items = await GiphyService.instance.trending(
          apiKey: apiKey,
          startCount:
              isEmpty ? 0 : (trendingList.isEmpty ? 0 : trendingList.length));
      if (isEmpty) trendingList.clear();
      if (items.isNotEmpty) {
        trendingList.addAll(items);
      } else if (trendingList.isEmpty) {
        emptyMessage.value = 'No GIFs available from GIPHY right now.';
      }
    } catch (e) {
      emptyMessage.value = e.toString().replaceFirst('Exception: ', '');
      Loggers.error('GIPHY trending: $e');
    } finally {
      isTrendingLoading.value = false;
    }
  }

  Future<void> fetchSearchGiphy({bool isEmpty = false}) async {
    if (isSearchLoading.value) return;
    if (!isEmpty && searchingGiphyList.length > 89) return;
    String apiKey = setting?.giphyKey ?? '';
    if (apiKey.trim().isEmpty) {
      emptyMessage.value =
          'GIPHY no configurado. Activa gif_support y giphy_key en el panel admin.';
      return;
    }
    isSearchLoading.value = true;
    emptyMessage.value = null;
    try {
      List<GiphyData> items = await GiphyService.instance.search(
          apiKey: apiKey,
          keyWord: searchTextController.text.trim(),
          startCount: isEmpty
              ? 0
              : (searchingGiphyList.isEmpty ? 0 : searchingGiphyList.length));
      if (isEmpty) searchingGiphyList.clear();
      if (items.isNotEmpty) {
        searchingGiphyList.addAll(items);
      } else if (searchingGiphyList.isEmpty) {
        emptyMessage.value = 'No GIFs found for this search.';
      }
    } catch (e) {
      emptyMessage.value = e.toString().replaceFirst('Exception: ', '');
      Loggers.error('GIPHY search: $e');
    } finally {
      isSearchLoading.value = false;
    }
  }

  void onChanged(String value) {
    isTextEmpty.value = value.trim().isEmpty;
    DebounceAction.shared.call(() {
      if (isTextEmpty.value) {
        fetchTrendingGiphy(isEmpty: true);
      } else {
        fetchSearchGiphy(isEmpty: true);
      }
    });
  }
}
