extension DurationToStringExtensions on int {
  String durationToString() {
    var d = Duration(minutes: this);
    int hours = d.inHours;
    int remainingMinutes = d.inMinutes.remainder(60);
    return '${hours.toString().padLeft(2, '0')} Jam ${remainingMinutes.toString().padLeft(2, '0')} Menit';
  }
}
