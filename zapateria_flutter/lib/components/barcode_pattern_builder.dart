import 'package:flutter/material.dart';
import 'package:zapateria_flutter/models/models.dart';

const Map<SegmentoTipo, Color> segmentoColor = {
  SegmentoTipo.fijo: Colors.blue,
  SegmentoTipo.modelo: Colors.green,
  SegmentoTipo.lote: Colors.grey,
  SegmentoTipo.talla: Colors.orange,
};

/// Concatena los segmentos fijo+modelo de [segmentos] aplicados sobre [codigo].
/// Misma lógica que el backend (ZapatoService.findByCodigoBarrasSmart).
String computeCodigoNormalizado(List<BarcodeSegmentoModel> segmentos, String codigo) {
  final buffer = StringBuffer();
  for (final s in segmentos) {
    if (s.tipo != SegmentoTipo.fijo && s.tipo != SegmentoTipo.modelo) continue;
    if (s.inicio + s.longitud > codigo.length) return '';
    buffer.write(codigo.substring(s.inicio, s.inicio + s.longitud));
  }
  return buffer.toString();
}

/// Extrae la talla del segmento `talla` de [segmentos] aplicado sobre [codigo].
double? extractTalla(List<BarcodeSegmentoModel> segmentos, String codigo) {
  final tallaSeg = segmentos.where((s) => s.tipo == SegmentoTipo.talla).firstOrNull;
  if (tallaSeg == null) return null;
  if (tallaSeg.inicio + tallaSeg.longitud > codigo.length) return null;
  final str = codigo.substring(tallaSeg.inicio, tallaSeg.inicio + tallaSeg.longitud);
  return double.tryParse(str);
}

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}

/// Fila de caracteres coloreados según los segmentos ya asignados. Uso de solo
/// lectura, compartido entre el builder interactivo y la vista de extracción.
class BarcodeSegmentedPreview extends StatelessWidget {
  final String codigo;
  final List<BarcodeSegmentoModel> segmentos;
  final int? highlightEnd;
  final void Function(int index)? onTapChar;

  const BarcodeSegmentedPreview({
    super.key,
    required this.codigo,
    required this.segmentos,
    this.highlightEnd,
    this.onTapChar,
  });

  SegmentoTipo? _tipoEn(int index) {
    for (final s in segmentos) {
      if (index >= s.inicio && index < s.inicio + s.longitud) return s.tipo;
    }
    return null;
  }

  int get _taggedLength =>
      segmentos.fold(0, (sum, s) => sum + s.longitud);

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 2,
      runSpacing: 4,
      children: List.generate(codigo.length, (i) {
        final tipo = _tipoEn(i);
        final pendiente = highlightEnd != null && i >= _taggedLength && i <= highlightEnd!;
        final tappable = onTapChar != null && tipo == null;
        final color = tipo != null
            ? segmentoColor[tipo]!
            : (pendiente ? Colors.amber : Colors.grey.shade300);
        final chip = Container(
          width: 22,
          height: 28,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: color.withOpacity(tipo != null ? 0.25 : (pendiente ? 0.5 : 0.15)),
            border: Border.all(color: color),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            codigo[i],
            style: const TextStyle(fontFamily: 'monospace', fontWeight: FontWeight.bold),
          ),
        );
        if (!tappable) return chip;
        return InkWell(
          borderRadius: BorderRadius.circular(4),
          onTap: () => onTapChar!(i),
          child: chip,
        );
      }),
    );
  }
}

class _LeyendaSegmentos extends StatelessWidget {
  const _LeyendaSegmentos();

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 12,
      children: SegmentoTipo.values.map((tipo) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: segmentoColor[tipo],
                borderRadius: BorderRadius.circular(3),
              ),
            ),
            const SizedBox(width: 4),
            Text(tipo.label, style: const TextStyle(fontSize: 12)),
          ],
        );
      }).toList(),
    );
  }
}

/// Componente interactivo para definir el patrón de código de barras de una
/// marca: el usuario pega un código de ejemplo y va tocando hasta dónde llega
/// cada segmento (fijo/modelo/lote/talla), de izquierda a derecha. La talla
/// siempre es el último segmento y consume el resto del código.
class BarcodePatternBuilder extends StatefulWidget {
  final String? initialCodigoEjemplo;
  final List<BarcodeSegmentoModel>? initialSegmentos;
  final void Function(String codigo, List<BarcodeSegmentoModel> segmentos, bool esValido)
      onChanged;

