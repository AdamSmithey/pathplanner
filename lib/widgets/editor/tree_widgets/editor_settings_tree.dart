import 'package:flutter/material.dart';
import 'package:pathplanner/util/prefs.dart';
import 'package:pathplanner/widgets/editor/tree_widgets/tree_card_node.dart';
import 'package:shared_preferences/shared_preferences.dart';

class EditorSettingsTree extends StatefulWidget {
  final bool initiallyExpanded;
  final VoidCallback? onPathChanged;

  const EditorSettingsTree({
    super.key,
    this.initiallyExpanded = false,
    required this.onPathChanged,
  });

  @override
  State<EditorSettingsTree> createState() => _EditorSettingsTreeState();
}

class _EditorSettingsTreeState extends State<EditorSettingsTree> {
  late SharedPreferences _prefs;
  bool _snapToGuidelines = Defaults.snapToGuidelines;
  bool _hidePathsOnHover = Defaults.hidePathsOnHover;
  bool _saveBothPaths = Defaults.saveBothPaths;

  @override
  void initState() {
    super.initState();

    SharedPreferences.getInstance().then((value) {
      setState(() {
        _prefs = value;
        _snapToGuidelines = _prefs.getBool(PrefsKeys.snapToGuidelines) ??
            Defaults.snapToGuidelines;
        _hidePathsOnHover = _prefs.getBool(PrefsKeys.hidePathsOnHover) ??
            Defaults.hidePathsOnHover;
        _saveBothPaths = _prefs.getBool(PrefsKeys.saveBothPaths) ?? 
            Defaults.saveBothPaths;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return TreeCardNode(
      initiallyExpanded: widget.initiallyExpanded,
      title: const Text('Editor Settings'),
      children: [
        Row(
          children: [
            Checkbox(
              value: _snapToGuidelines,
              onChanged: (val) {
                if (val != null) {
                  setState(() {
                    _snapToGuidelines = val;
                    _prefs.setBool(PrefsKeys.snapToGuidelines, val);
                  });
                }
              },
            ),
            const Padding(
              padding: EdgeInsets.only(
                bottom: 3.0,
                left: 4.0,
              ),
              child: Text(
                'Snap To Guidelines',
                style: TextStyle(fontSize: 15),
              ),
            ),
          ],
        ),
        Row(
          children: [
            Checkbox(
              value: _hidePathsOnHover,
              onChanged: (val) {
                if (val != null) {
                  setState(() {
                    _hidePathsOnHover = val;
                    _prefs.setBool(PrefsKeys.hidePathsOnHover, val);
                  });
                }
              },
            ),
            const Padding(
              padding: EdgeInsets.only(
                bottom: 3.0,
                left: 4.0,
              ),
              child: Text(
                'Hide Other Paths on Hover',
                style: TextStyle(fontSize: 15),
              ),
            ),
          ],
        ),
        Row(
          children: [
            Checkbox(
              value: _saveBothPaths,
              onChanged: (val) {
                if (val != null) {
                  widget.onPathChanged?.call();
                  
                  setState(() {
                    _saveBothPaths = val;
                    _prefs.setBool(PrefsKeys.saveBothPaths, val);
                  });
                }
              },
            ),
            const Padding(
              padding: EdgeInsets.only(
                bottom: 3.0,
                left: 4.0,
              ),
              child: Text(
                'test',
                style: TextStyle(fontSize: 15),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
