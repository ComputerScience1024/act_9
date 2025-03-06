import 'package:flutter/material.dart';


class FoldersScreen extends StatelessWidget {
  final List<Map<String, dynamic>> folders = [
    {'name': 'Hearts', 'image': 'assets/Heart.png', 'count': 3},
    {'name': 'Spades', 'image': 'assets/Spade.png', 'count': 5},
    {'name': 'Diamonds', 'image': 'assets/Diamond.png', 'count': 4},
    {'name': 'Clubs', 'image': 'assets/Club.png', 'count': 6},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Folders')),
      body: ListView.builder(
        itemCount: folders.length,
        itemBuilder: (context, index) {
          final folder = folders[index];
          return ListTile(
            leading: Image.asset(folder['image'], width: 50, height: 50),
            title: Text(folder['name']),
            subtitle: Text('${folder['count']} cards'),
            trailing: Icon(Icons.arrow_forward_ios),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => CardsScreen(folderName: folder['name']),
                ),
              );
            },
          );
        },
      ),
    );
  }
}


class CardsScreen extends StatelessWidget {
  final String folderName;
  final List<Map<String, dynamic>> cards = [
    {'name': 'Ace', 'image': 'assets/Ace.png'},
    {'name': 'King', 'image': 'assets/King.png'},
    {'name': 'Queen', 'image': 'assets/Queen.png'},
    {'name': 'Jack', 'image': 'assets/Jack.png'},
    {'name': '10', 'image': 'assets/10.png'},
  ];

  CardsScreen({required this.folderName});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('$folderName Cards')),
      body: GridView.builder(
        padding: EdgeInsets.all(10),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
        ),
        itemCount: cards.length,
        itemBuilder: (context, index) {
          final card = cards[index];
          return Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset(card['image'], width: 80, height: 80),
                SizedBox(height: 10),
                Text(card['name'], style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ],
            ),
          );
        },
      ),
    );
  }
}


void main() {
  runApp(MaterialApp(
    home: FoldersScreen(),
  ));
}
