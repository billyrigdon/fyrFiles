// ignore_for_file: avoid_print

import 'dart:convert';
import 'dart:async';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'dart:io';
import 'package:flutter/services.dart';

void main() {
  runApp(const FyrFilesApp());
}

class FyrFilesApp extends StatelessWidget {
  const FyrFilesApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: FyrFiles(),
    );
  }
}

class FyrFiles extends StatefulWidget {
  const FyrFiles({super.key});

  @override
  State<FyrFiles> createState() => _FyrFilesState();
}

class _FyrFilesState extends State<FyrFiles> {
  /* 
    'late' is similar to declaring a variable with ! in typescript.
    Means the value will be non-null at the time it's used
  */
  late List<FileSystemEntity> files;
  late Directory currentDir;
  FileSystemEntity? copiedEntity;
  bool isFileContextMenuShown = false;

  // called after constructor, think useEffect/ngOnInit/onMounted
  @override
  void initState() {
    super.initState();
    currentDir = Directory.current;
    files = currentDir.listSync();
  }

  String displayText(Directory dir, Directory currentDir) {
    if (dir.path == '/' && dir != currentDir) {
      return 'root > ';
    } else if (dir.path == '/' && dir == currentDir) {
      return 'root';
    } else if (dir != currentDir) {
      return '${dir.path.split('/').last} > ';
    } else {
      return dir.path.split('/').last;
    }
  }

  Map<String, dynamic> fileStatToMap(FileStat fileStat) {
    return {
      'mode': fileStat.mode.toString(),
      'modified': fileStat.modified.toString(),
      'accessed': fileStat.accessed.toString(),
      'changed': fileStat.changed.toString(),
      'size': fileStat.size,
      'type': fileStat.type.toString(),
    };
  }

  void openDirectory(Directory directory) {
    // setState notifies framework that variables have changed
    setState(() {
      currentDir = directory;
      files = directory.listSync();
    });
  }

  bool hasChildDirectories(Directory directory) {
    var entities = directory.listSync(followLinks: false);
    return entities.any((entity) => entity is Directory);
  }

  List<Directory> getParentDirectories(Directory currDir) {
    List<Directory> parents = [];
    Directory? dir = currDir;
    while (dir?.path != dir?.parent.path) {
      if (dir != null) {
        parents.add(dir);
      }
      dir = dir?.parent;
    }
    // Add the root directory
    if (dir != null && dir.path == dir.parent.path) {
      parents.add(dir);
    }
    return parents.reversed.toList();
  }

  String formatPath(String path) {
    List<String> segments = path.split('/');
    return segments.where((seg) => seg.isNotEmpty).join(' > ');
  }

  Stream<List<FileSystemEntity>> watchDirectory(Directory dir) {
    return dir.list().asyncMap((_) => dir.listSync());
  }

  Future<void> pasteFile(Directory targetDir) async {
    try {
      ClipboardData data =
          await Clipboard.getData('text/plain') as ClipboardData;
      String path = data.text ?? '';
      if (FileSystemEntity.isFileSync(path)) {
        File sourceFile = File(path);
        String fileName = sourceFile.uri.pathSegments.last;
        await sourceFile.copy('${targetDir.path}/$fileName');
      }
    } catch (err) {
      print(err);
    }
  }

  // Template for UI
  @override
  Widget build(BuildContext context) {
    double width = MediaQuery.of(context).size.width;
    Stream<List<FileSystemEntity>> fileStream = watchDirectory(currentDir);
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 30,
        leading: currentDir.path != currentDir.parent.path
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () {
                  openDirectory(currentDir.parent);
                },
                iconSize: 24.0,
              )
            : null,
        backgroundColor: Colors.transparent,
        flexibleSpace: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center, // Align vertically
          children: [
            SizedBox(width: 50), // This is to offset the back button
            Align(
              alignment: Alignment.center, // Vertically align the RichText
              child: RichText(
                text: TextSpan(
                  children: getParentDirectories(currentDir).map((dir) {
                    return TextSpan(
                      text: displayText(dir, currentDir),
                      style: const TextStyle(color: Colors.black),
                      recognizer: TapGestureRecognizer()
                        ..onTap = () {
                          openDirectory(dir);
                        },
                    );
                  }).toList(),
                ),
              ),
            ),
          ],
        ),
      ),
      body: StreamBuilder<List<FileSystemEntity>>(
        stream: fileStream,
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            files = snapshot.data as List<FileSystemEntity>;
            return Stack(
              children: [
                GridView.builder(
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: (width / 120).floor()),
                  itemCount: files.length,
                  itemBuilder: (context, index) {
                    var file = files[index];
                    var isDir = FileSystemEntity.isDirectorySync(file.path);
                    return Listener(
                      onPointerDown: (PointerDownEvent event) {
                        if (event.kind == PointerDeviceKind.mouse &&
                            event.buttons == kSecondaryMouseButton) {
                          isFileContextMenuShown = true;
                          showMenu(
                            context: context,
                            position: RelativeRect.fromLTRB(
                                event.position.dx,
                                event.position.dy,
                                event.position.dx,
                                event.position.dy),
                            items: [
                              PopupMenuItem(
                                child: ListTile(
                                  leading: Icon(Icons.copy),
                                  title: Text('Copy'),
                                  onTap: () {
                                    Clipboard.setData(
                                        ClipboardData(text: file.path));
                                    print(file.path);
                                    Navigator.pop(
                                        context); // Close the context menu
                                  },
                                ),
                              ),
                              PopupMenuItem(
                                child: ListTile(
                                  leading: Icon(Icons.info),
                                  title: Text('Properties'),
                                  onTap: () {
                                    var fileStat = file.statSync();
                                    var properties = fileStatToMap(fileStat);
                                    print(
                                        'Properties: ${jsonEncode(properties)}');
                                    Navigator.pop(
                                        context); // Close the context menu
                                  },
                                ),
                              ),
                            ],
                          ).then((value) => isFileContextMenuShown = false);
                        }
                      },
                      child: InkWell(
                        onTap: () async {
                          if (isDir) {
                            openDirectory(file as Directory);
                          } else {
                            var filePath = file.path;
                            var result =
                                await Process.run('xdg-open', [filePath]);
                            if (result.exitCode != 0) {
                              print(
                                  'Could not open $filePath: ${result.stderr}');
                            }
                          }
                        },
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              isDir ? Icons.folder : Icons.file_copy,
                              size: 48.0,
                              color: Colors.deepPurple,
                            ),
                            Text(
                              isDir
                                  ? file.path.split('/').last
                                  : file.uri.pathSegments.last,
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
                GestureDetector(
                  behavior: HitTestBehavior.translucent,
                  onSecondaryTapDown: (TapDownDetails details) {
                    if (!isFileContextMenuShown) {
                      showMenu(
                        context: context,
                        position: RelativeRect.fromLTRB(
                          details.globalPosition.dx,
                          details.globalPosition.dy,
                          details.globalPosition.dx,
                          details.globalPosition.dy,
                        ),
                        items: [
                          PopupMenuItem(
                            child: ListTile(
                              leading: Icon(Icons.paste),
                              title: Text('Paste'),
                              onTap: () async {
                                pasteFile(currentDir);
                                Navigator.pop(
                                    context); // Close the context menu
                              },
                            ),
                          ),
                        ],
                      );
                    }
                  },
                ),
              ],
            );
          }
          return const CircularProgressIndicator();
        },
      ),
    );
  }
}
