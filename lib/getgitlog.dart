import 'dart:convert';
import 'dart:io';

import 'package:mvp_branches/models/Commit.dart';
import 'package:mvp_branches/utils.dart';

Future<List<String>> getGitBranches() async {
  final result = await Process.run('git', ['branch'], stdoutEncoding: utf8);
  final output = result.stdout as String;
  final branches = output.trim().split('\n').map((branch) => branch.startsWith('*') ? branch.replaceFirst('*', '').trim() : branch.trim()).toList();
  return branches;
}


Future<List<String>> getGitLog(String branch) async {
  final process = await Process.start(
    'git',
    ['log', '--oneline', '-b', branch],
  );
  final output = await process.stdout.transform(utf8.decoder).toList();
  final exitCode = await process.exitCode;

  if (exitCode != 0) {
    throw Exception('O comando git falhou com o código $exitCode');
  } else {
    return output;
  }
}

Future<List<String>?> getModifiedFilesFromCommit(String commitId) async {
  final result = await Process.run(
      'git',
      ['diff-tree', '-r', '--no-commit-id', '--name-only', '--diff-filter=ACMRT', commitId]);

  if (result.exitCode != 0) {
    print('Erro ao executar o comando git: ${result.stderr}');
    return null;
  }

  final files = (result.stdout as String).trim().split('\n');

  if (files.isEmpty) {
    return null;
  }

  return files;
}


setDirectory(String diretorio) {
  Directory novoDiretorio = Directory(diretorio);
  Directory.current = novoDiretorio.path;
}

Future<List<Commit>> getCommitsFromBranch(String path, String branch,
    {bool restrito = false}) async {
  List<Commit> commits = [];

  setDirectory(path);

  final gitLog = await getGitLog(branch);

  for (final line in gitLog) {
    if (line.trim().isEmpty) {
      continue;
    }

    if (temQuebraDeLinha(line)) {
      List<String> linhas = line.split(RegExp(r'\n|\r\n'));

      for (int i = 0; i < linhas.length; i++) {
        String linha = linhas[i];
        if (linha.trim().isEmpty) {
          continue;
        }

        // print('Linha: $linha');

        commits.add(getCommitFromLinha(linha));
      }
    } else {
      if (!line.contains(branch)) {
        continue;
      }
      // print('Linha: $line');
      commits.add(getCommitFromLinha(line));
    }
  }

  if (restrito) {
    List<Commit> filteredCommits =
    commits.where((commit) => commit.mensagem.contains(branch)).toList();
    return filteredCommits;
  }

  return commits;
}

Commit getCommitFromLinha(String linha) {
  List<String> parts = linha.split(' ');
  String id = parts[0];
  String mensagem = linha.substring(id.length + 1);

  return Commit(id, mensagem);
}

Future<void> checkoutGitBranch(String branchName) async {
  final result = await Process.run('git', ['checkout', branchName]);
  if (result.exitCode != 0) {
    throw Exception('Erro ao executar o comando git checkout');
  }
}
