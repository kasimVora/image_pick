import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';

import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';

import 'logger_util.dart';
import 'media_controller.dart';
import 'media_sheet.dart';
import 'metods.dart';


enum MediaType{
  image,video,document,unknown
}

class MediaPicker {
  BuildContext context;
  int  maxLimit;
  MediaType mediaType;
  MediaPicker({
    required this.context,
     this.maxLimit = 1,
     this.mediaType = MediaType.image,
});

   Future<List<XFile>?> showPicker() async{
     bool isEnable = await _askPermission();
     if (isEnable) {
       Get.put(MediaPickerController());
       Get.find<MediaPickerController>().maxLimit = maxLimit;
       Get.find<MediaPickerController>().mediaType = mediaType;
       Get.find<MediaPickerController>().init();
       await Future.delayed(Duration(seconds: 1));
       return showGridBottomSheet(context,maxLimit);
     }
   return null;
  }

  Future<bool> _askPermission() async {
    Permission permission = await _getPermission();
    PermissionStatus status = await permission.request();

    if (status.isGranted || status.isLimited) {
      return true;
    } else if (status.isPermanentlyDenied) {
      openAppSettings();
      return false;
    }
    return false;
  }



  Future<Permission> _getPermission() async {
    if (Platform.isAndroid && await getAndroidVersion() < 33) {
      return Permission.storage;
    } else {
      return Permission.photos;
    }
  }



}
extension FileTypeChecker on File {
  MediaType _getFileType() {
    final extension = path.split('.').last.toLowerCase();

    switch (extension) {
      case 'mp4':
      case 'mov':
      case 'avi':
      case 'm4v':
      case '3gp':
        return MediaType.video;

      case 'jpg':
      case 'jpeg':
      case 'png':
        return MediaType.image;



      case 'pdf':
      case 'doc':
      case 'docx':
      case 'xlsx':
      case 'ppt':
      case 'pptx':
      case 'txt':
        return MediaType.document;

      default:
        return MediaType.unknown;
    }
  }

  MediaType get fileType => _getFileType();
  String get fileName => path.split("/").last;
}