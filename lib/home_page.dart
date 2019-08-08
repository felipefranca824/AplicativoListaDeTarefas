import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

class Home extends StatefulWidget {
  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {
  List _toDoList = [];
  TextEditingController _controleAdicionar = TextEditingController();

  Map<String, dynamic> tarefaRemover = Map();
  int posicaoTarefaRemovida;

  @override
  void initState() {
    super.initState();
    _lerArquivo().then((arquivo) {
      setState(() {
        _toDoList = json.decode(arquivo);
      });
    });
  }

  _addTarefa() {
    if (_controleAdicionar.text.isNotEmpty) {
      setState(() {
        Map<String, dynamic> itemLista = Map();
        itemLista['title'] = _controleAdicionar.text;
        _controleAdicionar.text = '';
        itemLista['ok'] = false;
        _toDoList.add(itemLista);
        _salvarArquivo();
      });
    }
  }

  //Metodo para achar o caminho do arquivo no celular
  Future<File> _pegarArquivo() async {
    final diretorio = await getApplicationDocumentsDirectory();
    return File('${diretorio.path}/arquivo.json');
  }

  //metodo para salvar tarefas no arquivo
  Future<File> _salvarArquivo() async {
    String dados = json.encode(_toDoList);
    final arquivo = await _pegarArquivo();
    return arquivo.writeAsString(dados);
  }

  //metodo para ler as tarefas no arquivo
  Future<String> _lerArquivo() async {
    try {
      final arquivo = await _pegarArquivo();
      return arquivo.readAsString();
    } catch (e) {
      return null;
    }
  }

  Future<Null> _refresh() async {
    await Future.delayed(Duration(seconds: 1));
    setState(() {
      _toDoList.sort((a, b) {
        if (a['ok'] && !b['ok'])
          return 1;
        else if (!a['ok'] && b['ok'])
          return -1;
        else
          return 0;
      });
    });

    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text("Lista de Tarefas"),
          centerTitle: true,
        ),
        body: Column(
          children: <Widget>[
            Container(
              padding: EdgeInsets.all(10.0),
              child: Row(
                children: <Widget>[
                  Expanded(
                    child: TextField(
                      controller: _controleAdicionar,
                      decoration: InputDecoration(
                          labelText: 'Nova Tarefa',
                          labelStyle: TextStyle(color: Colors.blueAccent)),
                    ),
                  ),
                  RaisedButton(
                    onPressed: _addTarefa,
                    color: Colors.blueAccent,
                    child: Text('ADD'),
                    textColor: Colors.white,
                  )
                ],
              ),
            ),
            Expanded(
                child: RefreshIndicator(
                    child: ListView.builder(
                      padding: EdgeInsets.all(10.0),
                      itemCount: _toDoList.length,
                      itemBuilder: (context, index) {
                        return checkList(context, index);
                      },
                    ),
                    onRefresh: _refresh)),
          ],
        ));
  }

  Widget checkList(context, index) {
    return Dismissible(
        onDismissed: (direcao) {
          setState(() {
            tarefaRemover = Map.from(_toDoList[index]);
            posicaoTarefaRemovida = index;
            _toDoList.removeAt(posicaoTarefaRemovida);
          });
          _salvarArquivo();

          final snack = SnackBar(
            content: Text('Tarefa ${tarefaRemover['title']} removida!'),
            action: SnackBarAction(
                label: 'Desfazer',
                onPressed: () {
                  setState(() {
                    _toDoList.insert(posicaoTarefaRemovida, tarefaRemover);
                    _salvarArquivo();
                  });
                }),
            duration: Duration(seconds: 2),
          );
          Scaffold.of(context).showSnackBar(snack);
        },
        background: Container(
          color: Colors.red,
          child: Align(
            alignment: Alignment(-0.9, 0.0),
            child: Icon(
              Icons.delete,
              color: Colors.white,
            ),
          ),
        ),
        key: Key(DateTime
            .now()
            .millisecondsSinceEpoch
            .toString()),
        direction: DismissDirection.startToEnd,
        child: CheckboxListTile(
          title: Text(_toDoList[index]['title']),
          onChanged: (checar) {
            setState(() {
              _toDoList[index]['ok'] = checar;
              _salvarArquivo();
            });
          },
          value: _toDoList[index]['ok'],
          secondary: CircleAvatar(
            child: Icon(_toDoList[index]['ok'] ? Icons.check : Icons.error),
          ),
        ));
  }
}
