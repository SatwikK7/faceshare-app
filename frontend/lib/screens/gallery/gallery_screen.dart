import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../services/photo_service.dart';
import '../../models/photo.dart';
import '../../utils/constants.dart';
import 'photo_detail_screen.dart';

class GalleryScreen extends StatefulWidget {
  const GalleryScreen({super.key});

  @override
  State<GalleryScreen> createState() => _GalleryScreenState();
}

class _GalleryScreenState extends State<GalleryScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    
    // Load photos when screen initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PhotoService>().refreshPhotos();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gallery'),
        backgroundColor: AppColors.primaryColor,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(text: 'My Photos'),
            Tab(text: 'Shared with Me'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => context.read<PhotoService>().refreshPhotos(),
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildMyPhotosTab(),
          _buildSharedPhotosTab(),
        ],
      ),
    );
  }

  Widget _buildMyPhotosTab() {
    return Consumer<PhotoService>(
      builder: (context, photoService, child) {
        if (photoService.isLoading && photoService.myPhotos.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        if (photoService.myPhotos.isEmpty) {
          return _buildEmptyState(
            icon: Icons.photo_library_outlined,
            title: 'No photos yet',
            subtitle: 'Upload your first photo using the Upload tab',
          );
        }

        return _buildPhotoGrid(photoService.myPhotos);
      },
    );
  }

  Widget _buildSharedPhotosTab() {
    return Consumer<PhotoService>(
      builder: (context, photoService, child) {
        if (photoService.isLoading && photoService.sharedPhotos.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        if (photoService.sharedPhotos.isEmpty) {
          return _buildEmptyState(
            icon: Icons.people_outline,
            title: 'No shared photos',
            subtitle: 'Photos shared with you will appear here',
          );
        }

        return _buildPhotoGrid(photoService.sharedPhotos);
      },
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 64,
            color: AppColors.textSecondary.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.textSecondary.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPhotoGrid(List<Photo> photos) {
    return RefreshIndicator(
      onRefresh: () => context.read<PhotoService>().refreshPhotos(),
      child: GridView.builder(
        padding: const EdgeInsets.all(8),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
          childAspectRatio: 1,
        ),
        itemCount: photos.length,
        itemBuilder: (context, index) {
          final photo = photos[index];
          return _buildPhotoCard(photo);
        },
      ),
    );
  }

  Widget _buildPhotoCard(Photo photo) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => PhotoDetailScreen(photo: photo),
            ),
          );
        },
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Photo image
            CachedNetworkImage(
              imageUrl: photo.imageUrl,
              fit: BoxFit.cover,
              placeholder: (context, url) => Container(
                color: AppColors.backgroundColor,
                child: const Center(
                  child: CircularProgressIndicator(),
                ),
              ),
              errorWidget: (context, url, error) => Container(
                color: AppColors.backgroundColor,
                child: const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error_outline, color: AppColors.error),
                    SizedBox(height: 4),
                    Text(
                      'Failed to load',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.error,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Status overlay
            Positioned(
              top: 8,
              right: 8,
              child: _buildStatusChip(photo),
            ),

            // Face count overlay
            if (photo.facesDetected > 0)
              Positioned(
                bottom: 8,
                left: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.face,
                        size: 16,
                        color: Colors.white,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${photo.facesDetected}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusChip(Photo photo) {
    Color color;
    IconData icon;
    String text;

    switch (photo.processingStatus) {
      case 'COMPLETED':
        color = AppColors.success;
        icon = Icons.check_circle;
        text = 'Done';
        break;
      case 'PROCESSING':
        color = AppColors.warning;
        icon = Icons.hourglass_empty;
        text = 'Processing';
        break;
      case 'FAILED':
        color = AppColors.error;
        icon = Icons.error;
        text = 'Failed';
        break;
      default:
        color = AppColors.textSecondary;
        icon = Icons.schedule;
        text = 'Pending';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: Colors.white),
          const SizedBox(width: 2),
          Text(
            text,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}