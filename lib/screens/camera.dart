import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class Camera extends StatelessWidget {
  Camera(this.listType, {super.key});
  final String listType;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          listType,
          style: const TextStyle(color: Color(0xFFFFFFFF)),
        ),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text(
              listType,
              style: Theme.of(context).textTheme.displayLarge,
            ),
          ],
        ),
      ),
    );
  }
}
