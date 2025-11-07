import 'package:flutter/material.dart';
import 'package:filmeals_app/core/theme/app_theme.dart';

class PersonalInfoPage extends StatelessWidget {
  final TextEditingController nameController;
  final TextEditingController emailController;
  final TextEditingController ageController;
  final String? selectedGender;
  final Function(String) onGenderSelected;

  const PersonalInfoPage({
    super.key,
    required this.nameController,
    required this.emailController,
    required this.ageController,
    required this.selectedGender,
    required this.onGenderSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Informations personnelles',
          style: Theme.of(context).textTheme.displayMedium,
        ),
        const SizedBox(height: 12),
        Text(
          'Parlez-nous un peu de vous',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 40),
        TextField(
          controller: nameController,
          decoration: const InputDecoration(
            labelText: 'Nom',
            hintText: 'Entrez votre nom',
            prefixIcon: Icon(Icons.person_outline),
          ),
        ),
        const SizedBox(height: 20),
        TextField(
          controller: emailController,
          keyboardType: TextInputType.emailAddress,
          decoration: const InputDecoration(
            labelText: 'Email',
            hintText: 'Entrez votre email',
            prefixIcon: Icon(Icons.email_outlined),
          ),
        ),
        const SizedBox(height: 20),
        TextField(
          controller: ageController,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Âge',
            hintText: 'Entrez votre âge',
            prefixIcon: Icon(Icons.cake_outlined),
          ),
        ),
        const SizedBox(height: 24),
        Text(
          'Genre',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildGenderCard(
                context,
                label: 'Homme',
                icon: Icons.male,
                value: 'male',
                isSelected: selectedGender == 'male',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildGenderCard(
                context,
                label: 'Femme',
                icon: Icons.female,
                value: 'female',
                isSelected: selectedGender == 'female',
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildGenderCard(
    BuildContext context, {
    required String label,
    required IconData icon,
    required String value,
    required bool isSelected,
  }) {
    return InkWell(
      onTap: () => onGenderSelected(value),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.primaryColor.withOpacity(0.1)
              : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppTheme.primaryColor : AppTheme.borderColor,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: 40,
              color: isSelected ? AppTheme.primaryColor : AppTheme.textSecondaryColor,
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: isSelected ? AppTheme.primaryColor : AppTheme.textPrimaryColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
