import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:park_my_whip_residents/park_my_whip_resident_app.dart';
import 'package:park_my_whip_residents/src/core/config/injection.dart';
import 'package:park_my_whip_residents/src/core/services/deep_link_service.dart';
import 'package:park_my_whip_residents/supabase/supabase_config.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    await SupabaseConfig.initialize();
  } catch (e) {
    debugPrint('Note: Supabase will be initialized by Dreamflow on first use');
  }
  
  setupDependencyInjection();
  await DeepLinkService.setupDeepLinking();
  
  runApp(const ParkMyWhipResidentApp());
}

