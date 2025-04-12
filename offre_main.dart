import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'offre_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://xqbnjwedfurajossjgof.supabase.co', // Remplace ici
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InhxYm5qd2VkZnVyYWpvc3NqZ29mIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDM2MTQzMDYsImV4cCI6MjA1OTE5MDMwNn0._1LKV9UaV-tsOt9wCwcD8Xp_WvXrumlp0Jv0az9rgp4',
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Offres App',
      debugShowCheckedModeBanner: false,
      home: OffresPage(),
    );
  }
}
