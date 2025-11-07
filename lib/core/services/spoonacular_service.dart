import 'dart:convert';
import 'package:http/http.dart' as http;

/// Service pour interagir avec l'API Spoonacular
class SpoonacularService {
  static const String _baseUrl = 'https://api.spoonacular.com';
  static const String _apiKey = '2e3642e419ea4ffd8b9f8095ae3c82f2';

  /// Rechercher des recettes avec informations nutritionnelles
  Future<List<RecipeSearchResult>> searchRecipes({
    required String query,
    int number = 10,
    int? maxCalories,
    int? minProtein,
    int? maxCarbs,
    int? maxFat,
  }) async {
    try {
      final queryParams = {
        'apiKey': _apiKey,
        'query': query,
        'number': number.toString(),
        'addRecipeNutrition': 'true',
        'fillIngredients': 'true',
      };

      // Chaque ligne vérifie si un paramètre optionnel (maxCalories, minProtein, maxCarbs, maxFat) a été fourni (différent de null) lors de l’appel de la fonction.
      // Si oui, la valeur est ajoutée à la map queryParams (qui sert à construire l’URL de la requête API) sous forme de chaîne de caractères.
      // Cela permet de ne transmettre à l’API que les filtres nutritionnels réellement renseignés par l’utilisateur.

      if (maxCalories != null) {
        queryParams['maxCalories'] = maxCalories.toString();
      }
      if (minProtein != null) queryParams['minProtein'] = minProtein.toString();
      if (maxCarbs != null) queryParams['maxCarbs'] = maxCarbs.toString();
      if (maxFat != null) queryParams['maxFat'] = maxFat.toString();

      final uri = Uri.parse(
        '$_baseUrl/recipes/complexSearch',
      ).replace(queryParameters: queryParams);

      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final results = data['results'] as List;
        return results
            .map((json) => RecipeSearchResult.fromJson(json))
            .toList();
      } else {
        throw Exception('Failed to search recipes: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error searching recipes: $e');
    }
  }

  /// Obtenir les informations détaillées d'une recette
  Future<RecipeDetails> getRecipeDetails(int recipeId) async {
    try {
      final uri = Uri.parse('$_baseUrl/recipes/$recipeId/information').replace(
        queryParameters: {'apiKey': _apiKey, 'includeNutrition': 'true'},
      );

      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return RecipeDetails.fromJson(data);
      } else {
        throw Exception('Failed to get recipe details: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error getting recipe details: $e');
    }
  }

  /// Rechercher des recettes par nutriments
  Future<List<RecipeSearchResult>> searchRecipesByNutrients({
    int? minCalories,
    int? maxCalories,
    int? minProtein,
    int? maxProtein,
    int? minCarbs,
    int? maxCarbs,
    int? minFat,
    int? maxFat,
    int number = 10,
  }) async {
    try {
      final queryParams = {'apiKey': _apiKey, 'number': number.toString()};

      if (minCalories != null)
        queryParams['minCalories'] = minCalories.toString();
      if (maxCalories != null)
        queryParams['maxCalories'] = maxCalories.toString();
      if (minProtein != null) queryParams['minProtein'] = minProtein.toString();
      if (maxProtein != null) queryParams['maxProtein'] = maxProtein.toString();
      if (minCarbs != null) queryParams['minCarbs'] = minCarbs.toString();
      if (maxCarbs != null) queryParams['maxCarbs'] = maxCarbs.toString();
      if (minFat != null) queryParams['minFat'] = minFat.toString();
      if (maxFat != null) queryParams['maxFat'] = maxFat.toString();

      final uri = Uri.parse(
        '$_baseUrl/recipes/findByNutrients',
      ).replace(queryParameters: queryParams);

      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final results = json.decode(response.body) as List;
        return results
            .map((json) => RecipeSearchResult.fromJson(json))
            .toList();
      } else {
        throw Exception(
          'Failed to search by nutrients: ${response.statusCode}',
        );
      }
    } catch (e) {
      throw Exception('Error searching by nutrients: $e');
    }
  }

  /// Obtenir des suggestions d'autocomplétion
  Future<List<String>> autocomplete(String query, {int number = 5}) async {
    try {
      final uri = Uri.parse('$_baseUrl/recipes/autocomplete').replace(
        queryParameters: {
          'apiKey': _apiKey,
          'query': query,
          'number': number.toString(),
        },
      );

      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final results = json.decode(response.body) as List;
        return results.map((item) => item['title'] as String).toList();
      } else {
        return [];
      }
    } catch (e) {
      return [];
    }
  }

  /// Rechercher des ingrédients
  Future<List<IngredientSearchResult>> searchIngredients({
    required String query,
    int number = 10,
  }) async {
    try {
      final uri = Uri.parse('$_baseUrl/food/ingredients/search').replace(
        queryParameters: {
          'apiKey': _apiKey,
          'query': query,
          'number': number.toString(),
          'metaInformation': 'true',
        },
      );

      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final results = data['results'] as List;
        return results
            .map((json) => IngredientSearchResult.fromJson(json))
            .toList();
      } else {
        throw Exception('Failed to search ingredients: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error searching ingredients: $e');
    }
  }

  /// Obtenir les informations nutritionnelles d'un ingrédient avec quantité
  Future<IngredientNutrition> getIngredientNutrition({
    required int ingredientId,
    required double amount,
    required String unit,
  }) async {
    try {
      final uri =
          Uri.parse(
            '$_baseUrl/food/ingredients/$ingredientId/information',
          ).replace(
            queryParameters: {
              'apiKey': _apiKey,
              'amount': amount.toString(),
              'unit': unit,
            },
          );

      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return IngredientNutrition.fromJson(data);
      } else {
        throw Exception(
          'Failed to get ingredient nutrition: ${response.statusCode}',
        );
      }
    } catch (e) {
      throw Exception('Error getting ingredient nutrition: $e');
    }
  }

  /// Autocomplétion pour les ingrédients
  Future<List<String>> autocompleteIngredient(
    String query, {
    int number = 5,
  }) async {
    try {
      final uri = Uri.parse('$_baseUrl/food/ingredients/autocomplete').replace(
        queryParameters: {
          'apiKey': _apiKey,
          'query': query,
          'number': number.toString(),
        },
      );

      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final results = json.decode(response.body) as List;
        return results.map((item) => item['name'] as String).toList();
      } else {
        return [];
      }
    } catch (e) {
      return [];
    }
  }
}

