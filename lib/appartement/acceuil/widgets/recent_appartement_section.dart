import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'appartement_card.dart';


class RecentAppartementSection extends StatelessWidget {

  final List<Map<String,dynamic>> apps;
  final Color accentColor;
  final VoidCallback onTapAll;
  final Function(Map<String,dynamic>) onTapCard;


  const RecentAppartementSection({
    super.key,
    required this.apps,
    required this.accentColor,
    required this.onTapAll,
    required this.onTapCard,
  });



  @override
  Widget build(BuildContext context) {

    if(apps.isEmpty){
      return const SizedBox.shrink();
    }


    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,

      children: [

        Padding(
          padding: EdgeInsets.symmetric(
            horizontal:16.w,
            vertical:8.h,
          ),

          child: Row(

            mainAxisAlignment:
            MainAxisAlignment.spaceBetween,

            children: [

              Text(
                "👀 Récemment consultés",
                style: TextStyle(
                  fontSize:18.sp,
                  fontWeight:FontWeight.bold,
                ),
              ),


              GestureDetector(
                onTap:onTapAll,

                child:Text(
                  "Voir tout →",
                  style:TextStyle(
                    color:accentColor,
                    fontSize:13.sp,
                    fontWeight:FontWeight.w600,
                  ),
                ),
              ),

            ],
          ),
        ),



        SizedBox(
          height:250.h,

          child:ListView.builder(

            scrollDirection:Axis.horizontal,

            padding:
            EdgeInsets.symmetric(horizontal:16.w),


            itemCount:apps.length,


            itemBuilder:(context,index){

              final app=apps[index];


              return Padding(

                padding:
                EdgeInsets.only(right:12.w),


                child:AppartementCard(

                  app:app,

                  isCompact:false,

                  onTap:(){
                    onTapCard(app);
                  },

                ),

              );

            },
          ),
        ),


        SizedBox(height:12.h),

      ],
    );
  }
}