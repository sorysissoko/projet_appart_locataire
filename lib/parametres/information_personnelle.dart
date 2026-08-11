import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:service/database_service.dart';
import '../../widgets/parametre_header.dart';
import 'package:service/auth_service.dart';
import 'package:service/service_locator.dart';

class InformationPersonnellePage extends StatefulWidget {
  const InformationPersonnellePage({super.key});

  @override
  State<InformationPersonnellePage> createState() =>
      _InformationPersonnellePageState();
}

class _InformationPersonnellePageState extends State<InformationPersonnellePage> {
  final AuthService _auth = ServiceLocator.auth;
  final DatabaseService _db = ServiceLocator.database;

  Map<String, dynamic>? _userData;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    // ✅ Vérifier si le widget est encore monté avant de setState
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final user = _auth.currentUser;
      if (user == null) {
        if (!mounted) return;
        setState(() {
          _errorMessage = 'Utilisateur non connecté';
          _isLoading = false;
        });
        return;
      }

      final response = await _db.supabase
          .from('users')
          .select('''
            id,
            nom,
            prenom,
            telephone,
            adresse,
            email,
            urgencephone,
            date_naissance,
            statut,
            pays,
            ville,
            code_postal,
            is_verified
          ''')
          .eq('id', user.id)
          .maybeSingle();

      // ✅ Vérifier si le widget est encore monté après l'appel async
      if (!mounted) return;

