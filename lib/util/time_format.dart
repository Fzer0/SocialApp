String formatPostTime(dynamic timestamp) {
  if (timestamp == null) return 'Ahora';

  DateTime? dateTime;

  try {
    if (timestamp is DateTime) {
      dateTime = timestamp;
    } else if (timestamp.toString().contains('Timestamp')) {
      dateTime = timestamp.toDate();
    }
  } catch (_) {
    return 'Ahora';
  }

  if (dateTime == null) return 'Ahora';

  final Duration difference = DateTime.now().difference(dateTime);

  if (difference.inSeconds < 60) {
    return 'Hace ${difference.inSeconds}s';
  }

  if (difference.inMinutes < 60) {
    return 'Hace ${difference.inMinutes} min';
  }

  if (difference.inHours < 24) {
    return 'Hace ${difference.inHours} h';
  }

  if (difference.inDays < 7) {
    return 'Hace ${difference.inDays} d';
  }

  if (difference.inDays < 30) {
    return 'Hace ${(difference.inDays / 7).floor()} sem';
  }

  if (difference.inDays < 365) {
    return 'Hace ${(difference.inDays / 30).floor()} mes';
  }

  return 'Hace ${(difference.inDays / 365).floor()} año';
}