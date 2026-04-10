import 'dart:io';

void main() {
  final dir = Directory('lib');
  final files = dir.listSync(recursive: true).whereType<File>().where((f) => f.path.endsWith('.dart'));
  int count = 0;
  for (final file in files) {
    String content = file.readAsStringSync();
    if (content.contains('GoogleFonts.poppins')) {
      content = content.replaceAll('GoogleFonts.poppins', 'GoogleFonts.playfairDisplay');
      file.writeAsStringSync(content);
      print('Updated ${file.path}');
      count++;
    }
  }
  print('Total files updated: $count');
}
