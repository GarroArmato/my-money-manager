import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:uuid/uuid.dart';
import '../models/transaction.dart';

/// Rappresenta un movimento grezzo secondo lo standard europeo PSD2 (es. GoCardless / Nordigen)
class Psd2RawTransaction {
  final String externalId;
  final DateTime bookingDate;
  final double signedAmount; // Negativo per uscite, positivo per entrate
  final String remittanceInfo;
  final String? merchantName;

  Psd2RawTransaction({
    required this.externalId,
    required this.bookingDate,
    required this.signedAmount,
    required this.remittanceInfo,
    this.merchantName,
  });

  factory Psd2RawTransaction.fromGoCardlessJson(Map<String, dynamic> json) {
    final txAmount = json['transactionAmount'] as Map<String, dynamic>;
    return Psd2RawTransaction(
      externalId: json['transactionId'] as String,
      bookingDate: DateTime.parse(json['bookingDate'] as String),
      signedAmount: double.parse(txAmount['amount'].toString()),
      remittanceInfo:
          (json['remittanceInformationUnstructured'] as String?) ?? '',
      merchantName: json['creditorName'] as String?,
    );
  }
}

class OpenBankingService {
  final String backendBaseUrl;
  static const _uuid = Uuid();

  OpenBankingService({
    this.backendBaseUrl = 'http://localhost:8080/api/openbanking',
  });

  /// Motore di categorizzazione automatica basato sulla causale bancaria
  static String autoCategorize(String description, bool isIncome) {
    final upper = description.toUpperCase();

    if (isIncome) {
      if (upper.contains('STIPENDIO') ||
          upper.contains('EMOLUMENTI') ||
          upper.contains('SALARIO')) {
        return 'cat_salary';
      }
      return 'cat_other_income';
    }

    // Regole per le uscite
    if (upper.contains('ESSELUNGA') ||
        upper.contains('CONAD') ||
        upper.contains('COOP') ||
        upper.contains('CARREFOUR') ||
        upper.contains('LIDL')) {
      return 'cat_food';
    }
    if (upper.contains('RISTORANTE') ||
        upper.contains('PIZZERIA') ||
        upper.contains('BAR ') ||
        upper.contains('DELIVEROO') ||
        upper.contains('GLOVO') ||
        upper.contains('MC DONALD')) {
      return 'cat_restaurant';
    }
    if (upper.contains('ENI ') ||
        upper.contains('Q8') ||
        upper.contains('IP ') ||
        upper.contains('TRENITALIA') ||
        upper.contains('ITALO') ||
        upper.contains('TELEPASS') ||
        upper.contains('ATM ')) {
      return 'cat_transport';
    }
    if (upper.contains('ENEL') ||
        upper.contains('ENI PLENITUDE') ||
        upper.contains('TIM ') ||
        upper.contains('VODAFONE') ||
        upper.contains('ILIAD') ||
        upper.contains('AFFITTO')) {
      return 'cat_home';
    }
    if (upper.contains('NETFLIX') ||
        upper.contains('SPOTIFY') ||
        upper.contains('CINEMA') ||
        upper.contains('STEAM') ||
        upper.contains('PLAYSTATION')) {
      return 'cat_entertainment';
    }

    return 'cat_shopping';
  }

  /// Converte i movimenti PSD2 grezzi in oggetti MoneyTransaction pronti per SQLite
  List<MoneyTransaction> mapPsd2ToTransactions(
    List<Psd2RawTransaction> rawList,
    String targetAccountId,
  ) {
    return rawList.map((raw) {
      final isIncome = raw.signedAmount >= 0;
      final absAmount = raw.signedAmount.abs();
      final combinedDesc = [
        if (raw.merchantName != null) raw.merchantName!,
        raw.remittanceInfo,
      ].join(' - ').trim();

      return MoneyTransaction(
        id: _uuid.v4(),
        amount: absAmount,
        date: raw.bookingDate,
        type: isIncome ? TransactionType.income : TransactionType.expense,
        accountId: targetAccountId,
        categoryId: autoCategorize(combinedDesc, isIncome),
        note: combinedDesc,
        merchantName: raw.merchantName,
        isBankSynced: true,
        externalBankTransactionId: raw.externalId,
      );
    }).toList();
  }

  /// Chiama il backend (es. Spring Boot / GoCardless proxy) per scaricare le transazioni reali
  Future<List<MoneyTransaction>> fetchBankTransactionsFromBackend({
    required String localAccountId,
    required String externalAccountId,
  }) async {
    final uri = Uri.parse('$backendBaseUrl/accounts/$externalAccountId/transactions');
    final response = await http.get(uri);

    if (response.statusCode != 200) {
      throw Exception('Errore sincronizzazione bancaria: HTTP ${response.statusCode}');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final booked = (data['transactions']['booked'] as List<dynamic>)
        .map((e) => Psd2RawTransaction.fromGoCardlessJson(e as Map<String, dynamic>))
        .toList();

    return mapPsd2ToTransactions(booked, localAccountId);
  }

  /// Simulatore Sandbox PSD2 per testare subito il flusso di importazione e categorizzazione
  Future<List<MoneyTransaction>> fetchSandboxBankTransactions(
    String targetAccountId,
  ) async {
    await Future.delayed(const Duration(milliseconds: 900));
    final now = DateTime.now();

    final mockPsd2 = [
      Psd2RawTransaction(
        externalId: 'PSD2-IT-2026-001',
        bookingDate: now.subtract(const Duration(hours: 3)),
        signedAmount: -48.60,
        remittanceInfo: 'PAGAMENTO POS ESSELUNGA MILANO',
        merchantName: 'Esselunga S.p.A.',
      ),
      Psd2RawTransaction(
        externalId: 'PSD2-IT-2026-002',
        bookingDate: now.subtract(const Duration(days: 1, hours: 5)),
        signedAmount: -35.00,
        remittanceInfo: 'RIFORNIMENTO CARBURANTE DISTRIBUTORE ENI',
        merchantName: 'Eni Station',
      ),
      Psd2RawTransaction(
        externalId: 'PSD2-IT-2026-003',
        bookingDate: now.subtract(const Duration(days: 2)),
        signedAmount: -15.99,
        remittanceInfo: 'ADDEBITO DIRETTO SDD NETFLIX.COM',
        merchantName: 'Netflix',
      ),
      Psd2RawTransaction(
        externalId: 'PSD2-IT-2026-004',
        bookingDate: now.subtract(const Duration(days: 4)),
        signedAmount: 1850.00,
        remittanceInfo: 'BONIFICO ACCREDITO STIPENDIO MESE CORRENTE',
        merchantName: 'Azienda S.r.l.',
      ),
    ];

    return mapPsd2ToTransactions(mockPsd2, targetAccountId);
  }
}
