import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:photo_manager/photo_manager.dart';

import 'loading_status.dart';
import 'media_screen.dart';

class MediaPickerController extends GetxController {
  int maxLimit = 0;
  MediaType mediaType = MediaType.image;
  final ScrollController scrollController = ScrollController();

  RxInt currentPage = 0.obs;
  int pageLimit = 12;
  RxInt end = 0.obs;

  RxList<AssetPathEntity> mediaFoldersStream = <AssetPathEntity>[].obs;
  RxList<File> selectedFile = <File>[].obs;
  RxList<File> mediaFilesStream = List.generate(20, (_) => File("")).obs;
  RxInt tabIndexStream = 0.obs;
  RxBool isLimitFinished = false.obs;

  Rx<LoadStatus> loadStatus = LoadStatus.initial.obs;

  // Initialize MediaPickerBloc and ask for permissions
  Future<void> init() async {
    await fetchAlbums(RequestType.image);
    fetchMediaOfAlbum(0); // load media from the first album by default

    scrollController.addListener(() async {
      if (scrollController.position.pixels ==
          scrollController.position.maxScrollExtent) {
        fetchMediaOfAlbum(tabIndexStream.value);
      }
    });
  }

  Future<void> fetchAlbums(RequestType type) async {
    var temp = await PhotoManager.getAssetPathList(
      hasAll: false,
      type: type,
    );

    mediaFoldersStream.value = [];

    for (int i = 0; i < temp.length; i++) {
      var d = await temp[i].assetCountAsync;
      if (kDebugMode) {
        print(
            "--- count $d -- name ${temp[i].type.toString()} ${temp[i].name.toString()}");
      }
      if (d != 0) {
        mediaFoldersStream.add(temp[i]);
      }
    }

    mediaFoldersStream.refresh();
  }

  Future<void> fetchMediaOfAlbum(int index) async {
    if (loadStatus.value == LoadStatus.loadingMore) {
      return; // Prevent duplicate loads
    }

    if (index != tabIndexStream.value) {
      currentPage.value = 0;
    }

    tabIndexStream.value = index; // added here to update view first

    if (index < mediaFoldersStream.length) {
      if (currentPage.value == 0) {
        loadStatus.value = LoadStatus.loading;
      } else {
        loadStatus.value = LoadStatus.loadingMore;
      }

      final fetchedMedia = await _mediaFromFolder(
        mediaFoldersStream[index],
        index,
        page: currentPage.value,
        limit: pageLimit,
      );

      if (currentPage.value == 0) {
        mediaFilesStream.clear();
      }

      mediaFilesStream.addAll(fetchedMedia);
      mediaFilesStream.refresh();
      currentPage.value++;
      loadStatus.value = LoadStatus.success;
    }
  }

  void onFileSelect(File file) {
    if (selectedFile.any((t) => t.path == file.path)) {
      selectedFile.removeWhere((f) => f.path == file.path);
    } else {
      if (selectedFile.length != maxLimit) {
        selectedFile.add(file);
        if (selectedFile.length == maxLimit) {
          isLimitFinished.value = true;
        }
      } else {
        isLimitFinished.value = true;
      }
    }
    selectedFile.refresh();
  }

  Future<List<File>> _mediaFromFolder(
    AssetPathEntity assetPathEntity,
    int index, {
    required int page,
    required int limit,
  }) async {
    List<File> fetchedFiles = [];
    final start = page * limit;
    final end = start + limit;

    List<AssetEntity> assets = await assetPathEntity.getAssetListRange(
      start: start,
      end: end,
    );

    for (var asset in assets) {
      final file = await asset.file;
      if (file != null) {
        fetchedFiles.add(file);
      }
    }

    // tabIndexStream.value = index ;
    return fetchedFiles;
  }
}
