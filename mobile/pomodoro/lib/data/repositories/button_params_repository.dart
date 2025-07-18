import 'package:pomodoro/data/datasources/local/button_params_local_ds.dart';
import 'package:pomodoro/models/button_params.dart';

/// Abstraction over data source for business logic.
abstract class ButtonParamsRepository {
  Future<ButtonParams> getParams();
  Future<void> saveParams(ButtonParams params);
}

class ButtonParamsRepositoryImpl implements ButtonParamsRepository {
  final ButtonParamsLocalDataSource _localDs;

  ButtonParamsRepositoryImpl(this._localDs);

  @override
  Future<ButtonParams> getParams() => _localDs.load();

  @override
  Future<void> saveParams(ButtonParams params) => _localDs.save(params);
}