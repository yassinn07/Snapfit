// lib/change_preferences.dart

import 'package:flutter/material.dart';
import 'services/profile_service.dart';

// Enum remains the same
enum PreferenceType { fit, ageGroup, lifestyle, season, colors, exclusions }

class ChangePreferencesPage extends StatefulWidget {
  // Receive initial preferences
  final String initialFit;
  final String initialLifestyle;
  final String initialSeason;
  final String initialAgeGroup;
  final List<String> initialColors;
  final List<String> initialExclusions;
  // Callback function for saving
  final Function(Map<String, dynamic>) onSave;
  final String token;

  // Updated constructor
  const ChangePreferencesPage({
    required this.initialFit,
    required this.initialLifestyle,
    required this.initialSeason,
    required this.initialAgeGroup,
    required this.initialColors,
    required this.initialExclusions,
    required this.onSave, // Make callback required
    required this.token,
    super.key,
  });

  @override
  State<ChangePreferencesPage> createState() => _ChangePreferencesPageState();
}

class _ChangePreferencesPageState extends State<ChangePreferencesPage> {
  // State variables remain the same
  late String _selectedFit;
  late String _selectedAgeGroup;
  late List<String> _selectedLifestyle;
  late String _selectedSeason;
  late List<String> _selectedColors;
  late List<String> _selectedExclusions;
  bool _isLoading = false;

  // Options lists remain the same
  final List<String> _fitOptions = ["Slim", "Regular", "Loose", "Oversized"];
  final List<String> _ageGroupOptions = ["Under 18", "18-24", "25-34", "35-44", "45+"];
  final List<String> _lifestyleOptions = ["Work", "Workout", "Everyday", "Party", "Formal", "Casual"];
  final List<String> _seasonOptions = ["Auto", "Spring", "Summer", "Autumn", "Winter"];
  final List<String> _colorOptions = ["Red", "Green", "Blue", "Yellow", "Black", "White", "Gray", "Brown", "Pink", "Purple", "Orange"];
  final List<String> _categoryExclusionOptions = ["Dresses", "Skirts", "Jackets", "Tops", "Pants", "Shoes", "Bags"];


  @override
  void initState() {
    super.initState();
    // Initialize state with the passed initial values
    _selectedFit = widget.initialFit;
    _selectedAgeGroup = widget.initialAgeGroup;
    _selectedLifestyle = widget.initialLifestyle.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList(); // Handle comma-separated string
    _selectedSeason = widget.initialSeason;
    _selectedColors = List.from(widget.initialColors);
    _selectedExclusions = List.from(widget.initialExclusions);
  }

  // --- Methods to Show Selection Modals/Dialogs ---

