import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../details/appartement_detail_page.dart';
import '../services/appartement_service.dart';
import '../widgets/appartement_card.dart';
import 'package:service/database_service.dart';


class PopulairesAppartementsPage extends StatefulWidget {

  const PopulairesAppartementsPage({
    super.key,
  });


  @override
  State<PopulairesAppartementsPage> createState() =>
      _PopulairesAppartementsPageState();

}



class _PopulairesAppartementsPageState
    extends State<PopulairesAppartementsPage> {


  late Future<List<Map<String,dynamic>>> futureApps;



  @override
  void initState() {

    super.initState();

    futureApps =
        _chargerPopulaires();

  }




  Future<List<Map<String,dynamic>>> _chargerPopulaires() async {


    final data =
    await AppartementService()
        .loadAllData();



    final apps =
        (data['appartements'] as List?)
            ?.cast<Map<String,dynamic>>()
            ?? [];



    // Trier par note décroissante
    apps.sort((a,b){


      final ratingA =
          double.tryParse(
            a['avg_rating']
                ?.toString()
                ?? '0',
          )
              ?? 0;



      final ratingB =
          double.tryParse(
            b['avg_rating']
                ?.toString()
                ?? '0',
          )
              ?? 0;



      return ratingB.compareTo(ratingA);


    });



    return apps;

  }





  void _ouvrirDetail(
      Map<String,dynamic> app
      ){


    Navigator.push(

      context,

      MaterialPageRoute(

        builder: (_) =>
            AppartementDetailPage(

              appartement: app,

              appartementService:
              DatabaseService(),

            ),

      ),

    );


  }






  @override
  Widget build(BuildContext context) {


    return Scaffold(


      backgroundColor:
      const Color(0xFFFFEFE0),



      appBar: AppBar(

        title:
        const Text(
          "Les Plus Populaires",
        ),


        backgroundColor:
        const Color(0xFFE85D26),


        foregroundColor:
        Colors.white,

      ),




      body: FutureBuilder<List<Map<String,dynamic>>>(


        future:
        futureApps,



        builder:(context,snapshot){



          if(snapshot.connectionState ==
              ConnectionState.waiting){


            return const Center(

              child:
              CircularProgressIndicator(
                  color: Color(0xFFE85D26)
              ),

            );


          }




          if(snapshot.hasError){


            return Center(

              child:
              Text(
                "Erreur de chargement",
              ),

            );


          }





          final apps =
              snapshot.data ?? [];





          if(apps.isEmpty){


            return const Center(

              child:
              Text(
                "Aucun appartement trouvé",
              ),

            );


          }





          return ListView.builder(


            padding:
            EdgeInsets.all(16.w),



            itemCount:
            apps.length,



            itemBuilder:(context,index){



              final app =
              apps[index];



              return Padding(


                padding:
                EdgeInsets.only(
                  bottom:12.h,
                ),



                child:
                AppartementCard(


                  app: app,


                  isCompact:true,



                  onTap: () =>
                      _ouvrirDetail(app),


                ),


              );


            },


          );

        },

      ),


    );


  }

}