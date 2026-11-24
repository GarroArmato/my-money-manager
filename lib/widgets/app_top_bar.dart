import 'package:flutter/material.dart';
import '../utils/money_scope.dart';

class AppTopBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final IconData icon;
  final List<Widget>? actions;
  final Widget? leading;
  final double? leadingWidth;

  const AppTopBar({
    super.key,
    required this.title,
    required this.icon,
    this.actions,
    this.leading,
    this.leadingWidth,
  });

  @override
  Size get preferredSize => const Size.fromHeight(56);

  @override
  Widget build(BuildContext context) {
    final provider = MoneyScope.of(context);
    final primary = provider.primaryColor;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            primary,
            Color.lerp(primary, Colors.black, 0.28) ?? primary,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: leading,
        leadingWidth: leadingWidth,
        titleSpacing: 16,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, size: 18, color: Colors.white),
            ),
            const SizedBox(width: 10),
            Text(
              title.toUpperCase(),
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.1,
                color: Colors.white,
              ),
            ),
          ],
        ),
        actions: actions,
      ),
    );
  }
}
