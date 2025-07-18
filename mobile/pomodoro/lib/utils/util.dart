(String, DateTime) getCurrentDayName() {
  DateTime now = DateTime.now();
  List<String> weekdays = [
    'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'
  ];
  return (weekdays[now.weekday - 1], now);
}