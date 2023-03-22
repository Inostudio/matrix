import '../../model/instruction.dart';
import '../../util/logger.dart';
import 'instruction.dart';

class IsolateTransferModel {
  final dynamic message;
  final LoggerVariant loggerVariant;

  const IsolateTransferModel({
    required this.message,
    required this.loggerVariant,
  });
}

IsolateRespose<T> makeResponseData<T>(
  Instruction? instruction,
  T data, {
  int? instructionId,
}) {
  return IsolateRespose(
    data: data,
    dataInstructionId: instruction?.instructionId ?? instructionId,
  );
}
