import 'dart:io';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_pick/loading_dialog.dart';
import 'package:image_pick/snack_bar_type.dart';
import 'package:image_picker/image_picker.dart';

import 'package:permission_handler/permission_handler.dart';


import 'image_type.dart';
import 'logger_util.dart';
import 'media_screen.dart';
import 'metods.dart';

class ImagePickSheet extends StatelessWidget {

  final Function(ImageType imageType)? onSelectOption;

  const ImagePickSheet({
    super.key,
    this.onSelectOption,
  });

  @override
  Widget build(BuildContext context) {
    ThemeData theme = Theme.of(context);
    bool isDarkMode = theme.brightness == Brightness.dark;

    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        padding:
        const EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text(
              "Select upload option",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 17
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment:  MainAxisAlignment.center,
              children: [
                InkWell(
                  highlightColor: Colors.transparent,
                  splashColor: Colors.transparent,
                  onTap: () {
                    if(onSelectOption!=null){
                      onSelectOption!(ImageType.camera);
                    }
                  },
                  child: _imageTypeContainer(
                    context,
                    title: "Take A Photo",
                    icon: Icons.camera_alt_rounded,
                  ),
                ),
                SizedBox(width: 20,),
                InkWell(
                  highlightColor: Colors.transparent,
                  splashColor: Colors.transparent,
                  onTap: () {
                    if(onSelectOption!=null){
                      onSelectOption!(ImageType.gallery);
                    }
                  },
                  child: _imageTypeContainer(
                    context,
                    title: "Choose From Gallery",
                    icon: Icons.photo,
                  ),
                ),



              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _imageTypeContainer(
      BuildContext context, {
        required String title,
        required IconData? icon,
      }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Container(
        decoration: const BoxDecoration(
          borderRadius: BorderRadius.all(Radius.circular(16)),
          color: Color(0xff1392B6),
        ),
        height: 105,
        width: 105,
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Icon(
            icon,
            size: 32,
            color: Color(0xFFFFFFFF),
          ),
        ),
      ),
    );
  }

  static Future<void> showImagePickBottomSheet({
    required BuildContext context,
    bool isDismissible = true,
    int? limit,
    bool allowMultiple = false,
    Function(XFile selectedImg)? onSelectImage,
    Function(XFile selecteVideo)? onSelectVideo,
    Function(List<XFile> multiSelect)? onMultiSelect,
  }) async {
    showModalBottomSheet(
      backgroundColor: Colors.transparent,
      context: context,
      useSafeArea: true,
      isDismissible: isDismissible,
      builder: (context) {
        return ImagePickSheet(
          onSelectOption: (imageType) async {
            Get.back(closeOverlays: true);

              bool isEnable = await askPermission(
                permission: await getPermission(imageType),
                whichPermission: imageType.name.tr,
              );
              if (isEnable) {

                if(
                imageType == ImageType.gallery
                ){
                  context.loading.show();
                  await  MediaPicker(context: context,maxLimit: limit ?? 1).showPicker()
                      .then((images) async{
                    context.loading.hide();

                    if ( images!= null && images.isNotEmpty) {

                      for(int i = 0;i<images.length;i++){

                        final XFile imageFile = images[i];
                        if (imageFile.path.toLowerCase().endsWith("jpg") ||
                            imageFile.path.toLowerCase().endsWith("png") ||
                            imageFile.path.toLowerCase().endsWith("jpeg") ||
                            imageFile.path.toLowerCase().endsWith("heic")) {
                          bool isValidImage = await imageSize(imageFile);
                          logger.i("IMAGE PICKED: $imageFile");

                          if (isValidImage) {
                            if(i == images.length-1){
                              onMultiSelect!(images);
                            }

                          } else {
                            showSnackBar(
                              "Sorry! Maximum image size should be 15 MB.",
                              context,
                              type: SnackbarType.failure,
                            );
                            break;
                          }
                        } else {
                          showSnackBar(
                            'Please upload image format like jpg, jpeg, png, heic, etc.',
                            context,
                            type: SnackbarType.failure,
                          );
                        }
                      }


                    }
                  }).catchError((_){
                    context.loading.hide();
                  });
                }
                else{
                  context.loading.show();
                  final XFile? imageFile = await ImagePicker().pickImage(
                    source: imageType == ImageType.gallery
                        ? ImageSource.gallery
                        : ImageSource.camera,
                    imageQuality: 65,
                  );
                  context.loading.hide();
                  if (imageFile != null) {
                    if (imageFile.path.toLowerCase().endsWith("jpg") ||
                        imageFile.path.toLowerCase().endsWith("png") ||
                        imageFile.path.toLowerCase().endsWith("jpeg") ||
                        imageFile.path.toLowerCase().endsWith("heic")) {
                      bool isValidImage = await imageSize(imageFile);

                      if (isValidImage) {
                        onSelectImage!(imageFile);
                      } else {
                        showSnackBar(
                          "Sorry! Maximum image size should be 15 MB.",
                          context,
                          type: SnackbarType.failure,
                        );
                      }
                    } else {
                      showSnackBar(
                        'Please upload image format like jpg, jpeg, png, heic, etc.',
                        context,
                        type: SnackbarType.failure,
                      );
                    }

                    logger.i("IMAGE PICKED: ${imageFile.path}");
                  }
                }






              }
          },
        );
      },
    );
  }




}
