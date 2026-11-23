import 'package:flutter/widgets.dart';
import '../providers/money_provider.dart';

class MoneyScope extends InheritedNotifier<MoneyProvider> {
  const MoneyScope({
    super.key,
    required MoneyProvider provider,
    required super.child,
  }) : super(notifier: provider);

  /// Ascolta i cambiamenti dello stato e ricostruisce il widget (equivalente a context.watch)
  static MoneyProvider of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<MoneyScope>();
    assert(scope != null, 'Nessun MoneyScope trovato nel widget tree');
    return scope!.notifier!;
  }

  /// Legge il provider senza sottoscrivere il widget ai rebuild (equivalente a context.read)
  static MoneyProvider read(BuildContext context) {
    final element =
        context.getElementForInheritedWidgetOfExactType<MoneyScope>();
    assert(element != null, 'Nessun MoneyScope trovato nel widget tree');
    return (element!.widget as MoneyScope).notifier!;
  }
}
