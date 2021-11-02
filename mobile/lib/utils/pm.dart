import 'dart:ui';

import 'package:app/constants/app_constants.dart';
import 'package:app/models/chartData.dart';
import 'package:app/models/measurement.dart';
import 'package:charts_flutter/flutter.dart' as charts;
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

List<charts.Series<TimeSeriesData, DateTime>> createData() {
  var today = DateTime.now();

  final data = [
    TimeSeriesData(today.add(Duration(hours: 1)), 5),
  ];

  return [
    charts.Series<TimeSeriesData, DateTime>(
      id: 'Forecast',
      colorFn: (_, __) => charts.MaterialPalette.blue.shadeDefault,
      domainFn: (TimeSeriesData sales, _) => sales.time,
      measureFn: (TimeSeriesData sales, _) => sales.value,
      data: data,
    )
  ];
}

List<Recommendation> getHealthRecommendations(double pm2_5) {
  var recommendations = <Recommendation>[];
  if (pm2_5 <= 12.09) {
    //good
    recommendations
      ..add(Recommendation(
          'For everyone',
          'Great air here today! Zero air pollution Zero worries',
          'assets/icon/search.svg'))
      ..add(Recommendation(
          'For children',
          'Perfect time to let your kids enjoy the park',
          'assets/icon/search.svg'))
      ..add(Recommendation(
          'For pregnant women',
          'Great time to enjoy a bleeze outdoor with caution',
          'assets/icon/search.svg'))
      ..add(Recommendation(
          'For elderly people',
          'Great time to enjoy a bleeze outdoor with caution',
          'assets/icon/search.svg'));
  } else if (pm2_5 >= 12.1 && pm2_5 <= 35.49) {
    //moderate
    recommendations
      ..add(Recommendation(
          'For everyone',
          'Reduce the intensity of your outdoor activities,'
              ' If possible stay indoor',
          'assets/icon/search.svg'))
      ..add(Recommendation(
          'For children',
          'Reduce the intensity of your outdoor activities',
          'assets/icon/search.svg'))
      ..add(Recommendation(
          'For pregnant women',
          'To keep you and your baby healthy, reduce'
              ' the intensity of your outdoor activities',
          'assets/icon/search.svg'))
      ..add(Recommendation(
          'For elderly people',
          'Reduce the intensity of your outdoor activities',
          'assets/icon/search.svg'));
  } else if (pm2_5 >= 35.5 && pm2_5 <= 55.49) {
    //sensitive
    recommendations
      ..add(Recommendation(
          'For everyone',
          'Reduce the intensity of your outdoor activities,'
              ' If possible stay indoor',
          'assets/icon/search.svg'))
      ..add(Recommendation(
          'For children',
          'Reduce the intensity of your outdoor activities',
          'assets/icon/search.svg'))
      ..add(Recommendation(
          'For pregnant women',
          'To keep you and your baby healthy, reduce'
              ' the intensity of your outdoor activities',
          'assets/icon/search.svg'))
      ..add(Recommendation(
          'For elderly people',
          'Reduce the intensity of your outdoor activities',
          'assets/icon/search.svg'));
  } else if (pm2_5 >= 55.5 && pm2_5 <= 150.49) {
    // unhealthy
    recommendations
      ..add(Recommendation(
          'For everyone',
          'Reduce the intensity of your outdoor activities,'
              ' If possible stay indoor',
          'assets/icon/search.svg'))
      ..add(Recommendation(
          'For children',
          'Reduce the intensity of your outdoor activities',
          'assets/icon/search.svg'))
      ..add(Recommendation(
          'For pregnant women',
          'To keep you and your baby healthy, reduce'
              ' the intensity of your outdoor activities',
          'assets/icon/search.svg'))
      ..add(Recommendation(
          'For elderly people',
          'Reduce the intensity of your outdoor activities',
          'assets/icon/search.svg'));
  } else if (pm2_5 >= 150.5 && pm2_5 <= 250.49) {
    // very unhealthy
    recommendations
      ..add(Recommendation(
          'For everyone',
          'Reduce the intensity of your outdoor activities,'
              ' If possible stay indoor',
          'assets/icon/search.svg'))
      ..add(Recommendation(
          'For children',
          'Reduce the intensity of your outdoor activities',
          'assets/icon/search.svg'))
      ..add(Recommendation(
          'For pregnant women',
          'To keep you and your baby healthy, reduce'
              ' the intensity of your outdoor activities',
          'assets/icon/search.svg'))
      ..add(Recommendation(
          'For elderly people',
          'Reduce the intensity of your outdoor activities',
          'assets/icon/search.svg'));
  } else if (pm2_5 >= 250.5) {
    // hazardous
    recommendations
      ..add(Recommendation(
          'For everyone',
          'Reduce the intensity of your outdoor activities,'
              ' If possible stay indoor',
          'assets/icon/search.svg'))
      ..add(Recommendation(
          'For children',
          'Reduce the intensity of your outdoor activities',
          'assets/icon/search.svg'))
      ..add(Recommendation(
          'For pregnant women',
          'To keep you and your baby healthy, reduce'
              ' the intensity of your outdoor activities',
          'assets/icon/search.svg'))
      ..add(Recommendation(
          'For elderly people',
          'Reduce the intensity of your outdoor activities',
          'assets/icon/search.svg'));
  } else {}

  return recommendations;
}

