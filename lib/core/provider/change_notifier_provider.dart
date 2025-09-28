
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../session/app_session.dart';

final appSessionProvider = ChangeNotifierProvider<AppSession>((ref) {
  return AppSession.instance;
});