import 'dart:convert';
import 'dart:math';

import 'package:file/file.dart';
import 'package:path/path.dart';
import 'package:pathplanner/commands/named_command.dart';
import 'package:pathplanner/util/pose2d.dart';
import 'package:pathplanner/commands/command.dart';
import 'package:pathplanner/commands/command_groups.dart';
import 'package:pathplanner/commands/path_command.dart';
import 'package:pathplanner/services/log.dart';

class PathPlannerAuto {
  String name;
  Pose2d? startingPose;
  SequentialCommandGroup sequence;

  String? folder;

  FileSystem fs;
  String autoDir;

  // Stuff used for UI
  DateTime lastModified = DateTime.now().toUtc();

  PathPlannerAuto({
    required this.name,
    required this.sequence,
    required this.autoDir,
    required this.fs,
    required this.folder,
    required this.startingPose,
  }) {
    _addNamedCommandsToSet(sequence.commands);
  }

  PathPlannerAuto.defaultAuto({
    this.name = 'New Auto',
    required this.autoDir,
    required this.fs,
    this.folder,
  })  : sequence = SequentialCommandGroup(commands: []),
        startingPose = Pose2d(position: const Point(2, 2));

  PathPlannerAuto duplicate(String newName, String f) {
    return PathPlannerAuto(
      name: newName,
      sequence: sequence.clone() as SequentialCommandGroup,
      autoDir: '$autoDir/${f == 'null' ? '' : f}',
      fs: fs,
      startingPose: startingPose,
      folder: f,
    );
  }

  PathPlannerAuto.fromJsonV1(
      Map<String, dynamic> json, String name, String autosDir, FileSystem fs)
      : this(
          autoDir: autosDir,
          fs: fs,
          name: name,
          startingPose: json['startingPose'] == null
              ? null
              : Pose2d.fromJson(json['startingPose']),
          sequence:
              Command.fromJson(json['command'] ?? {}) as SequentialCommandGroup,
          folder: json['folder'],
        );

  Map<String, dynamic> toJson() {
    return {
      'version': 1.0,
      'startingPose': startingPose?.toJson(),
      'command': sequence.toJson(),
      'folder': folder,
    };
  }

  static Future<List<PathPlannerAuto>> loadAllAutosInDir(
      String autosDir, FileSystem fs) async {
    List<PathPlannerAuto> autos = [];

    List<FileSystemEntity> files = fs.directory(autosDir).listSync();
    for (FileSystemEntity e in files) {
      if (e.path.endsWith('.auto')) {
        final file = fs.file(e.path);
        String jsonStr = await file.readAsString();
        try {
          Map<String, dynamic> json = jsonDecode(jsonStr);
          String autoName = basenameWithoutExtension(e.path);

          if (json['version'] == 1.0) {
            PathPlannerAuto auto =
                PathPlannerAuto.fromJsonV1(json, autoName, autosDir, fs);
            auto.lastModified = (await file.lastModified()).toUtc();

            autos.add(auto);
          } else {
            Log.error('Unknown auto version');
          }
        } catch (ex, stack) {
          Log.error('Failed to load auto', ex, stack);
        }
      }
    }
    return autos;
  }

  void rename(String newName) {
    Set<File> autoFiles = {
      fs.file(join(autoDir, '$name.auto')), 
      fs.file(join(autoDir, 'team/$name Red.auto')),
      fs.file(join(autoDir, 'team/$name Blue.auto'))};

    for(File file in autoFiles) {
      if (file.existsSync()) {
        file.renameSync(file.path.split('/').reversed.join('/').replaceFirst(name, newName).split('/').reversed.join('/'));
      }
    }
    name = newName;
    lastModified = DateTime.now().toUtc();
  }

  void delete() {
    Set<File> autoFiles = {
      fs.file(join(autoDir, '$name.auto')), 
      fs.file(join(autoDir, 'team/$name Red.auto')),
      fs.file(join(autoDir, 'team/$name Blue.auto'))};

    for(File file in autoFiles) {
      if (file.existsSync()) {
        file.delete();
      } 
    }
  }