Widget mapSection(Measurement measurement) {
  final _markers = <String, Marker>{};

  final marker = Marker(
    markerId: MarkerId(measurement.site.toString()),
    icon: pmToMarkerPoint(measurement.getPm2_5Value()),
    position: LatLng((measurement.site.latitude), measurement.site.longitude),
  );
  _markers[measurement.site.toString()] = marker;

  return Padding(
      padding: const EdgeInsets.fromLTRB(0.0, 2.0, 0.0, 2.0),
      child: Card(
          elevation: 20,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: GoogleMap(
            compassEnabled: false,
            mapType: MapType.normal,
            myLocationButtonEnabled: false,
            myLocationEnabled: false,
            rotateGesturesEnabled: false,
            tiltGesturesEnabled: false,
            mapToolbarEnabled: false,
            initialCameraPosition: CameraPosition(
              target:
                  LatLng(measurement.site.latitude, measurement.site.longitude),
              zoom: 13,
            ),
            markers: _markers.values.toSet(),
          )));
}

Color pm10TextColor(double pm10) {
  if (pm10 <= 50.99) {
    //good
    return const Color(0xff03B600);
  } else if (pm10 >= 51.00 && pm10 <= 100.99) {
    //moderate
    return const Color(0xffA8A800);
  } else if (pm10 >= 101.00 && pm10 <= 250.99) {
    //sensitive
    return const Color(0xffB86000);
  } else if (pm10 >= 251.00 && pm10 <= 350.99) {
    // unhealthy
    return const Color(0xffB80B00);
  } else if (pm10 >= 351.00 && pm10 <= 430.99) {
    // very unhealthy
    return const Color(0xff8E00AC);
  } else if (pm10 >= 431.00) {
    // hazardous
    return const Color(0xffA51F3F);
  } else {
    return ColorConstants.appColor;
  }
}

Color pm10ToColor(double pm10) {
  if (pm10 <= 50.99) {
    //good
    return ColorConstants.green;
  } else if (pm10 >= 51.00 && pm10 <= 100.99) {
    //moderate
    return ColorConstants.yellow;
  } else if (pm10 >= 101.00 && pm10 <= 250.99) {
    //sensitive
    return ColorConstants.orange;
  } else if (pm10 >= 251.00 && pm10 <= 350.99) {
    // unhealthy
    return ColorConstants.red;
  } else if (pm10 >= 351.00 && pm10 <= 430.99) {
    // very unhealthy
    return ColorConstants.purple;
  } else if (pm10 >= 431.00) {
    // hazardous
    return ColorConstants.maroon;
  } else {
    return ColorConstants.appColor;
  }
}

Color pm2_5TextColor(double pm2_5) {
  if (pm2_5 <= 12.09) {
    //good
    return const Color(0xff03B600);
  } else if (pm2_5 >= 12.1 && pm2_5 <= 35.49) {
    //moderate
    return const Color(0xffA8A800);
  } else if (pm2_5 >= 35.5 && pm2_5 <= 55.49) {
    //sensitive
    return const Color(0xffB86000);
  } else if (pm2_5 >= 55.5 && pm2_5 <= 150.49) {
    // unhealthy
    return const Color(0xffB80B00);
  } else if (pm2_5 >= 150.5 && pm2_5 <= 250.49) {
    // very unhealthy
    return const Color(0xff8E00AC);
  } else if (pm2_5 >= 250.5) {
    // hazardous
    return const Color(0xffA51F3F);
  } else {
    return ColorConstants.appColor;
  }
}

Color pm2_5ToColor(double pm2_5) {
  if (pm2_5 <= 12.09) {
    //good
    return ColorConstants.green;
  } else if (pm2_5 >= 12.1 && pm2_5 <= 35.49) {
    //moderate
    return ColorConstants.yellow;
  } else if (pm2_5 >= 35.5 && pm2_5 <= 55.49) {
    //sensitive
    return ColorConstants.orange;
  } else if (pm2_5 >= 55.5 && pm2_5 <= 150.49) {
    // unhealthy
    return ColorConstants.red;
  } else if (pm2_5 >= 150.5 && pm2_5 <= 250.49) {
    // very unhealthy
    return ColorConstants.purple;
  } else if (pm2_5 >= 250.5) {
    // hazardous
    return ColorConstants.maroon;
  } else {
    return ColorConstants.appColor;
  }
}

