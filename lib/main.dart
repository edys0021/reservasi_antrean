import 'dart:io';
import 'dart:convert';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_downloader/flutter_downloader.dart';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:open_file/open_file.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';
import 'package:image_gallery_saver/image_gallery_saver.dart';
import 'package:flutter/services.dart';
import 'package:connectivity/connectivity.dart';
import 'pages/err_page.dart';

void main() async {
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Color.fromRGBO(0, 123, 218, 1)));
  WidgetsFlutterBinding.ensureInitialized();
  await Permission.notification.request();
  await Permission.location.request();
  await Permission.camera.request();
  // await Permission.photos.request();
  await FlutterDownloader.initialize(
      debug: true, // optional: set false to disable printing logs to console,
      ignoreSsl: true // optional: set true to ignore ssl,
      );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
          scaffoldBackgroundColor: const Color.fromRGBO(33, 146, 229, 1)),
      debugShowCheckedModeBanner: false,
      // ignore: prefer_const_constructors
      home: WebViewScreen(),
    );
  }
}

class WebViewScreen extends StatefulWidget {
  const WebViewScreen({super.key});

  @override
  _WebViewScreen createState() => _WebViewScreen();
}

class _WebViewScreen extends State<WebViewScreen> {
  InAppWebViewController? webViewController;
  String pathurl = "";
  bool showErrorPage = false;
  FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();
  ConnectivityResult _connectionStatus = ConnectivityResult.none;