  // *** FIXED _showSingleChoiceOptions ***
  Future<void> _showSingleChoiceOptions(BuildContext context, PreferenceType type) async {
    String title = "";
    List<String> options = [];
    String currentSelection = ""; // Use local variable for initial state in modal

    switch (type) {
      case PreferenceType.fit:
        title = "Select Fit";
        options = _fitOptions;
        currentSelection = _selectedFit;
        break;
      case PreferenceType.ageGroup:
        title = "Select Age Group";
        options = _ageGroupOptions;
        currentSelection = _selectedAgeGroup;
        break;
      case PreferenceType.season:
        title = "Select Season";
        options = _seasonOptions;
        currentSelection = _selectedSeason;
        break;
      default:
        return; // Should not happen for single choice
    }

    // Correctly call showModalBottomSheet with context and builder
    final String? result = await showModalBottomSheet<String>(
      context: context, // Provide context
      shape: const RoundedRectangleBorder( // Rounded corners
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      backgroundColor: const Color(0xFFFDF9F7),
      builder: (BuildContext modalContext) {
        return SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontFamily: 'Archivo', fontWeight: FontWeight.bold, fontSize: 20, color: Colors.black)),
                const SizedBox(height: 15),
                StatefulBuilder(
                    builder: (BuildContext context, StateSetter setModalState) {
                      return ListView.builder(
                        shrinkWrap: true, // Important in bottom sheet
                        physics: const NeverScrollableScrollPhysics(), // Disable inner scroll
                        itemCount: options.length,
                        itemBuilder: (context, index) {
                          final option = options[index];
                          return RadioListTile<String>(
                            title: Text(option, style: const TextStyle(fontFamily: 'Archivo', color: Colors.black)),
                            value: option,
                            groupValue: currentSelection, // Use local state for groupValue
                            onChanged: (String? value) {
                              if (value != null) {
                                Navigator.pop(modalContext, value);
                              }
                            },
                            activeColor: const Color(0xFFD55F5F),
                          );
                        },
                      );
                    }
                ),
                const SizedBox(height: 10),
              ],
            ),
          ),
        );
      },
    );

    // Update actual state if a selection was made and returned
    if (result != null) {
      setState(() {
        switch (type) {
          case PreferenceType.fit:
            _selectedFit = result;
            break;
          case PreferenceType.ageGroup:
            _selectedAgeGroup = result;
            break;
          case PreferenceType.season:
            _selectedSeason = result;
            break;
          default: break;
        }
      });
    }
  }

  // *** FIXED _showMultiChoiceOptions ***
  Future<void> _showMultiChoiceOptions(BuildContext context, PreferenceType type) async {
    String title = "";
    List<String> options = [];
    List<String> initialSelections = []; // Initial selections from state

    switch (type) {
      case PreferenceType.lifestyle:
        title = "Select Lifestyle";
        options = _lifestyleOptions;
        initialSelections = List.from(_selectedLifestyle);
        break;
      case PreferenceType.colors:
        title = "Select Preferred Colors";
        options = _colorOptions;
        initialSelections = List.from(_selectedColors);
        break;
      case PreferenceType.exclusions:
        title = "Select Excluded Categories";
        options = _categoryExclusionOptions;
        initialSelections = List.from(_selectedExclusions);
        break;
      default:
        return; // Should not happen
    }

    // Create a list to track selection state that can be modified in the modal
    List<String> tempSelection = List.from(initialSelections);

    // Correctly call showModalBottomSheet with context and builder
    final List<String>? result = await showModalBottomSheet<List<String>>(
      context: context,
      isScrollControlled: true, // Allow modal to take more height
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      backgroundColor: const Color(0xFFFDF9F7),
      builder: (BuildContext modalContext) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return Padding(
              padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
              child: ConstrainedBox(
                constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.7),
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: const TextStyle(fontFamily: 'Archivo', fontWeight: FontWeight.bold, fontSize: 20, color: Colors.black)),
                      const SizedBox(height: 15),
                      Expanded(
                        child: ListView.builder(
                          shrinkWrap: true,
                          itemCount: options.length,
                          itemBuilder: (context, index) {
                            final option = options[index];
                            return CheckboxListTile(
                              title: Text(option, style: const TextStyle(fontFamily: 'Archivo', color: Colors.black)),
                              value: tempSelection.contains(option),
                              onChanged: (bool? value) {
                                setModalState(() {
                                  if (value == true && !tempSelection.contains(option)) {
                                    tempSelection.add(option);
                                  } else if (value == false && tempSelection.contains(option)) {
                                    tempSelection.remove(option);
                                  }
                                });
                              },
                              activeColor: const Color(0xFFD55F5F),
                              checkColor: Colors.white,
                              controlAffinity: ListTileControlAffinity.leading,
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 15),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          TextButton(
                            onPressed: () {
                              setModalState(() {
                                tempSelection.clear();
                              });
                            },
                            child: const Text("Clear All",
                                style: TextStyle(
                                  color: Colors.red,
                                  fontFamily: 'Archivo',
                                  fontWeight: FontWeight.bold,
                                )
                            ),
                          ),
                          ElevatedButton(
                            onPressed: () {
                              Navigator.pop(modalContext, tempSelection);
                            },
                            style: ElevatedButton.styleFrom(
                                backgroundColor: Color(0xFFD55F5F),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12)
                            ),
                            child: const Text("Done", style: TextStyle(fontFamily: 'Archivo', fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );

    // Update actual state if a selection was made and returned
    if (result != null) {
      setState(() {
        switch (type) {
          case PreferenceType.lifestyle:
            _selectedLifestyle = result;
            break;
          case PreferenceType.colors:
            _selectedColors = result;
            break;
          case PreferenceType.exclusions:
            _selectedExclusions = result;
            break;
          default: break;
        }
      });
    }
  }
  // --- End Selection Methods ---


  // Save Preferences Method remains the same
  void _savePreferences() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Call the API to save preferences
      final profileService = ProfileService(token: widget.token);
      final updatedProfile = await profileService.updatePreferences(
        fitPreference: _selectedFit,
        lifestylePreferences: _selectedLifestyle,
        seasonPreference: _selectedSeason,
        ageGroup: _selectedAgeGroup,
        preferredColors: _selectedColors,
        excludedCategories: _selectedExclusions,
      );

      // Create a map of the updated preferences
      final Map<String, dynamic> updatedPreferences = {
        'fit': updatedProfile.fitPreference,
        'ageGroup': updatedProfile.ageGroup,
        'lifestyle': updatedProfile.lifestylePreferences,
        'season': updatedProfile.seasonPreference,
        'colors': updatedProfile.preferredColors,
        'exclusions': updatedProfile.excludedCategories,
      };

      // Call the callback function passed from HomeScreen via ProfilePage
      widget.onSave(updatedPreferences);

      setState(() {
        _isLoading = false;
      });

      // Show feedback
      if (mounted) { // Check if the widget is still in the tree
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Preferences Saved!')),
        );
        // Return true to indicate preferences were updated
        Navigator.pop(context, true);
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Error saving preferences'))
        );
      }
    }
  }


  @override
  Widget build(BuildContext context) {
    // Build method remains the same
    const String defaultFontFamily = 'Archivo';
    return Scaffold(
      backgroundColor: const Color(0xFFF6F2EF),
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          "Change Preferences",
          style: TextStyle(fontFamily: 'Archivo', fontSize: 25, fontWeight: FontWeight.w500, letterSpacing: -0.02 * 25, color: Colors.black),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 19.0, vertical: 20.0),
        child: Column(
          children: [
            _buildPreferenceEditRow(title: "Fit", currentValue: _selectedFit, onTap: () => _showSingleChoiceOptions(context, PreferenceType.fit), fontFamily: 'Archivo'),
            const SizedBox(height: 15),
            _buildPreferenceEditRow(title: "Age group", currentValue: _selectedAgeGroup, onTap: () => _showSingleChoiceOptions(context, PreferenceType.ageGroup), fontFamily: 'Archivo'),
            const SizedBox(height: 15),
            _buildPreferenceEditRow(title: "Life Style", currentValue: _selectedLifestyle.join(', '), onTap: () => _showMultiChoiceOptions(context, PreferenceType.lifestyle), fontFamily: 'Archivo'),
            const SizedBox(height: 15),
            _buildPreferenceEditRow(title: "Season", currentValue: _selectedSeason, onTap: () => _showSingleChoiceOptions(context, PreferenceType.season), fontFamily: 'Archivo'),
            const SizedBox(height: 15),
            _buildPreferenceEditRow(title: "Colors", currentValue: _selectedColors.isEmpty ? "Select preferred colors" : _selectedColors.join(', '), onTap: () => _showMultiChoiceOptions(context, PreferenceType.colors), fontFamily: 'Archivo'),
            const SizedBox(height: 15),
            _buildPreferenceEditRow(title: "Exclusions", currentValue: _selectedExclusions.isEmpty ? "Select excluded categories" : _selectedExclusions.join(', '), onTap: () => _showMultiChoiceOptions(context, PreferenceType.exclusions), fontFamily: 'Archivo'),
            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _savePreferences,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFD55F5F),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  "Save Preferences",
                  style: TextStyle(
                    fontFamily: 'Archivo',
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Helper widget remains the same
  Widget _buildPreferenceEditRow({ required String title, required String currentValue, required VoidCallback onTap, required String fontFamily }) {
    return InkWell( onTap: onTap, borderRadius: BorderRadius.circular(15), child: Container( width: double.infinity, padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18), decoration: BoxDecoration( color: Colors.white, borderRadius: BorderRadius.circular(15), border: Border.all(color: Colors.black.withOpacity(0.09)), boxShadow: [ BoxShadow( color: Colors.grey.withOpacity(0.05), spreadRadius: 1, blurRadius: 3, offset: const Offset(0, 2)) ] ), child: Row( children: [ Expanded( child: Column( crossAxisAlignment: CrossAxisAlignment.start, children: [ Text(title, style: TextStyle(fontFamily: fontFamily, fontWeight: FontWeight.w600, fontSize: 15, letterSpacing: -0.02 * 15, color: const Color(0xFF040404))), const SizedBox(height: 8), Text(currentValue.isEmpty ? 'Tap to select' : currentValue, style: TextStyle(fontFamily: fontFamily, fontWeight: FontWeight.w500, fontSize: 14, letterSpacing: -0.02 * 14, color: currentValue.isEmpty ? Colors.grey.shade600 : const Color(0xFF221F1B).withOpacity(0.76)), maxLines: 2, overflow: TextOverflow.ellipsis) ] ) ), const SizedBox(width: 10), Icon(Icons.arrow_forward_ios, size: 18, color: Colors.grey.shade400) ] ) ) );
  }

} // End _ChangePreferencesPageState