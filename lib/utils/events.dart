import 'package:candide_mobile_app/controller/address_persistent_data.dart';
import 'package:event_bus/event_bus.dart';

final EventBus eventBus = EventBus();

class OnChangeOnboardPage {
  int index;

  OnChangeOnboardPage({required this.index});
}

class OnTransactionStatusChange {
  TransactionActivity activity;

  OnTransactionStatusChange({required this.activity});
}