import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../services/sessio.dart';

/// Entrada con código del correo: en el campo es más robusto que un enlace que tiene que
/// volver a la app, y funciona aunque el correo se lea en otro dispositivo.
class EntradaScreen extends StatefulWidget {
  const EntradaScreen({super.key});

  @override
  State<EntradaScreen> createState() => _EntradaScreenState();
}

class _EntradaScreenState extends State<EntradaScreen> {
  final _correu = TextEditingController();
  final _codi = TextEditingController();
  bool _codiEnviat = false;
  bool _treballant = false;
  String? _error;

  @override
  void dispose() {
    _correu.dispose();
    _codi.dispose();
    super.dispose();
  }

  bool get _valid => _codiEnviat ? _codi.text.trim().length == 6 : _correu.text.contains('@');

  Future<void> _fer(Future<void> Function() accio, String missatgeError) async {
    setState(() {
      _treballant = true;
      _error = null;
    });
    try {
      await accio();
    } catch (_) {
      if (mounted) setState(() => _error = missatgeError);
    } finally {
      if (mounted) setState(() => _treballant = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = L.of(context);
    final sessio = context.read<Sessio>();
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // El texto del logo es oscuro: en modo oscuro no se leería sin fondo
                  Center(
                    child: DecoratedBox(
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8)),
                      child: Padding(
                        padding: const EdgeInsets.all(8),
                        child: Image.asset('assets/logo.png', height: 48),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  Text(t.entradaTitol, style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 8),
                  Text(_codiEnviat ? t.entradaCodiEnviat(_correu.text.trim()) : t.entradaExplicacio),
                  const SizedBox(height: 16),
                  if (!_codiEnviat)
                    TextField(
                      controller: _correu,
                      onChanged: (_) => setState(() {}),
                      keyboardType: TextInputType.emailAddress,
                      autofillHints: const [AutofillHints.email],
                      decoration: InputDecoration(labelText: t.entradaCorreu),
                    )
                  else
                    TextField(
                      controller: _codi,
                      onChanged: (_) => setState(() {}),
                      keyboardType: TextInputType.number,
                      autofillHints: const [AutofillHints.oneTimeCode],
                      maxLength: 6,
                      decoration: InputDecoration(labelText: t.entradaCodi),
                    ),
                  if (_error != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
                    ),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: _treballant || !_valid
                        ? null
                        : () => _codiEnviat
                            ? _fer(() => sessio.verificarCodi(_correu.text.trim(), _codi.text.trim()), t.entradaCodiErroni)
                            : _fer(() async {
                                await sessio.demanarCodi(_correu.text.trim());
                                if (mounted) setState(() => _codiEnviat = true);
                              }, t.comuError),
                    child: Text(_codiEnviat ? t.entradaVerificar : t.entradaEnviar),
                  ),
                  if (_codiEnviat)
                    TextButton(
                      onPressed: () => setState(() {
                        _codiEnviat = false;
                        _codi.clear();
                        _error = null;
                      }),
                      child: Text(t.entradaAltreCorreu),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Primer acceso: sin alias, la coordinación no sabría quién es.
Future<void> demanarAlies(BuildContext context) => showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const _DialegAlies(),
    );

class _DialegAlies extends StatefulWidget {
  const _DialegAlies();

  @override
  State<_DialegAlies> createState() => _DialegAliesState();
}

class _DialegAliesState extends State<_DialegAlies> {
  final _nom = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _nom.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = L.of(context);
    return PopScope(
      canPop: false,
      child: AlertDialog(
        title: Text(t.aliesTitol),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(t.aliesExplicacio),
            const SizedBox(height: 12),
            TextField(controller: _nom, maxLength: 40, decoration: InputDecoration(labelText: t.aliesCamp, errorText: _error)),
          ],
        ),
        actions: [
          FilledButton(
            onPressed: () async {
              final nom = _nom.text.trim();
              if (nom.isEmpty) return;
              final navegador = Navigator.of(context);
              try {
                await context.read<Sessio>().desarAlies(nom);
                navegador.pop();
              } catch (_) {
                setState(() => _error = t.comuError);
              }
            },
            child: Text(t.aliesDesar),
          ),
        ],
      ),
    );
  }
}
