import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'snackbar_util.dart';
import '../providers/base_provider.dart';

mixin ProviderSnackbarMixin<T extends BaseProvider> {
  void setupProviderSnackbar(BuildContext context) {
    final provider = Provider.of<T>(context, listen: false);
    provider.setSnackbarCallback((success, message) {
      if (context.mounted) {
        SnackbarUtil.showApiResponse(context, success, message);
      }
    });
  }

  void clearProviderSnackbar(BuildContext context) {
    final provider = Provider.of<T>(context, listen: false);
    provider.setSnackbarCallback(null);
  }
}
