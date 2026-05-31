import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_constants.dart';
import '../models/login_request_model.dart';
import '../models/login_response_model.dart';
import '../models/register_request_model.dart';
import '../models/register_response_model.dart';

class AuthService {
  Future<LoginResponseModel> login(LoginRequestModel request) async {
    final json = await ApiClient.post(ApiConstants.login, request.toJson());
    return LoginResponseModel.fromJson(json);
  }

  Future<RegisterResponseModel> register(RegisterRequestModel request) async {
    final json = await ApiClient.post(ApiConstants.register, request.toJson());
    return RegisterResponseModel.fromJson(json);
  }
}