  void saveFile(bool parent) {
    if(parent) {
      PathPlannerAuto red = duplicate('$name Red', 'team');
      red.setTeam('Red');
      red.saveFile(false);

      PathPlannerAuto blue = duplicate('$name Blue', 'team');
      blue.setTeam('Blue');
      blue.saveFile(false);
    }

    try {
      File autoFile = fs.file(join(autoDir, '$name.auto'));
      autoFile.createSync(recursive: true);
      
      const JsonEncoder encoder = JsonEncoder.withIndent('  ');
      autoFile.writeAsString(encoder.convert(this));
      lastModified = DateTime.now().toUtc();
      Log.debug('Saved "$name.auto"');
    } catch (ex, stack) {
      Log.error('Failed to save auto', ex, stack);
    }

    resetTeam();
  }

  void setTeam(String team) {
    for (Command cmd in sequence.commands) {
      if (cmd is PathCommand && (cmd.pathName != null && !cmd.pathName!.contains(' $team'))) {
        _updatePathNameInCommands(sequence.commands, cmd.pathName!, '${cmd.pathName} $team');
      }
    }
  }

  void resetTeam() {
    for (Command cmd in sequence.commands) {
      if (cmd is PathCommand && cmd.pathName != null) {
        _updatePathNameInCommands(sequence.commands, cmd.pathName!, cmd.pathName!.replaceAll(' Red', '').replaceAll(' Blue', ''));
      }
    }
  }

  void updatePathName(String oldPathName, String newPathName) {
    _updatePathNameInCommands(sequence.commands, oldPathName, newPathName);
    //saveFile(!newPathName.contains(' Blue') && !newPathName.contains(' Red'));
    saveFile(true);
  }

  void _updatePathNameInCommands(
      List<Command> commands, String oldPathName, String newPathName) {
    for (Command cmd in commands) {
      if (cmd is PathCommand && cmd.pathName == oldPathName) {
        cmd.pathName = newPathName;
      } else if (cmd is CommandGroup) {
        _updatePathNameInCommands(cmd.commands, oldPathName, newPathName);
      }
    }
  }

  void _addNamedCommandsToSet(List<Command> commands) {
    for (Command cmd in commands) {
      if (cmd is NamedCommand) {
        if (cmd.name != null) {
          Command.named.add(cmd.name!);
          continue;
        }
      }

      if (cmd is CommandGroup) {
        _addNamedCommandsToSet(cmd.commands);
      }
    }
  }

  List<String> getAllPathNames() {
    return _getPathNamesInCommands(sequence.commands);
  }

  bool hasEmptyPathCommands() {
    return _hasEmptyPathCommands(sequence.commands);
  }

  bool _hasEmptyPathCommands(List<Command> commands) {
    for (Command cmd in commands) {
      if (cmd is PathCommand && cmd.pathName == null) {
        return true;
      } else if (cmd is CommandGroup) {
        bool hasEmpty = _hasEmptyPathCommands(cmd.commands);
        if (hasEmpty) {
          return true;
        }
      }
    }
    return false;
  }

  bool hasEmptyNamedCommand() {
    return _hasEmptyNamedCommand(sequence.commands);
  }

  bool _hasEmptyNamedCommand(List<Command> commands) {
    for (Command cmd in commands) {
      if (cmd is NamedCommand && cmd.name == null) {
        return true;
      } else if (cmd is CommandGroup) {
        bool hasEmpty = _hasEmptyNamedCommand(cmd.commands);
        if (hasEmpty) {
          return true;
        }
      }
    }
    return false;
  }

  List<String> _getPathNamesInCommands(List<Command> commands) {
    List<String> names = [];
    for (Command cmd in commands) {
      if (cmd is PathCommand && cmd.pathName != null) {
        names.add(cmd.pathName!);
      } else if (cmd is CommandGroup) {
        names.addAll(_getPathNamesInCommands(cmd.commands));
      }
    }
    return names;
  }

  void handleMissingPaths(List<String> pathNames) {
    return _handleMissingPaths(sequence.commands, pathNames);
  }

  void _handleMissingPaths(List<Command> commands, List<String> pathNames) {
    for (Command cmd in commands) {
      if (cmd is PathCommand && !pathNames.contains(cmd.pathName)) {
        cmd.pathName = null;
      } else if (cmd is CommandGroup) {
        _handleMissingPaths(cmd.commands, pathNames);
      }
    }
  }

  @override
  bool operator ==(Object other) =>
      other is PathPlannerAuto &&
      other.runtimeType == runtimeType &&
      other.name == name &&
      other.startingPose == startingPose &&
      other.sequence == sequence;

  @override
  int get hashCode => Object.hash(name, startingPose, sequence);
}
