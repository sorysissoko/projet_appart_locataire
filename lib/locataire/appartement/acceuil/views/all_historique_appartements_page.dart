import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../details/appartement_detail_page.dart';
import '../services/historique_consultation_service.dart';
import '../widgets/appartement_card.dart';
import 'package:service/database_service.dart';


class HistoriqueConsultationsPage extends StatefulWidget {

  const HistoriqueConsultationsPage({
    super.key,
  });


  @override
  State<HistoriqueConsultationsPage> createState() =>
      _HistoriqueConsultationsPageState();

}



class _HistoriqueConsultationsPageState
    extends State<HistoriqueConsultationsPage> {


  final HistoriqueConsultationService service =
  HistoriqueConsultationService();


  late Future<List<Map<String,dynamic>>> futureHistorique;



  @override
  void initState() {
    super.initState();

    futureHistorique =
        service.getHistorique();

  }



  void _refresh(){

    setState(() {

      futureHistorique =
          service.getHistorique();

    });

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
              appartementService: DatabaseService(),
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

        title: const Text(
          "Récemment consultés",
        ),

        backgroundColor:
        const Color(0xFFE85D26),

        foregroundColor:
        Colors.white,


        actions: [

          IconButton(

            icon: const Icon(
              Icons.delete_sweep,
            ),


            onPressed: () async {


              await service
                  .supprimerHistorique();


              _refresh();


            },

          )

        ],

      ),



      body: FutureBuilder<List<Map<String,dynamic>>>(

        future: futureHistorique,


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



          final apps =
              snapshot.data ?? [];



          if(apps.isEmpty){

            return Center(

              child: Column(

                mainAxisAlignment:
                MainAxisAlignment.center,


                children:[

                  Icon(
                    Icons.history,
                    size:60.sp,
                    color:Colors.grey,
                  ),


                  SizedBox(
                    height:15.h,
                  ),


                  const Text(
                    "Aucun historique",
                  ),

                ],

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


                child: AppartementCard(

                  app:app,

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