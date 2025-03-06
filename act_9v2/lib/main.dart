import 'package:flutter/material.dart';


class FoldersScreen extends StatelessWidget {
  final List<Map<String, dynamic>> folders = [
    {'name': 'Hearts', 'image': 'assets/Hearts.png', 'count': 3},
    {'name': 'Spades', 'image': 'assets/Spades.png', 'count': 5},
    {'name': 'Diamonds', 'image': 'assets/Diamonds.png', 'count': 4},
    {'name': 'Clubs', 'image': 'assets/Clubs.png', 'count': 6},
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

  CardsScreen({required this.folderName});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('$folderName Cards')),
      body: Center(
        child: ElevatedButton(
          onPressed: () {
            Navigator.pop(context);
          },
          child: Text('Back to Folders'),
        ),
      ),
    );
  }
}

void main() {
  runApp(MaterialApp(
    home: FoldersScreen(),
  ));
}
