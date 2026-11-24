import 'package:flutter/material.dart';
import '../services/database_helper.dart';
import '../utils/money_scope.dart';

class ThemeCustomizationScreen extends StatelessWidget {
  const ThemeCustomizationScreen({super.key});

  static const List<int> _themePalette = [
    DatabaseHelper.defaultPrimaryPurple, // Viola Default (0xFF6A1B9A)
    0xFF4A148C, // Viola Scuro
    0xFF7E57C2, // Lavanda / Viola Chiaro
    DatabaseHelper.defaultSecondaryGreen, // Verde Default (0xFF2E7D32)
    0xFF00897B, // Verde Acqua (Teal)
    0xFF43A047, // Verde Brillante
    0xFF1E88E5, // Blu
    0xFF283593, // Blu Notte
    0xFFD81B60, // Magenta
    DatabaseHelper.defaultExpenseColor, // Rosso (0xFFD32F2F)
    0xFFFB8C00, // Arancione
    0xFF546E7A, // Grigio Ardesia
  ];

  @override
  Widget build(BuildContext context) {
    final provider = MoneyScope.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Personalizzazione & Colori'),
        actions: [
          TextButton.icon(
            onPressed: () => provider.resetDefaultThemeColors(),
            icon: const Icon(Icons.restore, color: Colors.white, size: 18),
            label: const Text(
              'Reset Default',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'MODALITÀ TEMA',
            style: Theme.of(context).textTheme.labelLarge,
          ),
          const SizedBox(height: 8),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                width: double.infinity,
                child: SegmentedButton<ThemeMode>(
                  segments: const [
                    ButtonSegment(
                      value: ThemeMode.system,
                      label: Text('Auto'),
                      icon: Icon(Icons.brightness_auto, size: 18),
                    ),
                    ButtonSegment(
                      value: ThemeMode.light,
                      label: Text('Chiaro'),
                      icon: Icon(Icons.light_mode_outlined, size: 18),
                    ),
                    ButtonSegment(
                      value: ThemeMode.dark,
                      label: Text('Scuro'),
                      icon: Icon(Icons.dark_mode_outlined, size: 18),
                    ),
                  ],
                  selected: {provider.themeMode},
                  onSelectionChanged: (sel) => provider.setThemeMode(sel.first),
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),

          Text(
            'COLORI DELL\'APPLICAZIONE',
            style: Theme.of(context).textTheme.labelLarge,
          ),
          const SizedBox(height: 8),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Colore Principale App (Default: Viola)',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Usato per la barra superiore e gli elementi principali.',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  const SizedBox(height: 12),
                  _ColorPickerRow(
                    palette: _themePalette,
                    selectedColorValue: provider.primaryColorValue,
                    onSelect: (c) => provider.setPrimaryColor(c),
                  ),
                  const Divider(height: 28),

                  const Text(
                    'Colore Secondario & Entrate (Default: Verde)',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Usato per il pulsante "+ Movimento", le entrate e i saldi positivi.',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  const SizedBox(height: 12),
                  _ColorPickerRow(
                    palette: _themePalette,
                    selectedColorValue: provider.secondaryColorValue,
                    onSelect: (c) => provider.setSecondaryColor(c),
                  ),
                  const Divider(height: 28),

                  const Text(
                    'Colore Uscite & Spese',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Usato per evidenziare spese, addebiti e passività.',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  const SizedBox(height: 12),
                  _ColorPickerRow(
                    palette: _themePalette,
                    selectedColorValue: provider.expenseColorValue,
                    onSelect: (c) => provider.setExpenseColor(c),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          OutlinedButton.icon(
            onPressed: () => provider.resetDefaultThemeColors(),
            icon: const Icon(Icons.restore),
            label: const Text('Ripristina Combinazione Viola & Verde'),
          ),
        ],
      ),
    );
  }
}

class _ColorPickerRow extends StatelessWidget {
  final List<int> palette;
  final int selectedColorValue;
  final ValueChanged<int> onSelect;

  const _ColorPickerRow({
    required this.palette,
    required this.selectedColorValue,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: palette.map((col) {
        final isSelected = col == selectedColorValue;
        return InkWell(
          onTap: () => onSelect(col),
          borderRadius: BorderRadius.circular(20),
          child: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: Color(col),
              shape: BoxShape.circle,
              border: isSelected
                  ? Border.all(
                      color: Theme.of(context).colorScheme.onSurface,
                      width: 3,
                    )
                  : null,
            ),
            child: isSelected
                ? const Icon(
                    Icons.check,
                    size: 18,
                    color: Colors.white,
                  )
                : null,
          ),
        );
      }).toList(),
    );
  }
}