/// Résultat de recherche de recette
class RecipeSearchResult {
  final int id;
  final String title;
  final String? image;
  final int? calories;
  final double? protein;
  final double? carbs;
  final double? fat;
  final int? servings;

  RecipeSearchResult({
    required this.id,
    required this.title,
    this.image,
    this.calories,
    this.protein,
    this.carbs,
    this.fat,
    this.servings,
  });

  factory RecipeSearchResult.fromJson(Map<String, dynamic> json) {
    // Pour complexSearch avec addRecipeNutrition=true
    final nutrition = json['nutrition'];
    int? calories;
    double? protein;
    double? carbs;
    double? fat;

    if (nutrition != null) {
      final nutrients = nutrition['nutrients'] as List?;
      if (nutrients != null) {
        for (var nutrient in nutrients) {
          final name = nutrient['name']?.toString().toLowerCase() ?? '';
          final amount = (nutrient['amount'] as num?)?.toDouble() ?? 0.0;

          if (name.contains('calories')) {
            calories = amount.toInt();
          } else if (name.contains('protein')) {
            protein = amount;
          } else if (name.contains('carbohydrate')) {
            carbs = amount;
          } else if (name.contains('fat') && !name.contains('saturated')) {
            fat = amount;
          }
        }
      }
    } else {
      // Pour findByNutrients - les valeurs peuvent être des strings
      if (json['calories'] != null) {
        calories = json['calories'] is String
            ? int.tryParse(json['calories'])
            : (json['calories'] as num?)?.toInt();
      }
      if (json['protein'] != null) {
        protein = json['protein'] is String
            ? double.tryParse(json['protein'])
            : (json['protein'] as num?)?.toDouble();
      }
      if (json['carbs'] != null) {
        carbs = json['carbs'] is String
            ? double.tryParse(json['carbs'])
            : (json['carbs'] as num?)?.toDouble();
      }
      if (json['fat'] != null) {
        fat = json['fat'] is String
            ? double.tryParse(json['fat'])
            : (json['fat'] as num?)?.toDouble();
      }
    }

    return RecipeSearchResult(
      id: json['id'] as int,
      title: json['title'] as String,
      image: json['image'] as String?,
      calories: calories,
      protein: protein,
      carbs: carbs,
      fat: fat,
      servings: json['servings'] as int?,
    );
  }
}

/// Détails complets d'une recette
class RecipeDetails {
  final int id;
  final String title;
  final String? image;
  final int servings;
  final int readyInMinutes;
  final String? summary;
  final List<Ingredient> ingredients;
  final String? instructions;
  final NutritionInfo nutrition;

  RecipeDetails({
    required this.id,
    required this.title,
    this.image,
    required this.servings,
    required this.readyInMinutes,
    this.summary,
    required this.ingredients,
    this.instructions,
    required this.nutrition,
  });

