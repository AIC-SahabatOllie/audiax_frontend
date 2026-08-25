import 'package:flutter/material.dart';

import '../core/errors/api_exception.dart';
import '../core/network/api_client.dart';
import '../core/network/session_store.dart';
import '../features/auth/data/auth_repository.dart';
import '../features/auth/presentation/screens/landing_screen.dart';
import '../features/machine_management/presentation/screens/machines_screen.dart';
import '../shared/models/user.dart';
import '../shared/services/advisory_api.dart';
import '../shared/services/baselines_api.dart';
import '../shared/services/inspections_api.dart';
import '../shared/services/machine_repository.dart';
import '../shared/services/machines_api.dart';
import 'theme/app_colors.dart';
import 'theme/app_theme.dart';

enum _BootPhase { checking, unauthenticated, authenticated }

/// Root widget of the AUDIAX app — owns the network/session singletons and
/// decides whether to show the login flow or the machine dashboard, per
/// `docs/api_contract.md` §1 "Autentikasi": a stored, still-valid Bearer
/// token skips straight to the fleet; anything else lands on the landing
/// screen, which offers Login/Register from there.
class AudiaxApp extends StatefulWidget {
  const AudiaxApp({super.key});

  @override
  State<AudiaxApp> createState() => _AudiaxAppState();
}

class _AudiaxAppState extends State<AudiaxApp> {
  late final SessionStore _sessionStore = SessionStore();
  late final ApiClient _apiClient = ApiClient(sessionStore: _sessionStore);
  late final AuthRepository _authRepository = AuthRepository(
    client: _apiClient,
    sessionStore: _sessionStore,
  );
  late final MachinesApi _machinesApi = MachinesApi(_apiClient);
  late final BaselinesApi _baselinesApi = BaselinesApi(_apiClient);
  late final InspectionsApi _inspectionsApi = InspectionsApi(_apiClient);
  late final AdvisoryApi _advisoryApi = AdvisoryApi(_apiClient);

  _BootPhase _phase = _BootPhase.checking;
  User? _user;
  MachineRepository? _machineRepository;

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    await _sessionStore.load();
    if (!_sessionStore.isAuthenticated) {
      if (!mounted) return;
      setState(() => _phase = _BootPhase.unauthenticated);
      return;
    }
    try {
      final user = await _authRepository.currentUser();
      _enterAuthenticated(user);
    } on ApiException {
      await _sessionStore.clear();
      if (!mounted) return;
      setState(() => _phase = _BootPhase.unauthenticated);
    }
  }

  Future<void> _onAuthenticated() async {
    final user = await _authRepository.currentUser();
    _enterAuthenticated(user);
  }

  void _enterAuthenticated(User user) {
    final repository = MachineRepository(
      machinesApi: _machinesApi,
      baselinesApi: _baselinesApi,
      inspectionsApi: _inspectionsApi,
      advisoryApi: _advisoryApi,
    );
    repository.load();
    if (!mounted) return;
    setState(() {
      _user = user;
      _machineRepository = repository;
      _phase = _BootPhase.authenticated;
    });
  }

  void _onLoggedOut() {
    _machineRepository?.dispose();
    setState(() {
      _machineRepository = null;
      _user = null;
      _phase = _BootPhase.unauthenticated;
    });
  }

  @override
  void dispose() {
    _machineRepository?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AUDIAX',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      home: switch (_phase) {
        _BootPhase.checking => const _SplashScreen(),
        _BootPhase.unauthenticated => LandingScreen(
          authRepository: _authRepository,
          onAuthenticated: _onAuthenticated,
        ),
        _BootPhase.authenticated => MachinesScreen(
          repository: _machineRepository!,
          user: _user!,
          authRepository: _authRepository,
          onLoggedOut: _onLoggedOut,
        ),
      },
    );
  }
}

class _SplashScreen extends StatelessWidget {
  const _SplashScreen();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: AppColors.screenBackground,
      body: Center(child: CircularProgressIndicator(color: AppColors.brand)),
    );
  }
}
