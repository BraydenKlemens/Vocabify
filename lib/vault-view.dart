import 'package:flutter/material.dart';
import 'word-view.dart';
enum WordTypes {
  noun,
  adj
}

List _vaultItems = [
  {
    "word": "some word",
    "pronounce": "This is some part",
    "word_type": "Noun",
    "word_desc": "This is some word that is pretty cool! You can read some info about the word and learn something new.",
    "word_syns": ["Pepsi", "Coke", "Ice Cream", "Mario"]
  },
  {
    "word": "some word",
    "pronounce": "This is some part",
    "word_type": "Noun",
    "word_desc": "This is some word that is pretty cool! You can read some info about the word and learn something new.",
    "word_syns": ["Pepsi", "Coke", "Ice Cream", "Mario"]
  },
  {
    "word": "some word",
    "pronounce": "This is some part",
    "word_type": "Noun",
    "word_desc": "This is some word that is pretty cool! You can read some info about the word and learn something new.",
    "word_syns": ["Pepsi", "Coke", "Ice Cream", "Mario"]
  },
];

class VaultView extends StatefulWidget {
  const VaultView({ Key? key, required this.vaultTitle }) : super(key: key);
  final String vaultTitle;

  @override
  _VaultViewState createState() => _VaultViewState();
}

class _VaultViewState extends State<VaultView> {
  bool _isEditMode = false;
  double iconSize = 20;

  Widget _buildRow(index) { 
    return ListTile(
      title: Text(
        _vaultItems[index]["word"] + " / (" + _vaultItems[index]["pronounce"] + ") / " + _vaultItems[index]["word_type"],
      ),
      onTap: () {
        Navigator.push(context, MaterialPageRoute(builder: (context) => WordView()));
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Column(mainAxisAlignment: MainAxisAlignment.start, crossAxisAlignment: CrossAxisAlignment.start, children: [_isEditMode ? const TextBoxSearch() : Text(widget.vaultTitle, textAlign: TextAlign.start),
      Row(children: [ Icon(Icons.edit, size: iconSize), Icon(Icons.share, size: iconSize), Icon(Icons.more_horiz, size: iconSize)])], mainAxisSize: MainAxisSize.min),
      centerTitle: false,
      actions: [
        Padding(padding: const EdgeInsets.all(10), child: IconButton(onPressed: () => {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: !_isEditMode ? const Text("Entering Edit Mode") : const Text("Exiting Edit Mode"))),
          setState(() {
            _isEditMode = !_isEditMode;
            if (_isEditMode) {
              iconSize = 15;
            } else {
              iconSize = 20;
            }
          }),
        }, icon: !_isEditMode ? const Icon(Icons.search) : const Icon(Icons.close)) )

      ],
      ),
      body: ListView.builder(
      itemCount: _vaultItems.length+1,
      itemBuilder: (context, i) {
        var index = (i ~/ 2);
        if (i.isOdd || index >= _vaultItems.length) {
          return const Divider(
            color: Colors.black,
            thickness: 0.5,
          );
        }

      return _buildRow(index);
      },
      ),
    );
  }
}
class TextBoxSearch extends StatelessWidget {
  const TextBoxSearch({ Key? key }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(seconds: 1),
      curve: Curves.fastOutSlowIn,
      alignment: Alignment.centerLeft,
      color: Colors.white,
      height: 30,
      child: const TextField(
        decoration:
            InputDecoration(border: InputBorder.none, hintText: 'Search', hintStyle: TextStyle(fontSize: 15)),
      ),
    );
  }
}