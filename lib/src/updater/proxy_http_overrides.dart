import 'dart:io';

class ProxyHttpOverrides extends HttpOverrides {
  final String host;
  final int port;

  ProxyHttpOverrides(this.host, this.port);

  @override
  HttpClient createHttpClient(SecurityContext? context) {
    final client = super.createHttpClient(context);
    client.findProxy = (uri) {
      return "PROXY $host:$port;";
    };
    client.badCertificateCallback = (a, b, c) => true;
    return client;
  }
}