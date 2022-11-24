import 'package:event_bus/event_bus.dart';

final EventBus eventBus = EventBus();

class OnChangeOnboardPage {
  int index;

  OnChangeOnboardPage({required this.index});
}

class OnTransactionStatusChange {
  String hash;

  OnTransactionStatusChange({required this.hash});
}