class AppFormatters {
  static const List<String> _italianMonths = [
    'Gennaio',
    'Febbraio',
    'Marzo',
    'Aprile',
    'Maggio',
    'Giugno',
    'Luglio',
    'Agosto',
    'Settembre',
    'Ottobre',
    'Novembre',
    'Dicembre',
  ];

  /// Formatta un importo in Euro in stile italiano (es. "1.450,00 €")
  static String formatCurrency(double value) {
    final isNegative = value < 0;
    final absVal = value.abs();
    final parts = absVal.toStringAsFixed(2).split('.');
    final intPart = parts[0];
    final decPart = parts[1];

    final buffer = StringBuffer();
    for (int i = 0; i < intPart.length; i++) {
      final reverseIndex = intPart.length - 1 - i;
      buffer.write(intPart[i]);
      if (reverseIndex > 0 && reverseIndex % 3 == 0) {
        buffer.write('.');
      }
    }

    final sign = isNegative ? '-' : '';
    return '$sign${buffer.toString()},$decPart €';
  }

  /// Formatta mese e anno in italiano (es. "NOVEMBRE 2026")
  static String formatMonthYear(DateTime date) {
    final monthName = _italianMonths[date.month - 1];
    return '$monthName ${date.year}'.toUpperCase();
  }

  /// Formatta data e ora breve (es. "23/11 17:25")
  static String formatShortDateTime(DateTime date) {
    final d = date.day.toString().padLeft(2, '0');
    final m = date.month.toString().padLeft(2, '0');
    final h = date.hour.toString().padLeft(2, '0');
    final min = date.minute.toString().padLeft(2, '0');
    return '$d/$m $h:$min';
  }

  static int _counter = 0;

  /// Genera un ID univoco senza dipendenze esterne
  static String generateId() {
    _counter++;
    return 'tx_${DateTime.now().microsecondsSinceEpoch}_$_counter';
  }
}
