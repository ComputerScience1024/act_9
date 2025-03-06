import 'package:flutter/material.dart';


class FoldersScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Folders')),
      body: Center(
        child: ElevatedButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => CardsScreen()),
            );
          },
          child: Text('Go to Cards'),
        ),
      ),
    );
  }
}


class CardsScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Cards')),
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
