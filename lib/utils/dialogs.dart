import 'package:app_movil_comunidad/utils/constants/constants.dart';
import 'package:flutter/material.dart';
import 'package:cool_alert_two/cool_alert_two.dart';

class Dialogs {
  static ButtonStyle flatButtonStyle = TextButton.styleFrom(
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(100.0),
      side: const BorderSide(color: kPrimaryColor),
    ),
    backgroundColor: kPrimary2Color,
    foregroundColor: Colors.white,
    padding: const EdgeInsets.all(8.0),
  );

  static void showDialogLogoutMejorado(
    BuildContext context, {
    VoidCallback? onOk,
    VoidCallback? onCancel,
  }) {
    CoolAlertTwo.show(
      title: "Confirmación",
      animType: CoolAlertTwoAnimType.scale,
      borderRadius: 25,
      barrierDismissible: false,
      context: context,
      type: CoolAlertTwoType.confirm,
      flareAsset: "assets/flare/info_check.flr",
      cancelBtnText: "No",
      confirmBtnColor: Colors.red,
      confirmBtnText: "Si",
      onConfirmBtnTap: onOk,
      onCancelBtnTap: onCancel,
      text: "¿Estás seguro que quieres cerrar sesión?",
    );
  }

  static void showDialogPersonalizado(
    BuildContext context,
    String text, {
    VoidCallback? onOk,
    VoidCallback? onCancel,
  }) {
    CoolAlertTwo.show(
      title: "Confirmación",
      animType: CoolAlertTwoAnimType.scale,
      borderRadius: 25,
      barrierDismissible: false,
      context: context,
      type: CoolAlertTwoType.confirm,
      flareAsset: "assets/flare/info_check.flr",
      cancelBtnText: "No",
      confirmBtnColor: Colors.red,
      confirmBtnText: "Si",
      onConfirmBtnTap: onOk,
      onCancelBtnTap: onCancel,
      text: text,
    );
  }

  static void showDialogValidar(
    BuildContext context,
    String title,
    String text,
    CoolAlertTwoType cooAlert,
  ) {
    CoolAlertTwo.show(
      title: title,
      animType: CoolAlertTwoAnimType.scale,
      flareAsset: "assets/flare/info_check.flr",
      borderRadius: 25,
      barrierDismissible: false,
      context: context,
      type: cooAlert,
      text: text,
    );
  }

  static void showDialogSuccess(
    BuildContext context,
    param1, {
    String title = '',
    String text = '',
    VoidCallback? onOk,
  }) {
    CoolAlertTwo.show(
      title: title,
      onConfirmBtnTap: onOk,
      animType: CoolAlertTwoAnimType.scale,
      flareAsset: "assets/flare/success_check.flr",
      borderRadius: 25,
      barrierDismissible: true,
      context: context,
      type: CoolAlertTwoType.success,
      text: text,
    );
  }

  static void showDialogLoading(
    BuildContext context,
    String title,
    String text,
  ) {
    CoolAlertTwo.show(
      title: title,
      animType: CoolAlertTwoAnimType.scale,
      flareAsset: "assets/flare/loading.flr",
      borderRadius: 25,
      barrierDismissible: false,
      context: context,
      type: CoolAlertTwoType.loading,
      text: text,
    );
  }
}
