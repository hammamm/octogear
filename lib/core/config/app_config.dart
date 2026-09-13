import 'environment.dart';

class AppConfig {
  static const Environment environment = Environment.dev;

  static String get baseUrl {
    switch (environment) {
      case Environment.dev:
        return 'http://0.0.0.0:8000/api/v1/';
      case Environment.test:
        return 'http://JHR-staging-env.eba-gkjaypcc.ap-south-1.elasticbeanstalk.com/api/v1/';

      case Environment.prod:
        return 'https://jaldom.com/api/v1/';
    }
  }
}