  factory RecipeDetails.fromJson(Map<String, dynamic> json) {
    final ingredientsJson = json['extendedIngredients'] as List? ?? [];
    final ingredients = ingredientsJson
        .map((i) => Ingredient.fromJson(i as Map<String, dynamic>))
        .toList();

    return RecipeDetails(
      id: json['id'] as int,
      title: json['title'] as String,
      image: json['image'] as String?,
      servings: json['servings'] as int? ?? 1,
      readyInMinutes: json['readyInMinutes'] as int? ?? 0,
      summary: json['summary'] as String?,
      ingredients: ingredients,
      instructions: json['instructions'] as String?,
      nutrition: NutritionInfo.fromJson(json['nutrition'] ?? {}),
    );
  }
}

/// Ingrédient d'une recette
class Ingredient {
  final int id;
  final String name;
  final String original;
  final double amount;
  final String unit;

  Ingredient({
    required this.id,
    required this.name,
    required this.original,
    required this.amount,
    required this.unit,
  });

  factory Ingredient.fromJson(Map<String, dynamic> json) {
    return Ingredient(
      id: json['id'] as int,
      name: json['name'] as String,
      original: json['original'] as String,
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      unit: json['unit'] as String? ?? '',
    );
  }
}

/// Informations nutritionnelles
class NutritionInfo {
  final int calories;
  final double protein;
  final double carbs;
  final double fat;
  final double fiber;
  final double sugar;

  NutritionInfo({
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
    this.fiber = 0,
    this.sugar = 0,
  });

  factory NutritionInfo.fromJson(Map<String, dynamic> json) {
    final nutrients = json['nutrients'] as List? ?? [];

    int calories = 0;
    double protein = 0;
    double carbs = 0;
    double fat = 0;
    double fiber = 0;
    double sugar = 0;

    for (var nutrient in nutrients) {
      final name = nutrient['name']?.toString().toLowerCase() ?? '';
      final amount = (nutrient['amount'] as num?)?.toDouble() ?? 0.0;

      if (name.contains('calories')) {
        calories = amount.toInt();
      } else if (name.contains('protein')) {
        protein = amount;
      } else if (name.contains('carbohydrate')) {
        carbs = amount;
      } else if (name.contains('fat') && !name.contains('saturated')) {
        fat = amount;
      } else if (name.contains('fiber')) {
        fiber = amount;
      } else if (name.contains('sugar')) {
        sugar = amount;
      }
    }

    return NutritionInfo(
      calories: calories,
      protein: protein,
      carbs: carbs,
      fat: fat,
      fiber: fiber,
      sugar: sugar,
    );
  }
}

/// Résultat de recherche d'ingrédient
class IngredientSearchResult {
  final int id;
  final String name;
  final String image;

  IngredientSearchResult({
    required this.id,
    required this.name,
    required this.image,
  });

  factory IngredientSearchResult.fromJson(Map<String, dynamic> json) {
    return IngredientSearchResult(
      id: json['id'] as int,
      name: json['name'] as String,
      image: json['image'] as String? ?? '',
    );
  }
}

/// Nutrition d'un ingrédient avec quantité spécifique
class IngredientNutrition {
  final int id;
  final String name;
  final double amount;
  final String unit;
  final int calories;
  final double protein;
  final double carbs;
  final double fat;
  final List<String> possibleUnits;

  IngredientNutrition({
    required this.id,
    required this.name,
    required this.amount,
    required this.unit,
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
    required this.possibleUnits,
  });

  factory IngredientNutrition.fromJson(Map<String, dynamic> json) {
    final nutrients = json['nutrition']?['nutrients'] as List? ?? [];

    int calories = 0;
    double protein = 0;
    double carbs = 0;
    double fat = 0;

    for (var nutrient in nutrients) {
      final name = nutrient['name']?.toString().toLowerCase() ?? '';
      final amount = (nutrient['amount'] as num?)?.toDouble() ?? 0.0;

      if (name.contains('calories')) {
        calories = amount.toInt();
      } else if (name.contains('protein')) {
        protein = amount;
      } else if (name.contains('carbohydrate')) {
        carbs = amount;
      } else if (name.contains('fat') && !name.contains('saturated')) {
        fat = amount;
      }
    }

    final possibleUnits =
        (json['possibleUnits'] as List?)?.map((u) => u.toString()).toList() ??
        [];

    return IngredientNutrition(
      id: json['id'] as int,
      name: json['name'] as String,
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      unit: json['unit'] as String? ?? '',
      calories: calories,
      protein: protein,
      carbs: carbs,
      fat: fat,
      possibleUnits: possibleUnits,
    );
  }
}
