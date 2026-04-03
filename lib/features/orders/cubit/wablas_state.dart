import 'package:equatable/equatable.dart';

abstract class WablasState extends Equatable {
  const WablasState();

  @override
  List<Object> get props => [];
}

class WablasInitial extends WablasState {}

class WablasLoading extends WablasState {}

class WablasSuccess extends WablasState {
  final String message;
  const WablasSuccess(this.message);

  @override
  List<Object> get props => [message];
}

class WablasFailure extends WablasState {
  final String error;
  const WablasFailure(this.error);

  @override
  List<Object> get props => [error];
}
