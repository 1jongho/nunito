import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';

class CustomFluttertoast {
  static const double _bottomOffset = 110.0;
  static FToast? _fToast;

  static Future<void> showToast({
    required String msg,
    Toast? toastLength,
    double? fontSize,
    ToastGravity? gravity,
    Color? backgroundColor,
    Color? textColor,
    required BuildContext context,
  }) async {
    if (gravity == ToastGravity.BOTTOM) {
      await _showCustomBottomToast(
        context: context,
        msg: msg,
        toastLength: toastLength,
        fontSize: fontSize,
        backgroundColor: backgroundColor,
        textColor: textColor,
      );
    } else {
      await Fluttertoast.showToast(
        msg: msg,
        toastLength: toastLength,
        gravity: gravity,
        timeInSecForIosWeb: (toastLength == Toast.LENGTH_LONG) ? 3 : 2,
        fontSize: fontSize,
        backgroundColor: backgroundColor,
        textColor: textColor,
      );
    }
  }

  static Future<void> _showCustomBottomToast({
    required BuildContext context,
    required String msg,
    Toast? toastLength,
    double? fontSize,
    Color? backgroundColor,
    Color? textColor,
  }) async {
    try {
      _fToast = FToast();
      _fToast!.init(context);

      Widget toast = Container(
        margin: EdgeInsets.symmetric(horizontal: 20.0),
        padding: EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(25.0),
          color: backgroundColor ?? Colors.black87,
          boxShadow: [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 8.0,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Text(
          msg,
          style: TextStyle(
            color: textColor ?? Colors.white,
            fontSize: fontSize ?? 16.0,
            fontFamily: 'Pretendard',
          ),
          textAlign: TextAlign.center,
        ),
      );

      int durationSeconds = (toastLength == Toast.LENGTH_LONG) ? 3 : 2;

      _fToast!.showToast(
        child: toast,
        toastDuration: Duration(seconds: durationSeconds),
        positionedToastBuilder: (context, child, gravity) {
          return Positioned(
            bottom: _bottomOffset,
            left: 0,
            right: 0,
            child: child,
          );
        },
      );
    } catch (e) {
      await Fluttertoast.showToast(
        msg: msg,
        toastLength: toastLength,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: backgroundColor,
        textColor: textColor,
        fontSize: fontSize,
      );
    }
  }

  static void cancel() {
    _fToast?.removeCustomToast();
  }

  static void cancelAll() {
    _fToast?.removeQueuedCustomToasts();
  }
}
