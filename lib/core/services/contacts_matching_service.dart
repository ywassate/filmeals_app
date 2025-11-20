import 'package:flutter_contacts/flutter_contacts.dart';

/// Service de matching entre noms Bluetooth et contacts téléphone
///
/// ALGORITHME DE MATCHING (4 règles avec système de scoring):
/// 1. Match EXACT (score 100): "sarah" == "sarah" → retour immédiat
/// 2. Bluetooth CONTIENT contact (score 80+): "AirPods de Sarah" contient "Sarah"
/// 3. Contact CONTIENT bluetooth (score 70+): "Sarah Martin" contient "Sarah"
/// 4. Match prénom/nom (score 60+): "sarah" trouvé dans "Sarah Martin" (word boundary)
///
/// Le meilleur score >= 60 gagne. Les noms sont normalisés (minuscules, sans accents).
class ContactsMatchingService {
  static final ContactsMatchingService instance = ContactsMatchingService._init();

  ContactsMatchingService._init();

  // Cache des contacts téléphone (évite de recharger à chaque scan)
  List<Contact>? _cachedContacts;

  /// Récupérer tous les contacts du téléphone
  Future<List<Contact>> getAllContacts() async {
    if (_cachedContacts != null) {
      return _cachedContacts!;
    }

    try {
      bool hasPermission = await FlutterContacts.requestPermission(readonly: true);

      if (!hasPermission) {
        return [];
      }

      List<Contact> contacts = await FlutterContacts.getContacts(
        withProperties: true,
      );

      _cachedContacts = contacts;
      return _cachedContacts!;
    } catch (e) {
      print('❌ Erreur chargement contacts: $e');
      return [];
    }
  }

  /// Matcher un nom Bluetooth avec un contact
  ///
  /// Parcourt TOUS les contacts et applique 4 règles de matching par ordre de priorité.
  /// Chaque règle a un score de base + bonus selon la longueur du nom.
  ///
  /// EXEMPLES DE MATCHING:
  /// - "Sarah" bluetooth vs "Sarah Martin" contact → RÈGLE 3 (score 75)
  /// - "AirPods de Sarah" bluetooth vs "Sarah" contact → RÈGLE 2 (score 85)
  /// - "Paul" bluetooth vs "Paul" contact → RÈGLE 1 (score 100, retour immédiat)
  /// - "redmi de marie" bluetooth vs "Marie Dupont" contact → RÈGLE 4 (score 65)
  ///
  /// SCORING: Plus le nom est long, meilleur le score (évite les faux positifs sur "Ali", "Max", etc.)
  /// Seuil minimum: 60 points. En dessous, pas de match.
  Future<String?> findMatchingContact(String bluetoothName) async {
    if (bluetoothName.isEmpty || bluetoothName == 'Appareil Inconnu') {
      return null;
    }

    final contacts = await getAllContacts();
    final normalizedBluetoothName = _normalize(bluetoothName);

    String? bestMatch;
    int bestMatchScore = 0;

    for (var contact in contacts) {
      final displayName = contact.displayName;
      if (displayName.isEmpty || displayName.length < 3) {
        continue; // Ignorer contacts avec noms trop courts
      }

      final normalizedContactName = _normalize(displayName);

      // === RÈGLE 1: Match EXACT (priorité maximale) ===
      // Ex: "sarah" == "sarah"
      if (normalizedContactName == normalizedBluetoothName) {
        return displayName; // Retour immédiat, pas besoin de continuer
      }

      // === RÈGLE 2: Bluetooth CONTIENT contact (score élevé) ===
      // Ex: "airpods de sarah" contient "sarah"
      // Min 5 caractères pour éviter faux positifs ("AirPods de M" ne match pas "M")
      if (normalizedContactName.length >= 5 &&
          normalizedBluetoothName.contains(normalizedContactName)) {
        int score = 80 + normalizedContactName.length; // Plus le nom est long, mieux c'est
        if (score > bestMatchScore) {
          bestMatchScore = score;
          bestMatch = displayName;
        }
        continue;
      }

      // === RÈGLE 3: Contact CONTIENT bluetooth ===
      // Ex: "sarah martin" contient "sarah"
      if (normalizedBluetoothName.length >= 5 &&
          normalizedContactName.contains(normalizedBluetoothName)) {
        int score = 70 + normalizedBluetoothName.length;
        if (score > bestMatchScore) {
          bestMatchScore = score;
          bestMatch = displayName;
        }
        continue;
      }

      // === RÈGLE 4: Match sur prénom OU nom (word boundary) ===
      // Ex: bluetooth "redmi de marie" match avec prénom "Marie" dans "Marie Dupont"
      // Min 4 caractères + word boundary (évite "sarah" dans "sarahmachine")
      final givenName = contact.name.first;
      final familyName = contact.name.last;

      if (givenName.isNotEmpty && givenName.length >= 4) {
        final normalizedGivenName = _normalize(givenName);

        // Vérifier que c'est un mot complet, pas une sous-chaîne
        if (_isWordBoundaryMatch(normalizedBluetoothName, normalizedGivenName)) {
          int score = 60 + normalizedGivenName.length;
          if (score > bestMatchScore) {
            bestMatchScore = score;
            bestMatch = displayName;
          }
        }
      }

      if (familyName.isNotEmpty && familyName.length >= 4) {
        final normalizedFamilyName = _normalize(familyName);

        if (_isWordBoundaryMatch(normalizedBluetoothName, normalizedFamilyName)) {
          int score = 60 + normalizedFamilyName.length;
          if (score > bestMatchScore) {
            bestMatchScore = score;
            bestMatch = displayName;
          }
        }
      }
    }

    // Retourner le meilleur match si score >= 60
    if (bestMatch != null && bestMatchScore >= 60) {
      return bestMatch;
    }

    return null; // Aucun match trouvé
  }

