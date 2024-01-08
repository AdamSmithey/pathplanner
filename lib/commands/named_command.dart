import 'package:pathplanner/commands/command.dart';

class NamedCommand extends Command {
  String? name;
  String? path;

  NamedCommand({this.name, this.path}) : super(type: 'named');

  NamedCommand.fromDataJson(Map<String, dynamic> json)
      : this(name: json['name'], path: json['path']);

  @override
  Map<String, dynamic> dataToJson() {
    return {
      'name': name,
      'path': path,
    };
  }

  @override
  Command clone() {
    return NamedCommand(name: name, path: path);
  }

  @override
  bool operator ==(Object other) =>
      other is NamedCommand &&
      other.runtimeType == runtimeType &&
      other.name == name &&
      other.path == path;

  @override
  int get hashCode => Object.hash(type, name, path);
}
