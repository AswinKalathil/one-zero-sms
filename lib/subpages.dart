import 'package:flutter/material.dart';
import 'package:one_zero/custom-widgets.dart';

Widget buildSettings(BuildContext context, Function onThemeChange) {
  bool isDarkMode = Theme.of(context).brightness == Brightness.dark;
  return SingleChildScrollView(
    scrollDirection: Axis.vertical,
    child: SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Center(
        child: Container(
          width: 650,
          height: 1500,
          child: Column(
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 35, vertical: 8),
                  child: Text(
                    "Apearence",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
                  ),
                ),
              ),
              Container(
                width: 600,
                height: 200,
                decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey, width: 1),
                    borderRadius: BorderRadius.all(Radius.circular(4))),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text("Theme"),
                        Spacer(),
                        Padding(
                          padding: const EdgeInsets.all(20.0),
                          child: IconButton(
                            icon: isDarkMode
                                ? Icon(Icons.wb_sunny)
                                : Icon(Icons.nightlight_round),
                            selectedIcon: Icon(Icons.wb_sunny),
                            tooltip: isDarkMode ? "Light" : "Dark",
                            onPressed: () {
                              onThemeChange(!isDarkMode);
                            },
                          ),
                        ),
                      ],
                    )
                  ],
                ),
              ),
              //second
              Align(
                alignment: Alignment.centerLeft,
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 35, vertical: 8),
                  child: Text(
                    "Backup",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
                  ),
                ),
              ),
              Container(
                width: 600,
                height: 300,
                decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey, width: 1),
                    borderRadius: BorderRadius.all(Radius.circular(4))),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [],
                ),
              ),
              // third
              Align(
                alignment: Alignment.centerLeft,
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 35, vertical: 8),
                  child: Text(
                    "Edit Classes",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
                  ),
                ),
              ),
              Container(
                width: 600,
                height: 500,
                decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey, width: 1),
                    borderRadius: BorderRadius.all(Radius.circular(4))),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [],
                ),
              )
            ],
          ),
        ),
      ),
    ),
  );
}
