import 'dart:io';
import 'package:archive/archive.dart';

Future<String> createZipFile(List<String> filesToZip) async {
  // Obter o diretório de downloads do usuário
  final username = Platform.environment['USERNAME'];
  print('Username: $username');

  final downloadsDirectory = 'C:\\Users\\$username\\Downloads';

  // Nome do arquivo ZIP gerado, com base na data e hora atual
  String zipFileName = 'package-${DateTime.now().toIso8601String()}'
      .replaceAll(RegExp(r'[^\w\s]'), '')
      .replaceAll(RegExp(r'\s+'), '');
  zipFileName = '$zipFileName.zip';

  // Cria um novo arquivo ZIP no diretório de downloads
  final zipFile = File('${downloadsDirectory}/$zipFileName');
  final zipEncoder = ZipEncoder();
  final zipArchive = Archive();

  // Adiciona cada arquivo da lista ao arquivo ZIP
  for (final file in filesToZip) {
    final fileBytes = await File(file).readAsBytes();
    zipArchive.addFile(ArchiveFile(file, fileBytes.length, fileBytes));
  }

  // Codifica o arquivo ZIP e salva no disco
  final zipBytes = zipEncoder.encode(zipArchive);
  await zipFile.writeAsBytes(zipBytes!);

  print('Arquivo ZIP gerado com sucesso: ${zipFile.path}');

  return zipFile.path;
}

bool temQuebraDeLinha(String texto) {
  final regex = RegExp(r'\n|\r\n');
  return regex.hasMatch(texto);
}

void stripString(String texto) {
  for (int i = 0; i < texto.length; i++) {
    print("O código ASCII de '${texto[i]}' é: ${texto.codeUnitAt(i)}");
  }
}

void aguarde() {
  print('Pressione ENTER: ');
  // Aguarda a entrada do usuário
  stdin.readLineSync();
}
