import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';

import '../../core/theme/app_colors.dart';

/// Doctor introduction video — supports both YouTube and direct URLs.
class DoctorDetailsVideo extends StatelessWidget {
  final bool videoStarted;
  final VideoPlayerController? videoController;
  final YoutubePlayerController? youtubeController;
  final VoidCallback onStartVideo;
  final ImageProvider Function(String path) imageProvider;
  final String doctorImage;

  const DoctorDetailsVideo({
    super.key,
    required this.videoStarted,
    this.videoController,
    this.youtubeController,
    required this.onStartVideo,
    required this.imageProvider,
    required this.doctorImage,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: AspectRatio(
        aspectRatio: 16 / 9,
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (videoStarted && youtubeController != null)
              YoutubePlayer(
                controller: youtubeController!,
                backgroundColor: Colors.black,
              )
            else if (videoStarted &&
                videoController != null &&
                videoController!.value.isInitialized)
              FittedBox(
                fit: BoxFit.cover,
                child: SizedBox(
                  width: videoController!.value.size.width,
                  height: videoController!.value.size.height,
                  child: VideoPlayer(videoController!),
                ),
              )
            else
              _buildVideoPoster(context),
          ],
        ),
      ),
    );
  }

  Widget _buildVideoPoster(BuildContext context) {
    return GestureDetector(
      onTap: onStartVideo,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image(
            image: imageProvider(doctorImage),
            fit: BoxFit.cover,
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return Container(
                color: AppColors.getSurfaceSecondary(context),
                child: Center(
                  child: CircularProgressIndicator(
                    value: loadingProgress.expectedTotalBytes != null
                        ? loadingProgress.cumulativeBytesLoaded /
                              loadingProgress.expectedTotalBytes!
                        : null,
                  ),
                ),
              );
            },
            errorBuilder: (_, _, _) => Container(
              color: AppColors.getSurfaceSecondary(context),
              child: const Center(
                child: Icon(
                  Icons.image_not_supported_rounded,
                  color: Colors.grey,
                  size: 32,
                ),
              ),
            ),
          ),
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withValues(alpha: 0.25),
                  Colors.black.withValues(alpha: 0.6),
                ],
              ),
            ),
          ),
          Center(
            child: Container(
              width: 62,
              height: 62,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.92),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.25),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Icon(
                Icons.play_arrow_rounded,
                size: 34,
                color: AppColors.primary,
              ),
            ),
          ),
          if (videoStarted)
            const Center(child: CircularProgressIndicator(color: Colors.white)),
        ],
      ),
    );
  }
}
