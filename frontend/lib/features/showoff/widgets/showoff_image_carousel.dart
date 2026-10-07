import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';

class ShowOffImageCarousel extends StatefulWidget {
  final List<String> images;
  final Widget overlay;

  const ShowOffImageCarousel({
    super.key,
    required this.images,
    required this.overlay,
  });

  @override
  State<ShowOffImageCarousel> createState() => _ShowOffImageCarouselState();
}

class _ShowOffImageCarouselState extends State<ShowOffImageCarousel> {
  int _current = 0;

  @override
  Widget build(BuildContext context) {
    final count = widget.images.length;
    return SizedBox(
      height: 460.h,
      child: Stack(
        fit: StackFit.expand,
        children: [
          PageView.builder(
            itemCount: count,
            onPageChanged: (i) => setState(() => _current = i),
            itemBuilder: (_, i) => CachedNetworkImage(
              imageUrl: widget.images[i],
              fit: BoxFit.cover,
              fadeInDuration: const Duration(milliseconds: 300),
              placeholder: (_, __) => Shimmer.fromColors(
                baseColor: const Color(0xFFE0E0E0),
                highlightColor: const Color(0xFFF5F5F5),
                child: Container(color: Colors.white),
              ),
              errorWidget: (_, __, ___) => Container(
                color: Colors.grey.shade200,
                child: const Icon(
                  Icons.broken_image_rounded,
                  size: 48,
                  color: Colors.grey,
                ),
              ),
            ),
          ),
          const IgnorePointer(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.transparent,
                    Color(0xB3000000),
                  ],
                  stops: [0, 0.6, 1],
                ),
              ),
            ),
          ),
          if (count > 1) ...[
            Positioned(top: 14.h, right: 14.w, child: _counter(count)),
            Positioned(bottom: 10.h, left: 0, right: 0, child: _dots(count)),
          ],
          Positioned(
            left: 16.w,
            right: 16.w,
            bottom: count > 1 ? 30.h : 16.h,
            child: widget.overlay,
          ),
        ],
      ),
    );
  }

  Widget _counter(int count) => Container(
    padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
    decoration: BoxDecoration(
      color: Colors.black54,
      borderRadius: BorderRadius.circular(12.r),
    ),
    child: Text(
      '${_current + 1}/$count',
      style: TextStyle(
        color: Colors.white,
        fontSize: 12.sp,
        fontWeight: FontWeight.w600,
      ),
    ),
  );

  Widget _dots(int count) => Row(
    mainAxisAlignment: MainAxisAlignment.center,
    children: List.generate(
      count,
      (i) => AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: EdgeInsets.symmetric(horizontal: 3.w),
        width: i == _current ? 18.w : 6.w,
        height: 6.w,
        decoration: BoxDecoration(
          color: i == _current ? Colors.white : Colors.white54,
          borderRadius: BorderRadius.circular(3.r),
        ),
      ),
    ),
  );
}
