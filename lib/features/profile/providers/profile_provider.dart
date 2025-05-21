import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/utils/storage_util.dart';
import '../models/profile_model.dart';

class ProfileProvider extends ChangeNotifier {
  final StorageUtil _storage = StorageUtil();
  ProfileModel? _profile;
  bool _isLoading = false;
  String? _error;

  ProfileModel? get profile => _profile;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> getProfile() async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final token = await _storage.getToken();
      final response = await http.get(
        Uri.parse('${ApiConstants.baseUrl}/users/profile'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        _profile = ProfileModel.fromJson(data['data']);
      } else {
        _error = 'Failed to load profile';
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateProfile({
    String? name,
    int? age,
    String? gender,
    double? height,
    double? weight,
    String? activityLevel,
  }) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final token = await _storage.getToken();
      final response = await http.put(
        Uri.parse('${ApiConstants.baseUrl}/users/profile'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          if (name != null) 'name': name,
          if (age != null) 'age': age,
          if (gender != null) 'gender': gender,
          if (height != null) 'height': height,
          if (weight != null) 'weight': weight,
          if (activityLevel != null) 'activityLevel': activityLevel,
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        _profile = ProfileModel.fromJson(data['data']);
      } else {
        _error = 'Failed to update profile';
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> uploadProfileImage(File imageFile) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final token = await _storage.getToken();
      
      // Create multipart request
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('${ApiConstants.baseUrl}/users/profile/image'),
      );

      // Add authorization header
      request.headers.addAll({
        'Authorization': 'Bearer $token',
      });

      // Add image file
      final fileStream = http.ByteStream(imageFile.openRead());
      final fileLength = await imageFile.length();
      
      final multipartFile = http.MultipartFile(
        'image',
        fileStream,
        fileLength,
        filename: imageFile.path.split('/').last,
        contentType: MediaType('image', 'jpeg'),
      );

      request.files.add(multipartFile);

      // Send request
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (_profile != null) {
          _profile = ProfileModel.fromJson({
            ..._profile!.toJson(),
            'profileImage': data['data']['profileImage'],
          });
        }
      } else {
        _error = 'Failed to upload profile image';
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final token = await _storage.getToken();
      final response = await http.post(
        Uri.parse('${ApiConstants.baseUrl}/auth/logout'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        await _storage.clearToken();
        _profile = null;
      } else {
        _error = 'Failed to logout';
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
} 