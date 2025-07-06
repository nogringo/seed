import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:nip19/nip19.dart';

void main() {
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "Seed",
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Color(0xFFFFB200)),
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Color(0xFFFFB200),
          brightness: Brightness.dark,
        ),
      ),
      home: Scaffold(
        body: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.only(
              top: kToolbarHeight,
              bottom: 8,
              right: 8,
              left: 8,
            ),
            child: Align(
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: 300),
                child: SeederView(),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class SeederView extends StatelessWidget {
  const SeederView({super.key});

  @override
  Widget build(BuildContext context) {
    final seedController = TextEditingController();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text("Seed", style: Theme.of(context).textTheme.displaySmall),
        TextField(
          controller: seedController,
          decoration: InputDecoration(
            hintText: "Something that you can remember",
          ),
        ),
        SizedBox(height: 16),
        FilledButton.icon(
          onPressed: () async {
            final nsec = generateNsecFromString(seedController.text);
            await Clipboard.setData(ClipboardData(text: nsec));
          },
          label: Text("Copy your nsec"),
          icon: Icon(Icons.copy),
        ),
      ],
    );
  }
}

String generateNsecFromString(String seed) {
  final bytes = utf8.encode(seed);
  final digest = sha256.convert(bytes);
  final privateKeyHex = digest.toString();

  return Nip19.nsecFromHex(privateKeyHex);
}
