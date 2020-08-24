import 'package:charts_flutter/flutter.dart' as charts;
import 'package:flutter/foundation.dart';

class SubscriberSeries {
  final String month;
  final int count;
  final charts.Color barColor;

  SubscriberSeries(
      {@required this.month,
      @required this.count,
      @required this.barColor});
}