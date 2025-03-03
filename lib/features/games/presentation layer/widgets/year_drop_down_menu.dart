import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../domain layer/entities/season_entity.dart';

class YearDropdownMenu extends StatefulWidget {
  final List<SeasonEntity> seasons;

  YearDropdownMenu({required this.seasons});

  @override
  _YearDropdownMenuState createState() => _YearDropdownMenuState();
}

class _YearDropdownMenuState extends State<YearDropdownMenu> {
  late String? selectedYear;
  late List<String> years;

  @override
  void initState() {
    super.initState();
    selectedYear = widget.seasons.first.year;
    years = widget.seasons.map((e) => e.year).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.zero, // Remove default padding
      child: DropdownButton<String>(
        value: selectedYear,
        dropdownColor: Colors.grey[800],
        icon: Icon(Icons.arrow_drop_down, color: Colors.white),
        style: TextStyle(
          color: Colors.white,
          fontSize: 55.sp,
          fontWeight: FontWeight.w700,
        ),
        underline: Container(),
        onChanged: (String? newValue) {
          setState(() {
            selectedYear = newValue;
          });
        },
        items:
            years.map<DropdownMenuItem<String>>((String value) {
              return DropdownMenuItem<String>(
                value: value,
                child: Text(value, style: TextStyle(fontSize: 45.sp)),
              );
            }).toList(),
      ),
    );
  }
}
