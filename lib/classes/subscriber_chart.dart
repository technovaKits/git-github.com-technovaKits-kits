import 'package:charts_flutter/flutter.dart' as charts;
import 'package:flutter/material.dart';
import 'package:kits/classes/SubscriberSeries.dart';

class SubscriberChart extends StatelessWidget {
  final List<SubscriberSeries> data;
  final String tablo;

  SubscriberChart({@required this.data,@required this.tablo});

  @override
  Widget build(BuildContext context) {
    List<charts.Series<SubscriberSeries, String>> series = [
      charts.Series(
          id: "Subscribers",
          data: data,
          domainFn: (SubscriberSeries series, _) => series.month,
          measureFn: (SubscriberSeries series, _) => series.count,
          colorFn: (SubscriberSeries series, _) => series.barColor)
    ];

    // ignore: deprecated_member_use
    TextStyle body22 = Theme.of(context).textTheme.body2;
        return Container(
          height: 300,
          padding: EdgeInsets.all(10),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                children: <Widget>[
                  Text(
                    tablo,
                    style: body22,
              ),
              Expanded(
                child: charts.BarChart(series, animate: true),
              )
            ],
          ),
        ),
      ),
    );
  }
}