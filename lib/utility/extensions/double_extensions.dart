

extension DoubleExtensions on double{
  String byteToMb(){
    return "${(this / (1024 * 1024)).toStringAsFixed(2)} MB";
  }
}