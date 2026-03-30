import 'package:flutter/material.dart';

class AppLogo extends StatelessWidget {
  final double size;
  final bool showText;

  const AppLogo({super.key, this.size = 120, this.showText = true});

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).colorScheme.primary;
    
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: primaryColor.withOpacity(0.2),
                blurRadius: 20,
                spreadRadius: 5,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Padding(
            padding: EdgeInsets.all(size * 0.05), // Reduced padding for better image fit
            child: Image.asset(
              'lib/raw/icon.png',
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) => Icon(
                Icons.school,
                size: size * 0.6,
                color: primaryColor,
              ),
            ),
          ),
        ),
        if (showText) ...[
          const SizedBox(height: 16),
          Text(
            "CMS",
            style: TextStyle(
              fontSize: size * 0.25,
              fontWeight: FontWeight.w800,
              color: primaryColor,
              letterSpacing: 2,
            ),
          ),
          Text(
            "College Management System",
            style: TextStyle(
              fontSize: size * 0.08,
              fontWeight: FontWeight.w500,
              color: Colors.grey[600],
              letterSpacing: 1.2,
            ),
          ),
        ]
      ],
    );
  }
}
