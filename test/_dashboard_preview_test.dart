// TEMPORARY visual harness — renders the dashboard to PNG for design review.
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:audiax_frontend/app/theme/app_theme.dart';
import 'package:audiax_frontend/core/network/api_client.dart';
import 'package:audiax_frontend/core/network/session_store.dart';
import 'package:audiax_frontend/features/auth/data/auth_repository.dart';
import 'package:audiax_frontend/features/machine_management/presentation/screens/machines_screen.dart';
import 'package:audiax_frontend/shared/models/baseline.dart' as models;
import 'package:audiax_frontend/shared/models/inspection.dart';
import 'package:audiax_frontend/shared/models/machine.dart';
import 'package:audiax_frontend/shared/models/user.dart';
import 'package:audiax_frontend/shared/services/advisory_api.dart';
import 'package:audiax_frontend/shared/services/baselines_api.dart';
import 'package:audiax_frontend/shared/services/inspections_api.dart';
import 'package:audiax_frontend/shared/services/machine_repository.dart';
import 'package:audiax_frontend/shared/services/machines_api.dart';

class FakeRepo extends MachineRepository {
  FakeRepo(this._items, {this.loading = false, this.err})
    : super(
        machinesApi: MachinesApi(ApiClient(sessionStore: SessionStore())),
        baselinesApi: BaselinesApi(ApiClient(sessionStore: SessionStore())),
        inspectionsApi: InspectionsApi(ApiClient(sessionStore: SessionStore())),
        advisoryApi: AdvisoryApi(ApiClient(sessionStore: SessionStore())),
      ) {
    isLoading = loading;
    error = err;
  }

  final List<Machine> _items;
  final bool loading;
  final String? err;

  @override
  List<Machine> get machines => _items;

  @override
  Future<void> load() async {}
}

Machine machine({
  required String id,
  required String label,
  String? location,
  String? status,
  double? z,
  int hoursAgo = 3,
  bool calibrated = true,
  String? reason,
}) {
  final now = DateTime.now();
  return Machine(
    id: id,
    label: label,
    location: location,
    createdAt: now,
    updatedAt: now,
    latestBaseline: calibrated
        ? models.Baseline(
            id: 'b$id',
            machineId: id,
            modelFingerprint: 'fp',
            nWindows: 118,
            calibrationQuality: 'baik',
            isActive: true,
            calibratedAt: now.subtract(const Duration(days: 6)),
          )
        : null,
    latestInspection: status == null
        ? null
        : Inspection(
            id: 'i$id',
            machineId: id,
            baselineId: 'b$id',
            status: InspectionStatusX.fromApi(status),
            zScore: z,
            healthScore: 80,
            dominantIndicator: 'spectral centroid',
            reason: reason,
            disclaimer: 'x',
            inspectedAt: now.subtract(Duration(hours: hoursAgo)),
          ),
  );
}

Future<void> _loadFonts() async {
  Future<void> load(String family, String path) async {
    // Read synchronously: awaiting real file I/O inside the test's fake-async
    // zone never completes.
    final bytes = File(path).readAsBytesSync();
    final loader = FontLoader(family)
      ..addFont(Future<ByteData>.value(ByteData.view(bytes.buffer)));
    await loader.load();
  }

  await load('Roboto', '/System/Library/Fonts/Supplemental/Arial.ttf');
  await load('monospace', '/System/Library/Fonts/Supplemental/Andale Mono.ttf');
}

void main() {
  final user = User(
    id: 'u1',
    email: 'lavinia@pabrik.id',
    name: 'Lavinia Nataniela',
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
  );

  Future<void> shoot(
    WidgetTester tester,
    String name,
    MachineRepository repo, {
    Size size = const Size(390, 1500),
  }) async {
    await tester.binding.setSurfaceSize(size);
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 2.0;
    await tester.pumpWidget(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        home: MachinesScreen(
          repository: repo,
          user: user,
          authRepository: AuthRepository(
            client: ApiClient(sessionStore: SessionStore()),
            sessionStore: SessionStore(),
          ),
          onLoggedOut: () {},
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 900));
    await tester.pump(const Duration(milliseconds: 400));
    await expectLater(
      find.byType(MachinesScreen),
      matchesGoldenFile('preview/$name.png'),
    );
  }

  testWidgets('dashboard - fleet', (tester) async {
    await _loadFonts();
    await shoot(
      tester,
      'dashboard_fleet',
      FakeRepo([
        machine(
          id: '1',
          label: 'Kompresor Utama',
          location: 'Lini A',
          status: 'CRITICAL',
          z: 6.8,
          hoursAgo: 2,
          reason: 'Energi frekuensi tinggi naik tajam dibanding baseline.',
        ),
        machine(
          id: '2',
          label: 'Blower Pengering',
          location: 'Lini B',
          status: 'WARNING',
          z: 3.9,
          hoursAgo: 5,
        ),
        machine(
          id: '3',
          label: 'Konveyor 2',
          location: 'Lini A',
          status: 'NORMAL',
          z: 1.2,
          hoursAgo: 1,
        ),
        machine(id: '4', label: 'Pompa Air', location: 'Utilitas', calibrated: false),
      ]),
      size: const Size(390, 1900),
    );
  });

  testWidgets('dashboard - empty', (tester) async {
    await _loadFonts();
    await shoot(tester, 'dashboard_empty', FakeRepo([]), size: const Size(390, 1050));
  });

  testWidgets('dashboard - loading', (tester) async {
    await _loadFonts();
    await shoot(
      tester,
      'dashboard_loading',
      FakeRepo([], loading: true),
      size: const Size(390, 700),
    );
  });
}
