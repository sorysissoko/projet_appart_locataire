import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../details/appartement_detail_page.dart';
import '../services/appartement_service.dart';
import '../widgets/appartement_card.dart';
import 'package:service/database_service.dart';

class NouveauxAppartementsPage extends StatefulWidget {
  const NouveauxAppartementsPage({super.key});

  @override
  State<NouveauxAppartementsPage> createState() =>
      _NouveauxAppartementsPageState();
}

class _NouveauxAppartementsPageState extends State<NouveauxAppartementsPage> {
  late Future<List<Map<String, dynamic>>> futureApps;


  Map<String, bool> _disponibilites = {};

  final DatabaseService _dbService = DatabaseService();

  @override
  void initState() {
    super.initState();
    futureApps = _chargerNouveaux();
  }

  Future<List<Map<String, dynamic>>> _chargerNouveaux() async {
    final data = await AppartementService().loadAllData();

    final apps = (data['appartements'] as List?)
        ?.cast<Map<String, dynamic>>() ??
        [];

    apps.sort((a, b) {
      final dateA = DateTime.tryParse(a['created_at'].toString());
      final dateB = DateTime.tryParse(b['created_at'].toString());
      if (dateA == null) return 1;
      if (dateB == null) return -1;
      return dateB.compareTo(dateA);
    });

    // ==========================================================
    // ✅ CHARGER LES DISPONIBILITÉS EN BATCH
    // ==========================================================
    final ids = apps
        .map((a) => a['id']?.toString())
        .whereType<String>()
        .toList();

    _disponibilites = await _dbService.fetchDisponibiliteActuelleBatch(ids);

    if (mounted) setState(() {});

    return apps;
  }

  void ouvrirDetail(Map<String, dynamic> app) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AppartementDetailPage(
          appartement: app,
          appartementService: _dbService,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFEFE0),
      appBar: AppBar(
        title: const Text("Nouveautés"),
        backgroundColor: const Color(0xFFE85D26),
        foregroundColor: Colors.white,
      ),
      body: FutureBuilder(
        future: futureApps,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFFE85D26)),
            );
          }

          final apps = snapshot.data!;

          return ListView.builder(
            padding: EdgeInsets.all(16.w),
            itemCount: apps.length,
            itemBuilder: (context, index) {
              final app = apps[index];
              final appId = app['id']?.toString() ?? '';

              // ✅ Statut de dispo
              final isDisponible = _disponibilites[appId] ?? false;

              return Padding(
                padding: EdgeInsets.only(bottom: 12.h),
                child: AppartementCard(
                  app: app,
                  isCompact: true,

                  // ✅ Passer le statut au widget
                  isDisponible: isDisponible,

                  onTap: () => ouvrirDetail(app),
                ),
              );
            },
          );
        },
      ),
    );
  }
}