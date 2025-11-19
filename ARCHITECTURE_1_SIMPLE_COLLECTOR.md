# 📱 Architecture 1 : Collecteur Simple pour MCP

## Vue d'ensemble

FitMeals utilise une **architecture simple de collecte de données** pour le serveur MCP.

### Principe
- ✅ **L'app = Collecteur de données brutes**
- ✅ **Calculs de base locaux** (BMI, calories)
- ✅ **PAS d'IA dans l'app**
- ✅ **Le serveur MCP = Analyse IA**

---

## 🏗️ Architecture

```
┌─────────────────────────────────────┐
│         FitMeals App                │
│  (Collecteur de données)            │
├─────────────────────────────────────┤
│                                     │
│  📊 Calculs Locaux:                 │
│  - BMI (formule mathématique)       │
│  - Calories (Mifflin-St Jeor)       │
│  - Totaux journaliers               │
│                                     │
│  📝 Entrée Manuelle:                │
│  - Repas (calories, macros)         │
│  - Nom, description                 │
│  - Type de repas                    │
│                                     │
│  💾 Stockage Local (Hive):          │
│  - UserModel                        │
│  - MealModel                        │
│                                     │
└─────────────────────────────────────┘
              ↓
         📤 Export
              ↓
┌─────────────────────────────────────┐
│      Serveur MCP                    │
│  (Analyse IA)                       │
├─────────────────────────────────────┤
│                                     │
│  🤖 Intelligence Artificielle:      │
│  - Analyse des patterns             │
│  - Recommandations                  │
│  - Prédictions                      │
│  - Comparaisons utilisateurs        │
│  - ML / Deep Learning               │
│                                     │
└─────────────────────────────────────┘
```

---

## 📊 Données Collectées

### 1. Profil Utilisateur

```dart
UserModel {
  id: String,
  name: String,
  email: String,
  age: int,
  gender: String,
  height: int,  // cm
  weight: int,  // kg
  goal: GoalType,  // maintainWeight, loseWeight, gainWeight
  targetWeight: int?,
  activityLevel: ActivityLevel,
  dailyCalorieGoal: int,  // Calculé avec Mifflin-St Jeor
  createdAt: DateTime,
  updatedAt: DateTime,
}
```

### 2. Repas (Entrée Manuelle)

```dart
MealModel {
  id: String,
  userId: String,
  name: String,
  description: String,
  calories: int,
  protein: double,  // grammes
  carbs: double,    // grammes
  fat: double,      // grammes
  mealType: MealType,  // breakfast, lunch, dinner, snack
  date: DateTime,
  createdAt: DateTime,
  updatedAt: DateTime,
}
```

---

## 🧮 Calculs Locaux

### BMI (Body Mass Index)

```dart
double calculateBMI(int weight, int height) {
  if (height <= 0) return 0;
  double heightInMeters = height / 100;
  return weight / (heightInMeters * heightInMeters);
}
```

### Catégorie BMI

```dart
String determineBMICategory(double bmi) {
  if (bmi < 18.5) return 'Underweight';
  if (bmi >= 18.5 && bmi < 24.9) return 'Normal weight';
  if (bmi >= 25 && bmi < 29.9) return 'Overweight';
  return 'Obesity';
}
```

### Calories Journalières (Formule Mifflin-St Jeor)

```dart
int suggestDailyCalorie(
  int age,
  String gender,
  int weight,
  int height,
  GoalType goal,
  ActivityLevel activityLevel,
) {
  // Calcul du BMR (Basal Metabolic Rate)
  double bmr;
  if (gender.toLowerCase() == 'male') {
    bmr = 10 * weight + 6.25 * height - 5 * age + 5;
  } else {
    bmr = 10 * weight + 6.25 * height - 5 * age - 161;
  }

  // Multiplier par niveau d'activité
  double activityMultiplier = {
    sedentary: 1.2,
    lightlyActive: 1.375,
    moderatelyActive: 1.55,
    veryActive: 1.725,
    extraActive: 1.9,
  }[activityLevel];

  double dailyCalories = bmr * activityMultiplier;

  // Ajuster selon l'objectif
  if (goal == GoalType.loseWeight) dailyCalories -= 500;
  if (goal == GoalType.gainWeight) dailyCalories += 500;

  return dailyCalories.round();
}
```

---

## 📤 Export vers MCP

### Format JSON

