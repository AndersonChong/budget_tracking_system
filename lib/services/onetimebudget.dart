import 'package:budget_tracking_system/services/record.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'category.dart';
import 'package:meta/meta.dart';

class OneTimeBudget {
  String _uid;
  String _id;
  String _title;
  Category _category;
  double _amount;
  double _amountUsed;
  DateTime _startDate;
  DateTime _endDate;
  static List<OneTimeBudget> _list = [];
  static List<OneTimeBudget> _activeList = [];
  String _budgetStatus = "no status";
  static List<Record> _budgetRecordList = [];

// Constructor for Add Budget
// interval (refresh), onetime (change state)
// method-refresh when start app
  OneTimeBudget({
    @required String uid,
    String id = " ",
    @required String title,
    @required Category category,
    @required double amount,
    @required DateTime startDate,
    @required DateTime endDate,
    bool save = false,
  })  : _title = title,
        _uid = uid,
        _id = id,
        _category = category,
        _amount = amount,
        _startDate = startDate,
        _endDate = endDate {
    if (save == true) {
      Firestore.instance
          .collection("users")
          .document(_uid)
          .collection("one time budget")
          .add({
        "id": _id,
        "title": _title,
        "category": _category.id,
        "amount": _amount,
        "amount used": 0,
        "start date": _startDate,
        "end date": _endDate,
        "budget status": _budgetStatus,
      }).then((value) => {
                _id = value.documentID,
                Firestore.instance
                    .collection("users")
                    .document(_uid)
                    .collection("one time budget")
                    .document(value.documentID)
                    .updateData({"id": value.documentID})
              });
    }
  }

  // getter for each properties
  String get title {
    return _title;
  }

  Category get category {
    return _category;
  }

  double get amount {
    return _amount;
  }

  double get amountUsed {
    return _amountUsed;
  }

  DateTime get startDate {
    return _startDate;
  }

  DateTime get endDate {
    return _endDate;
  }

  String get budgetStatus {
    return _budgetStatus;
  }

  static List<OneTimeBudget> get list {
    return _list;
  }

  static List<OneTimeBudget> get activeList {
    return _activeList;
  }

  // setter/update budget
  void setBudget({
    @required String title,
    @required Category category,
    @required double amount,
    @required DateTime startDate,
    @required DateTime endDate,
  }) {
    _title = title;
    _category = category;
    _amount = amount;
    _startDate = startDate;
    _endDate = endDate;

    Firestore.instance
        .collection("users")
        .document(_uid)
        .collection("one time budget")
        .document("id")
        .updateData({
      "title": title,
      "category": category.id,
      "amount": amount,
      "start date": startDate,
      "end date": endDate,
    });
  }

  //change budget status(upcoming/completed/current) based on start and end date
  //loop thru all the one time budget to change status
  static void changeStatus() {
    _list.forEach((element) {
      if (element._startDate.isBefore(DateTime.now()) &&
          element._endDate.isBefore(DateTime.now())) {
        element._budgetStatus = "Completed";
      } else if (element._startDate.isAfter(DateTime.now()) &&
          element._endDate.isAfter(DateTime.now())) {
        element._budgetStatus = "Up-coming";
      } else if (element._startDate.isBefore(DateTime.now()) &&
          element._endDate.isAfter(DateTime.now())) {
        element._budgetStatus = "Current";
      }
      Firestore.instance
          .collection("users")
          .document(element._uid)
          .collection("one time budget")
          .document(element._id)
          .updateData({"budget status": element._budgetStatus});
    });
  }

  // Add all periodic budget into _list
  static List<OneTimeBudget> add(OneTimeBudget oneTimeBudget) {
    _list.add(oneTimeBudget);
    return _list;
  }

  void delete() {
    _list.remove(this);

    Firestore.instance
        .collection("users")
        .document(_uid)
        .collection("one time budget")
        .document("id")
        .delete();
  }

  //return list of active budget at thta time (parameter: that time)
  static List<OneTimeBudget> returnList(DateTime dateTime) {
    _list.forEach((element) {
      if (!element.startDate.isAfter(dateTime) &&
          !element.endDate.isBefore(dateTime)) {
        activeList.add(element);
      }
    });
    return activeList;
  }

  // Add all RELATED record into budget specific list
  static List<Record> budgetRecordList(
      Category category, DateTime startDate, DateTime endDate) {
    Record.list.forEach((record) {
      if (!record.dateTime.isBefore(startDate) &&
          !record.dateTime.isAfter(endDate) &&
          record.type == "Expenses" &&
          record.category == category) {
        print(record.title);
        _budgetRecordList.add(record);
      }
    });
    return _budgetRecordList;
  }

  // TODO How to calculate amountUsed
  // take all record for that period of time (between start and end date)
  // is budget's record only come from user selection? if user no choose, will it count into budget?
  // if yes (only come from choose) {amountused can get from a list of record in that budget (no need condition)}
  // if no (can both user choose and auto)
  static void calculateAmountUsed() {
    _list.forEach((onetimebudget) {
      List<Record> recordList = [];
      double sum = 0;
      Record.list.forEach((record) {
        if (!record.dateTime.isBefore(onetimebudget._startDate) &&
            !record.dateTime.isAfter(onetimebudget._endDate) &&
            record.type == "Expenses" &&
            record.category == onetimebudget._category) {
          recordList.add(record);
        }
      }); // Record loop

      recordList.forEach((element) {
        sum += element.amount;
      }); // recordList loop

      onetimebudget._amountUsed = sum;

      Firestore.instance
          .collection("users")
          .document(onetimebudget._uid)
          .collection("one time budget")
          .document(onetimebudget._id)
          .updateData({"amount used": onetimebudget._amountUsed});
    }); // _list loop
  }

  static Future<void> getOneTimeBudget({@required String uid}) async {
    _list = [];
    await Firestore.instance
        .collection('users')
        .document(uid)
        .collection('one time budget')
        .getDocuments()
        .then(
          (querySnapshot) => {
            querySnapshot.documents.forEach(
              (element) {
                Timestamp startDate = element.data['start date'];
                Timestamp endDate = element.data['end date'];
                Category category;
                Category.list.forEach((cat) {
                  if (cat.id == element.data['category']) {
                    category = cat;
                  }
                });
                OneTimeBudget.add(OneTimeBudget(
                  uid: uid,
                  id: element.data['id'],
                  title: element.data['title'],
                  endDate: DateTime.fromMicrosecondsSinceEpoch(
                      endDate.microsecondsSinceEpoch),
                  startDate: DateTime.fromMicrosecondsSinceEpoch(
                      startDate.microsecondsSinceEpoch),
                  category: category,
                  amount: element.data['amount'],
                  save: false,
                ));
              },
            ),
            print('One Time Budget retrieved: ${_list}')
          },
        );
    return null;
  }
}