charts.Color pmToChartColor(double value, String pollutant) {
  if (pollutant.trim().toLowerCase() == 'pm2.5') {
    if (value <= 12.09) {
      //good
      return charts.ColorUtil.fromDartColor(ColorConstants.green);
    } else if (value >= 12.1 && value <= 35.49) {
      //moderate
      return charts.ColorUtil.fromDartColor(ColorConstants.yellow);
    } else if (value >= 35.5 && value <= 55.49) {
      //sensitive
      return charts.ColorUtil.fromDartColor(ColorConstants.orange);
    } else if (value >= 55.5 && value <= 150.49) {
      // unhealthy
      return charts.ColorUtil.fromDartColor(ColorConstants.red);
    } else if (value >= 150.5 && value <= 250.49) {
      // very unhealthy
      return charts.ColorUtil.fromDartColor(ColorConstants.purple);
    } else if (value >= 250.5) {
      // hazardous
      return charts.ColorUtil.fromDartColor(ColorConstants.maroon);
    } else {
      return charts.ColorUtil.fromDartColor(ColorConstants.appColor);
    }
  } else {
    if (value <= 50.99) {
      //good
      return charts.ColorUtil.fromDartColor(ColorConstants.green);
    } else if (value >= 51.00 && value <= 100.99) {
      //moderate
      return charts.ColorUtil.fromDartColor(ColorConstants.yellow);
    } else if (value >= 101.00 && value <= 250.99) {
      //sensitive
      return charts.ColorUtil.fromDartColor(ColorConstants.orange);
    } else if (value >= 251.00 && value <= 350.99) {
      // unhealthy
      return charts.ColorUtil.fromDartColor(ColorConstants.red);
    } else if (value >= 351.00 && value <= 430.99) {
      // very unhealthy
      return charts.ColorUtil.fromDartColor(ColorConstants.purple);
    } else if (value >= 431.00) {
      // hazardous
      return charts.ColorUtil.fromDartColor(ColorConstants.maroon);
    } else {
      return charts.ColorUtil.fromDartColor(ColorConstants.appColor);
    }
  }
}

String pmToEmoji(double pm2_5) {
  if (pm2_5 <= 12.09) {
    //good
    return 'assets/images/good-face.png';
  } else if (pm2_5 >= 12.1 && pm2_5 <= 35.49) {
    //moderate
    return 'assets/images/moderate-face.png';
  } else if (pm2_5 >= 35.5 && pm2_5 <= 55.49) {
    //sensitive
    return 'assets/images/sensitive-face.png';
  } else if (pm2_5 >= 55.5 && pm2_5 <= 150.49) {
    // unhealthy
    return 'assets/images/unhealthy-face.png';
  } else if (pm2_5 >= 150.5 && pm2_5 <= 250.49) {
    // very unhealthy
    return 'assets/images/very-unhealthy-face.png';
  } else if (pm2_5 >= 250.5) {
    // hazardous
    return 'assets/images/hazardous-face.png';
  } else {
    return 'assets/images/good-face.png';
  }
}

String pmToInfoDialog(double pm2_5) {
  if (pm2_5 <= 12.09) {
    //good
    return 'Air quality is safe for everyone!';
  } else if (pm2_5 >= 12.1 && pm2_5 <= 35.49) {
    //moderate
    return 'Sensitive people should consider reducing prolonged '
        'or heavy exertion. Everyone should avoid prolonged or heavy exertion';
  } else if (pm2_5 >= 35.5 && pm2_5 <= 55.49) {
    //sensitive
    return 'Sensitive people should consider reducing prolonged '
        'or heavy exertion. Everyone should avoid prolonged or heavy exertion';
  } else if (pm2_5 >= 55.5 && pm2_5 <= 150.49) {
    // unhealthy
    return 'Sensitive people should consider reducing prolonged '
        'or heavy exertion. Everyone should avoid prolonged or heavy exertion';
  } else if (pm2_5 >= 150.5 && pm2_5 <= 250.49) {
    // very unhealthy
    return 'Sensitive people should consider reducing prolonged '
        'or heavy exertion. Everyone should avoid prolonged or heavy exertion';
  } else if (pm2_5 >= 250.5) {
    // hazardous
    return 'Sensitive people should consider reducing prolonged '
        'or heavy exertion. Everyone should avoid prolonged or heavy exertion';
  } else {
    return '';
  }
}