```json
{
  "schema_version": "1.0",
  "export_metadata": {
    "timestamp": "2025-01-07T15:30:00Z",
    "app_version": "1.0.0",
    "platform": "android",
    "data_types": ["user_profile", "meals", "daily_aggregates", "behavioral_insights"]
  },

  "user_profile": {
    "anonymous_id": "a3f5e7c9",
    "demographics": {
      "age": 25,
      "gender": "male",
      "height_cm": 180,
      "weight_kg": 75
    },
    "goals": {
      "type": "maintainWeight",
      "target_weight_kg": null,
      "activity_level": "moderatelyActive"
    },
    "calculated_metrics": {
      "bmi": 23.1,
      "bmi_category": "Normal weight",
      "daily_calorie_goal": 2500
    },
    "account_created_at": "2025-01-01T10:00:00Z",
    "last_updated_at": "2025-01-07T10:00:00Z"
  },

  "meals": [
    {
      "meal_id": "b7d9e1a2",
      "timestamp": "2025-01-07T08:00:00Z",
      "type": "breakfast",
      "name": "Oeufs et lait",
      "description": "3 oeufs et 100ml lait",
      "nutrition": {
        "calories": 276,
        "protein_g": 22.3,
        "carbs_g": 5.9,
        "fat_g": 17.6
      },
      "metadata": {
        "created_at": "2025-01-07T08:15:00Z",
        "updated_at": "2025-01-07T08:15:00Z"
      }
    }
  ],

  "daily_aggregates": [
    {
      "date": "2025-01-07",
      "totals": {
        "calories": 2450,
        "protein_g": 145.5,
        "carbs_g": 275.0,
        "fat_g": 78.5
      },
      "goals_achievement": {
        "calories_percent": 98
      },
      "meals_count": 4,
      "meal_types": ["breakfast", "lunch", "snack", "dinner"]
    }
  ],

  "behavioral_insights": {
    "meal_timing_patterns": [
      {"meal_type": "breakfast", "average_hour": 8, "frequency": 7},
      {"meal_type": "lunch", "average_hour": 13, "frequency": 7},
      {"meal_type": "dinner", "average_hour": 19, "frequency": 7}
    ],
    "food_preferences": [
      {"meal_type": "breakfast", "frequency": 28, "percentage": 35}
    ],
    "goal_adherence_score": 0.92,
    "consistency_score": 0.95,
    "total_days_tracked": 30,
    "days_compliant": 28
  },

  "progress_tracking": {
    "tracking_started": "2025-01-01T00:00:00Z",
    "days_tracked": 30,
    "total_meals_logged": 120,
    "average_meals_per_day": 4.0,
    "status": "excellent"
  }
}
```

---

## 🔄 Flux de Données

### 1. Onboarding (Création du profil)

```
User remplit le formulaire
    ↓
Données: âge, poids, taille, objectif, activité
    ↓
Calcul LOCAL:
  - BMI = calculateBMI(weight, height)
  - Catégorie BMI = determineBMICategory(bmi)
  - Calories = suggestDailyCalorie(...)
    ↓
Création UserModel
    ↓
Sauvegarde Hive (local)
    ↓
[Prêt pour export MCP]
```

### 2. Ajout d'un repas (Entrée manuelle)

```
User entre manuellement:
  - Nom: "Petit-déjeuner protéiné"
  - Description: "3 oeufs et 100ml lait"
  - Calories: 276
  - Protéines: 22.3g
  - Glucides: 5.9g
  - Lipides: 17.6g
  - Type: breakfast
    ↓
Création MealModel
    ↓
Sauvegarde Hive (local)
    ↓
Calcul totaux du jour (local)
    ↓
Affichage dans l'app
    ↓
[Prêt pour export MCP]
```

### 3. Export vers MCP

```
User clique "Exporter vers MCP"
    ↓
MCPExportService collecte:
  - UserModel (anonymisé)
  - Tous les MealModel
  - Calcul agrégats quotidiens
  - Calcul patterns comportementaux
  - Calcul progression
    ↓
Génération JSON formaté
    ↓
Sauvegarde fichier:
  mcp_export_1704639000000.json
    ↓
[Fichier prêt à envoyer au serveur MCP]
```

---

## 💾 Stockage Local (Hive)

```
📦 Hive Boxes:
├── users_box
│   └── UserModel (profil utilisateur)
└── meals_box
    └── MealModel[] (historique des repas)
```

**Taille estimée** :
- 1 user: ~1 KB
- 1 meal: ~500 bytes
- 1 an (1500 meals): ~750 KB
- **Total: ~1 MB pour 1 an**

---

## 🔒 Confidentialité & Anonymisation

### Données PAS exportées

- ❌ Nom complet
- ❌ Email
- ❌ Photo de profil
- ❌ Identifiants directs

### Données exportées (anonymisées)

- ✅ ID anonyme (hash)
- ✅ Âge
- ✅ Sexe
- ✅ Métriques physiques
- ✅ Données nutritionnelles

### Méthode d'anonymisation

```dart
String _generateAnonymousId(String originalId) {
  return originalId.hashCode.toRadixString(16).padLeft(16, '0');
  // "user-12345" → "a3f5e7c9"
}
```

