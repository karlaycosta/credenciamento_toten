import 'dart:async';
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:rive/rive.dart' as rive;

import '../models/attendee.dart';
import '../repository/repository_even3.dart';

enum Estado { espera, verificando, sucesso, falha, checado }

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final stringBuffer = StringBuffer();
  final attendees = <Attendee>[];
  final checkedList = <int>{};
  Estado state = Estado.espera;
  Attendee? attendee;
  Timer? timer;

  /// Controller for playback
  late rive.StateMachineController controller;
  late rive.SMITrigger verificando;
  late rive.SMITrigger espera;
  late rive.SMITrigger falha;
  late rive.SMITrigger sucesso;
  late rive.SMITrigger checado;

  void onRiveInit(rive.Artboard artboard) {
    controller = rive.StateMachineController.fromArtboard(
      artboard,
      'State',
    ) as rive.StateMachineController;
    artboard.addController(controller);
    verificando = controller.getTriggerInput('verificando') as rive.SMITrigger;
    espera = controller.getTriggerInput('espera') as rive.SMITrigger;
    falha = controller.getTriggerInput('falha') as rive.SMITrigger;
    sucesso = controller.getTriggerInput('sucesso') as rive.SMITrigger;
    checado = controller.getTriggerInput('checado') as rive.SMITrigger;
  }

  @override
  void initState() {
    super.initState();
    // Escuta as entradas do teclado
    HardwareKeyboard.instance.addHandler((event) {
      if (state != Estado.espera) return false;

      if (stringBuffer.isNotEmpty &&
          event is KeyUpEvent &&
          event.logicalKey.keyLabel == 'Enter') {
        try {
          final code = int.parse(stringBuffer.toString());
          process(code);
        } catch (_) {
          log('Qrcode inválido!');
        }
        stringBuffer.clear();
        return false;
      }

      // Adiciona o caractere no [StringBuffer]
      if (event.character != null) {
        stringBuffer.write(event.character);
      }
      return false;
    });
  }

  @override
  void dispose() {
    HardwareKeyboard.instance.removeHandler((event) => false);
    controller.dispose();
    super.dispose();
  }

  Future<void> process(int qrcode) async {
    await [
      qrScan(qrcode),
      Future.delayed(const Duration(milliseconds: 350)),
    ].wait;
    if (attendee == null) {
      state = Estado.falha;
      falha.fire();
    } else {
      if (checkedList.contains(attendee!.checkinCode)) {
        state = Estado.checado;
        checado.fire();
      } else {
        RepositoryEven3().checkin(attendee!);
        checkedList.add(attendee!.checkinCode);
        state = Estado.sucesso;
        sucesso.fire();
      }
    }
    setState(() {});
    timer?.cancel();
    timer = Timer(
      const Duration(seconds: 3),
      () => setState(() {
        state = Estado.espera;
        espera.fire();
      }),
    );
  }

  Future<void> qrScan(int qrcode) async {
    setState(() {
      state = Estado.verificando;
      verificando.fire();
    });

    attendee = await findAttendee(qrcode);
    if (attendee == null) {
      await updateAttendees();
      attendee = await findAttendee(qrcode);
    }
  }

  Future<void> updateAttendees() async {
    final data = await RepositoryEven3().getAttendees();
    if (data.isEmpty) return;
    attendees.clear();
    attendees.addAll(data);
  }

  Future<Attendee?> findAttendee(int qrcode) async {
    for (final pessoa in attendees) {
      if (pessoa.checkinCode == qrcode) return pessoa;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        color: switch (state) {
          Estado.verificando || Estado.espera => Colors.white,
          Estado.sucesso => Colors.green,
          Estado.falha => Colors.red,
          Estado.checado => Colors.amber,
        },
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              children: [
                SizedBox(
                  height: 180,
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: AnimatedCrossFade(
                      firstChild: Image.asset(
                        'assets/images/simtec2024.webp',
                      ),
                      secondChild: Image.asset(
                        'assets/images/simtec2024-2.webp',
                      ),
                      crossFadeState: switch (state) {
                        Estado.espera ||
                        Estado.verificando =>
                          CrossFadeState.showFirst,
                        _ => CrossFadeState.showSecond,
                      },
                      duration: const Duration(milliseconds: 350),
                      firstCurve: Curves.easeOut,
                      secondCurve: Curves.easeIn,
                      sizeCurve: Curves.easeInOut,
                      alignment: Alignment.center,
                    ),
                  ),
                ),
                Expanded(
                  child: rive.RiveAnimation.asset(
                    'assets/qrcode.riv',
                    fit: BoxFit.contain,
                    onInit: onRiveInit,
                  ),
                ),
                SizedBox(
                  height: 160,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: FittedBox(
                      child: switch (state) {
                        Estado.espera => const Text(
                            'Faça seu Check-in',
                            style: TextStyle(
                              color: Color(0XFF196a44),
                              fontWeight: FontWeight.bold,
                              fontFamily: 'Rubik',
                            ),
                          ),
                        Estado.verificando => null,
                        Estado.sucesso => Text(
                            attendee!.name,
                            style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'Rubik'),
                          ),
                        Estado.falha => const Text(
                            'Participante não encontado!',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'Rubik',
                            ),
                          ),
                        Estado.checado => const Text(
                            'Check-in OK',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'Rubik'),
                          ),
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
