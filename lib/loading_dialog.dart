import 'dart:ui';

import 'package:flutter/material.dart';


class LoadingDialog {
  LoadingDialog(this.context);

  final BuildContext context;
  final GlobalKey alertKey = GlobalKey();

  static LoadingDialog of(BuildContext context) {
    return LoadingDialog(context);
  }

  void show({String? feedback}) {
    _openLoadingDialog(context, feedback);
  }

  void hide({value}) {
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    }
    // if (alertKey.currentContext != null) {
    //   Navigator.of(context).pop();
    // }
  }

  void _openLoadingDialog(BuildContext context, String? feedback) {
    showDialog(
      barrierDismissible: false,
      context: context,
      barrierColor: Colors.black54,
      builder: (BuildContext context) {
        return BackdropFilter(
          filter: ImageFilter.blur(sigmaY: 8, sigmaX: 8),
          child: PopScope(
            canPop: false,
            onPopInvoked: (didPop) async {
              return;
            },
            child: Dialog(
              key: alertKey,
              backgroundColor: Colors.transparent,
              surfaceTintColor: Colors.transparent,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                   Container(
                     decoration: BoxDecoration(
                       borderRadius: BorderRadius.circular(20),
                       color: Colors.white,
                     ),
                     height: 60,
                     width: 60,
                     child: Center(
                       child: CircularProgressIndicator.adaptive(),
                     ),
                   ),
                  if (feedback != null) const SizedBox(height: 4),
                  if (feedback != null)
                    Text(
                      feedback,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.white),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

extension LoadingDialogExtension on BuildContext {
  LoadingDialog get loading => LoadingDialog.of(this);
}
