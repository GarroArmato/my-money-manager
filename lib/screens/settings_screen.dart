import 'package:flutter/material.dart';
import '../models/category.dart';
import '../services/notification_reader_service.dart';
import '../utils/money_scope.dart';
import '../widgets/app_top_bar.dart';
import 'accounts_screen.dart';
import 'categories_screen.dart';
import 'theme_customization_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  Future<void> _showNotificationSimulatorDialog(BuildContext context) async {
    final provider = MoneyScope.read(context);
    final bankAccount = provider.accounts.firstWhere(
      (a) => a.groupId == 'grp_bank',
      orElse: () => provider.accounts.first,
    );
    final controller = TextEditingController(
      text: NotificationReaderService.sampleBankNotifications.first,
    );

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            return AlertDialog(
              title: const Text('Simulatore Notifica Bancaria'),
              content: SizedBox(
                width: 440,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Seleziona o modifica il testo di una notifica push per testare la creazione automatica della spesa:',
                      style: TextStyle(fontSize: 13),
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
                          label: Text(label),
                          onPressed: () {
                            setDialogState(() {
                              controller.text = sample;
                            });
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: controller,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: 'Testo della notifica',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: const Text('Chiudi'),
                ),
                FilledButton.icon(
                  onPressed: () async {
                    final tx = await provider.processBankNotification(
                      notificationText: controller.text,
                      accountId: bankAccount.id,
                    );
                    if (dialogContext.mounted) {
                      Navigator.of(dialogContext).pop();
                    }
                    if (context.mounted) {
                      final cat = provider.getCategoryById(tx?.categoryId);
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
                  label: const Text('Simula Notifica'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = MoneyScope.of(context);

    return Scaffold(
      appBar: const AppTopBar(
        title: 'Impostazioni',
        icon: Icons.tune_outlined,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 88),
        children: [
          // 1. SOTTOMENU PERSONALIZZAZIONE & COLORI
          Text(
            'PERSONALIZZAZIONE',
            style: Theme.of(context).textTheme.labelLarge,
          ),
          const SizedBox(height: 8),
          Card(
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: provider.primaryColor.withValues(alpha: 0.15),
                child: Icon(Icons.palette_outlined, color: provider.primaryColor),
              ),
              title: const Text(
                'Aspetto, Tema e Colori',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: const Text(
                'Tema chiaro/scuro e colori personalizzati (Default: Viola & Verde)',
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _ColorDot(color: provider.primaryColor),
                  const SizedBox(width: 4),
                  _ColorDot(color: provider.secondaryColor),
                  const SizedBox(width: 8),
                  const Icon(Icons.chevron_right),
                ],
              ),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const ThemeCustomizationScreen(),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 20),

          // 2. CATEGORIE, GRUPPI E CONTI
          Text(
            'GESTIONE CATEGORIE E CONTI',
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
                    '${provider.expenseCategories.length} categorie configurate',
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
                    '${provider.incomeCategories.length} categorie configurate',
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
                    'Nuovo Gruppo di Conti',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    '${provider.accountGroups.length} gruppi attivi',
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
                    'Nuovo Conto',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    '${provider.accounts.length} conti attivi',
                  ),
                  trailing: const Icon(Icons.add),
                  onTap: () => showAccountEditorDialog(context),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // 3. COLLEGAMENTO BANCA (FACOLTATIVO)
          Text(
            'AUTOMAZIONI BANCARIE (FACOLTATIVE)',
            style: Theme.of(context).textTheme.labelLarge,
          ),
          const SizedBox(height: 8),
          Card(
            child: Column(
              children: [
                SwitchListTile(
                  secondary: const CircleAvatar(
                    child: Icon(Icons.upload_file),
                  ),
                  title: const Text(
                    'Importazione CSV / Excel Banca',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: const Text(
                    'Abilita il tasto "Importa CSV" nei conti bancari e carte.',
                  ),
                  value: provider.enableCsvImport,
                  onChanged: (val) => provider.toggleCsvImport(val),
                ),
                const Divider(height: 1),
                SwitchListTile(
                  secondary: const CircleAvatar(
                    child: Icon(Icons.notifications_active_outlined),
                  ),
                  title: const Text(
                    'Lettura Notifiche Pagamenti',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: const Text(
                    'Registra automaticamente le spese dalle notifiche push della banca.',
                  ),
                  value: provider.enableNotificationReader,
                  onChanged: (val) => provider.toggleNotificationReader(val),
                ),
                if (provider.enableNotificationReader) ...[
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.science_outlined),
                    title: const Text('Testa Simulatore Notifica Push'),
                    trailing: const Icon(Icons.play_arrow),
                    onTap: () => _showNotificationSimulatorDialog(context),
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

class _ColorDot extends StatelessWidget {
  final Color color;

  const _ColorDot({required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 16,
      height: 16,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 1.5),
      ),
    );
  }
}
