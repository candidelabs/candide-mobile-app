import 'package:candide_mobile_app/controller/persistent_data.dart';
import 'package:event_bus/event_bus.dart';

final EventBus eventBus = EventBus();

class OnChangeOnboardPage {
  int index;

  OnChangeOnboardPage({required this.index});
}

class OnWalletConnectDisconnect {
  OnWalletConnectDisconnect();
}

class OnHomeRequestChangePageIndex {
  int index;
  OnHomeRequestChangePageIndex({required this.index});
}

class OnAccountDataEdit {
  bool recovered;
  OnAccountDataEdit({this.recovered=false});
}

class OnAccountChange {
  OnAccountChange();
}

class OnPinErrorChange {
  final String error;
  OnPinErrorChange({required this.error});
}

class OnTransactionStatusChange {
  TransactionActivity activity;

  OnTransactionStatusChange({required this.activity});
}