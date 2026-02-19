// packages/mm_editor_schema/lib/src/model/project.dart

class MMProject {
  final int schemaVersion;
  final String projectId;
  final Map<String, dynamic> data;

  MMProject({
    required this.schemaVersion,
    required this.projectId,
    required this.data,
  });

  Map<String, dynamic> toJson() => {
        'schema_version': schemaVersion,
        'project_id': projectId,
        ...data,
      };

  factory MMProject.fromJson(Map<String, dynamic> json) {
    return MMProject(
      schemaVersion: json['schema_version'] ?? 1,
      projectId: json['project_id'],
      data: Map<String, dynamic>.from(json)
        ..remove('schema_version')
        ..remove('project_id'),
    );
  }
}
