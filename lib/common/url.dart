class UrlData {
  // PocketBase GCP Server
  final String baseUrl = 'http://34.101.210.210:8080';
  final String apiUrl = 'http://34.101.210.210:8080/api';

  // PocketBase Collections Endpoints
  final String url_users = 'http://34.101.210.210:8080/api/collections/users';
  final String url_devices =
      'http://34.101.210.210:8080/api/collections/devices';
  final String url_sensor_data =
      'http://34.101.210.210:8080/api/collections/sensor_data';
  final String url_controls =
      'http://34.101.210.210:8080/api/collections/controls';

  // Authentication
  final String url_login =
      'http://34.101.210.210:8080/api/collections/users/auth-with-password';
  final String url_register =
      'http://34.101.210.210:8080/api/collections/users/records';

  // File Storage
  final String url_images = 'http://34.101.210.210:8080/api/files/';

  // Scheduling Collections Endpoints
  final String url_schedules =
      'http://34.101.210.210:8080/api/collections/schedules';
  final String url_automation_rules =
      'http://34.101.210.210:8080/api/collections/automation_rules';
  final String url_schedule_executions =
      'http://34.101.210.210:8080/api/collections/schedule_executions';

  // Legacy endpoints mapping (untuk backward compatibility)
  final String url_summary =
      'http://34.101.210.210:8080/api/collections/devices/records'; // data utama
  final String url_realtime =
      'http://34.101.210.210:8080/api/collections/sensor_data/records'; // data sensor
  final String url_kontrol =
      'http://34.101.210.210:8080/api/collections/controls/records'; // kontrol alat
  final String url_status_alat =
      'http://34.101.210.210:8080/api/collections/devices/records'; // status alat
  final String url_update_kontrol =
      'http://34.101.210.210:8080/api/collections/controls/records'; // update kontrol
}