String pmToLongString(double pm2_5) {
  if (pm2_5 <= 12.09) {
    //good
    return 'Good';
  } else if (pm2_5 >= 12.1 && pm2_5 <= 35.49) {
    //moderate
    return 'Moderate';
  } else if (pm2_5 >= 35.5 && pm2_5 <= 55.49) {
    //sensitive
    return 'Unhealthy for Sensitive Groups';
  } else if (pm2_5 >= 55.5 && pm2_5 <= 150.49) {
    // unhealthy
    return 'Unhealthy';
  } else if (pm2_5 >= 150.5 && pm2_5 <= 250.49) {
    // very unhealthy
    return 'Very Unhealthy';
  } else if (pm2_5 >= 250.5) {
    // hazardous
    return 'Hazardous';
  } else {
    return '';
  }
}

Future<BitmapDescriptor> pmToMarker(double pm2_5) async {
  var width = 55;
  var value = pm2_5;
  var bgColor = pm2_5ToColor(pm2_5);
  var textColor = pm2_5TextColor(pm2_5);

  final pictureRecorder = PictureRecorder();
  final canvas = Canvas(pictureRecorder);
  final paint = Paint()..color = bgColor;
  final radius = width / 2;
  canvas.drawCircle(
    Offset(radius, radius),
    radius,
    paint,
  );

  var textPainter = TextPainter(
    textDirection: TextDirection.ltr,
    text: TextSpan(
      text: value.toStringAsFixed(2),
      style: TextStyle(
        fontSize: radius - 10,
        fontWeight: FontWeight.bold,
        color: textColor,
      ),
    ),
    textAlign: TextAlign.center,
  )..layout();

  textPainter.paint(
    canvas,
    Offset(
      radius - textPainter.width / 2,
      radius - textPainter.height / 2,
    ),
  );
  final image = await pictureRecorder.endRecording().toImage(
        radius.toInt() * 2,
        radius.toInt() * 2,
      );
  final data = await image.toByteData(format: ImageByteFormat.png);
  return BitmapDescriptor.fromBytes(data!.buffer.asUint8List());
}

BitmapDescriptor pmToMarkerPoint(double pm2_5) {
  if (pm2_5 <= 12.09) {
    //good
    return BitmapDescriptor.defaultMarkerWithHue(
        HSVColor.fromColor(ColorConstants.green).hue);
  } else if (pm2_5 >= 12.10 && pm2_5 <= 35.49) {
    //moderate
    return BitmapDescriptor.defaultMarkerWithHue(
        HSVColor.fromColor(ColorConstants.yellow).hue);
  } else if (pm2_5 >= 35.50 && pm2_5 <= 55.49) {
    //sensitive
    return BitmapDescriptor.defaultMarkerWithHue(
        HSVColor.fromColor(ColorConstants.orange).hue);
  } else if (pm2_5 >= 55.50 && pm2_5 <= 150.49) {
    // unhealthy
    return BitmapDescriptor.defaultMarkerWithHue(
        HSVColor.fromColor(ColorConstants.red).hue);
  } else if (pm2_5 >= 150.50 && pm2_5 <= 250.49) {
    // very unhealthy
    return BitmapDescriptor.defaultMarkerWithHue(
        HSVColor.fromColor(ColorConstants.purple).hue);
  } else if (pm2_5 >= 250.5) {
    // hazardous
    return BitmapDescriptor.defaultMarkerWithHue(
        HSVColor.fromColor(ColorConstants.maroon).hue);
  } else {
    return BitmapDescriptor.defaultMarker;
  }
}

String pmToString(double pm2_5) {
  if (pm2_5 <= 12.09) {
    //good
    return 'Good';
  } else if (pm2_5 >= 12.1 && pm2_5 <= 35.49) {
    //moderate
    return 'Moderate';
  } else if (pm2_5 >= 35.5 && pm2_5 <= 55.49) {
    //sensitive
    return 'Unhealthy FSGs';
  } else if (pm2_5 >= 55.5 && pm2_5 <= 150.49) {
    // unhealthy
    return 'Unhealthy';
  } else if (pm2_5 >= 150.5 && pm2_5 <= 250.49) {
    // very unhealthy
    return 'Very Unhealthy';
  } else if (pm2_5 >= 250.5) {
    // hazardous
    return 'Hazardous';
  } else {
    return '';
  }
}

class Recommendation {
  String title = '';
  String body = '';
  String imageUrl = '';

  Recommendation(this.title, this.body, this.imageUrl);
}

class Tip {
  String header = '';
  String body = '';
  Color imageColor = ColorConstants.appTipColor;

  Tip(this.header, this.body);
}
