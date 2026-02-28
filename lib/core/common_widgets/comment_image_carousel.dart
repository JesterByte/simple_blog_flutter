import 'package:flutter/material.dart';

class CommentImageCarousel extends StatefulWidget {
  final List<String> images;

  const CommentImageCarousel({super.key, required this.images});

  @override
  State<CommentImageCarousel> createState() => _CommentImageCarouselState();
}

class _CommentImageCarouselState extends State<CommentImageCarousel> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 180,
      child: Stack(
        children: [
          PageView.builder(
            itemCount: widget.images.length,
            onPageChanged: (i) {
              setState(() {
                _index = i;
              });
            },
            itemBuilder: (context, index) {
              return ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.network(widget.images[index], fit: BoxFit.cover),
              );
            },
          ),
          if (widget.images.isNotEmpty && widget.images.length > 1)
            Positioned(
              bottom: 10,
              right: 10,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${_index + 1} / ${widget.images.length}',
                  style: const TextStyle(color: Colors.white, fontSize: 12),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
