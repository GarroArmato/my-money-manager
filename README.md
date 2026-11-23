# My Money Manager 🐷💳

Applicazione mobile multipiattaforma (**Android & iOS**) sviluppata in **Flutter**, ispirata a *Money Manager* con integrazione nativa per la sincronizzazione bancaria tramite **Open Banking (PSD2)**.

---

## ✨ Funzionalità Implementate

1. **Gestione Multi-Conto (Offline & Online)**
   - Gestione separata di *Contanti*, *Conto Corrente Bancario*, *Carte* e *Risparmi*.
   - Calcolo automatico del patrimonio totale e del saldo di ogni singolo conto.
2. **Partita Doppia: Uscite, Entrate e Trasferimenti**
   - Inserimento rapido di spese ed entrate categorizzate.
   - Supporto per i **Trasferimenti tra conti** (es. prelievo dal Bancomat verso i Contanti senza alterare il bilancio mensile delle spese).
3. **Sincronizzazione Bancaria Open Banking (PSD2)**
   - Modulo `OpenBankingService` compatibile con il formato JSON standard europeo PSD2 (es. *GoCardless Bank Account Data* / *Nordigen*).
   - **Prevenzione duplicati**: ogni movimento bancario è identificato dal suo `externalBankTransactionId` univoco nel database SQLite.
   - **Auto-Categorizzazione Intelligente**: riconoscimento automatico dell'esercente/causale (es. `ESSELUNGA` → *Alimentari*, `ENI` → *Trasporti*, `NETFLIX` → *Svago*, `STIPENDIO` → *Stipendio*).
4. **Statistiche Mensili**
   - Raggruppamento e calcolo delle percentuali di spesa per categoria con barre di distribuzione visive.

---

## 📂 Struttura del Progetto

```text
my-money-manager/
├── lib/
│   ├── main.dart                         # Entry point e configurazione Tema Material 3
│   ├── models/
│   │   ├── account.dart                  # Modello Conto (Contanti, Banca, IBAN, PSD2 ID)
│   │   ├── category.dart                 # Categorie predefinite con icone e colori
│   │   └── transaction.dart              # Modello Movimento (Uscita, Entrata, Trasferimento)
│   ├── services/
│   │   ├── database_helper.dart          # Persistenza locale offline-first su SQLite
│   │   └── open_banking_service.dart     # Client PSD2 e motore di auto-categorizzazione
│   ├── providers/
│   │   └── money_provider.dart           # State Management (saldi, filtri mensili, sync banca)
│   └── screens/
│       ├── main_navigation_screen.dart   # Navigazione principale e Floating Action Button
│       ├── transactions_screen.dart      # Dashboard mensile con Entrate, Uscite e Lista
│       ├── add_transaction_screen.dart   # Form di inserimento (Uscita / Entrata / Trasferimento)
│       ├── accounts_screen.dart          # Riepilogo Conti e pulsante Sincronizzazione PSD2
│       └── stats_screen.dart             # Statistiche percentuali per categoria
└── pubspec.yaml                          # Dipendenze Flutter (sqflite, provider, intl, http)
```

---

## 🚀 Come Avviare il Progetto

1. Assicurati di avere installato il [Flutter SDK](https://docs.flutter.dev/get-started/install).
2. Clona il repository ed entra nella cartella:
   ```bash
   git clone https://github.com/GarroArmato/my-money-manager.git
   cd my-money-manager
   ```
3. Scarica le dipendenze e genera le cartelle piattaforma (se non presenti):
   ```bash
   flutter create .
   flutter pub get
   ```
4. Avvia l'app su emulatore Android, iOS o dispositivo fisico:
   ```bash
   flutter run
   ```
