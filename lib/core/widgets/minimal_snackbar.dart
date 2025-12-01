import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:filmeals_app/core/theme/app_theme.dart';

/// Widget pour afficher des SnackBars avec un style minimaliste amélioré
class MinimalSnackBar {
  /// Affiche un SnackBar de succès avec style minimaliste
  static void showSuccess(
    BuildContext context, {
    required String title,
    required String message,
    Duration duration = const Duration(seconds: 3),
  }) {
    _show(
      context,
      icon: Icons.check_circle,
      title: title,
      message: message,
      duration: duration,
    );
  }

  /// Affiche un SnackBar d'erreur avec style minimaliste
  static void showError(
    BuildContext context, {
    required String title,
    required String message,
    Duration duration = const Duration(seconds: 4),
  }) {
    _show(
      context,
      icon: Icons.error,
      title: title,
      message: message,
      duration: duration,
    );
  }

  /// Affiche un SnackBar d'information avec style minimaliste
  static void showInfo(
    BuildContext context, {
    required String title,
    required String message,
    Duration duration = const Duration(seconds: 3),
  }) {
    _show(
      context,
      icon: Icons.info,
      title: title,
      message: message,
      duration: duration,
    );
  }

  /// Affiche un SnackBar de warning avec style minimaliste
  static void showWarning(
    BuildContext context, {
    required String title,
    required String message,
    Duration duration = const Duration(seconds: 3),
  }) {
    _show(
      context,
      icon: Icons.warning,
      title: title,
      message: message,
      duration: duration,
    );
  }

  static void _show(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String message,
    required Duration duration,
  }) {
    // Light haptic feedback
    HapticFeedback.lightImpact();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.15),
                blurRadius: 30,
                offset: const Offset(0, 8),
                spreadRadius: -4,
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppTheme.surfaceColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: AppTheme.textPrimaryColor,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimaryColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      message,
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppTheme.textSecondaryColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.transparent,
        elevation: 0,
        duration: duration,
        margin: const EdgeInsets.all(20),
        dismissDirection: DismissDirection.horizontal,
      ),
    );
  }
}

/// Dialog de confirmation avec style minimaliste amélioré
class MinimalConfirmDialog extends StatefulWidget {
  final String title;
  final String message;
  final IconData icon;
  final VoidCallback onConfirm;
  final String confirmText;
  final String cancelText;

  const MinimalConfirmDialog({
    super.key,
    required this.title,
    required this.message,
    this.icon = Icons.help_outline,
    required this.onConfirm,
    this.confirmText = 'Confirmer',
    this.cancelText = 'Annuler',
  });

  @override
  State<MinimalConfirmDialog> createState() => _MinimalConfirmDialogState();

  /// Affiche le dialog et retourne true si confirmé, false sinon
  static Future<bool> show({
    required BuildContext context,
    required String title,
    required String message,
    IconData icon = Icons.help_outline,
    required VoidCallback onConfirm,
    String confirmText = 'Confirmer',
    String cancelText = 'Annuler',
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => MinimalConfirmDialog(
        title: title,
        message: message,
        icon: icon,
        onConfirm: onConfirm,
        confirmText: confirmText,
        cancelText: cancelText,
      ),
    );
    return result ?? false;
  }
}

class _MinimalConfirmDialogState extends State<MinimalConfirmDialog>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );

    _scaleAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    );

    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scaleAnimation,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: Dialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Icône
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    widget.icon,
                    color: AppTheme.textPrimaryColor,
                    size: 24,
                  ),
                ),
                const SizedBox(height: 20),
                // Titre
                Text(
                  widget.title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimaryColor,
                  ),
                ),
                const SizedBox(height: 12),
                // Message
                Text(
                  widget.message,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppTheme.textSecondaryColor,
                  ),
                ),
                const SizedBox(height: 24),
                // Boutons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          HapticFeedback.selectionClick();
                          Navigator.of(context).pop(false);
                        },
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          side: BorderSide(color: Colors.grey[300]!),
                        ),
                        child: Text(
                          widget.cancelText,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey[600],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          HapticFeedback.mediumImpact();
                          Navigator.of(context).pop(true);
                          widget.onConfirm();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.textPrimaryColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        child: Text(
                          widget.confirmText,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Loading dialog avec style minimaliste et animation fluide
class MinimalLoadingDialog extends StatelessWidget {
  final String title;
  final String? message;

  const MinimalLoadingDialog({
    super.key,
    this.title = 'Chargement...',
    this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Loading indicator
            const SizedBox(
              width: 48,
              height: 48,
              child: CircularProgressIndicator(
                strokeWidth: 3,
                valueColor: AlwaysStoppedAnimation<Color>(
                  AppTheme.textPrimaryColor,
                ),
              ),
            ),
            const SizedBox(height: 24),
            // Titre
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimaryColor,
              ),
            ),
            if (message != null) ...[
              const SizedBox(height: 12),
              // Message optionnel
              Text(
                message!,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 14,
                  color: AppTheme.textSecondaryColor,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// Affiche le loading dialog et exécute une tâche async
  static Future<T?> show<T>({
    required BuildContext context,
    required Future<T> Function() task,
    String title = 'Chargement...',
    String? message,
  }) async {
    // Afficher le dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => MinimalLoadingDialog(
        title: title,
        message: message,
      ),
    );

    try {
      // Exécuter la tâche
      final result = await task();

      // Fermer le dialog
      if (context.mounted) {
        Navigator.of(context).pop();
      }

      return result;
    } catch (e) {
      // Fermer le dialog en cas d'erreur
      if (context.mounted) {
        Navigator.of(context).pop();
      }
      rethrow;
    }
  }
}
