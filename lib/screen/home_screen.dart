import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:photo_manager/photo_manager.dart';
import '../controller/permission_controller.dart';

class HomeScreen extends StatefulWidget {
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final PermissionController controller = Get.put(PermissionController());

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    // Schedule the permission dialog to show after the first frame is rendered.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _showPermissionDialog(context);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blueGrey,
        title: const Text('Get Photos',style: TextStyle(color: Colors.white),),
        centerTitle: true,
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        if (controller.albums.isEmpty) {
          return const Center(child: Text('No albums available.'));
        }

        // Display list of albums
        return ListView.builder(
          itemCount: controller.albums.length,
          itemBuilder: (context, index) {
            final album = controller.albums[index];
            return ExpansionTile(
              title: Text(album.name,style: const TextStyle(fontSize: 20,fontWeight: FontWeight.bold),),
              children: [
                FutureBuilder<List<AssetEntity>>(
                  future: album.getAssetListPaged(page: 0, size: 50),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const CircularProgressIndicator();
                    } else if (snapshot.hasError) {
                      return Text('Error: ${snapshot.error}');
                    } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      return const Text('No photos found.');
                    }

                    final photos = snapshot.data!;
                    return GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        crossAxisSpacing: 4.0,
                        mainAxisSpacing: 4.0,
                      ),
                      itemCount: photos.length,
                      itemBuilder: (context, photoIndex) {
                        return FutureBuilder<Widget>(
                          future: _buildImageThumbnail(photos[photoIndex]),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState == ConnectionState.done) {
                              return snapshot.data!;
                            } else {
                              return const CircularProgressIndicator();
                            }
                          },
                        );
                      },
                    );
                  },
                ),
              ],
            );
          },
        );
      }),
    );
  }

  // Helper method to build image thumbnails
  Future<Widget> _buildImageThumbnail(AssetEntity asset) async {
    try {
      final thumbnail = await asset.thumbnailDataWithSize(const ThumbnailSize(200, 200));
      if (thumbnail != null) {
        return Image.memory(thumbnail, fit: BoxFit.cover);
      } else {
        return const Center(child: Text('No Image Available'));
      }
    } catch (e) {
      return Center(child: Text('Error loading image: $e'));
    }
  }


  // Show permission dialog
  Future<void> _showPermissionDialog(BuildContext context) async {
    showDialog(
      context: context,
      barrierDismissible: false, // Prevent closing dialog without interaction
      builder: (context) {
        return AlertDialog(
          title: const Text('Permissions Required'),
          content: const Text(
              'This app needs access to your camera, storage, and photos to work properly.'),
          actions: [
            TextButton(
              onPressed: () => Get.back(), // Close dialog
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final isGranted = await controller.requestPermissions(); // Wait for permissions

                if (isGranted) {
                  Get.back(); // Close dialog if granted
                }
              },
              child: const Text('Allow'),
            )
          ],
        );
      },
    );
  }
}
