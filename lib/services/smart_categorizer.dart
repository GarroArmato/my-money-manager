class SmartCategorizer {
  /// Motore di categorizzazione automatica basato sulla causale o sul nome dell'esercente
  static String guessCategory(String description, bool isIncome) {
    final upper = description.toUpperCase();

    if (isIncome) {
      if (upper.contains('STIPENDIO') ||
          upper.contains('EMOLUMENTI') ||
          upper.contains('SALARIO') ||
          upper.contains('COMPENSO')) {
        return 'cat_salary';
      }
      return 'cat_other_income';
    }

    // Regole per le uscite
    if (upper.contains('ESSELUNGA') ||
        upper.contains('CONAD') ||
        upper.contains('COOP') ||
        upper.contains('CARREFOUR') ||
        upper.contains('LIDL') ||
        upper.contains('EUROSPIN') ||
        upper.contains('SUPERMERCATO')) {
      return 'cat_food';
    }
    if (upper.contains('RISTORANTE') ||
        upper.contains('PIZZERIA') ||
        upper.contains('BAR ') ||
        upper.contains('CAFFE') ||
        upper.contains('DELIVEROO') ||
        upper.contains('GLOVO') ||
        upper.contains('JUST EAT') ||
        upper.contains('MC DONALD') ||
        upper.contains('BURGER')) {
      return 'cat_restaurant';
    }
    if (upper.contains('ENI') ||
        upper.contains('Q8') ||
        upper.contains('IP ') ||
        upper.contains('TAMOIL') ||
        upper.contains('TRENITALIA') ||
        upper.contains('ITALO') ||
        upper.contains('TELEPASS') ||
        upper.contains('CARBURANTE') ||
        upper.contains('BENZINA')) {
      return 'cat_transport';
    }
    if (upper.contains('ENEL') ||
        upper.contains('PLENITUDE') ||
        upper.contains('A2A') ||
        upper.contains('TIM ') ||
        upper.contains('VODAFONE') ||
        upper.contains('ILIAD') ||
        upper.contains('FASTWEB') ||
        upper.contains('AFFITTO') ||
        upper.contains('MUTUO') ||
        upper.contains('CONDOMINIO')) {
      return 'cat_home';
    }
    if (upper.contains('NETFLIX') ||
        upper.contains('SPOTIFY') ||
        upper.contains('DISNEY') ||
        upper.contains('PRIME') ||
        upper.contains('CINEMA') ||
        upper.contains('STEAM') ||
        upper.contains('PLAYSTATION')) {
      return 'cat_entertainment';
    }

    return 'cat_shopping';
  }
}
