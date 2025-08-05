import 'dart:typed_data';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/painting.dart'; // For PaintingBinding
import 'package:photo_manager/photo_manager.dart';
import 'package:flutter/services.dart'; // For MethodCall type

class AllPhotosTab extends StatefulWidget {
  const AllPhotosTab({super.key});

  @override
  State<AllPhotosTab> createState() => _AllPhotosTabState();
}

class _AllPhotosTabState extends State<AllPhotosTab> with WidgetsBindingObserver {
  List<AssetEntity> cameraAssets = [];
  bool loading = true;
  bool permissionDenied = false;

  final ScrollController _scrollController = ScrollController();

  // Correct callback signature:
  late void Function(MethodCall call) _photoChangeCallback;

  @override
  void initState() {
    super.initState();
    PaintingBinding.instance.imageCache
      ..maximumSize = 300
      ..maximumSizeBytes = 200 << 20; // 200MB

    WidgetsBinding.instance.addObserver(this);

    // Correct signature here:
    _photoChangeCallback = (MethodCall call) {
      if (mounted) _refreshAssets(keepOffset: true);
    };
    PhotoManager.addChangeCallback(_photoChangeCallback);
    PhotoManager.startChangeNotify();
    fetchCameraAssets();
  }

  @override
  void dispose() {
    PhotoManager.removeChangeCallback(_photoChangeCallback);
    PhotoManager.stopChangeNotify();
    WidgetsBinding.instance.removeObserver(this);
    _scrollController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _refreshAssets(keepOffset: true);
    }
  }

  Future<void> fetchCameraAssets() async {
    setState(() {
      loading = true;
    });

    final permitted = await PhotoManager.requestPermissionExtend();
    if (!mounted) return;
    if (!permitted.isAuth) {
      setState(() {
        loading = false;
        permissionDenied = true;
      });
      return;
    }
    final albums = await PhotoManager.getAssetPathList(
      onlyAll: false,
      type: RequestType.all,
    );
    final cameraAlbums = albums.where((album) {
      final n = album.name.toLowerCase();
      return n == 'camera' || n.contains('dcim');
    }).toList();

    List<AssetEntity> allAssets = [];
    for (final album in cameraAlbums) {
      final files = await album.getAssetListPaged(page: 0, size: 400);
      allAssets.addAll(files);
    }
    allAssets.sort((a, b) => b.createDateTime.compareTo(a.createDateTime));

    setState(() {
      cameraAssets = allAssets;
      loading = false;
      permissionDenied = false;
    });
  }

  // Reload, keeping scroll offset if desired
  Future<void> _refreshAssets({bool keepOffset = false}) async {
    if (!keepOffset) {
      await fetchCameraAssets();
      return;
    }
    final oldAssets = cameraAssets;
    final scrollOffset = _scrollController.hasClients ? _scrollController.offset : 0.0;
    await fetchCameraAssets();

    if (!mounted || cameraAssets.isEmpty || oldAssets.isEmpty) return;
    final visibleIndex = _getFirstVisibleIndex(scrollOffset);
    if (visibleIndex == -1) return;
    final oldId = oldAssets[visibleIndex].id;
    final newIndex = cameraAssets.indexWhere((asset) => asset.id == oldId);
    if (newIndex != -1 && _scrollController.hasClients) {
      final row = newIndex ~/ 3; // 3 columns grid
      final itemExtent = (MediaQuery.of(context).size.width / 3) + 4;
      final targetOffset = row * itemExtent;
      _scrollController.jumpTo(targetOffset);
    } else if (_scrollController.hasClients) {
      _scrollController.jumpTo(scrollOffset);
    }
  }

  int _getFirstVisibleIndex(double offset) {
    final itemExtent = (MediaQuery.of(context).size.width / 3) + 4;
    final row = (offset / itemExtent).floor();
    final index = row * 3;
    if (index >= cameraAssets.length) return -1;
    return index;
  }

  @override
  Widget build(BuildContext context) {
    const double navBarHeight = 0;
    final double bottomInset = MediaQuery.of(context).padding.bottom;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 55, left: 12, right: 12, bottom: 25),
          child: SizedBox(
            height: 40,
            child: Stack(
              alignment: Alignment.center,
              children: [
                const Center(
                  child: Text(
                    'All Photos',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const Positioned(
                  right: 0,
                  child: Text(
                    'Select',
                    style: TextStyle(
                      color: CupertinoColors.activeBlue,
                      fontSize: 17,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        Expanded(
          child: Builder(
            builder: (context) {
              if (loading) {
                return const Center(child: CircularProgressIndicator());
              }
              if (permissionDenied) {
                return Center(
                  child: Text(
                    'Permission denied.\nEnable photo/video permissions in settings.',
                    style: Theme.of(context).textTheme.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                );
              }
              if (cameraAssets.isEmpty) {
                return const Center(child: Text('No camera photos or videos found.'));
              }
              return GridView.builder(
                controller: _scrollController,
                physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
                padding: EdgeInsets.fromLTRB(
                  2, 8, 2,
                  8 + navBarHeight + bottomInset,
                ),
                itemCount: cameraAssets.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  childAspectRatio: 1.0,
                  crossAxisSpacing: 6,
                  mainAxisSpacing: 4,
                ),
                itemBuilder: (context, index) {
                  final asset = cameraAssets[index];
                  return FutureBuilder<Uint8List?>(
                    future: asset.thumbnailDataWithSize(const ThumbnailSize(400, 400)),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.done && snapshot.hasData && snapshot.data != null) {
                        return Stack(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(16),
                              child: Image.memory(
                                snapshot.data!,
                                fit: BoxFit.cover,
                                width: double.infinity,
                                height: double.infinity,
                              ),
                            ),
                            if (asset.type == AssetType.video)
                              Positioned(
                                left: 6,
                                bottom: 6,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.black54,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(CupertinoIcons.videocam, size: 14, color: Colors.white),
                                      const SizedBox(width: 4),
                                      Text(
                                        formatDuration(asset.videoDuration),
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w600,
                                          fontFamily: 'InterSemiBold',
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                          ],
                        );
                      } else {
                        return Container(
                          color: Colors.grey[300],
                          child: const Center(child: Icon(Icons.broken_image, color: Colors.grey, size: 32)),
                        );
                      }
                    },
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

String formatDuration(Duration d) {
  final min = d.inMinutes.toString().padLeft(2, '0');
  final sec = (d.inSeconds % 60).toString().padLeft(2, '0');
  return '$min:$sec';
}
