import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:get/get_utils/src/platform/platform.dart';
import 'package:image_pick/snack_bar_type.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';

import 'image_type.dart';
import 'logger_util.dart';

Future<int> getAndroidVersion() async {
  if (GetPlatform.isAndroid) {
    AndroidDeviceInfo androidDeviceInfo =
    await DeviceInfoPlugin().androidInfo;
    logger.log(
      "androidDeviceInfo.version.sdkInt: ${androidDeviceInfo.version.sdkInt}",
    );
    return androidDeviceInfo.version.sdkInt;
  } else {
    return 0;
  }
}


/// gallery permission
Future<Permission?> getPermission(ImageType imageType) async {
  if (imageType == ImageType.camera) {
    return Permission.camera;
  } else if (Platform.isAndroid && await getAndroidVersion() < 33) {
    return Permission.storage;
  } else {
    return Permission.photos;
  }
}


Future<bool> askPermission({
  Permission? permission,
  String? whichPermission,
}) async {
  bool isPermissionGranted = await permission!.isGranted;
  var shouldShowRequestRationale = await permission.shouldShowRequestRationale;

  if (isPermissionGranted) {
    return true;
  } else {
    if (!shouldShowRequestRationale) {
      var permissionStatus = await permission.request();
      logger.e("STATUS == $permissionStatus");
      if (permissionStatus.isPermanentlyDenied) {
/* CommonWidgets.showCustomDialog(
              Get.context,
              LocaleKeys.permission.tr,
              "${LocaleKeys.pleaseAllowThe.tr} $whichPermission ${LocaleKeys.permissionFromSettings.tr}",
              LocaleKeys.cancel.tr,
              LocaleKeys.settings.tr, (value) {
            /// OPEN SETTING CODE
            if (value == 1) {
              openAppSettings();
            }
          });*/
        return false;
      }
      if (permissionStatus.isGranted || permissionStatus.isLimited) {
        return true;
      } else {
        return false;
      }
    } else {
      var permissionStatus = await permission.request();
      if (permissionStatus.isGranted || permissionStatus.isLimited) {
        return true;
      } else {
        return false;
      }
    }
  }
}

Future<bool> imageSize(XFile file) async {
  final bytes = (await file.readAsBytes()).lengthInBytes;
  final kb = bytes / 1024;
  final mb = kb / 1024;

  logger.e("IMAGE SIZE ----$mb");

  if (mb <= 15) {
    return true;
  } else {
    return false;
  }
}

void showSnackBar(
    String message,
    BuildContext context,{
      SnackbarType type = SnackbarType.success,
      void Function()? onErrorDialogClick,
    }) async {
  if (!Get.isSnackbarOpen) {
    if (Get.isSnackbarOpen) {
      Get.closeCurrentSnackbar();
    }

    Get.snackbar(
      '',
      '',
      snackPosition: SnackPosition.TOP,
      snackStyle: SnackStyle.FLOATING,
      messageText: Text(
        message,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w500,
        ),
      ),
      titleText: Container(),
      borderWidth: 1,
      backgroundColor:
      type == SnackbarType.success ? Colors.green : Colors.red,
      colorText: Theme.of(context).colorScheme.surface,
      isDismissible: true,
      animationDuration: const Duration(milliseconds: 500),
      duration: const Duration(seconds: 3),
      margin: const EdgeInsets.all(8.0),
      mainButton: TextButton(
        child: type == SnackbarType.success
            ? const Icon(
          Icons.done,
          color: Colors.white,
        )
            : const Icon(
          Icons.close,
          color: Colors.white,
        ),
        onPressed: () {
          if (Get.isSnackbarOpen) {
            Get.closeCurrentSnackbar();
          }
        },
      ),
    );
  }
}

