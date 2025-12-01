/// Utilitaires de formatage de durée
class DurationFormatter {
  /// Formate une durée en minutes au format "Xh Ymin" ou "Ymin"
  static String formatMinutes(int minutes) {
    final hours = minutes ~/ 60;
    final mins = minutes % 60;

    if (hours == 0) {
      return '${mins}min';
    }

    if (mins == 0) {
      return '${hours}h';
    }

    return '${hours}h ${mins}min';
  }

  /// Formate une durée en secondes au format "HH:MM:SS"
  static String formatSeconds(int seconds) {
    final hours = seconds ~/ 3600;
    final minutes = (seconds % 3600) ~/ 60;
    final secs = seconds % 60;

    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
    }

    return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  /// Formate une Duration au format "Xh Ymin"
  static String formatDuration(Duration duration) {
    return formatMinutes(duration.inMinutes);
  }
}
