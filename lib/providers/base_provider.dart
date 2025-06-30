import 'package:flutter/material.dart';

typedef SnackbarCallback = void Function(bool success, String message);

abstract class BaseProvider extends ChangeNotifier {
  bool _isLoading = false;
  String? _error;
  String? _successMessage;
  SnackbarCallback? _snackbarCallback;

  // Getters
  bool get isLoading => _isLoading;
  String? get error => _error;
  String? get successMessage => _successMessage;

  // Set callback untuk snackbar
  void setSnackbarCallback(SnackbarCallback? callback) {
    _snackbarCallback = callback;
  }

  // Set loading state
  void setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  // Set error
  void setError(String? error) {
    _error = error;
    if (error != null && _snackbarCallback != null) {
      _snackbarCallback!(false, error);
    }
    notifyListeners();
  }

  // Set success message
  void setSuccess(String? message) {
    _successMessage = message;
    if (message != null && _snackbarCallback != null) {
      _snackbarCallback!(true, message);
    }
    notifyListeners();
  }

  // Clear error and success message
  void clearMessages() {
    _error = null;
    _successMessage = null;
    notifyListeners();
  }

  // Handle API response and show snackbar
  void handleApiResponse(bool success, String message) {
    if (success) {
      setSuccess(message);
    } else {
      setError(message);
    }
  }

  @override
  void dispose() {
    _snackbarCallback = null;
    super.dispose();
  }
}
