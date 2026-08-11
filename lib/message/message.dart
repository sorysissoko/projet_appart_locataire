import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../widgets/appbar.dart'; // Import de ton AppBar personnalisé

class MessagePage extends StatefulWidget {
  const MessagePage({super.key});

  @override
  State<MessagePage> createState() => _MessagePageState();
}

class _MessagePageState extends State<MessagePage> {
  final Color accentColor = const Color(0xFFE85D26);

  // Exemple de données fictives pour tes discussions (à lier avec Supabase plus tard)
  final List<Map<String, dynamic>> _mockChats = [
    {
      "id": "1",
      "nom": "Moussa Diarra",
      "initiales": "MD",
      "dernierMessage": "Bonjour, l'appartement à Bamako est-il toujours disponible ?",
      "heure": "14:32",
      "nonLu": 2,
    },
    {
      "id": "2",
      "nom": "Fatoumata Coulibaly",
      "initiales": "FC",
      "dernierMessage": "Merci pour votre réactivité ! À demain pour la visite.",
      "heure": "Hier",
      "nonLu": 0,
    },
    {
      "id": "3",
      "nom": "Amadou Traoré",
      "initiales": "AT",
      "dernierMessage": "Le prix pour la villa à Ségou est-il négociable ?",
      "heure": "05 Juin",
      "nonLu": 0,
    }
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFEFE0),
      // Appel de ton AppBar personnalisé avec le bon titre
      appBar: const CustomAppBar(title: "Messages"),
      body: _mockChats.isEmpty
          ? _buildEmptyState()
          : ListView.builder(
        padding: EdgeInsets.symmetric(vertical: 12.h, horizontal: 16.w),
        itemCount: _mockChats.length,
        itemBuilder: (context, index) {
          final chat = _mockChats[index];
          return _buildChatTile(chat);
        },
      ),
    );
  }

  /// Élément individuel de la liste des discussions (un salon de discussion)
  Widget _buildChatTile(Map<String, dynamic> chat) {
    final bool hasUnread = chat['nonLu'] > 0;

    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF5EC),
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
        leading: Container(
          width: 50.w,
          height: 50.h,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              colors: [accentColor, const Color(0xFFFF8A50)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Center(
            child: Text(
              chat['initiales'],
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              chat['nom'],
              style: TextStyle(
                fontSize: 15.sp,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            Text(
              chat['heure'],
              style: TextStyle(
                fontSize: 11.sp,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
        subtitle: Padding(
          padding: EdgeInsets.only(top: 6.h),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  chat['dernierMessage'],
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13.sp,
                    color: hasUnread ? Colors.black : Colors.grey.shade600,
                    fontWeight: hasUnread ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
              ),
              if (hasUnread)
                Container(
                  margin: EdgeInsets.only(left: 8.w),
                  padding: EdgeInsets.all(6.w),
                  decoration: BoxDecoration(
                    color: accentColor,
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    chat['nonLu'].toString(),
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
        ),
        onTap: () {
          // Action lors du clic sur la discussion (ouvrir le chat complet)
        },
      ),
    );
  }

  /// Écran affiché si la boîte de réception est vide
  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(32.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.mail_outline, size: 80.sp, color: Colors.grey[400]),
            SizedBox(height: 16.h),
            Text(
              "Aucun message",
              style: TextStyle(
                fontSize: 18.sp,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF2D3748),
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              "Vos conversations avec les propriétaires de logements au Mali s'afficheront ici.",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14.sp, color: const Color(0xFF718096)),
            ),
          ],
        ),
      ),
    );
  }
}