# My Money Manager 🐷💳

Applicazione mobile e desktop multipiattaforma (**Android, iOS, Web & Windows**) sviluppata in **Flutter**, ispirata a *Money Manager* con automazioni bancarie attivabili da **Impostazioni**.

---

## ✨ Funzionalità Implementate

1. **Gestione Multi-Conto**
   - Gestione separata di *Contanti*, *Conto Corrente Bancario*, *Carte* e *Risparmi*.
   - Calcolo automatico del patrimonio totale e del saldo di ogni singolo conto.
2. **Partita Doppia: Uscite, Entrate e Trasferimenti**
   - Inserimento rapido di spese ed entrate categorizzate.
   - Supporto per i **Trasferimenti tra conti** (es. prelievo dal Bancomat verso i Contanti senza alterare il bilancio mensile delle spese).
3. **Importazione Rapida CSV / Excel della Banca (Attivabile in Impostazioni)**
   - Modulo `CsvImportService` che legge i tracciati CSV esportati dall'home banking (`Data;Descrizione;Importo`).
   - **Prevenzione duplicati**: ignora automaticamente le righe CSV già importate in precedenza.
   - **Auto-Categorizzazione Intelligente** (`SmartCategorizer`): riconosce l'esercente/causale (es. `ESSELUNGA` → *Alimentari*, `ENI` → *Trasporti*, `NETFLIX` → *Svago*, `STIPENDIO` → *Stipendio*).
4. **Lettura Notifiche Pagamenti su Android (Facoltativa con Flag in Impostazioni)**
   - Modulo `NotificationReaderService` che analizza il testo delle notifiche push dell'app bancaria o di Google Wallet (es. *"Hai effettuato un pagamento POS di 18,50 € presso PIZZERIA DA MICHELE"*), estrae importo ed esercente e registra la spesa in automatico.
5. **Statistiche Mensili**
   - Raggruppamento e calcolo delle percentuali di spesa per categoria con barre di distribuzione visive.

---

## 📂 Struttura del Progetto

```text
my-money-manager/
├── lib/
│   ├── main.dart                         # Entry point e configurazione Tema Material 3
│   ├── models/
│   │   ├── account.dart                  # Modello Conto (Contanti, Banca, IBAN)
│   │   ├── category.dart                 # Categorie predefinite con icone e colori
│   │   └── transaction.dart              # Modello Movimento (Manuale, da CSV, da Notifica)
│   ├── services/
│   │   ├── database_helper.dart          # Persistenza locale multipiattaforma
│   │   ├── smart_categorizer.dart        # Motore di categorizzazione automatica
│   │   ├── csv_import_service.dart       # Parser tracciati CSV bancari con deduplicazione
│   │   └── notification_reader_service.dart # Parser notifiche push bancarie / Google Pay
│   ├── providers/
│   │   └── money_provider.dart           # State Management (saldi, filtri mensili, flag impostazioni)
│   └── screens/
│       ├── main_navigation_screen.dart   # Navigazione a 4 tab (Movimenti, Statistiche, Conti, Impostazioni)
│       ├── transactions_screen.dart      # Dashboard mensile con Entrate, Uscite e Lista
│       ├── add_transaction_screen.dart   # Form di inserimento (Uscita / Entrata / Trasferimento)
│       ├── accounts_screen.dart          # Riepilogo Conti e finestra di Importazione CSV
│       ├── stats_screen.dart             # Statistiche percentuali per categoria
│       └── settings_screen.dart          # Flag facoltativi per Import CSV e Lettura Notifiche
└── pubspec.yaml                          # Dipendenze Flutter
```

---

## 🚀 Come Avviare il Progetto

1. Entra nella cartella del progetto:
   ```bash
   cd C:\Users\Andrea.Garro\.gemini\antigravity\scratch\my-money-manager
   ```
2. Genera i file di piattaforma Flutter e scarica le dipendenze:
   ```bash
   flutter create .
   flutter pub get
   ```
3. Avvia l'app (su Chrome, Windows Desktop o Android):
   ```bash
   flutter run -d chrome
   ```
