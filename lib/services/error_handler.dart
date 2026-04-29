// ignore_for_file: unnecessary_import

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';
import 'dart:async';

class AppErrorHandler {
  static String getErrorMessage(dynamic error) {
    String message = '';
    String solution = '';

    if (error is FirebaseAuthException) {
      switch (error.code) {
        case 'user-not-found':
          message = 'Account not found.';
          solution = 'Double-check your email for spelling mistakes or create a new account if you haven\'t registered yet.';
          break;
        case 'wrong-password':
          message = 'Incorrect password.';
          solution = 'Check if Caps Lock is on or use the "Forgot Password" option to reset it.';
          break;
        case 'email-already-in-use':
          message = 'Email is already taken.';
          solution = 'Try logging in with this email or use a different email address to sign up.';
          break;
        case 'network-request-failed':
          message = 'Network error.';
          solution = 'Check your internet connection (Wi-Fi or Mobile Data) and try again.';
          break;
        case 'invalid-email':
          message = 'The email address is not valid.';
          solution = 'Make sure the email is in the correct format, like: name@example.com.';
          break;
        case 'user-disabled':
          message = 'This account has been disabled.';
          solution = 'Please contact the administration to understand why and re-activate it.';
          break;
        case 'too-many-requests':
          message = 'Too many attempts in a short time.';
          solution = 'Wait for about 5 to 10 minutes and then try again.';
          break;
        default:
          message = error.message ?? 'Authentication failed.';
          solution = 'Please try again later or check your credentials.';
      }
    } else if (error is FirebaseException) {
      switch (error.code) {
        case 'permission-denied':
          message = 'Access Denied.';
          solution = 'You don\'t have permission to perform this action. Contact the admin if you think this is a mistake.';
          break;
        case 'unavailable':
          message = 'Service temporarily down.';
          solution = 'Our servers are busy or undergoing maintenance. Please try again in a few minutes.';
          break;
        case 'not-found':
          message = 'Data not found.';
          solution = 'The item you are looking for might have been deleted. Try refreshing your list.';
          break;
        case 'deadline-exceeded':
          message = 'Request timed out.';
          solution = 'Your internet might be slow. Move to a better coverage area and try again.';
          break;
        default:
          message = 'Database error occurred.';
          solution = 'Check your connection and try the operation again.';
      }
    } else if (error is SocketException) {
      message = 'No Internet connection.';
      solution = 'Please turn on your Wi-Fi or mobile data and make sure you have an active plan.';
    } else if (error is TimeoutException) {
      message = 'The request took too long.';
      solution = 'Your internet might be slow or unstable. Try again when you have better signal.';
    } else if (error is HttpException) {
      message = 'Resource not found.';
      solution = 'The server could not find the requested item. Try refreshing.';
    } else if (error is FormatException) {
      message = 'Data format error.';
      solution = 'Received unexpected data from the server. Try updating the app.';
    } else if (error is String) {
      return error;
    } else {
      message = 'An unexpected error occurred.';
      solution = 'Try closing and reopening the app. If the issue persists, contact support.';
    }

    return "Error: $message\n\n💡 How to fix: $solution";
  }

  static void showError(BuildContext context, dynamic error) async {
    final message = getErrorMessage(error);
    
    try {
      final prefs = await SharedPreferences.getInstance();
      final ignoredErrors = prefs.getStringList('ignored_errors') ?? [];
      if (ignoredErrors.contains(message)) return;
    } catch (_) {}

    if (!context.mounted) return;
    _showNotification(context, message, isError: true);
  }

  static void showSuccess(BuildContext context, String message) {
    _showNotification(context, message, isError: false);
  }

  static void _showNotification(BuildContext context, String message, {required bool isError}) {
    final overlay = Overlay.of(context);
    OverlayEntry? overlayEntry;

    overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        top: MediaQuery.of(context).padding.top + 10,
        left: 10,
        right: 10,
        child: Material(
          color: Colors.transparent,
          child: Dismissible(
            key: UniqueKey(),
            direction: DismissDirection.horizontal,
            onDismissed: (direction) {
              overlayEntry?.remove();
              overlayEntry = null;
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isError ? Colors.redAccent.withOpacity(0.95) : Colors.green.withOpacity(0.95),
                borderRadius: BorderRadius.circular(12),
                boxShadow: const [
                  BoxShadow(color: Colors.black26, blurRadius: 10, offset: Offset(0, 4)),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        isError ? Icons.error_outline : Icons.check_circle_outline,
                        color: Colors.white,
                        size: 28,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          message,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.white70, size: 20),
                        onPressed: () {
                          overlayEntry?.remove();
                          overlayEntry = null;
                        },
                      ),
                    ],
                  ),
                  if (isError) ...[
                    const Divider(color: Colors.white24, height: 20),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () async {
                          final prefs = await SharedPreferences.getInstance();
                          final list = prefs.getStringList('ignored_errors') ?? [];
                          if (!list.contains(message)) {
                            list.add(message);
                            await prefs.setStringList('ignored_errors', list);
                          }
                          overlayEntry?.remove();
                          overlayEntry = null;
                        },
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.zero,
                          minimumSize: const Size(50, 30),
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: const Text(
                          "Don't display again",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );

    overlay.insert(overlayEntry!);

    // Auto-remove after 5 seconds
    Future.delayed(const Duration(seconds: 5), () {
      if (overlayEntry != null) {
        try {
          overlayEntry?.remove();
          overlayEntry = null;
        } catch (_) {}
      }
    });
  }

  static Widget buildErrorWidget(dynamic error, VoidCallback onRetry) {
    final message = getErrorMessage(error);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.cloud_off, size: 80, color: Colors.redAccent),
            const SizedBox(height: 16),
            Text(
              "Something Went Wrong",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey[800]),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text("Try Again"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  static Widget buildLoadingWidget() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text("Loading data...", style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }
}

class LoadingOverlay {
  static void show(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: Card(
          child: Padding(
            padding: EdgeInsets.all(20.0),
            child: CircularProgressIndicator(),
          ),
        ),
      ),
    );
  }

  static void hide(BuildContext context) {
    if (Navigator.canPop(context)) {
      Navigator.of(context).pop();
    }
  }
}
