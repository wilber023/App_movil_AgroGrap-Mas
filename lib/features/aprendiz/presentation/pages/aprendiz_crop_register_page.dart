import 'package:flutter/material.dart';

class AprendizCropRegisterPage extends StatelessWidget {
  const AprendizCropRegisterPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Registro de Cultivo (Aprendiz)')),
      body: const Center(
        child: Text('Formulario para registrar nuevo cultivo'),
      ),
    );
  }
}
