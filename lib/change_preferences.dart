// lib/change_preferences.dart

import 'package:flutter/material.dart';

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


  // Updated constructor
  const ChangePreferencesPage({
    required this.initialFit,
    required this.initialLifestyle,
    required this.initialSeason,
    required this.initialAgeGroup,
    required this.initialColors,
    required this.initialExclusions,
    required this.onSave, // Make callback required
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

  // Options lists remain the same
  final List<String> _fitOptions = ["Slim", "Regular", "Loose", "Oversized"];
  final List<String> _ageGroupOptions = ["Under 18", "18-24", "25-34", "35-44", "45+"];
  final List<String> _lifestyleOptions = ["Work", "Workout", "Everyday", "Party", "Formal", "Casual"];
  final List<String> _seasonOptions = ["Auto", "Spring", "Summer", "Autumn", "Winter"];
  final List<String> _colorOptions = ["Red", "Green", "Blue", "Yellow", "Black", "White", "Gray", "Brown", "Pink", "Purple", "Orange"];
  final List<String> _categoryExclusionOptions = ["Dresses", "Skirts", "Jackets", "Tops", "Pants", "Shoes", "Bags", "Accessories"];


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
      builder: (BuildContext modalContext) { // Provide builder function
        // Use modalContext inside the builder
        return SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(modalContext).textTheme.titleLarge?.copyWith(fontFamily: 'Archivo')),
                const SizedBox(height: 15),
                // Use StatefulBuilder to manage the radio button state within the modal
                StatefulBuilder(
                    builder: (BuildContext context, StateSetter setModalState) {
                      return ListView.builder(
                        shrinkWrap: true, // Important in bottom sheet
                        physics: const NeverScrollableScrollPhysics(), // Disable inner scroll
                        itemCount: options.length,
                        itemBuilder: (context, index) {
                          final option = options[index];
                          return RadioListTile<String>(
                            title: Text(option, style: const TextStyle(fontFamily: 'Archivo')),
                            value: option,
                            groupValue: currentSelection, // Use local state for groupValue
                            onChanged: (String? value) {
                              if (value != null) {
                                // Update local state for immediate UI feedback (optional but good UX)
                                // setModalState(() {
                                //   currentSelection = value;
                                // });
                                // Pop with the selected value
                                Navigator.pop(modalContext, value);
                              }
                            },
                            activeColor: const Color(0xFF8960C4), // Theme color
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
    List<String> currentSelectionCopy = []; // Use a copy for the modal

    switch (type) {
      case PreferenceType.lifestyle:
        title = "Select Lifestyle";
        options = _lifestyleOptions;
        currentSelectionCopy = List.from(_selectedLifestyle); // Use copy
        break;
      case PreferenceType.colors:
        title = "Select Preferred Colors";
        options = _colorOptions;
        currentSelectionCopy = List.from(_selectedColors); // Use copy
        break;
      case PreferenceType.exclusions:
        title = "Select Excluded Categories";
        options = _categoryExclusionOptions;
        currentSelectionCopy = List.from(_selectedExclusions); // Use copy
        break;
      default:
        return; // Should not happen
    }

    // Correctly call showModalBottomSheet with context and builder
    final List<String>? result = await showModalBottomSheet<List<String>>(
      context: context, // Provide context
      isScrollControlled: true, // Allow modal to take more height
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (BuildContext modalContext) { // Provide builder function
        // Use StatefulWidget inside (via StatefulBuilder) to manage temporary checked state
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            // Temporary list to hold selections within the modal, initialized with the copy
            List<String> tempSelection = List.from(currentSelectionCopy);

            return Padding(
              padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom), // Adjust for keyboard if needed later
              child: ConstrainedBox(
                constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.7), // Limit height
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontFamily: 'Archivo')),
                      const SizedBox(height: 15),
                      Expanded( // Make the list scrollable
                        child: ListView.builder(
                          shrinkWrap: true,
                          itemCount: options.length,
                          itemBuilder: (context, index) {
                            final option = options[index];
                            final isSelected = tempSelection.contains(option);
                            return CheckboxListTile(
                              title: Text(option, style: const TextStyle(fontFamily: 'Archivo')),
                              value: isSelected,
                              onChanged: (bool? value) {
                                // Use the modal's state setter for immediate UI update
                                setModalState(() {
                                  if (value == true) {
                                    tempSelection.add(option);
                                  } else {
                                    tempSelection.remove(option);
                                  }
                                });
                              },
                              activeColor: const Color(0xFF8960C4), // Theme color
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 15),
                      Center(
                        child: ElevatedButton(
                          onPressed: () {
                            // Pop and return the final selection from the modal
                            Navigator.pop(modalContext, tempSelection);
                          },
                          style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.black,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12)
                          ),
                          child: const Text("Done", style: TextStyle(fontFamily: 'Archivo')),
                        ),
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
  void _savePreferences() {
    // TODO: Add validation if needed before saving

    // Create a map of the selected preferences
    final Map<String, dynamic> updatedPreferences = {
      'fit': _selectedFit,
      'ageGroup': _selectedAgeGroup,
      'lifestyle': _selectedLifestyle, // Pass the list directly
      'season': _selectedSeason,
      'colors': _selectedColors,
      'exclusions': _selectedExclusions,
    };

    // Call the callback function passed from HomeScreen via ProfilePage
    widget.onSave(updatedPreferences);

    // Show feedback
    if (mounted) { // Check if the widget is still in the tree
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Preferences Saved!')),
      );
      // Pop the screen
      Navigator.pop(context);
    }
  }


  @override
  Widget build(BuildContext context) {
    // Build method remains the same
    const String defaultFontFamily = 'Archivo';
    return Scaffold(
      backgroundColor: const Color(0xFFFDF9F7),
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          "Change Preferences",
          style: TextStyle(fontFamily: defaultFontFamily, fontSize: 25, fontWeight: FontWeight.w500, letterSpacing: -0.02 * 25, color: Colors.black),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 19.0, vertical: 20.0),
        child: Column(
          children: [
            _buildPreferenceEditRow(title: "Fit", currentValue: _selectedFit, onTap: () => _showSingleChoiceOptions(context, PreferenceType.fit), fontFamily: defaultFontFamily),
            const SizedBox(height: 15),
            _buildPreferenceEditRow(title: "Age group", currentValue: _selectedAgeGroup, onTap: () => _showSingleChoiceOptions(context, PreferenceType.ageGroup), fontFamily: defaultFontFamily),
            const SizedBox(height: 15),
            _buildPreferenceEditRow(title: "Life Style", currentValue: _selectedLifestyle.join(', '), onTap: () => _showMultiChoiceOptions(context, PreferenceType.lifestyle), fontFamily: defaultFontFamily),
            const SizedBox(height: 15),
            _buildPreferenceEditRow(title: "Season", currentValue: _selectedSeason, onTap: () => _showSingleChoiceOptions(context, PreferenceType.season), fontFamily: defaultFontFamily),
            const SizedBox(height: 15),
            _buildPreferenceEditRow(title: "Colors", currentValue: _selectedColors.isEmpty ? "Select preferred colors" : _selectedColors.join(', '), onTap: () => _showMultiChoiceOptions(context, PreferenceType.colors), fontFamily: defaultFontFamily),
            const SizedBox(height: 15),
            _buildPreferenceEditRow(title: "I want to exclude", currentValue: _selectedExclusions.isEmpty ? "Select categories you don’t want" : _selectedExclusions.join(', '), onTap: () => _showMultiChoiceOptions(context, PreferenceType.exclusions), fontFamily: defaultFontFamily),
            const SizedBox(height: 40),
            ElevatedButton(
                onPressed: _savePreferences,
                style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                    padding: const EdgeInsets.symmetric(vertical: 12)
                ),
                child: const Text("Save Preferences", style: TextStyle(fontFamily: defaultFontFamily, fontSize: 16, fontWeight: FontWeight.w500))
            ),
            const SizedBox(height: 20),
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
