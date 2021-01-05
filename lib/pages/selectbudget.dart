import 'package:flutter/material.dart';
import 'package:budget_tracking_system/budgetStats/onetime_stats.dart';
import 'package:budget_tracking_system/budgetStats/periodic_stats.dart';

class SelectBudget extends StatefulWidget {
  @override
  _SelectBudgetState createState() => _SelectBudgetState();
}

class _SelectBudgetState extends State<SelectBudget> {
  @override
  Widget build(BuildContext context) {
   return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Color.fromRGBO(57, 57, 57, 1),
          flexibleSpace: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TabBar(
                labelColor: Color.fromRGBO(255, 185, 49, 1),
                indicatorColor: Color.fromRGBO(255, 185, 49, 1),
                unselectedLabelColor: Colors.grey,
                tabs: [
                  Tab(text: "Periodic",),
                  Tab(text: "One-Time",),
                ],
              ),
            ],
          ),
        ),
        body: SafeArea(
          child: TabBarView(
            children: [
              PeriodicStats(),
              OneTimeStats(),          
            ],
          ),
        ),
      ),
   );
  }
}