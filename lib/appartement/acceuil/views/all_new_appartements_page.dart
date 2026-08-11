import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../details/appartement_detail_page.dart';
import '../services/appartement_service.dart';
import '../widgets/appartement_card.dart';
import 'package:service/database_service.dart';


class NouveauxAppartementsPage extends StatefulWidget {

  const NouveauxAppartementsPage({
    super.key,
  });


  @override
  State<NouveauxAppartementsPage> createState() =>
      _NouveauxAppartementsPageState();

}



class _NouveauxAppartementsPageState
    extends State<NouveauxAppartementsPage> {


  late Future<List<Map<String,dynamic>>> futureApps;


  @override
  void initState() {
    super.initState();

    futureApps =
        _chargerNouveaux();

  }



  Future<List<Map<String,dynamic>>> _chargerNouveaux() async {

    final data =
    await AppartementService()
        .loadAllData();


    final apps =
        (data['appartements'] as List?)
            ?.cast<Map<String,dynamic>>()
            ?? [];


    apps.sort((a,b){

      final dateA =
      DateTime.tryParse(
          a['created_at'].toString()
      );

      final dateB =
      DateTime.tryParse(
          b['created_at'].toString()
      );


      if(dateA == null) return 1;
      if(dateB == null) return -1;


      return dateB.compareTo(dateA);

    });


    return apps;

  }



  void ouvrirDetail(Map<String,dynamic> app){

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            AppartementDetailPage(
              appartement: app,
              appartementService: DatabaseService(),
            ),
      ),
    );

  }



  @override
  Widget build(BuildContext context){

    return Scaffold(

      backgroundColor:
      const Color(0xFFFFEFE0),


      appBar: AppBar(

        title:
        const Text(
          "Nouveautés",
        ),

        backgroundColor:
        const Color(0xFFE85D26),

        foregroundColor:
        Colors.white,

      ),


      body: FutureBuilder(

        future: futureApps,

        builder:(context,snapshot){


          if(!snapshot.hasData){

            return const Center(
              child:
              CircularProgressIndicator(color: Color(0xFFE85D26)),
            );

          }


          final apps =
          snapshot.data!;


          return ListView.builder(

            padding:
            EdgeInsets.all(16.w),

            itemCount:
            apps.length,


            itemBuilder:(context,index){

              return Padding(

                padding:
                EdgeInsets.only(
                  bottom:12.h,
                ),


                child: AppartementCard(

                  app:apps[index],

                  isCompact:true,


                  onTap:() =>
                      ouvrirDetail(
                          apps[index]
                      ),

                ),

              );

            },

          );


        },

      ),

    );

  }

}