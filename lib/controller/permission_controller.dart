import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:device_info_plus/device_info_plus.dart';

class PermissionController extends GetxController {
  var albums = <AssetPathEntity>[].obs;
  var isLoading = false.obs;

  // Request permissions and handle results
  Future<bool> requestPermissions() async {
    isLoading(true); // Start loading indicator

    // Request permissions using PhotoManager

    // Request permissions
    final storageStatus = await Permission.storage.request();
    final photosStatus = await Permission.photos.request();

    print("permission for storage  == ${storageStatus.isGranted}");
    print("permission  for status == ${photosStatus.isGranted}");

    // Handle different permissions for different Android versions
    if (Platform.isAndroid) {
      if (await _requestAndroidPermissions()) {
        print("Permissions granted for Android devices.");
        await loadAlbums();  // Load albums if permissions are granted
        isLoading(false);  // Stop loading indicator
        Get.back();  // Close the dialog
        return true;
      }
    } else if (Platform.isIOS) {
      // For iOS, only request the Photos permission
      final photosStatus = await Permission.photos.request();
      if (photosStatus.isGranted) {
        print("Photos permission granted for IOS devices.");
        await loadAlbums();
        isLoading(false);
        return true;
      }
    }
    // If permissions are denied or permanently denied
    Get.snackbar(
      'Permissions Required',
      'Please enable permissions from settings.',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.redAccent,
    );
    await openAppSettings();  // Open app settings if permanently denied
    isLoading(false);
    return false;
  }

  // Helper function to request Android permissions
  Future<bool> _requestAndroidPermissions() async {
    // For Android 13+ (API 33+), request READ_MEDIA permissions
    if (Platform.isAndroid && (await _isAndroid13OrHigher())) {
      final photosPermission = await Permission.photos.request();
      print("Photos permission: ${photosPermission.isGranted}");
      return photosPermission.isGranted;
    }

    // For Android 11+ (API 30+), request Manage Storage or Storage access
    final manageStorage = await Permission.manageExternalStorage.request();
    print("Manage Storage permission: ${manageStorage.isGranted}");

    if (manageStorage.isGranted) return true;

    // For Android 10 and below, request legacy storage permission
    final storagePermission = await Permission.storage.request();
    print("Storage permission: ${storagePermission.isGranted}");
    return storagePermission.isGranted;
  }
  // Check if the device is running Android 13 or higher
  Future<bool> _isAndroid13OrHigher() async {
    final version = await DeviceInfoPlugin().androidInfo;
    return version.version.sdkInt >= 33;
  }
  // Load albums (folders) from internal storage
  Future<void> loadAlbums() async {
    try {
      isLoading.value = true;
      print('Loading albums...');

      final allAlbums = await PhotoManager.getAssetPathList(type: RequestType.image);
      print(' albums data ==  $allAlbums');

      if (allAlbums.isNotEmpty) {
        print('Albums loaded: ${allAlbums.length}');
        albums.assignAll(allAlbums);
      } else {
        print('No albums found.');
        albums.clear();
      }
    } catch (e) {
      print('Error loading albums: $e');
    } finally {
      isLoading.value = false;
    }
  }
}
