import 'package:krimson/common/service/api/api_service.dart';
import 'package:krimson/common/service/utils/params.dart';
import 'package:krimson/common/service/utils/web_service.dart';
import 'package:krimson/model/agency/agency_dashboard_model.dart';
import 'package:krimson/model/user_model/user_model.dart';

class AgencyService {
  AgencyService._();
  static final AgencyService instance = AgencyService._();

  Future<AgencyDashboard> fetchDashboard() async {
    final json = await ApiService.instance.call<Map<String, dynamic>>(
      url: WebService.user.agencyListWorkers,
      param: const {},
      fromJson: (j) => j,
    );
    if (json['status'] != true) {
      throw Exception(json['message'] ?? 'No se pudieron cargar los workers');
    }
    return AgencyDashboard.fromJson(json);
  }

  Future<List<User>> listWorkers() async {
    final dash = await fetchDashboard();
    return dash.workers
        .map((w) => User(
              id: w.user.id,
              fullname: w.user.fullname,
              username: w.user.username,
              identity: w.user.identity,
              userEmail: w.user.userEmail,
              profilePhoto: w.user.profilePhoto,
              coinWallet: w.stats.streamerWallet,
              coinCollectedLifetime: w.stats.streamerEarnedLifetime,
              weeklyCallGrade: w.user.weeklyCallGrade,
              isFreez: w.user.isFreez,
            ))
        .toList();
  }

  Future<User> createWorker({
    required String fullname,
    required String identity,
    required String password,
    String? username,
  }) async {
    final json = await ApiService.instance.call<Map<String, dynamic>>(
      url: WebService.user.agencyCreateWorker,
      param: {
        Params.fullname: fullname,
        Params.identity: identity,
        Params.password: password,
        if (username != null && username.trim().isNotEmpty)
          Params.username: username.trim(),
      },
      fromJson: (j) => j,
    );
    if (json['status'] != true) {
      throw Exception(json['message'] ?? 'No se pudo crear el streamer');
    }
    final data = Map<String, dynamic>.from(json['data'] as Map? ?? {});
    final worker = data['worker'];
    if (worker is Map) {
      return User.fromJson(Map<String, dynamic>.from(worker));
    }
    throw Exception('Respuesta inválida');
  }
}
