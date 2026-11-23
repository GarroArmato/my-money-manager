import 'package:flutter/material.dart';
import '../models/category.dart';
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
          // Sezione Categorie & Conti in stile Money Manager
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
                    backgroundColor: Colors.red.withValues(alpha: 0.15),
                    child: Icon(Icons.arrow_upward, color: Colors.red.shade700),
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
                    backgroundColor: Colors.green.withValues(alpha: 0.15),
                    child: Icon(Icons.arrow_downward,
                        color: Colors.green.shade700),
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

                // Pannello di prova visibile solo quando il flag è attivo
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
