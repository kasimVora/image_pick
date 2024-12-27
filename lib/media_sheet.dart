import 'dart:async';
import 'dart:io';
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:image_pick/loading_dialog.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:skeletonizer/skeletonizer.dart';
import 'package:image/image.dart' as img;


import 'loading_status.dart';
import 'media_controller.dart';

Future<List<XFile>?> showGridBottomSheet(BuildContext context, int maxLimit) {
  var controller = Get.find<MediaPickerController>();
  // controller.init();

  return showModalBottomSheet<List<XFile>?>(
    context: context,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(15)),
    ),
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setState) {
          return Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Obx(
                        () => Row(
                      children: List.generate(
                          controller.mediaFoldersStream.length, (index) {
                        return InkWell(
                          highlightColor: Colors.transparent,
                          splashColor: Colors.transparent,
                          onTap: () async {
                            if (controller.loadStatus.value != LoadStatus.loading) {
                              await controller.fetchMediaOfAlbum(index);
                            }else{
                              print("loading");
                            }
                          },
                          child: Skeletonizer(
                            enabled: controller.loadStatus.value ==
                                LoadStatus.loading && controller
                                .mediaFoldersStream.isEmpty,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 6),
                              margin: const EdgeInsets.only(right: 10),
                              decoration: BoxDecoration(
                                color: controller.tabIndexStream.value ==
                                    index
                                    ? Colors.lightBlueAccent
                                    .withOpacity(0.2)
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(controller
                                  .mediaFoldersStream[index].name),
                            ),
                          ),
                        );
                      }),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                // GridView for Media Files
                Expanded(
                  child: Obx(
                        () => Skeletonizer(
                      enabled: controller.loadStatus.value ==
                          LoadStatus.loading,
                      child: GridView.builder(
                        gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          mainAxisSpacing: 8.0,
                          crossAxisSpacing: 8.0,
                          childAspectRatio: 1.0,
                        ),
                        itemCount: controller.mediaFilesStream.length,
                        controller: controller.scrollController,
                        itemBuilder: (context, index) {
                          return Skeleton.replace(
                            replace: controller.loadStatus.value ==
                                LoadStatus.loading &&
                                controller
                                    .mediaFilesStream[index].path.isEmpty,
                            replacement: Skeletonizer.zone(
                              child: Bone(
                                height: 50,
                                width: 50,
                                borderRadius: BorderRadius.circular(10.0),
                              ),
                            ),
                            child: InkWell(
                              highlightColor: Colors.transparent,
                              splashColor: Colors.transparent,
                              onTap: () async {
                                controller.onFileSelect(File(controller
                                    .mediaFilesStream[index].path));
                                if (maxLimit == 1) {
                                  Navigator.pop(
                                      context,
                                      (await compressed([
                                        File(controller
                                            .mediaFilesStream[index].path)
                                      ], context)));
                                }
                              },
                              child: Stack(
                                fit: StackFit.loose,
                                alignment: Alignment.topRight,
                                children: [
                                  ClipRRect(
                                    borderRadius:
                                    BorderRadius.circular(10.0),
                                    child: Stack(
                                      fit: StackFit.expand,
                                      children: [
                                        Image.file(
                                          controller
                                              .mediaFilesStream[index],
                                          width: double.infinity,
                                          height: double.infinity,
                                          cacheWidth: 300,
                                          cacheHeight: 300,
                                          filterQuality:
                                          FilterQuality.low,
                                          key: ValueKey<File>(controller
                                              .mediaFilesStream[index]),
                                          fit: BoxFit.contain,
                                        ),
                                      ],
                                    ),
                                  ),
                                  controller.selectedFile.isNotEmpty &&
                                      controller.selectedFile.any(
                                              (t) =>
                                          t.path ==
                                              controller
                                                  .mediaFilesStream[
                                              index]
                                                  .path)
                                      ? const Icon(
                                    Icons.check_circle,
                                    color: Colors.blue,
                                  )
                                      : const SizedBox()
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    InkWell(
                        highlightColor: Colors.transparent,
                        splashColor: Colors.transparent,
                        onTap: () {
                          Navigator.pop(context, null);
                        },
                        child: const Padding(
                          padding: EdgeInsets.all(8.0),
                          child: Text(
                            "Cancel",
                            style:
                            TextStyle(color: Colors.lightBlueAccent),
                          ),
                        )),
                    InkWell(
                        highlightColor: Colors.transparent,
                        splashColor: Colors.transparent,
                        onTap: () async {
                          Navigator.pop(
                              context,
                              controller.selectedFile.isNotEmpty
                                  ? await compressed(
                                  controller.selectedFile, context)
                                  : null);
                        },
                        child: const Padding(
                          padding: EdgeInsets.all(8.0),
                          child: Text(
                            "Done",
                            style:
                            TextStyle(color: Colors.lightBlueAccent),
                          ),
                        )),
                  ],
                )
              ],
            ),
          );
        },
      );
    },
  );
}

Future<List<XFile>> compressed(List<File> files, BuildContext context) async {
  List<XFile> comp = [];

  //if(files.first.fileType == MediaType.image){
  Get.context!.loading.show();
  // }

  try {
    final directory = await getTemporaryDirectory();

    for (int i = 0; i < files.length; i++) {
      // Pass the CompressionParams object to the compute function
      final compressedFilePath = await compute(
          compressImage, CompressionParams(files[i].path, directory.path));
      comp.add(XFile(compressedFilePath));
    }
    //if(files.first.fileType == MediaType.image){
    context.loading.hide();
    //}

    return comp;
  } catch (e) {
    context.loading.hide();
    print('Error during image compression: $e'); // Log error
    return comp;
  }
}

Future<String> compressImage(CompressionParams params) async {
  final file = File(params.filePath);

  if (kDebugMode) {
    final originalSize = await file.length();
    print('Original Size: ${(originalSize / 1024).toStringAsFixed(2)} KB');
  }

  // Read and decode the image
  final imageData = await file.readAsBytes();
  img.Image? originalImage = img.decodeImage(imageData);

  if (originalImage == null) {
    throw Exception('Could not decode image'); // Handle error if decoding fails
  }

  // Resize the image if necessary
  if (originalImage.width > params.maxWidth) {
    originalImage = img.copyResize(originalImage, width: params.maxWidth);
  }

  // Encode the image with compression
  final compressedData = img.encodeJpg(originalImage, quality: params.quality);

  // Get the directory to save the compressed image
  final newPath =
      '${params.directoryPath}/compressed_${file.uri.pathSegments.last}';
  final compressedFile = File(newPath)..writeAsBytesSync(compressedData);

  // if (kDebugMode) {
  //   final compressedSize = compressedFile.lengthSync();
  //   print('Compressed Size: ${(compressedSize / 1024).toStringAsFixed(2)} KB');
  // }

  return compressedFile.path;
}

class CompressionParams {
  final String filePath;
  final String directoryPath;
  final int quality;
  final int maxWidth;

  CompressionParams(this.filePath, this.directoryPath,
      {this.quality = 60, this.maxWidth = 400});
}