  @override
  void initState() {
    super.initState();

    Connectivity().onConnectivityChanged.listen((result) {
      setState(() {
        _connectionStatus = result;
      });
    });

    checkConnectivity();
    _requestNotificationPermissions();
    _configureLocalNotifications();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
        canPop: false,
        onPopInvoked: (didPop) {
          if (didPop) {
            return;
          }
          onPopScopePressBackShowAlertDialog();
        },
        child: Scaffold(
            body: _connectionStatus != ConnectivityResult.none
                ? SafeArea(
                    child: Column(
                      children: [
                        Expanded(
                            child: InAppWebView(
                          initialUrlRequest: URLRequest(
                              url: Uri.parse(
                                  'https://demo-cerbisque.cpm.systems/')),
                          onWebViewCreated: (controller) {
                            webViewController = controller;
                          },
                          androidOnGeolocationPermissionsShowPrompt:
                              (InAppWebViewController controller,
                                  String origin) async {
                            return GeolocationPermissionShowPromptResponse(
                                origin: origin, allow: true, retain: true);
                          },
                          initialOptions: InAppWebViewGroupOptions(
                            crossPlatform: InAppWebViewOptions(
                              useShouldOverrideUrlLoading: true,
                              useOnDownloadStart: true,
                              mediaPlaybackRequiresUserGesture: false,
                            ),
                            android: AndroidInAppWebViewOptions(
                              useHybridComposition: true,
                              supportMultipleWindows: true,
                              useWideViewPort: true,
                              geolocationEnabled: true,
                            ),
                          ),
                          androidOnPermissionRequest:
                              (InAppWebViewController controller, String origin,
                                  List<String> resources) async {
                            return PermissionRequestResponse(
                                resources: resources,
                                action: PermissionRequestResponseAction.GRANT);
                          },
                          onDownloadStartRequest:
                              (controller, downloadStartRequest) async {
                            String file64 = downloadStartRequest.url
                                .toString()
                                .split(":")[0];
                            if (file64 == "data") {
                              String extension = downloadStartRequest.url
                                  .toString()
                                  .split(";")[0]
                                  .split(":")[1]
                                  .split("/")[1];
                              await downloadBase64(
                                  downloadStartRequest.url
                                      .toString()
                                      .split(",")[1],
                                  extension);
                            } else {
                              await downloadFile(
                                  downloadStartRequest.url.toString(),
                                  downloadStartRequest.suggestedFilename);
                            }
                          },
                          onLoadError: (controller, url, code, message) {
                            showError();
                          },
                          onLoadHttpError:
                              (controller, url, statusCode, description) {
                            showError();
                          },
                        )),
                        showErrorPage
                            ? const ErrPage()
                            : const SizedBox(height: 0, width: 0)
                      ],
                    ),
                  )
                : ErrPage()));
  }

  Future<void> checkConnectivity() async {
    var connectivityResult = await Connectivity().checkConnectivity();
    print("${_connectionStatus != ConnectivityResult.none} EDYS00000021");

    setState(() {
      _connectionStatus = connectivityResult;
    });
  }

  Future<void> downloadFile(String url, [String? filename]) async {
    var hasStoragePermission = await Permission.photos.isGranted;
    if (!hasStoragePermission) {
      final status = await Permission.photos.request();
      hasStoragePermission = status.isGranted;
    }
    if (hasStoragePermission) {
      final success = await FlutterDownloader.enqueue(
          url: url,
          headers: {},
          savedDir: (await getTemporaryDirectory()).path,
          showNotification: false,
          saveInPublicStorage: true,
          fileName: filename);

      if (success != null) {
        var androidPlatformChannelSpecifics = const AndroidNotificationDetails(
          'v002i',
          'reservasi antrean',
          channelDescription: 'reservasi antrean BRI',
          importance: Importance.max,
          priority: Priority.high,
          color: Colors.blue,
          colorized: true,
        );

        await flutterLocalNotificationsPlugin
            .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin>()
            ?.startForegroundService(1, 'colored background text title',
                'colored background text body',
                notificationDetails: androidPlatformChannelSpecifics,
                payload: 'item x');

        var platformChannelSpecifics =
            NotificationDetails(android: androidPlatformChannelSpecifics);
        int notificationId = DateTime.now().millisecondsSinceEpoch ~/ 1000;

        await flutterLocalNotificationsPlugin.show(
          notificationId,
          'Reservasi Antrean',
          '$filename telah berhasil disimpan',
          platformChannelSpecifics,
          payload: 'item x',
        );
      }
    }
  }

  void showError() async {
    setState(() {
      showErrorPage = true;
    });
  }

  Future<String> downloadBase64(String url, String extension) async {
    final encodedStr = url;
    Uint8List bytes = base64Decode(encodedStr);
    String dir = (await getTemporaryDirectory()).path;
    File file = File("$dir/" +
        DateTime.now().millisecondsSinceEpoch.toString() +
        ".$extension");
    await file.writeAsBytes(bytes);
    await ImageGallerySaver.saveFile(file.path);
    pathurl = file.path;
    var androidPlatformChannelSpecifics = const AndroidNotificationDetails(
      'v002i',
      'reservasi antrean',
      channelDescription: 'reservasi antrean BRI',
      importance: Importance.max,
      priority: Priority.high,
      color: Colors.blue,
      colorized: true,
    );

    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.startForegroundService(
            1, 'colored background text title', 'colored background text body',
            notificationDetails: androidPlatformChannelSpecifics,
            payload: 'item x');

    var platformChannelSpecifics =
        NotificationDetails(android: androidPlatformChannelSpecifics);
    int notificationId = DateTime.now().millisecondsSinceEpoch ~/ 1000;

    await flutterLocalNotificationsPlugin.show(
      notificationId,
      'Reservasi Antrean',
      'Halaman telah berhasil disimpan',
      platformChannelSpecifics,
      payload: 'item x',
    );
    return file.path;
  }

  Future<void> _configureLocalNotifications() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('app_icon');

    const IOSInitializationSettings initializationSettingsIOS =
        IOSInitializationSettings();

    const InitializationSettings initializationSettings =
        InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    await flutterLocalNotificationsPlugin.initialize(initializationSettings,
        onSelectNotification: (String? payload) {
      if (payload != null) OpenFile.open(pathurl);
    });
  }

  Future<void> _requestNotificationPermissions() async {
    final status = await Permission.notification.status;

    if (status.isDenied) {
      await Permission.notification.request();
    }
  }

  Future onPopScopePressBackShowAlertDialog() async {
    showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text(
              'Apa Anda yakin untuk meninggalkan Reservasi Antrean?',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, height: 1.6),
            ),
            shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.all(Radius.circular(16))),
            contentPadding: const EdgeInsets.only(
                left: 10.0, right: 10.0, top: 8.0, bottom: 5.0),
            actions: <Widget>[
              ElevatedButton(
                child: const Text('Keluar',
                    style: TextStyle(color: Color.fromRGBO(215, 52, 2, 1))),
                onPressed: () {
                  exit(0);
                },
                style: ButtonStyle(
                    shape: MaterialStateProperty.all<RoundedRectangleBorder>(
                        RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)))),
              ),
              ElevatedButton(
                child: const Text('Tetap',
                    style: TextStyle(color: Color.fromRGBO(0, 123, 218, 1))),
                onPressed: () {
                  Navigator.pop(context);
                },
                style: ButtonStyle(
                    shape: MaterialStateProperty.all<RoundedRectangleBorder>(
                        RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16)))),
              ),
            ],
          );
        });
  }
}
