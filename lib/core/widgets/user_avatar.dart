import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import 'image_loading_placeholder.dart';

/// A circular avatar: the person's real profile photo if they have one,
/// otherwise the first letter of their name on a solid background — used
/// anywhere a user's identity shows up (community posts today; comments and
/// chat can adopt the same widget later).
class UserAvatar extends StatelessWidget {
  const UserAvatar({
    super.key,
    required this.name,
    this.imageUrl,
    this.radius = 20,
  });

  final String name;
  final String? imageUrl;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final url = imageUrl;
    return CircleAvatar(
      radius: radius,
      backgroundColor: AppColors.primary,
      child: ClipOval(
        child: url != null
            ? CachedNetworkImage(
                imageUrl: url,
                width: radius * 2,
                height: radius * 2,
                fit: BoxFit.cover,
                placeholder: (context, url) =>
                    ImageLoadingPlaceholder(background: AppColors.primary),
                errorWidget: (context, url, error) => _initial(),
              )
            : _initial(),
      ),
    );
  }

  Widget _initial() {
    return Text(
      name.isNotEmpty ? name[0].toUpperCase() : '?',
      style: AppTheme.fredoka(color: Colors.white, fontSize: radius * 0.75),
    );
  }
}
