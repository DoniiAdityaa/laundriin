import 'dart:math';

List<DateTime> getOneMonthsBeforeAndAfter() {
  DateTime today = DateTime.now();

  // Calculate the start and end dates
  DateTime startDate = DateTime(today.year, today.month - 1, today.day);
  DateTime endDate = DateTime(today.year, today.month + 1, today.day);

  List<DateTime> dateList = [];

  // Iterate from the start date to the end date
  for (DateTime date = startDate;
      date.isBefore(endDate) || date.isAtSameMomentAs(endDate);
      date = date.add(Duration(days: 1))) {
    dateList.add(date);
  }

  return dateList;
}

List<DateTime> getDatesInRange() {
  final now = DateTime.now();
  final startDate = DateTime(now.year, now.month - 1, 1);
  final endDate = DateTime(now.year, now.month + 2, 1);
  final daysInMonth = 31; // Assuming maximum days in a month
  final differenceInDays = endDate.difference(startDate).inDays;
  final numberOfDays = min(differenceInDays + 1, daysInMonth);

  return List.generate(
    numberOfDays,
    (index) => startDate.add(Duration(days: index)),
  );
}
