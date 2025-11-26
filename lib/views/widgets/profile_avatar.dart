import 'package:flutter/material.dart';
import '../../models/user/user_profile.dart';

class ProfileAvatar extends StatefulWidget {
  final UserProfile profile;
  final double size;
  final bool showBorder;

  const ProfileAvatar({
    super.key,
    required this.profile,
    this.size = 100,
    this.showBorder = false,
  });

  @override
  State<ProfileAvatar> createState() => _ProfileAvatarState();
}

class _ProfileAvatarState extends State<ProfileAvatar> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: widget.size,
        height: widget.size,
        decoration: BoxDecoration(
          color: _parseColor(widget.profile.avatarColor),
          borderRadius: BorderRadius.circular(8),
          border: widget.showBorder || _isHovered
              ? Border.all(color: Colors.white, width: 3)
              : null,
        ),
        child: Center(
          child: widget.profile.avatarIcon != null
              ? Text(
                  widget.profile.avatarIcon!,
                  style: TextStyle(
                    fontSize: widget.size * 0.5,
                  ),
                )
              : Icon(
                  Icons.person,
                  size: widget.size * 0.6,
                  color: Colors.white,
                ),
        ),
      ),
    );
  }

  Color _parseColor(String colorString) {
    try {
      return Color(int.parse(colorString.replaceFirst('#', '0xFF')));
    } catch (e) {
      return const Color(0xFFE50914);
    }
  }
}
