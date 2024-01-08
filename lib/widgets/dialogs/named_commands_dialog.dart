import 'dart:io' as io;

import 'package:flutter/material.dart';
import 'package:pathplanner/commands/command.dart';
import 'package:pathplanner/util/prefs.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NamedCommandsDialog extends StatefulWidget {
  final SharedPreferences? prefs;
  final Function(String, String) onCommandRenamed;
  final Function(String) onCommandDeleted;

  const NamedCommandsDialog({
    super.key,
    this.prefs,
    required this.onCommandRenamed,
    required this.onCommandDeleted,
  });

  @override
  State<NamedCommandsDialog> createState() => _NamedCommandsDialogState();
}

class _NamedCommandsDialogState extends State<NamedCommandsDialog> {
  @override
  Widget build(BuildContext context) {
    ColorScheme colorScheme = Theme.of(context).colorScheme;

    return AlertDialog(
      title: Row(
        children: [
          const Text('Manage Named Commands'),
          const Spacer(),
          Tooltip(
            message: 'Set default command path',
            child: IconButton(
              onPressed: () => {_showSetPathDialog(widget.prefs!.getString(PrefsKeys.commandPath))},
              icon: const Icon(Icons.text_snippet_outlined),
            ),
          ),
          Tooltip(
            message: 'Add new command',
            waitDuration: const Duration(seconds: 1),
            child: IconButton(
              onPressed: () {
                String name;
                if(Command.named.containsKey('New Command')) {
                  int i = 0;
                  while(Command.named.containsKey('New Command ${++i}')) {}
                  name = 'New Command $i';
                } else {
                  name = 'New Command';
                }

                Command.named[name] = '';
                Command.saveNamed(name);
                setState(() {});
              },
              icon: const Icon(Icons.add),
            ),
          ),
        ],
      ),
      content: Container(
        width: 500,
        height: 350,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: colorScheme.surfaceVariant,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: ListView(
          shrinkWrap: true,
          children: [
            for (String namedCommand in Command.named.keys)
              ListTile(
                title: Text(namedCommand),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Tooltip(
                      message: 'Edit Command',
                      waitDuration: const Duration(milliseconds: 500),
                      child: IconButton(
                        onPressed: () => _showRenameDialog(namedCommand),
                        icon: const Icon(Icons.more_horiz),
                      ),
                    ),
                    Tooltip(
                      message: 'Remove named command',
                      waitDuration: const Duration(milliseconds: 500),
                      child: IconButton(
                        onPressed: () {
                          showDialog(
                              context: context,
                              builder: (BuildContext context) => AlertDialog(
                                    title: const Text('Remove Named Command'),
                                    content: Text(
                                        'Are you sure you want to remove the named command "$namedCommand"? This cannot be undone.'),
                                    actions: [
                                      TextButton(
                                        onPressed: Navigator.of(context).pop,
                                        child: const Text('Cancel'),
                                      ),
                                      TextButton(
                                        onPressed: () {
                                          setState(() {
                                            widget
                                                .onCommandDeleted(namedCommand);
                                            Command.named.remove(namedCommand);
                                          });

                                          Navigator.of(context).pop();
                                        },
                                        child: const Text('Confirm'),
                                      ),
                                    ],
                                  ));
                        },
                        icon: Icon(
                          Icons.close_rounded,
                          color: colorScheme.error,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: Navigator.of(context).pop,
          child: const Text('Close'),
        ),
      ],
    );
  }

  void _showSetPathDialog(String? originalPath) {
    String? projectDirectory = widget.prefs?.getString(PrefsKeys.currentProjectDir);

    TextEditingController path =
        TextEditingController(text: originalPath);

    ColorScheme colorScheme = Theme.of(context).colorScheme;

    showDialog(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: const Text('Edit Settings'),
        content: SizedBox(
          height: 130,
          width: 400,
          child:
           Column(
            children: [
              TextField(
                controller: path,
                style: TextStyle(fontSize: 14, color: colorScheme.onSurface),
                decoration: InputDecoration(
                  contentPadding: const EdgeInsets.fromLTRB(8, 4, 8, 4),
                  labelText: 'Command Name',
                  border:
                      OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
              const Divider(
                height: 32,
                thickness: 0,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: Navigator.of(context).pop,
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              // print('$projectDirectory/${path.text}');
              if(!io.Directory('$projectDirectory/${path.text}').existsSync()) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('This Path does not exist'),
                  ),
                );
              } else {
                Navigator.of(context).pop();

                widget.prefs?.setString(PrefsKeys.commandPath, path.text);
              }
            },
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
  }

  void _showRenameDialog(String originalName) {
    String originalPath = Command.named[originalName] as String;

    String? commandDirectory = widget.prefs?.getString(PrefsKeys.commandPath);
    String? projectDirectory = widget.prefs?.getString(PrefsKeys.currentProjectDir);
    // print(projectDirectory);

    TextEditingController name =
        TextEditingController(text: originalName);
    
    TextEditingController path = 
        TextEditingController(text: originalPath.replaceAll('$commandDirectory/', ''));

    ColorScheme colorScheme = Theme.of(context).colorScheme;

    showDialog(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: const Text('Edit Settings'),
        content: SizedBox(
          height: 130,
          width: 400,
          child:
           Column(
            children: [
              TextField(
                controller: name,
                style: TextStyle(fontSize: 14, color: colorScheme.onSurface),
                decoration: InputDecoration(
                  contentPadding: const EdgeInsets.fromLTRB(8, 4, 8, 4),
                  labelText: 'Command Name',
                  border:
                      OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
              const Divider(
                height: 32,
                thickness: 0,
              ),
              TextField(
                controller: path,
                style: TextStyle(fontSize: 14, color: colorScheme.onSurface),
                decoration: InputDecoration(
                  contentPadding: const EdgeInsets.fromLTRB(8, 4, 8, 4),
                  labelText: 'Command Path',
                  border:
                      OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: Navigator.of(context).pop,
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              if (name.text == originalName && path.text == originalPath) {
                Navigator.of(context).pop();
              } else if (Command.named.keys.contains(path.text)) {
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('A command with that name already exists'),
                  ),
                );
              } else if(!io.File('$projectDirectory/$commandDirectory/${path.text}.java').existsSync()) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('This Path does not exist'),
                  ),
                );
              } else {
                Navigator.of(context).pop();

                setState(() {
                  Command.named.remove(originalName);
                  Command.named[name.text] = path.text;
                  Command.saveNamed(name.text, oldName: originalName);
                  widget.onCommandRenamed(originalName, name.text);

                });
              }
            },
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
  }
}
