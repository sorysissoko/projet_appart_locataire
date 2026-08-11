import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:service/snackbar_service.dart';
import 'package:service/database_service.dart';

import '../details/appartement_detail_page.dart';
import '../providers/tab_provider.dart';
import '../widgets/appbar.dart';
import 'favorites_service.dart';
import 'widgets/favorite_card.dart';

class FavoritesPage extends StatefulWidget {
  const FavoritesPage({super.key});

  @override
  State<FavoritesPage> createState() => _FavoritesPageState();
}

class _FavoritesPageState extends State<FavoritesPage> with AutomaticKeepAliveClientMixin {
  final Color accentColor = const Color(0xFFE85D26);

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    // Appel initial une fois le widget construit
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<FavoritesService>().loadFavorites();
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return Scaffold(
      backgroundColor: const Color(0xFFFFEFE0),
      appBar: CustomAppBar(title: "Mes favoris"),
      body: Consumer<FavoritesService>(
        builder: (context, service, child) {
          if (service.isLoading && service.favorites.isEmpty) {
            return const Center(
              child: CircularProgressIndicator(
                color: Color(0xFFE85D26),
                strokeWidth: 2
            ),);
          }

          return RefreshIndicator(
            onRefresh: () => service.loadFavorites(background: true),
            color: accentColor,
            backgroundColor: const Color(0xFFFFF5EC),
            child: service.favorites.isEmpty
                ? LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: Container(
                    constraints: BoxConstraints(minHeight: constraints.maxHeight),
                    child: _buildEmptyState(),
                  ),
                );
              },
            )
                : ListView.builder(
              padding: EdgeInsets.all(16.w),
              physics: const AlwaysScrollableScrollPhysics(),
              itemCount: service.favorites.length,
              itemBuilder: (context, index) {
                final favorite = service.favorites[index];
                return Padding(
                  padding: EdgeInsets.only(bottom: 16.h),
                  child: FavoriteCard(
                    favorite: favorite,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => AppartementDetailPage(
                            appartement: favorite.appartement,
                            appartementService: DatabaseService(),
                          ),
                        ),
                      );
                    },
                    onDelete: () => _showDeleteDialog(context, favorite.id, service),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }

  void _showDeleteDialog(BuildContext context, String favoriteId, FavoritesService service) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.r)),
        title: const Text("Retirer des favoris ?"),
        content: const Text("Ce logement sera retiré de votre liste de favoris."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Annuler", style: TextStyle(color: Colors.grey.shade600)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await service.removeFavorite(favoriteId);
                if (context.mounted) {
                  SnackBarService().showSuccess('Retiré des favoris ❤️');
                }
              } catch (e) {
                if (context.mounted) {
                  SnackBarService().showError('Erreur lors de la suppression');
                }
              }
            },
            child: const Text("Retirer", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(32.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.favorite_border, size: 80.sp, color: Colors.grey[300]),
            SizedBox(height: 16.h),
            Text(
              "Aucun coup de cœur ?",
              style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold, color: const Color(0xFF2D3748)),
            ),
            SizedBox(height: 8.h),
            Text(
              "Explorez les logements disponibles au Mali et ajoutez-les à vos favoris pour les retrouver ici.",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14.sp, color: const Color(0xFF718096)),
            ),
            SizedBox(height: 24.h),
            ElevatedButton(
              onPressed: () {
                final tabProvider = Provider.of<TabProvider>(context, listen: false);
                tabProvider.goToHome();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: accentColor,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 12.h),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30.r)),
              ),
              child: const Text("Découvrir des logements"),
            ),
          ],
        ),
      ),
    );
  }
}