  /// Vérifier si un mot est trouvé comme MOT COMPLET (word boundary)
  ///
  /// PROBLÈME SANS WORD BOUNDARY:
  /// "sarah" serait trouvé dans "sarahmachine" → FAUX POSITIF!
  ///
  /// SOLUTION: Le mot doit être entouré d'espaces ou caractères spéciaux:
  /// ✅ "redmi de marie" contient "marie" (entouré d'espaces)
  /// ✅ "marie's phone" contient "marie" (suivi d'un ')
  /// ❌ "mariemachine" ne contient PAS "marie" (pas de séparateur)
  ///
  /// Regex: (début|espace|non-alphanum) + mot + (fin|espace|non-alphanum)
  bool _isWordBoundaryMatch(String text, String word) {
    final regex = RegExp(r'(^|\s|[^a-z0-9])' + RegExp.escape(word) + r'($|\s|[^a-z0-9])');
    return regex.hasMatch(text);
  }

  /// Normaliser un nom pour le matching (uniformisation)
  ///
  /// TRANSFORMATIONS:
  /// 1. Minuscules: "Sarah" → "sarah" (casse insensible)
  /// 2. Trim: "  Sarah  " → "sarah" (enlève espaces début/fin)
  /// 3. Espaces multiples: "Sarah   Martin" → "sarah martin"
  /// 4. Suppression accents: "José" → "jose", "François" → "francois"
  ///
  /// POURQUOI? Sans normalisation, "José" ne matcherait jamais avec "jose"!
  /// Les noms Bluetooth n'ont souvent pas d'accents ("jose's airpods").
  String _normalize(String text) {
    return text
        .toLowerCase()
        .trim()
        .replaceAll(RegExp(r'\s+'), ' ') // Espaces multiples → un seul espace
        .replaceAll('é', 'e')
        .replaceAll('è', 'e')
        .replaceAll('ê', 'e')
        .replaceAll('à', 'a')
        .replaceAll('â', 'a')
        .replaceAll('ô', 'o')
        .replaceAll('ù', 'u')
        .replaceAll('û', 'u')
        .replaceAll('ç', 'c')
        .replaceAll('î', 'i')
        .replaceAll('ï', 'i');
  }

  /// Rafraîchir le cache
  void clearCache() {
    _cachedContacts = null;
  }
}
