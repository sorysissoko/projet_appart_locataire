import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class SkeletonWidgets {
  static Widget buildSkeletonTitle() {
    return Center(
      child: Transform.translate(
        offset: const Offset(0, -20),
        child: Container(
          width: 200.w,
          height: 30.h,
          color: Colors.grey[300],
          margin: EdgeInsets.symmetric(horizontal: 20.w),
        ),
      ),
    );
  }

  static Widget buildSkeletonStatusRow() {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 2.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          Container(
            width: 100.w,
            height: 30.h,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(20.r),
            ),
          ),
          SizedBox(width: 60.w),
          CircleAvatar(backgroundColor: Colors.grey[300], radius: 20.r),
          CircleAvatar(backgroundColor: Colors.grey[300], radius: 20.r),
        ],
      ),
    );
  }

  static Widget buildSkeletonRoomsSection() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 10.h),
      child: Wrap(
        spacing: 8.w,
        runSpacing: 15.h,
        children: List.generate(6, (index) => SizedBox(
          width: 80.w,
          child: Column(
            children: [
              Container(width: 30.w, height: 30.h, color: Colors.grey[300]),
              SizedBox(height: 5.h),
              Container(width: 40.w, height: 10.h, color: Colors.grey[300]),
              SizedBox(height: 3.h),
              Container(width: 60.w, height: 8.h, color: Colors.grey[300]),
            ],
          ),
        )),
      ),
    );
  }

  static Widget buildSkeletonFeatures() {
    return SizedBox(
      height: 320.h,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: 25.w, vertical: 12.h),
        child: Row(
          children: [
            buildSkeletonFeatureCard(),
            SizedBox(width: 30.w),
            buildSkeletonFeatureCard(),
          ],
        ),
      ),
    );
  }

  static Widget buildSkeletonFeatureCard() {
    return Container(
      width: 220.w,
      decoration: BoxDecoration(
        color: const Color(0xFFFFEFE6),
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      padding: EdgeInsets.only(top: 20.h, right: 10.w, left: 15.w, bottom: 20.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(width: 100.w, height: 20.h, color: Colors.grey[300]),
          SizedBox(height: 12.h),
          ...List.generate(
            4,
                (index) => Padding(
              padding: EdgeInsets.only(bottom: 14.h),
              child: Row(
                children: [
                  Container(width: 22.w, height: 22.h, color: Colors.grey[300]),
                  SizedBox(width: 10.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(width: 120.w, height: 15.h, color: Colors.grey[300]),
                        SizedBox(height: 2.h),
                        Container(width: 60.w, height: 15.h, color: Colors.grey[300]),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  static Widget buildSkeletonDescription() {
    return Padding(
      padding: EdgeInsets.all(16.r),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(width: 100.w, height: 25.h, color: Colors.grey[300]),
          SizedBox(height: 10.h),
          Container(width: double.infinity, height: 60.h, color: Colors.grey[200]),
        ],
      ),
    );
  }

  static Widget buildSkeletonRules() {
    return Padding(
      padding: EdgeInsets.all(16.r),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(width: 200.w, height: 25.h, color: Colors.grey[300]),
          SizedBox(height: 10.h),
          Container(width: 250.w, height: 15.h, color: Colors.grey[200]),
          SizedBox(height: 5.h),
          Container(width: 200.w, height: 15.h, color: Colors.grey[200]),
        ],
      ),
    );
  }

  static Widget buildSkeletonLocation() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.only(top: 15.h, left: 15.w, right: 15.w),
          child: Container(width: 150.w, height: 25.h, color: Colors.grey[300]),
        ),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.w),
          child: Container(width: 200.w, height: 15.h, color: Colors.grey[200]),
        ),
        SizedBox(height: 14.h),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.w),
          child: Center(
            child: Container(height: 450.h, width: double.infinity, color: Colors.grey[200]),
          ),
        ),
      ],
    );
  }

  static Widget buildSkeletonLoading() {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF0E5),
      body: Stack(
        children: [
          Container(height: 300.h, width: double.infinity, color: const Color(0xFFFFF0E5)),
          DraggableScrollableSheet(
            initialChildSize: 0.75,
            minChildSize: 0.71,
            maxChildSize: 0.95,
            builder: (_, controller) {
              return Container(
                padding: EdgeInsets.only(top: 5.h),
                decoration: const BoxDecoration(
                  color: Color(0xFFFFF0E5),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(35)),
                ),
                child: ListView(
                  controller: controller,
                  physics: const ClampingScrollPhysics(),
                  children: [
                    buildSkeletonTitle(),
                    buildSkeletonStatusRow(),
                    buildSkeletonRoomsSection(),
                    buildSkeletonFeatures(),
                    const Divider(),
                    buildSkeletonDescription(),
                    const Divider(),
                    buildSkeletonRules(),
                    const Divider(),
                    buildSkeletonLocation(),
                    SizedBox(height: 80.h),
                  ],
                ),
              );
            },
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Container(
                margin: EdgeInsets.only(top: 2.h, left: 15.w, right: 15.w, bottom: 10.h),
                padding: EdgeInsets.symmetric(horizontal: 20.w),
                height: 70.h,
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(25.r),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 100.w,
                          height: 20.h,
                          color: Colors.grey[300],
                          margin: EdgeInsets.only(bottom: 5.h),
                        ),
                        Container(width: 60.w, height: 15.h, color: Colors.grey[300]),
                      ],
                    ),
                    Container(
                      width: 180.w,
                      height: 50.h,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(25.r),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            top: 40.h,
            left: 15.w,
            child: CircleAvatar(backgroundColor: Colors.grey[300], radius: 25.r),
          ),
        ],
      ),
    );
  }
}