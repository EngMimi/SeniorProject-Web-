// Short month names used to build the date string below.
const _months = [
  'Jan',
  'Feb',
  'Mar',
  'Apr',
  'May',
  'Jun',
  'Jul',
  'Aug',
  'Sep',
  'Oct',
  'Nov',
  'Dec',
];

// Converts a DateTime into a readable string like "24 Sep 2026".
String formatDate(DateTime date) =>
    '${date.day} ${_months[date.month - 1]} ${date.year}';
