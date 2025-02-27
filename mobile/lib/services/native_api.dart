import 'dart:io';
import 'dart:isolate';
import 'dart:ui' as ui;
import 'dart:ui';

import 'package:app/constants/constants.dart';
import 'package:app/models/models.dart';
import 'package:app/services/rest_api.dart';
import 'package:app/utils/utils.dart';
import 'package:app/widgets/widgets.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart'
    as cache_manager;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:share_plus/share_plus.dart';
import 'package:workmanager/workmanager.dart' as workmanager;

import 'firebase_service.dart';
import 'hive_service.dart';
import 'local_storage.dart';

class SystemProperties {
  static Future<void> setDefault() async {
    try {
      SystemChrome.setSystemUIOverlayStyle(
        const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.dark,
        ),
      );

      await SystemChrome.setPreferredOrientations(
        [DeviceOrientation.portraitUp, DeviceOrientation.portraitDown],
      );

      await SystemChrome.setEnabledSystemUIMode(
        SystemUiMode.manual,
        overlays: [SystemUiOverlay.bottom, SystemUiOverlay.top],
      );
    } catch (exception, stackTrace) {
      await logException(exception, stackTrace);
    }
  }
}

class RateService {
  static Future<void> rateApp() async {
    final InAppReview inAppReview = InAppReview.instance;
    await inAppReview.openStoreListing(appStoreId: Config.iosStoreId);
  }

  static Future<void> logAppRating() async {
    await CloudAnalytics.logEvent(
      AnalyticsEvent.rateApp,
    );
  }
}

class ShareService {
  static String getShareMessage() {
    return 'Download the AirQo app from Google play\nhttps://play.google.com/store/apps/details?id=com.airqo.app\nand App Store\nhttps://itunes.apple.com/ug/app/airqo-monitoring-air-quality/id1337573091\n';
  }

  static Future<bool> shareWidget({
    required BuildContext buildContext,
    required GlobalKey globalKey,
    String? imageName,
  }) async {
    try {
      final boundary =
          globalKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
      final image = await boundary.toImage(
        pixelRatio: 10.0,
      );
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      final pngBytes = byteData!.buffer.asUint8List();

      final directory = (await getApplicationDocumentsDirectory()).path;
      final imgFile = File("$directory/${imageName ?? 'airqo_analytics'}.png");
      await imgFile.writeAsBytes(pngBytes);

      final result = await Share.shareXFiles([XFile(imgFile.path)]);

      if (result.status == ShareResultStatus.success) {
        await updateUserShares();
      }
    } catch (exception, stackTrace) {
      await shareFailed(
        exception,
        stackTrace,
        buildContext,
      );
    }

    return true;
  }

  static Future<void> shareFailed(
    exception,
    StackTrace stackTrace,
    BuildContext context,
  ) async {
    await logException(
      exception,
      stackTrace,
    );
    showSnackBar(
      context,
      Config.shareFailedMessage,
    );
  }

  static void shareMeasurementText(AirQualityReading airQualityReading) {
    final healthTipList =
        getHealthTips(airQualityReading.pm2_5, Pollutant.pm2_5);
    var healthtips = '';
    for (final value in healthTipList) {
      healthtips = '$healthtips\n- ${value.body}';
    }
    Share.share(
      '${airQualityReading.name}, Current Air Quality.\n\n'
      'PM2.5 : ${airQualityReading.pm2_5.toStringAsFixed(2)} µg/m\u00B3 (${Pollutant.pm2_5.stringValue(airQualityReading.pm2_5)}) \n'
      'PM10 : ${airQualityReading.pm2_5.toStringAsFixed(2)} µg/m\u00B3 \n'
      '$healthtips\n\n'
      'Source: AirQo App',
      subject: 'AirQo, ${airQualityReading.name}!',
    ).then(
      (value) => {updateUserShares()},
    );
  }

  static Future<void> updateUserShares() async {
    final preferences = await SharedPreferencesHelper.getPreferences();
    final value = preferences.aqShares + 1;
    if (CustomAuth.isLoggedIn()) {
      final profile = await Profile.getProfile();
      profile.preferences.aqShares = value;
      await profile.update();
    } else {
      await SharedPreferencesHelper.updatePreference('aqShares', value, 'int');
    }

    if (value >= 5) {
      await CloudAnalytics.logEvent(
        AnalyticsEvent.shareAirQualityInformation,
      );
    }
  }
}

