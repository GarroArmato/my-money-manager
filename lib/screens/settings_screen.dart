import 'package:flutter/material.dart';
import '../models/category.dart';
import '../services/database_helper.dart';
import '../services/notification_reader_service.dart';
import '../utils/money_scope.dart';
import 'accounts_screen.dart';
import 'categories_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final TextEditingController _customNotifController = TextEditingController(
    text: NotificationReaderService.sampleBankNotifications.first,
  );

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
  void dispose() {
    _customNotifController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = MoneyScope.of(context);
    final bankAccount = provider.accounts.firstWhere(
      (a) => a.groupId == 'grp_bank',
      orElse: () => provider.accounts.first,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Impostazioni'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 88),
        children: [
          // --- SEZIONE 1: ASPETTO E COLORI (DEFAULT VIOLA & VERDE) ---
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'ASPETTO E COLORI APP',
                style: Theme.of(context).textTheme.labelLarge,
              ),
              TextButton.icon(
                onPressed: () => provider.resetDefaultThemeColors(),
                icon: const Icon(Icons.restore, size: 16),
                label: const Text('Reset Viola & Verde'),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Selettore Tema Chiaro / Scuro / Sistema
                  SizedBox(
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
                      onSelectionChanged: (sel) =>
                          provider.setThemeMode(sel.first),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // 1. Colore Principale App (Default: Viola)
                  const Text(
                    'Colore Principale App (Default: Viola)',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                  const SizedBox(height: 8),
                  _ColorPickerRow(
                    palette: _themePalette,
                    selectedColorValue: provider.primaryColorValue,
                    onSelect: (c) => provider.setPrimaryColor(c),
                  ),
                  const SizedBox(height: 16),

                  // 2. Colore Secondario / Accento ed Entrate (Default: Verde)
                  const Text(
                    'Colore Secondario, Pulsanti & Entrate (Default: Verde)',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                  const SizedBox(height: 8),
                  _ColorPickerRow(
                    palette: _themePalette,
                    selectedColorValue: provider.secondaryColorValue,
                    onSelect: (c) => provider.setSecondaryColor(c),
                  ),
                  const SizedBox(height: 16),

                  // 3. Colore Uscite / Passività
                  const Text(
                    'Colore Uscite & Passività',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                  const SizedBox(height: 8),
                  _ColorPickerRow(
                    palette: _themePalette,
                    selectedColorValue: provider.expenseColorValue,
                    onSelect: (c) => provider.setExpenseColor(c),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // --- SEZIONE 2: CATEGORIE, GRUPPI E CONTI ---
          Text(
            'CATEGORIE, GRUPPI E CONTI',
            style: Theme.of(context).textTheme.labelLarge,
          ),
          const SizedBox(height: 8),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: CircleAvatar(
                    backgroundColor:
                        provider.expenseColor.withValues(alpha: 0.15),
                    child:
                        Icon(Icons.arrow_upward, color: provider.expenseColor),
                  ),
                  title: const Text(
                    'Categorie Uscite',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    '${provider.expenseCategories.length} categorie attive (aggiungi, modifica, elimina)',
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const CategoriesScreen(
                          initialKind: CategoryKind.expense,
                        ),
                      ),
                    );
                  },
                ),
                const Divider(height: 1),
                ListTile(
                  leading: CircleAvatar(
                    backgroundColor:
                        provider.secondaryColor.withValues(alpha: 0.15),
                    child: Icon(Icons.arrow_downward,
                        color: provider.secondaryColor),
                  ),
                  title: const Text(
                    'Categorie Entrate',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    '${provider.incomeCategories.length} categorie attive (aggiungi, modifica, elimina)',
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const CategoriesScreen(
                          initialKind: CategoryKind.income,
                        ),
                      ),
                    );
                  },
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const CircleAvatar(
                    child: Icon(Icons.create_new_folder_outlined),
                  ),
                  title: const Text(
                    'Crea Nuovo Gruppo di Conti',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    '${provider.accountGroups.length} gruppi attivi (es. Contanti, Banche, Carte, Crypto...)',
                  ),
                  trailing: const Icon(Icons.add),
                  onTap: () => showAccountGroupEditorDialog(context),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const CircleAvatar(
                    child: Icon(Icons.account_balance_wallet_outlined),
                  ),
                  title: const Text(
                    'Crea Nuovo Conto',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: const Text(
                    'Aggiungi un nuovo conto in qualsiasi gruppo',
                  ),
                  trailing: const Icon(Icons.add),
                  onTap: () => showAccountEditorDialog(context),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // --- SEZIONE 3: COLLEGAMENTO BANCA FACOLTATIVO ---
          Text(
            'COLLEGAMENTO BANCA (FACOLTATIVO)',
            style: Theme.of(context).textTheme.labelLarge,
          ),
          const SizedBox(height: 8),

          // Flag Punto 2: Importazione CSV / Excel della Banca
          Card(
            child: SwitchListTile(
              secondary: const CircleAvatar(
                child: Icon(Icons.upload_file),
              ),
              title: const Text(
                'Importazione CSV / Excel Banca',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: const Text(
                'Mostra nei conti abilitati il pulsante per importare e categorizzare i file CSV scaricati dall\'home banking.',
              ),
              value: provider.enableCsvImport,
              onChanged: (val) => provider.toggleCsvImport(val),
            ),
          ),
          const SizedBox(height: 12),

          // Flag Punto 3: Lettura Notifiche Bancarie / Google Pay (Android)
          Card(
            child: Column(
              children: [
                SwitchListTile(
                  secondary: const CircleAvatar(
                    child: Icon(Icons.notifications_active_outlined),
                  ),
                  title: const Text(
                    'Lettura Notifiche Pagamenti (Android)',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: const Text(
                    'Intercetta le notifiche push dell\'app della banca o Google Wallet quando paghi col POS e registra la spesa in automatico.',
                  ),
                  value: provider.enableNotificationReader,
                  onChanged: (val) => provider.toggleNotificationReader(val),
                ),

                if (provider.enableNotificationReader) ...[
                  const Divider(),
                  Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.science_outlined,
                              size: 18,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Simulatore Notifica Push Bancaria',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Prova come l\'app legge il testo di una notifica push e crea automaticamente il movimento sul conto bancario:',
                          style: TextStyle(fontSize: 12),
                        ),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: NotificationReaderService
                              .sampleBankNotifications
                              .map((sample) {
                            final label = sample.split(':').first;
                            return ActionChip(
                              label: Text('Esempio $label'),
                              onPressed: () {
                                setState(() {
                                  _customNotifController.text = sample;
                                });
                              },
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 10),
                        TextField(
                          controller: _customNotifController,
                          maxLines: 2,
                          decoration: const InputDecoration(
                            labelText: 'Testo della notifica ricevuta',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Align(
                          alignment: Alignment.centerRight,
                          child: FilledButton.tonalIcon(
                            onPressed: () async {
                              final tx =
                                  await provider.processBankNotification(
                                notificationText: _customNotifController.text,
                                accountId: bankAccount.id,
                              );
                              if (context.mounted) {
                                final cat =
                                    provider.getCategoryById(tx?.categoryId);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      tx != null
                                          ? 'Notifica letta! Creato movimento di ${tx.amount.toStringAsFixed(2)} € in "${cat?.name ?? 'Altro'}"'
                                          : 'Impossibile estrarre un importo valido dalla notifica.',
                                    ),
                                  ),
                                );
                              }
                            },
                            icon: const Icon(Icons.bolt),
                            label: const Text('Simula Arrivo Notifica'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
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
      spacing: 8,
      runSpacing: 8,
      children: palette.map((col) {
        final isSelected = col == selectedColorValue;
        return InkWell(
          onTap: () => onSelect(col),
          borderRadius: BorderRadius.circular(20),
          child: Container(
            width: 34,
            height: 34,
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