  const BarcodePatternBuilder({
    super.key,
    this.initialCodigoEjemplo,
    this.initialSegmentos,
    required this.onChanged,
  });

  @override
  State<BarcodePatternBuilder> createState() => _BarcodePatternBuilderState();
}

class _BarcodePatternBuilderState extends State<BarcodePatternBuilder> {
  late TextEditingController _codigoCtrl;
  late List<BarcodeSegmentoModel> _segmentos;
  int? _selectionEnd;

  bool get _tallaAsignada => _segmentos.any((s) => s.tipo == SegmentoTipo.talla);
  int get _taggedLength => _segmentos.fold(0, (sum, s) => sum + s.longitud);
  String get _codigo => _codigoCtrl.text.trim();

  bool get _esValido =>
      _codigo.isNotEmpty &&
      _segmentos.isNotEmpty &&
      _segmentos.last.tipo == SegmentoTipo.talla &&
      _segmentos.any((s) => s.tipo == SegmentoTipo.fijo || s.tipo == SegmentoTipo.modelo);

  @override
  void initState() {
    super.initState();
    _codigoCtrl = TextEditingController(text: widget.initialCodigoEjemplo ?? '');
    _segmentos = List.of(widget.initialSegmentos ?? const []);
    WidgetsBinding.instance.addPostFrameCallback((_) => _notify());
  }

  @override
  void dispose() {
    _codigoCtrl.dispose();
    super.dispose();
  }

  void _notify() {
    widget.onChanged(_codigo, _segmentos, _esValido);
  }

  void _onCodigoChanged(String _) {
    setState(() {
      _segmentos = [];
      _selectionEnd = null;
    });
    _notify();
  }

  void _onTapChar(int index) {
    if (_tallaAsignada || index < _taggedLength) return;
    setState(() => _selectionEnd = index);
  }

  void _asignarTipo(SegmentoTipo tipo) {
    if (_selectionEnd == null) return;
    final inicio = _taggedLength;
    final longitud = tipo == SegmentoTipo.talla
        ? _codigo.length - inicio
        : _selectionEnd! - inicio + 1;
    setState(() {
      _segmentos = [..._segmentos, BarcodeSegmentoModel(tipo: tipo, inicio: inicio, longitud: longitud)];
      _selectionEnd = null;
    });
    _notify();
  }

  void _deshacer() {
    if (_segmentos.isEmpty) return;
    setState(() {
      _segmentos = _segmentos.sublist(0, _segmentos.length - 1);
      _selectionEnd = null;
    });
    _notify();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          controller: _codigoCtrl,
          decoration: const InputDecoration(
            labelText: 'Código de barras de ejemplo',
            helperText: 'Pega un código real de un producto de esta marca',
            border: OutlineInputBorder(),
          ),
          onChanged: _onCodigoChanged,
        ),
        const SizedBox(height: 12),
        if (_codigo.isNotEmpty) ...[
          BarcodeSegmentedPreview(
            codigo: _codigo,
            segmentos: _segmentos,
            highlightEnd: _selectionEnd,
            onTapChar: _tallaAsignada ? null : _onTapChar,
          ),
          const SizedBox(height: 8),
          const _LeyendaSegmentos(),
          const SizedBox(height: 12),
          if (_selectionEnd != null)
            Wrap(
              spacing: 8,
              children: SegmentoTipo.values.map((tipo) {
                return ActionChip(
                  avatar: CircleAvatar(backgroundColor: segmentoColor[tipo], radius: 6),
                  label: Text(tipo.label),
                  onPressed: () => _asignarTipo(tipo),
                );
              }).toList(),
            )
          else if (!_tallaAsignada)
            Text(
              'Toca el último carácter del siguiente segmento (posición ${_taggedLength + 1})',
              style: Theme.of(context).textTheme.bodySmall,
            )
          else
            const Text('Patrón completo.', style: TextStyle(color: Colors.green)),
          const SizedBox(height: 8),
          Row(
            children: [
              if (_segmentos.isNotEmpty)
                TextButton.icon(
                  onPressed: _deshacer,
                  icon: const Icon(Icons.undo, size: 18),
                  label: const Text('Deshacer último segmento'),
                ),
            ],
          ),
          if (_esValido)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Text(
                'Vista previa: fijo+modelo="${computeCodigoNormalizado(_segmentos, _codigo)}"  '
                'talla="${extractTalla(_segmentos, _codigo)?.toStringAsFixed(0)}"',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
        ],
      ],
    );
  }
}
