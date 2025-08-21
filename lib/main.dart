import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:convert';
import 'package:cryptography/cryptography.dart';
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
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.teal,
          brightness: Brightness.dark,
        ),
      ),
      home: Scaffold(
        body: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(
              vertical: kToolbarHeight,
              horizontal: 16,
            ),
            child: Align(
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: 400),
                child: SeederView(),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class SeederView extends StatefulWidget {
  const SeederView({super.key});

  @override
  State<SeederView> createState() => _SeederViewState();
}

class _SeederViewState extends State<SeederView> {
  final nameController = TextEditingController();
  final seedController = TextEditingController();
  bool isGenerating = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text("Seed", style: Theme.of(context).textTheme.displaySmall),
        TextField(
          controller: nameController,
          decoration: InputDecoration(hintText: "Your Name"),
        ),
        SizedBox(height: 16),
        TextField(
          controller: seedController,
          decoration: InputDecoration(
            hintText: "Something that you can remember",
          ),
        ),
        SizedBox(height: 16),
        FilledButton.icon(
          onPressed: isGenerating ? null : generateNsec,
          label: Text(isGenerating ? "Generating" : "Copy your nsec"),
          icon: Icon(Icons.copy),
        ),
      ],
    );
  }

  void generateNsec() async {
    setState(() {
      isGenerating = true;
    });

    final nsec = await generateNsecFromString(
      seedController.text,
      salt: nameController.text,
    );

    setState(() {
      isGenerating = false;
    });

    await Clipboard.setData(ClipboardData(text: nsec));
  }
}

Future<String> generateNsecFromString(String seed, {String salt = ''}) async {
  final saltString = "nostr_seed_v1:${salt.toLowerCase().replaceAll(" ", "")}";
  final saltBytes = utf8.encode(saltString);

  // Argon2id parameters - these are secure defaults
  // Memory: 64 MB (65536 KB)
  // Iterations: 3
  // Parallelism: 4
  final algorithm = Argon2id(
    memory: 262144, // 64 MB
    iterations: 10,
    parallelism: 8,
    hashLength: 32, // 256 bits for secp256k1
  );

  // Create a SecretKey from the password
  final passwordKey = SecretKey(utf8.encode(seed));

  // Derive the key
  final derivedKey = await algorithm.deriveKey(
    secretKey: passwordKey,
    nonce: saltBytes,
  );

  // Get the raw bytes
  final privateKeyBytes = await derivedKey.extractBytes();

  // Convert to hex
  final privateKeyHex = privateKeyBytes
      .map((byte) => byte.toRadixString(16).padLeft(2, '0'))
      .join();

  return Nip19.nsecFromHex(privateKeyHex);
}
