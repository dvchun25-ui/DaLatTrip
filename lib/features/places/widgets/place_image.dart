import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../../constants/app_colors.dart';
import '../../../core/utils/image_utils.dart';
import '../../../domain/entities/place.dart';
import '../services/place_image_service.dart';
import '../services/place_image_cache.dart';

class PlaceImage extends StatefulWidget {
  static final PlaceImageService defaultService = PlaceImageService();

  final Place place;
  final double width;
  final double height;
  final double borderRadius;
  final BoxFit fit;
  final PlaceImageService? service;

  const PlaceImage({
    super.key,
    required this.place,
    required this.width,
    required this.height,
    this.borderRadius = 16,
    this.fit = BoxFit.cover,
    this.service,
  });

  @override
  State<PlaceImage> createState() => _PlaceImageState();
}

class _PlaceImageState extends State<PlaceImage> {
  String? _imageUrl;

  PlaceImageService get _service => widget.service ?? PlaceImage.defaultService;

  @override
  void initState() {
    super.initState();
    _imageUrl = _service.getImageUrl(widget.place);
  }

  @override
  void didUpdateWidget(covariant PlaceImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.place.id != widget.place.id ||
        oldWidget.place.imageUrl != widget.place.imageUrl ||
        oldWidget.service != widget.service) {
      _imageUrl = _service.getImageUrl(widget.place);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(widget.borderRadius),
      child: SizedBox(
        width: widget.width,
        height: widget.height,
        child: _buildImage(context),
      ),
    );
  }

  Widget _buildImage(BuildContext context) {
    final image = _imageUrl;
    if (image == null || image.isEmpty) return _placeholder();

    final pixelRatio = MediaQuery.devicePixelRatioOf(context);
    final memoryWidth = widget.width.isFinite
        ? (widget.width * pixelRatio).round()
        : null;
    final memoryHeight = widget.height.isFinite
        ? (widget.height * pixelRatio).round()
        : null;

    if (!ImageUtils.isRemoteUrl(image)) {
      return Image.asset(
        image,
        width: widget.width,
        height: widget.height,
        fit: widget.fit,
        cacheWidth: memoryWidth,
        cacheHeight: memoryHeight,
        errorBuilder: (_, _, _) => _placeholder(),
      );
    }

    return CachedNetworkImage(
      imageUrl: image,
      cacheManager: PlaceImageCache.instance,
      width: widget.width,
      height: widget.height,
      fit: widget.fit,
      // Ảnh mạng còn lại được giải mã đúng kích thước widget để tiết kiệm RAM.
      memCacheWidth: memoryWidth,
      memCacheHeight: memoryHeight,
      fadeInDuration: const Duration(milliseconds: 180),
      placeholder: (_, _) => _loading(),
      errorWidget: (_, _, _) => _placeholder(),
    );
  }

  Widget _loading() {
    return Container(
      color: AppColors.mintBadgeLight,
      alignment: Alignment.center,
      child: const SizedBox(
        width: 20,
        height: 20,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          color: AppColors.primary,
        ),
      ),
    );
  }

  Widget _placeholder() {
    return Container(
      width: widget.width,
      height: widget.height,
      color: const Color(0xFFE8F0EB),
      alignment: Alignment.center,
      child: const Icon(
        Icons.image_outlined,
        color: AppColors.textSecondary,
        size: 30,
      ),
    );
  }
}
