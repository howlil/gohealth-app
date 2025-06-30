import 'package:flutter/material.dart';
import 'loading_skeleton.dart';

class LoadingOverlay extends StatelessWidget {
  final bool isLoading;
  final Widget child;

  const LoadingOverlay({
    Key? key,
    required this.isLoading,
    required this.child,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        if (isLoading)
          Container(
            color: Colors.black.withValues(alpha: 0.3),
            child: const Center(
              child: SizedBox(
                width: 60,
                height: 60,
                child: LoadingSkeleton(
                  width: 60,
                  height: 60,
                  borderRadius: 30,
                  baseColor: Colors.white,
                  highlightColor: Colors.grey,
                ),
              ),
            ),
          ),
      ],
    );
  }
}
