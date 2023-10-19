class FileInfo {
  final String path;
  List<String> tags;

  FileInfo(this.path, [this.tags = const []]);

  // Convert a FileInfo into a Map
  Map<String, dynamic> toJson() => {
        'path': path,
        'tags': tags,
      };

  // Create a FileInfo from a Map
  static FileInfo fromJson(Map<String, dynamic> json) {
    return FileInfo(json['path'], List<String>.from(json['tags']));
  }
}
