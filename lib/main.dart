import 'dart:collection';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:git/git.dart';
import 'package:mvp_branches/getgitlog.dart';
import 'package:mvp_branches/models/Commit.dart' as mycommit;
import 'package:mvp_branches/models/CommitItem.dart';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:mvp_branches/utils.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Exemplo ListView com borda, espaço e títulos',
      home: MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key? key}) : super(key: key);

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  String? _selectedDir;
  late String _directoryPath;
  final _branches = <String>[];
  int _selectedIndex = -1;
  final _commits = <CommitItem>[];
  final _listaDeArquivos = <String>[];

  @override
  void initState() {
    super.initState();
    _directoryPath = 'Diretório: não selecionado';
  }

  void _getGitBranches() async {
    if (_selectedDir == null) {
      return;
    }

    try {
      final gitDir = await GitDir.fromExisting(_selectedDir!);
      setDirectory(_selectedDir.toString());
      final branches = await getGitBranches();
      setState(() {
        _branches.clear();
        _branches.addAll(branches);
      });
    } on GitError catch (e) {
      print('Error getting git branches: $e');
    }
  }

  Future<void> _selectDirectory() async {
    String? selectedDirectory = "C:\\Desenvolvimento\\workspace\\mfc";
    if (!kIsWeb) {
      selectedDirectory = await FilePicker.platform.getDirectoryPath();
    }

    if (selectedDirectory != null) {
      setState(() {
        _directoryPath = 'Diretório: $selectedDirectory';
        _selectedDir = selectedDirectory.toString();
      });
      _getGitBranches();
    }
  }

  Future<void> _commitsFromBranch() async {
    List<mycommit.Commit> commitsFromBranch = [];
    try {
      commitsFromBranch = await getCommitsFromBranch(
          _selectedDir!, _branches[_selectedIndex],
          restrito: true);
    } catch (e) {
      print('Ocorreu uma exceção: $e');
    }
    setState(() {
      _commits.clear();
      for (mycommit.Commit commit in commitsFromBranch) {
        String title = commit.mensagem.length > 50
            ? "${commit.mensagem.substring(0, 50)}..."
            : commit.mensagem;
        _commits
            .add(CommitItem(title: '${commit.id} - $title', commit: commit));
      }
    });
  }

  Future<void> exibirDialogo() async {
    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Arquivos do commit'),
          content: SingleChildScrollView(
            child: ListBody(
              children: _listaDeArquivos.map(
                (string) {
                  return Text(string);
                },
              ).toList(),
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Fechar'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Lista de Branches e Commits'),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              TextButton(
                onPressed: _selectDirectory,
                child: const Text('Selecione o repositório'),
              ),
              const SizedBox(
                width: 16,
              ),
              Expanded(
                child: Container(
                  margin: const EdgeInsets.only(right: 10.0),
                  padding:
                      const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                  decoration: BoxDecoration(
                    border: Border.all(),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(_directoryPath),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Container(
                  margin: const EdgeInsets.all(10.0),
                  decoration: BoxDecoration(
                    border: Border.all(),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8.0),
                        child: const Text(
                          'Branches',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(
                        height: 8,
                      ),
                      Container(
                        height: 200,
                        child: ListView.builder(
                          itemCount: _branches.length,
                          itemBuilder: (context, index) {
                            return Container(
                              padding: const EdgeInsets.symmetric(
                                  vertical: 2.0, horizontal: 2.0),
                              color: _selectedIndex == index
                                  ? Colors.grey[200]
                                  : null,
                              height: 40,
                              child: Center(
                                child: ListTile(
                                  title: Text(
                                    _branches[index],
                                    style: TextStyle(
                                        fontFamily: 'UbuntuMono',
                                        fontSize: 14,
                                        fontWeight: _selectedIndex == index
                                            ? FontWeight.bold
                                            : FontWeight.normal),
                                  ),
                                  selected: _selectedIndex == index,
                                  onTap: () {
                                    setState(() {
                                      _selectedIndex = index;
                                      checkoutGitBranch(_branches[index]);
                                      _commitsFromBranch();
                                    });
                                  },
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Container(
                  margin: const EdgeInsets.all(10.0),
                  decoration: BoxDecoration(
                    border: Border.all(),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        child: const Text(
                          'Commits',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(
                        height: 8,
                      ),
                      Container(
                        height: 200,
                        child: ListView.builder(
                          itemCount: _commits.length,
                          itemBuilder: (context, index) {
                            final item = _commits[index];
                            return Container(
                              padding: const EdgeInsets.symmetric(
                                  vertical: 2.0, horizontal: 2.0),
                              height: 40,
                              child: Center(
                                child: CheckboxListTile(
                                  title: Text(
                                    item.title,
                                    style: const TextStyle(
                                      fontFamily: 'UbuntuMono',
                                      fontSize: 14.0,
                                    ),
                                  ),
                                  value: item.selected,
                                  onChanged: (newValue) {
                                    setState(() {
                                      item.selected = newValue ?? false;
                                    });
                                  },
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              ElevatedButton(
                onPressed: btnEmpacotarOnPressed,
                child: const Text('Empacotar'),
              ),
              const SizedBox(width: 8),
              TextButton(
                onPressed: () {},
                child: const Text('Limpar'),
              ),
              const SizedBox(width: 16),
            ],
          ),
        ],
      ),
    );
  }

  void btnEmpacotarOnPressed() async {
    var set = LinkedHashSet<String>();
    _listaDeArquivos.clear();
    for (CommitItem ci in _commits) {
      if (ci.selected) {
        final filesFuture = getModifiedFilesFromCommit(ci.commit.id);

        final files = await filesFuture;

        if (files != null) {
          for (final file in files) {
            set.add(file);
          }
        } else {
          print('Nenhum arquivo modificado no commit ${ci.commit.id}.');
        }
      }
    }
    var orderedList = set.toList()..sort();
    _listaDeArquivos.addAll(orderedList);

    var zipFile = await createZipFile(_listaDeArquivos);
    print('Arquivo compactado: $zipFile');

    exibirDialogo();
  }
}