      if (response != null) {
        setState(() {
          _userData = Map<String, dynamic>.from(response);
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = 'Données utilisateur non trouvées';
          _isLoading = false;
        });
      }
    } catch (e) {
      // ✅ Vérifier si le widget est encore monté
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Erreur: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  Future<void> _updateUserField(String field, String value) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      await _db.supabase
          .from('users')
          .update({field: value})
          .eq('id', user.id);

      // Recharger les données
      await _loadUserData();

      // ✅ Vérifier si le widget est encore monté
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✅ $field mis à jour avec succès'),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 2),
        ),
      );
    } catch (e) {
      // ✅ Vérifier si le widget est encore monté
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Erreur: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showEditDialog({
    required String title,
    required String field,
    required String currentValue,
    String? hintText,
    TextInputType keyboardType = TextInputType.text,
  }) {
    final controller = TextEditingController(text: currentValue);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        title: Text('Modifier $title'),
        content: TextField(
          controller: controller,
          keyboardType: keyboardType,
          decoration: InputDecoration(
            hintText: hintText ?? 'Entrez $title',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () async {
              final newValue = controller.text.trim();
              if (newValue.isNotEmpty && newValue != currentValue) {
                // ✅ Fermer le dialog avant l'opération async
                Navigator.pop(dialogContext);
                await _updateUserField(field, newValue);
              } else {
                Navigator.pop(dialogContext);
              }
            },
            child: const Text('Enregistrer'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          const ParametreHeader(title: "Informations personnelles"),
          Padding(
            padding: const EdgeInsets.only(top: 170, left: 16, right: 16),
            child: _buildContent(),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(
            color: Color(0xFFE85D26),
            strokeWidth: 2
        ),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red[300],
            ),
            const SizedBox(height: 16),
            Text(
              _errorMessage!,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 16,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadUserData,
              child: const Text('Réessayer'),
            ),
          ],
        ),
      );
    }

    if (_userData == null) {
      return const Center(
        child: Text('Aucune donnée disponible'),
      );
    }

    final data = _userData!;

    return SingleChildScrollView(
      child: Column(
        children: [
          _buildInfoSection(
            title: "Nom et Prénom",
            value: "${data['prenom'] ?? ''} ${data['nom'] ?? ''}",
            buttonLabel: "Modifier",
            onTap: () {
              _showEditDialog(
                title: 'le nom',
                field: 'nom',
                currentValue: data['nom'] ?? '',
                hintText: 'Votre nom',
              );
            },
          ),
          _divider(),

          _buildInfoSection(
            title: "Prénom",
            value: data['prenom'] ?? "Non défini",
            buttonLabel: "Modifier",
            onTap: () {
              _showEditDialog(
                title: 'le prénom',
                field: 'prenom',
                currentValue: data['prenom'] ?? '',
                hintText: 'Votre prénom',
              );
            },
          ),
          _divider(),

          _buildInfoSection(
            title: "Téléphone",
            value: data['telephone'] ?? "Non défini",
            buttonLabel: "Modifier",
            onTap: () {
              _showEditDialog(
                title: 'le téléphone',
                field: 'telephone',
                currentValue: data['telephone'] ?? '',
                hintText: '+223 XX XX XX XX',
                keyboardType: TextInputType.phone,
              );
            },
          ),
          _divider(),

          _buildInfoSection(
            title: "Adresse de résidence",
            value: data['adresse'] ?? "Non renseigné",
            buttonLabel: "Modifier",
            onTap: () {
              _showEditDialog(
                title: "l'adresse",
                field: 'adresse',
                currentValue: data['adresse'] ?? '',
                hintText: 'Votre adresse',
              );
            },
          ),
          _divider(),

          _buildInfoSection(
            title: "Téléphone d'urgence",
            value: data['urgencephone'] ?? "Non renseigné",
            buttonLabel: "Modifier",
            onTap: () {
              _showEditDialog(
                title: "le téléphone d'urgence",
                field: 'urgencephone',
                currentValue: data['urgencephone'] ?? '',
                hintText: '+223 XX XX XX XX',
                keyboardType: TextInputType.phone,
              );
            },
          ),
          _divider(),

          _buildInfoSection(
            title: "Ville",
            value: data['ville'] ?? "Non renseigné",
            buttonLabel: "Modifier",
            onTap: () {
              _showEditDialog(
                title: "la ville",
                field: 'ville',
                currentValue: data['ville'] ?? '',
                hintText: 'Votre ville',
              );
            },
          ),
          _divider(),

          _buildInfoSection(
            title: "Pays",
            value: data['pays'] ?? "Non renseigné",
            buttonLabel: "Modifier",
            onTap: () {
              _showEditDialog(
                title: "le pays",
                field: 'pays',
                currentValue: data['pays'] ?? '',
                hintText: 'Votre pays',
              );
            },
          ),
          _divider(),

          _buildInfoOnly(
            title: "Email",
            value: data['email'] ?? "Non défini",
          ),
          _divider(),

          _buildInfoOnly(
            title: "Date de naissance",
            value: data['date_naissance'] != null
                ? _formatDate(data['date_naissance'])
                : "Non renseignée",
          ),
          _divider(),

          _buildInfoOnly(
            title: "Vérification d'identité",
            value: data['is_verified'] == true ? "✅ Vérifiée" : "⏳ En attente",
            valueColor: data['is_verified'] == true ? Colors.green : Colors.orange,
          ),
          _divider(),

          _buildInfoOnly(
            title: "Statut",
            value: _getStatusText(data['statut'] ?? 'inactif'),
          ),
          _divider(),

          const SizedBox(height: 20),
        ],
      ),
    );
  }

  String _formatDate(dynamic date) {
    if (date == null) return '';
    try {
      if (date is DateTime) {
        return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
      }
      final parsed = DateTime.parse(date.toString());
      return '${parsed.day.toString().padLeft(2, '0')}/${parsed.month.toString().padLeft(2, '0')}/${parsed.year}';
    } catch (e) {
      return date.toString();
    }
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'actif':
        return '🟢 Actif';
      case 'inactif':
        return '🔴 Inactif';
      case 'suspendu':
        return '🟠 Suspendu';
      case 'bloque':
        return '⚫ Bloqué';
      default:
        return status;
    }
  }

  // ---- Widget Section avec bouton ----
  Widget _buildInfoSection({
    required String title,
    required String value,
    required String buttonLabel,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.inter(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  value,
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: value == "Non défini" || value == "Non renseigné"
                        ? Colors.grey[400]
                        : Colors.black54,
                  ),
                ),
              ],
            ),
          ),
          InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(20),
            child: Container(
              width: 90,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.black87,
                borderRadius: BorderRadius.circular(20),
              ),
              alignment: Alignment.center,
              child: Text(
                buttonLabel,
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ---- Widget Section SANS bouton ----
  Widget _buildInfoOnly({
    required String title,
    required String value,
    Color? valueColor,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.inter(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                value,
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: valueColor ?? Colors.black54,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ---- Divider standard ----
  Widget _divider() {
    return const Divider(
      thickness: 1,
      indent: 20,
      endIndent: 20,
      color: Color(0xFFE0E0E0),
    );
  }
}