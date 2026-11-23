import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/account.dart';
import '../providers/money_provider.dart';
import '../services/notification_reader_service.dart';

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
    final provider = context.watch<MoneyProvider>();
    final bankAccount = provider.accounts.firstWhere(
      (a) => a.type == AccountType.bankAccount,
      orElse: () => provider.accounts.first,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Impostazioni & Automazioni'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
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
                'Mostra nei conti bancari il pulsante per importare e categorizzare i file CSV scaricati dall\'home banking.',
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
