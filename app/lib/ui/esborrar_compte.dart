import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../services/paquets.dart';
import '../services/sessio.dart';
import '../services/sincronitzacio.dart';
import 'adaptatiu.dart';

// Esborrar el compte des de la app (RGPD art. 17; App Store 5.1.1(v); Google Play).
// Primer el servidor (supabase/migrations/20261120000001_esborrar_compte.sql) i, si ha anat bé,
// el que hi ha en el dispositiu: aportacions i revisions sense enviar i els mapes descarregats.

const _paraula = 'ESBORRA';

Future<void> obrirEsborrarCompte(BuildContext context) =>
    Navigator.of(context, rootNavigator: true).push(MaterialPageRoute<void>(
      fullscreenDialog: true,
      builder: (_) => const PantallaEsborrarCompte(),
    ));

class PantallaEsborrarCompte extends StatefulWidget {
  const PantallaEsborrarCompte({super.key});

  @override
  State<PantallaEsborrarCompte> createState() => _PantallaEsborrarCompteState();
}

class _PantallaEsborrarCompteState extends State<PantallaEsborrarCompte> {
  final _confirmacio = TextEditingController();
  bool _esborrant = false;
  bool _error = false;

  @override
  void initState() {
    super.initState();
    _confirmacio.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _confirmacio.dispose();
    super.dispose();
  }

  bool get _confirmat => _confirmacio.text.trim().toUpperCase() == _paraula;

  Future<void> _esborrar() async {
    final t = L.of(context);
    final sessio = context.read<Sessio>();
    final sinc = context.read<Sincronitzacio>();
    final paquets = context.read<Paquets>();
    final navegador = Navigator.of(context);
    final avis = ScaffoldMessenger.of(context);
    setState(() {
      _esborrant = true;
      _error = false;
    });
    try {
      await sessio.esborrarCompte();
    } catch (e) {
      debugPrint('Esborrar el compte: $e');
      if (mounted) {
        setState(() {
          _esborrant = false;
          _error = true;
        });
      }
      return;
    }
    // El compte ja no existeix: fora també el que hi ha en el dispositiu
    try {
      await sinc.buidar();
      await paquets.esborrarTot();
    } catch (e) {
      debugPrint('Dades locals sense esborrar del tot: $e');
    }
    // Primer es tanca esta pantalla; després, en tancar la sessió, el router porta a l'entrada
    navegador.pop();
    avis.showSnackBar(SnackBar(content: Text(t.compteEsborrat)));
    await sessio.tancarLocal();
  }

  @override
  Widget build(BuildContext context) {
    final t = L.of(context);
    final cs = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(title: Text(t.compteEsborrarTitol)),
      body: Centrat(
        maxim: ampladaFormulari,
        base: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        builder: (context, farciment) => ListView(
          padding: farciment,
          children: [
            Text(t.compteEsborraEs, style: text.titleMedium),
            const SizedBox(height: 8),
            for (final s in [t.compteEsborraCompte, t.compteEsborraPendents, t.compteEsborraAvisos, t.compteEsborraDispositiu])
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Padding(padding: const EdgeInsets.only(top: 2, right: 8), child: Icon(Icons.close, size: 18, color: cs.error)),
                  Expanded(child: Text(s, style: text.bodyLarge)),
                ]),
              ),
            const SizedBox(height: 12),
            Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Padding(padding: const EdgeInsets.only(top: 2, right: 8), child: Icon(Icons.public, size: 18, color: cs.primary)),
              Expanded(child: Text(t.compteEsQueda, style: text.bodyLarge)),
            ]),
            const SizedBox(height: 16),
            Text(t.compteDadesWeb, style: text.bodyMedium?.copyWith(color: cs.onSurfaceVariant)),
            const SizedBox(height: 20),
            Text(t.compteIrreversible, style: text.titleSmall?.copyWith(color: cs.error)),
            const SizedBox(height: 12),
            TextField(
              controller: _confirmacio,
              enabled: !_esborrant,
              autocorrect: false,
              textCapitalization: TextCapitalization.characters,
              decoration: InputDecoration(labelText: t.compteEscriu(_paraula)),
            ),
            if (_error) ...[
              const SizedBox(height: 12),
              Text(t.compteEsborrarError, style: TextStyle(color: cs.error)),
            ],
            const SizedBox(height: 20),
            FilledButton.icon(
              style: FilledButton.styleFrom(backgroundColor: cs.error, foregroundColor: cs.onError, minimumSize: const Size.fromHeight(52)),
              onPressed: _confirmat && !_esborrant ? _esborrar : null,
              icon: _esborrant
                  ? SizedBox.square(dimension: 18, child: CircularProgressIndicator(strokeWidth: 2, color: cs.onError))
                  : const Icon(Icons.delete_forever),
              label: Text(_esborrant ? t.compteEsborrant : t.compteEsborrarBoto),
            ),
          ],
        ),
      ),
    );
  }
}
