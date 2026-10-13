import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../data/equipements_categories.dart';

class EquipementsSection extends StatelessWidget {
  final Map<String, dynamic> appartement;

  const EquipementsSection({
    super.key,
    required this.appartement,
  });

  static const Color orange = Color(0xFFE85D26);
  static const Color orangeLight = Color(0xFFF16522);
  static const Color orangeDark = Color(0xFFC5521B);
  static const Color textBrown = Color(0xE58A4E1E);

  @override
  Widget build(BuildContext context) {
    final data = appartement['autres_equipements'];

    Map<String, dynamic> raw = {};

    if (data is Map) {
      raw = Map<String, dynamic>.from(data);
    } else if (data is String && data.isNotEmpty) {
      try {
        final decoded = jsonDecode(data);

        if (decoded is Map) {
          raw = Map<String, dynamic>.from(decoded);
        }
      } catch (_) {
        return const SizedBox.shrink();
      }
    }

    final Set<String> equipementsActifs = raw.entries
        .where(
          (e) => e.value == true,
    )
        .map(
          (e) => e.key.toString(),
    )
        .toSet();

    final List<Map<String, dynamic>> tousLesEquipements = [];

    for (final categoryKey
    in EquipementsCategories.data.keys) {
      final category =
      EquipementsCategories.data[categoryKey];

      if (category == null) continue;

      final items =
      category['items'] as Map<String, dynamic>;

      for (final itemKey in items.keys) {
        tousLesEquipements.add({
          'key': itemKey,
          'label':
          EquipementsCategories.getLabelForKey(
            itemKey,
          ),
          'icon':
          EquipementsCategories.getIconForKey(
            itemKey,
          ),
          'actif':
          equipementsActifs.contains(itemKey),
        });
      }
    }

    final actifs = tousLesEquipements
        .where(
          (item) => item['actif'] == true,
    )
        .toList();

    final preview = actifs.take(5).toList();

    final restants = actifs.length > 5
        ? actifs.length - 5
        : 0;

    final hasMore = restants > 0;

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: 16.w,
        vertical: 12.h,
      ),
      child: Column(
        crossAxisAlignment:
        CrossAxisAlignment.start,
        children: [
          Text(
            'Autres équipements',
            style: GoogleFonts.poppins(
              fontSize: 20.sp,
              fontWeight: FontWeight.w600,
              color: orange,
            ),
          ),

          SizedBox(height: 12.h),

          ...preview.map(
                (item) {
              return Padding(
                padding: EdgeInsets.symmetric(
                  vertical: 4.h,
                ),
                child: Row(
                  crossAxisAlignment:
                  CrossAxisAlignment.center,
                  children: [
                    Icon(
                      item['icon'],
                      size: 24.sp,
                      color: orangeLight,
                    ),

                    SizedBox(width: 12.w),

                    Expanded(
                      child: Text(
                        item['label']
                            ?.toString() ??
                            '',
                        maxLines: 2,
                        overflow:
                        TextOverflow.ellipsis,
                        style: GoogleFonts.poppins(
                          fontSize: 16.sp,
                          color: textBrown,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),

          SizedBox(height: 16.h),

          SizedBox(
            width: double.infinity,
            height: 50.h,
            child: Container(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [
                    orangeLight,
                    orangeDark,
                  ],
                ),
                borderRadius:
                BorderRadius.circular(25.r),
                boxShadow: [
                  BoxShadow(
                    color: orange.withValues(
                      alpha: 0.20,
                    ),
                    blurRadius: 5,
                    offset:
                    const Offset(0, 2),
                  ),
                ],
              ),
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                  Colors.transparent,
                  foregroundColor:
                  Colors.white,
                  shadowColor:
                  Colors.transparent,
                  padding:
                  EdgeInsets.symmetric(
                    horizontal: 16.w,
                  ),
                  shape:
                  RoundedRectangleBorder(
                    borderRadius:
                    BorderRadius.circular(
                      25.r,
                    ),
                  ),
                ),
                onPressed: () {
                  _showAllEquipementsModal(
                    context,
                    tousLesEquipements,
                  );
                },
                child: Row(
                  mainAxisAlignment:
                  MainAxisAlignment.center,
                  children: [
                    Flexible(
                      child: Text(
                        hasMore
                            ? 'Voir les $restants autres équipements'
                            : 'Voir tous les ${actifs.length} équipements',
                        maxLines: 1,
                        overflow:
                        TextOverflow.ellipsis,
                        textAlign:
                        TextAlign.center,
                        style: GoogleFonts.poppins(
                          fontSize: 15.sp,
                          fontWeight:
                          FontWeight.w600,
                        ),
                      ),
                    ),

                    SizedBox(width: 8.w),

                    Icon(
                      Icons.arrow_forward,
                      size: 20.sp,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // MODAL
  void _showAllEquipementsModal(
      BuildContext context,
      List<Map<String, dynamic>>
      tousLesEquipements,
      ) {
    if (tousLesEquipements.isEmpty) {
      return;
    }

    final Map<String,
        List<Map<String, dynamic>>>
    equipementsParCategorie = {};

    for (final item in tousLesEquipements) {
      final key = item['key'];

      final categoryKey =
      EquipementsCategories
          .getCategoryForKey(key);

      if (categoryKey == null) continue;

      equipementsParCategorie
          .putIfAbsent(
        categoryKey,
            () => [],
      )
          .add(item);
    }

    final categories =
    equipementsParCategorie.keys.toList();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.80,
          maxChildSize: 0.95,
          minChildSize: 0.45,
          builder: (_, controller) {
            return Container(
              padding: EdgeInsets.fromLTRB(
                16.w,
                12.h,
                16.w,
                20.h,
              ),
              decoration:
              BoxDecoration(
                color: const Color(
                  0xFFFFF5EC,
                ),
                borderRadius:
                BorderRadius.vertical(
                  top: Radius.circular(
                    25.r,
                  ),
                ),
              ),
              child: Column(
                children: [
                  Container(
                    width: 40.w,
                    height: 4.h,
                    margin:
                    EdgeInsets.only(
                      bottom: 14.h,
                    ),
                    decoration:
                    BoxDecoration(
                      color: Colors.grey,
                      borderRadius:
                      BorderRadius
                          .circular(
                        10.r,
                      ),
                    ),
                  ),

                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Autres équipements',
                          maxLines: 1,
                          overflow:
                          TextOverflow
                              .ellipsis,
                          style: GoogleFonts.poppins(
                            fontSize: 21.sp,
                            fontWeight:
                            FontWeight
                                .bold,
                            color: orange,
                          ),
                        ),
                      ),

                      IconButton(
                        onPressed: () {
                          Navigator.pop(
                            context,
                          );
                        },
                        icon: Icon(
                          Icons.close,
                          size: 22.sp,
                          color:
                          Colors.grey[500],
                        ),
                      ),
                    ],
                  ),

                  SizedBox(height: 6.h),

                  Expanded(
                    child:
                    ListView.builder(
                      controller:
                      controller,
                      physics:
                      const BouncingScrollPhysics(),
                      itemCount:
                      categories.length,
                      itemBuilder:
                          (context, index) {
                        final categoryKey =
                        categories[
                        index];

                        final items =
                        equipementsParCategorie[
                        categoryKey]!;

                        final category =
                        EquipementsCategories
                            .data[
                        categoryKey];

                        if (category ==
                            null) {
                          return const SizedBox
                              .shrink();
                        }

                        return Padding(
                          padding:
                          EdgeInsets.only(
                            bottom: 20.h,
                          ),
                          child: Column(
                            crossAxisAlignment:
                            CrossAxisAlignment
                                .start,
                            children: [
                              Text(
                                category[
                                'label'],
                                style:
                                GoogleFonts.poppins(
                                  fontSize:
                                  19.sp,
                                  fontWeight:
                                  FontWeight
                                      .w600,
                                  color:
                                  textBrown,
                                ),
                              ),

                              SizedBox(
                                height: 6.h,
                              ),

                              ...items.map(
                                    (item) {
                                  final isActive =
                                      item[
                                      'actif'] ==
                                          true;

                                  final description =
                                  EquipementsCategories
                                      .getDescriptionForKey(
                                    item[
                                    'key'],
                                    isActive:
                                    isActive,
                                  );

                                  return Padding(
                                    padding:
                                    EdgeInsets.symmetric(
                                      vertical:
                                      6.h,
                                    ),
                                    child:
                                    Column(
                                      crossAxisAlignment:
                                      CrossAxisAlignment
                                          .start,
                                      children: [
                                        Row(
                                          crossAxisAlignment:
                                          CrossAxisAlignment
                                              .center,
                                          children: [
                                            Icon(
                                              item[
                                              'icon'],
                                              size:
                                              28.sp,
                                              color: isActive
                                                  ? orangeLight
                                                  : const Color(
                                                0xBE8A4E1E,
                                              ),
                                            ),

                                            SizedBox(
                                              width:
                                              10.w,
                                            ),

                                            Expanded(
                                              child:
                                              Text(
                                                item[
                                                'label']
                                                    ?.toString() ??
                                                    '',
                                                maxLines:
                                                2,
                                                overflow:
                                                TextOverflow.ellipsis,
                                                style:
                                                GoogleFonts.poppins(
                                                  fontSize:
                                                  17.sp,
                                                  color: isActive
                                                      ? textBrown
                                                      : const Color(
                                                    0xBE8A4E1E,
                                                  ),
                                                  decoration: isActive
                                                      ? null
                                                      : TextDecoration
                                                      .lineThrough,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),

                                        if (description
                                            .isNotEmpty)
                                          Padding(
                                            padding:
                                            EdgeInsets.only(
                                              left:
                                              38.w,
                                              top:
                                              2.h,
                                            ),
                                            child:
                                            Text(
                                              description,
                                              style:
                                              GoogleFonts.poppins(
                                                fontSize:
                                                13.sp,
                                                color:
                                                const Color(
                                                  0xB38A4E1E,
                                                ),
                                                fontStyle:
                                                FontStyle.italic,
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}