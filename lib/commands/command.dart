import 'dart:convert';

import 'package:file/file.dart';
import 'package:file/local.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart';
import 'package:pathplanner/commands/command_groups.dart';
import 'package:pathplanner/commands/named_command.dart';
import 'package:pathplanner/commands/none_command.dart';
import 'package:pathplanner/commands/path_command.dart';
import 'package:pathplanner/commands/wait_command.dart';
import 'package:pathplanner/services/log.dart';
import 'package:pathplanner/util/prefs.dart';
import 'package:shared_preferences/shared_preferences.dart';

abstract class Command {
  static Map<String, String> named = {};
  static late Directory commandDir;

  final String type;

  const Command({
    required this.type,
  });

  Map<String, dynamic> dataToJson();

  Command clone();

  @nonVirtual
  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'data': dataToJson(),
    };
  }

  static void loadAllNamedCommands(FileSystem fs, Directory dir) async {
    for(FileSystemEntity f in dir.listSync()) {
      if(f.path.endsWith('.json')) {
        final file = fs.file(f.path);
        String jsonStr = await file.readAsString();
        try {
          Map<String, dynamic> json = jsonDecode(jsonStr);

          if(json['type'] == 'named') {
            NamedCommand c = fromJson(json) as NamedCommand;
            named.putIfAbsent(c.name as String, () => c.path as String);
          }
        } catch (ex, stack) {
          Log.error('Failed to load command', ex, stack);
        }
      }
    }
  }

  static Future<void> saveNamed(String name, {String? oldName}) async {
    print(name);
    
    try {
      File pathFile = commandDir.childFile('$name.json');
      if(oldName != null) deleteNamed(file: commandDir.childFile('$oldName.json'));

      pathFile.createSync(recursive: true);
      const JsonEncoder encoder = JsonEncoder.withIndent('  ');
      pathFile.writeAsString(encoder.convert(NamedCommand(name: name, path: named[name])));
    } catch (ex, stack) {
      Log.error('Failed to save command', ex, stack);
    }
  }

  static void deleteNamed({Directory? dir, File? file, String? name}) async {
    if(file != null) {
      file.deleteSync(recursive: true);
    } else if(dir != null) {
      dir.listSync().forEach((element) {
        if(element.path.endsWith('$name.json')) {
          element.deleteSync(recursive: true);
        }
      });
    }
  }

  static Command fromJson(Map<String, dynamic> json) {
    String? type = json['type'];

    if (type == 'wait') {
      return WaitCommand.fromDataJson(json['data'] ?? {});
    } else if (type == 'named') {
      return NamedCommand.fromDataJson(json['data'] ?? {});
    } else if (type == 'path') {
      return PathCommand.fromDataJson(json['data'] ?? {});
    } else if (type == 'sequential') {
      return SequentialCommandGroup.fromDataJson(json['data'] ?? {});
    } else if (type == 'parallel') {
      return ParallelCommandGroup.fromDataJson(json['data'] ?? {});
    } else if (type == 'race') {
      return RaceCommandGroup.fromDataJson(json['data'] ?? {});
    } else if (type == 'deadline') {
      return DeadlineCommandGroup.fromDataJson(json['data'] ?? {});
    }

    return const NoneCommand();
  }

  static Command fromType(String type, {List<Command>? commands}) {
    if (type == 'named') {
      return NamedCommand();
    } else if (type == 'wait') {
      return WaitCommand();
    } else if (type == 'path') {
      return PathCommand();
    } else if (type == 'sequential') {
      return SequentialCommandGroup(commands: commands ?? []);
    } else if (type == 'parallel') {
      return ParallelCommandGroup(commands: commands ?? []);
    } else if (type == 'race') {
      return RaceCommandGroup(commands: commands ?? []);
    } else if (type == 'deadline') {
      return DeadlineCommandGroup(commands: commands ?? []);
    }

    return const NoneCommand();
  }
}
