import 'package:flutter/material.dart';
import 'package:gohealth/models/profile_model.dart';

class ProfileForm extends StatefulWidget {
  final ProfileModel profile;
  final Function({
    String? name,
    int? age,
    String? gender,
    double? height,
    double? weight,
    String? activityLevel,
  }) onUpdate;

  const ProfileForm({
    Key? key,
    required this.profile,
    required this.onUpdate,
  }) : super(key: key);

  @override
  State<ProfileForm> createState() => _ProfileFormState();
}

class _ProfileFormState extends State<ProfileForm> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _ageController;
  late TextEditingController _heightController;
  late TextEditingController _weightController;
  String? _selectedGender;
  String? _selectedActivityLevel;

  final List<String> _activityLevels = [
    'SEDENTARY',
    'LIGHTLY',
    'MODERATELY_ACTIVE',
    'VERY_ACTIVE',
    'EXTRA_ACTIVE'
  ];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.profile.name);
    _ageController = TextEditingController(text: widget.profile.age?.toString() ?? '');
    _heightController = TextEditingController(text: widget.profile.height?.toString() ?? '');
    _weightController = TextEditingController(text: widget.profile.weight?.toString() ?? '');
    _selectedGender = widget.profile.gender;
    _selectedActivityLevel = widget.profile.activityLevel;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    _heightController.dispose();
    _weightController.dispose();
    super.dispose();
  }

  void _handleSubmit() {
    if (_formKey.currentState!.validate()) {
      widget.onUpdate(
        name: _nameController.text,
        age: int.tryParse(_ageController.text),
        gender: _selectedGender,
        height: double.tryParse(_heightController.text),
        weight: double.tryParse(_weightController.text),
        activityLevel: _selectedActivityLevel,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextFormField(
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: 'Name',
              border: OutlineInputBorder(),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter your name';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _ageController,
            decoration: const InputDecoration(
              labelText: 'Age',
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.number,
            validator: (value) {
              if (value != null && value.isNotEmpty) {
                final age = int.tryParse(value);
                if (age == null || age < 1 || age > 120) {
                  return 'Please enter a valid age (1-120)';
                }
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            value: _selectedGender,
            decoration: const InputDecoration(
              labelText: 'Gender',
              border: OutlineInputBorder(),
            ),
            items: const [
              DropdownMenuItem(value: 'MALE', child: Text('Male')),
              DropdownMenuItem(value: 'FEMALE', child: Text('Female')),
            ],
            onChanged: (value) {
              setState(() => _selectedGender = value);
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _heightController,
            decoration: const InputDecoration(
              labelText: 'Height (cm)',
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.number,
            validator: (value) {
              if (value != null && value.isNotEmpty) {
                final height = double.tryParse(value);
                if (height == null || height < 50 || height > 300) {
                  return 'Please enter a valid height (50-300 cm)';
                }
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _weightController,
            decoration: const InputDecoration(
              labelText: 'Weight (kg)',
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.number,
            validator: (value) {
              if (value != null && value.isNotEmpty) {
                final weight = double.tryParse(value);
                if (weight == null || weight < 20 || weight > 500) {
                  return 'Please enter a valid weight (20-500 kg)';
                }
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            value: _selectedActivityLevel,
            decoration: const InputDecoration(
              labelText: 'Activity Level',
              border: OutlineInputBorder(),
            ),
            items: _activityLevels.map((level) {
              return DropdownMenuItem(
                value: level,
                child: Text(level.replaceAll('_', ' ').toLowerCase()),
              );
            }).toList(),
            onChanged: (value) {
              setState(() => _selectedActivityLevel = value);
            },
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _handleSubmit,
            child: const Text('Update Profile'),
          ),
        ],
      ),
    );
  }
} 