---

## 🎯 Utilisation des données par le MCP

### Cas d'usage 1 : Analyse de patterns

Le serveur MCP peut analyser :
- Patterns de repas réussis
- Heures optimales de repas
- Distributions de macros efficaces
- Corrélations activité/nutrition

### Cas d'usage 2 : Recommandations personnalisées

Basé sur les données collectées :
- Suggestions de repas
- Ajustements d'objectifs
- Rappels personnalisés
- Coaching nutritionnel

### Cas d'usage 3 : Machine Learning

Entraînement de modèles ML pour :
- Prédiction de succès
- Détection de patterns négatifs
- Optimisation des plans nutritionnels
- Segmentation utilisateurs

---

## 📝 Fichiers Importants

### Services

- `lib/core/services/mcp_export_service.dart` - Export des données vers MCP
- `lib/data/models/user_model.dart` - Calculs BMI et calories
- `lib/data/repository/user_repository.dart` - Gestion utilisateurs
- `lib/data/repository/meal_repository.dart` - Gestion repas

### Écrans

- `lib/presentation/screens/onboarding/onboarding_screen.dart` - Création profil
- `lib/presentation/screens/meals/add_custom_meal_screen_v2.dart` - Ajout repas manuel
- `lib/presentation/screens/home/tabs/home_tab.dart` - Dashboard
- `lib/presentation/screens/home/tabs/profile_tab.dart` - Profil utilisateur

---

## ✅ Avantages de l'Architecture 1

1. **Simplicité** :
   - Pas de gestion d'API OpenAI dans l'app
   - Pas de cache complexe
   - Code plus simple et maintenable

2. **Performance** :
   - Calculs locaux instantanés
   - Pas de latence réseau pour les calculs de base
   - App fonctionne 100% hors-ligne

3. **Coûts** :
   - Zéro coût API dans l'app
   - Tous les coûts IA centralisés sur le serveur MCP
   - Meilleur contrôle des dépenses

4. **Flexibilité** :
   - Le serveur MCP peut changer de modèle IA sans toucher l'app
   - Ajout de nouvelles analyses sans mise à jour app
   - Tests A/B côté serveur

5. **Confidentialité** :
   - Données stockées localement sur l'appareil
   - Export anonymisé uniquement
   - Contrôle utilisateur sur l'export

---

## 🚀 Prochaines Étapes

### Phase 1 : Collecte ✅ (Actuelle)
- [x] Calculs locaux (BMI, calories)
- [x] Entrée manuelle repas
- [x] Stockage Hive
- [x] MCPExportService

### Phase 2 : Export
- [ ] Bouton "Exporter vers MCP" dans Settings
- [ ] Affichage du résumé avant export
- [ ] Sauvegarde du fichier JSON
- [ ] Partage du fichier (email, cloud, etc.)

### Phase 3 : Serveur MCP
- [ ] API endpoint pour recevoir les exports
- [ ] Base de données MCP
- [ ] Analyse IA des données
- [ ] Dashboard MCP

### Phase 4 : Feedback
- [ ] Récupération des recommandations MCP
- [ ] Affichage dans l'app
- [ ] Notifications personnalisées
- [ ] Coaching adaptatif

---

## 📚 Documentation Technique

### MCPExportService

```dart
class MCPExportService {
  final UserRepository userRepository;
  final MealRepository mealRepository;

  // Exporte toutes les données
  Future<Map<String, dynamic>> exportUserData() async { ... }

  // Sauvegarde dans un fichier JSON
  Future<File> saveExportToFile() async { ... }

  // Résumé rapide pour l'UI
  Future<Map<String, dynamic>> getExportSummary() async { ... }
}
```

### Utilisation

```dart
// Dans les Settings
final exportService = MCPExportService(
  userRepository: userRepository,
  mealRepository: mealRepository,
);

// Obtenir le résumé
final summary = await exportService.getExportSummary();
print('Total repas: ${summary['total_meals']}');
print('Jours suivis: ${summary['days_tracked']}');

// Exporter vers fichier
final file = await exportService.saveExportToFile();
print('Export sauvegardé: ${file.path}');
```

---

## 🎯 Conclusion

L'Architecture 1 transforme FitMeals en un **collecteur de données intelligent** :

- 📊 **Collecte précise** : Données brutes de qualité
- 🧮 **Calculs fiables** : Formules mathématiques éprouvées
- 💾 **Stockage local** : Respect de la vie privée
- 📤 **Export structuré** : Format JSON standardisé
- 🤖 **Analyse MCP** : Intelligence artificielle centralisée

Cette architecture garantit une **séparation claire des responsabilités** :
- **L'app** = Interface et collecte
- **Le MCP** = Intelligence et analyse