class PermissionService {
  static Future<bool> checkPermission(
    AppPermission permission, {
    bool request = false,
  }) async {
    PermissionStatus status;
    switch (permission) {
      case AppPermission.notification:
        status = await Permission.notification.status;
        break;
      case AppPermission.location:
        status = await Permission.location.status;
        break;
      case AppPermission.photosStorage:
        status = await Permission.photos.status;
        break;
    }

    if (status != PermissionStatus.granted && request) {
      if (status == PermissionStatus.permanentlyDenied) {
        return await openAppSettings();
      } else {
        switch (permission) {
          case AppPermission.notification:
            return await Permission.notification.request() ==
                PermissionStatus.granted;
          case AppPermission.location:
            return await Permission.location.request() ==
                PermissionStatus.granted;
          case AppPermission.photosStorage:
            return await Permission.accessMediaLocation.request() ==
                PermissionStatus.granted;
        }
      }
    }

    return status == PermissionStatus.granted;
  }
}

void backgroundCallbackDispatcher() {
  workmanager.Workmanager().executeTask(
    (task, inputData) async {
      await dotenv.load(fileName: Config.environmentFile);
      try {
        switch (task) {
          case BackgroundService.airQualityUpdates:
            final airQualityReadings =
                await AirqoApiClient().fetchAirQualityReadings();
            final sendPort = IsolateNameServer.lookupPortByName(
              BackgroundService.taskChannel(task),
            );
            if (sendPort != null) {
              sendPort.send(airQualityReadings);
            } else {
              // TODO: implement saving
              // final SharedPreferences prefs = await
              // SharedPreferences.getInstance();
              // await prefs.setString('measurements', 'measurements');
            }
            break;
        }

        return Future.value(true);
      } catch (exception, stackTrace) {
        await logException(
          exception,
          stackTrace,
        );

        return Future.value(false);
      }
    },
  );
}

class BackgroundService {
  factory BackgroundService() {
    return _instance;
  }

  BackgroundService._internal();

  static final BackgroundService _instance = BackgroundService._internal();

  static const airQualityUpdates = 'Air Quality Updates';

  static String taskChannel(String task) {
    return 'channel_${task.toLowerCase().replaceAll(' ', '_')}';
  }

  void registerAirQualityRefreshTask() {
    if (Platform.isAndroid) {
      workmanager.Workmanager().registerPeriodicTask(
        BackgroundService.airQualityUpdates,
        BackgroundService.airQualityUpdates,
        frequency: const Duration(minutes: 15),
        constraints: workmanager.Constraints(
          networkType: workmanager.NetworkType.connected,
        ),
      );
    }
    if (Platform.isIOS) {
      workmanager.Workmanager().registerOneOffTask(
        BackgroundService.airQualityUpdates,
        BackgroundService.airQualityUpdates,
        constraints: workmanager.Constraints(
          networkType: workmanager.NetworkType.connected,
        ),
      );
    }
  }

  Future<void> initialize() async {
    await workmanager.Workmanager().initialize(
      backgroundCallbackDispatcher,
      isInDebugMode: kReleaseMode ? false : true,
    );
  }

  void listenToTask(String task) {
    var port = ReceivePort();
    // if (IsolateNameServer.lookupPortByName('bChannel') != null) {
    //   IsolateNameServer.removePortNameMapping('bChannel');
    // }

    IsolateNameServer.registerPortWithName(
      port.sendPort,
      BackgroundService.taskChannel(task),
    );
    port.listen(
      (dynamic data) async {
        await HiveService.updateAirQualityReadings(
          data as List<AirQualityReading>,
        );
      },
    );
  }
}

class CacheService {
  static cache_manager.Config cacheConfig(String key) {
    return cache_manager.Config(
      key,
      stalePeriod: const Duration(days: 7),
    );
  }

  static void cacheKyaImages(Kya _) {
    // TODO : implement caching
    // await Future.wait([
    //   cache_manager.DefaultCacheManager()
    //       .downloadFile(kya.imageUrl, key: kya.imageUrlCacheKey()),
    //   cache_manager.DefaultCacheManager().downloadFile(kya.secondaryImageUrl,
    //       key: kya.secondaryImageUrlCacheKey())
    // ]);
    //
    // for (final lesson in kya.lessons) {
    //   await cache_manager.DefaultCacheManager()
    //       .downloadFile(lesson.imageUrl, key: lesson.imageUrlCacheKey(kya));
    // }
  }
}

Future<void> initializeBackgroundServices() async {
  if (Platform.isAndroid) {
    await BackgroundService().initialize();
    BackgroundService().listenToTask(BackgroundService.airQualityUpdates);
    BackgroundService().registerAirQualityRefreshTask();
  }
}
