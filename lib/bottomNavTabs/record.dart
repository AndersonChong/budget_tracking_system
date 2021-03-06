import 'package:budget_tracking_system/pages/addrecord.dart';
import 'package:budget_tracking_system/pages/editrecord.dart';
import 'package:budget_tracking_system/pages/searchrecord.dart';
import 'package:budget_tracking_system/pages/favrecord.dart';
import 'package:budget_tracking_system/services/user.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:grouped_list/grouped_list.dart';
import 'package:budget_tracking_system/services/record.dart' as service;
import 'package:provider/provider.dart';
import 'package:month_picker_dialog/month_picker_dialog.dart';

//A separator class that is responsible for grouping the list based on day by creating a new container/header for each list.
class RecordGroupSeparator extends StatelessWidget {
  //Initialize variable and creating a constructor
  final DateTime date;
  RecordGroupSeparator({this.date});

  @override
  Widget build(BuildContext context) {
    //Creates a container box which has these properties
    return Container(
      decoration: BoxDecoration(color: Color.fromRGBO(41, 41, 41, 1)),
      height: 50,
      child: Padding(
        padding: const EdgeInsets.only(left: 12.0),
        //The header is a row and has 2 parts
        child: Row(
          children: [
            //The first part is to display the day of the month from date.
            //Eg: If the record was added on 2020/12/19, it will display 19.
            Expanded(
              flex: 1,
              child: Text(
                "${this.date.day}",
                style: TextStyle(color: Colors.white, fontSize: 25.0),
              ),
            ),
            //This second part is to display the exact day of the month.
            //Eg: Tuesday
            Expanded(
              flex: 7,
              child: Text(
                DateFormat('EEEE').format(date),
                style: TextStyle(color: Colors.grey, fontSize: 14.0),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class Record extends StatefulWidget {
  final String uid;

  Record({Key key, @required this.uid}) : super(key: key);
  @override
  _RecordState createState() => _RecordState(uid);
}

class _RecordState extends State<Record> {
  //Initialize current date and date format
  DateTime _pickedDate;
  DateFormat df = new DateFormat('yyyy MMM');

  List<service.Record> _recordList;

  final String uid;
  _RecordState(this.uid);

  pickDate() async {
    DateTime date = await showMonthPicker(
        context: context,
        firstDate: DateTime(DateTime.now().year - 5),
        lastDate: DateTime(DateTime.now().year + 5),
        initialDate: _pickedDate);

    if (date != null) {
      setState(() {
        _pickedDate = date;
      });
    }
    filterList();
  }

  void filterList() {
    List<service.Record> _searchList = [];
    service.Record.list.forEach((value) {
      if (value.dateTime.month == _pickedDate.month &&
          value.dateTime.year == _pickedDate.year) {
        _searchList.add(value);
      }
    });

    setState(() {
      _recordList = _searchList;
    });
  }

  @override
  void initState() {
    // TODO: implement initState
    _pickedDate = DateTime.now();
    filterList();
  }

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<User>(context);
    return Scaffold(
      backgroundColor: Color.fromRGBO(57, 57, 57, 1),
      appBar: AppBar(
        backgroundColor: Color.fromRGBO(18, 18, 18, 1),
        title: Row(
          children: [
            Flexible(
              child: RaisedButton(
                shape: RoundedRectangleBorder(
                    side: BorderSide(color: Colors.grey[700])),
                color: Color.fromRGBO(18, 18, 18, 1),
                onPressed: () {
                  pickDate();
                },
                child: Text(
                  "${df.format(_pickedDate)}",
                  style: TextStyle(
                      fontWeight: FontWeight.normal,
                      fontSize: 16.0,
                      color: Colors.white),
                ),
              ),
            )
          ],
        ),
        //Actions Button inside the AppBar widget - Favourite Icon and Search Icon
        actions: [
          IconButton(
            icon: Icon(
              Icons.search,
              color: Colors.white,
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => SearchRecord(
                          uid: user.uid,
                        ),
                    fullscreenDialog: true),
              ).then((value) => setState(() {
                    filterList();
                  }));
            },
          ),
          IconButton(
            icon: Icon(
              Icons.favorite,
              color: Colors.white,
            ),
            //temporary log out function
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => FavouriteRecord(
                          uid: user.uid,
                        ),
                    fullscreenDialog: true),
              ).then((value) => setState(() {
                    filterList();
                  }));
            },
          ),
        ],
      ),

      body: _recordList.length != 0
          ? SafeArea(
              //GroupedListView is a widget that can help group the list view by anything
              //Eg: Can group lists based on category or date.
              //DateTime object is explicitly stated so that it can group the records by date
              child: GroupedListView<dynamic, DateTime>(
                  //Elements takes in a list of data that needs to be grouped, in this case recordView's data needs to be taken in.
                  elements: _recordList,
                  //groupBy is a function that chooses what to group given by an element.
                  //In this case, we give an element named record to represent our recordView list, and we want to group by currentDate.
                  groupBy: (record) {
                    return DateTime(
                      record.dateTime.year,
                      record.dateTime.month,
                      record.dateTime.day,
                    );
                  },
                  //This function prepares to separate the lists by date.
                  //This can be done by returning a constructor of RecordGroupSeparator() that passes currentDate to date.
                  //Hence the RecordGroupSeparator() class can perform its own task which is to generate respective headers for each lists.
                  groupSeparatorBuilder: (DateTime dateTime) =>
                      RecordGroupSeparator(date: dateTime),
                  //Arrange the grouped lists in descending order
                  order: GroupedListOrder.DESC,
                  itemComparator: (item1, item2) =>
                      item1.dateTime.hour.compareTo(item2.dateTime.hour),
                  separator: Divider(
                    color: Colors.grey,
                    indent: 15.0,
                    endIndent: 15.0,
                  ),
                  padding: EdgeInsets.only(bottom: 100),
                  //To build and display all the items of recordView list.
                  indexedItemBuilder: (context, dynamic record, index) {
                    return Container(
                      height: 70.0,
                      //Each list is a row and is expanded to 3 parts.
                      child: Row(
                        children: [
                          //First part is to display the category.
                          Expanded(
                            flex: 4,
                            child: ListTile(
                              onTap: () {
                                print(record.title);
                                print(_recordList.length - 1 - index);
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (context) => EditRecord(
                                            uid: user.uid,
                                            recordList: _recordList,
                                            index:
                                                _recordList.length - 1 - index,
                                            type: _recordList[
                                                    _recordList.length -
                                                        1 -
                                                        index]
                                                .type,
                                            title: _recordList[
                                                    _recordList.length -
                                                        1 -
                                                        index]
                                                .title,
                                            dateTime: _recordList[
                                                    _recordList.length -
                                                        1 -
                                                        index]
                                                .dateTime,
                                            category: _recordList[
                                                    _recordList.length -
                                                        1 -
                                                        index]
                                                .category,
                                            account: _recordList[
                                                    _recordList.length -
                                                        1 -
                                                        index]
                                                .account,
                                            toAccount: _recordList[
                                                    _recordList.length -
                                                        1 -
                                                        index]
                                                .toAccount,
                                            budget: _recordList[
                                                    _recordList.length -
                                                        1 -
                                                        index]
                                                .budget,
                                            amount: _recordList[
                                                    _recordList.length -
                                                        1 -
                                                        index]
                                                .amount,
                                            note: _recordList[
                                                    _recordList.length -
                                                        1 -
                                                        index]
                                                .note,
                                            isFav: _recordList[
                                                    _recordList.length -
                                                        1 -
                                                        index]
                                                .isFav,
                                          ),
                                      fullscreenDialog: true),
                                ).then((value) => setState(() {
                                      filterList();
                                    }));
                              },
                              leading: record.type != 'Transfer'
                                  ? Text(
                                      record.category.name,
                                      //Used to wrap long texts
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                          color: Colors.grey, fontSize: 14),
                                    )
                                  : Text(
                                      'Transfer',
                                      //Used to wrap long texts
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                          color: Colors.grey, fontSize: 14),
                                    ),
                            ),
                          ),
                          //Second part is to display the title.
                          Expanded(
                            flex: 8,
                            child: ListTile(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (context) => EditRecord(
                                            uid: user.uid,
                                            recordList: _recordList,
                                            index:
                                                _recordList.length - 1 - index,
                                            type: _recordList[
                                                    _recordList.length -
                                                        1 -
                                                        index]
                                                .type,
                                            title: _recordList[
                                                    _recordList.length -
                                                        1 -
                                                        index]
                                                .title,
                                            dateTime: _recordList[
                                                    _recordList.length -
                                                        1 -
                                                        index]
                                                .dateTime,
                                            category: _recordList[
                                                    _recordList.length -
                                                        1 -
                                                        index]
                                                .category,
                                            account: _recordList[
                                                    _recordList.length -
                                                        1 -
                                                        index]
                                                .account,
                                            toAccount: _recordList[
                                                    _recordList.length -
                                                        1 -
                                                        index]
                                                .toAccount,
                                            budget: _recordList[
                                                    _recordList.length -
                                                        1 -
                                                        index]
                                                .budget,
                                            amount: _recordList[
                                                    _recordList.length -
                                                        1 -
                                                        index]
                                                .amount,
                                            note: _recordList[
                                                    _recordList.length -
                                                        1 -
                                                        index]
                                                .note,
                                            isFav: _recordList[
                                                    _recordList.length -
                                                        1 -
                                                        index]
                                                .isFav,
                                          ),
                                      fullscreenDialog: true),
                                ).then((value) => setState(() {
                                      filterList();
                                    }));
                              },
                              title: Text(
                                record.title,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(color: Colors.white),
                              ),
                              subtitle: record.type != 'Transfer'
                                  ? Text(
                                      record.account.name,
                                      style: TextStyle(color: Colors.grey),
                                    )
                                  : Text(
                                      '${record.account.name} - ${record.toAccount.name}',
                                      style: TextStyle(color: Colors.grey),
                                    ),
                            ),
                          ),
                          //Third part is to display the money.
                          Expanded(
                            flex: 6,
                            child: ListTile(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (context) => EditRecord(
                                            uid: user.uid,
                                            recordList: _recordList,
                                            index:
                                                _recordList.length - 1 - index,
                                            type: _recordList[
                                                    _recordList.length -
                                                        1 -
                                                        index]
                                                .type,
                                            title: _recordList[
                                                    _recordList.length -
                                                        1 -
                                                        index]
                                                .title,
                                            dateTime: _recordList[
                                                    _recordList.length -
                                                        1 -
                                                        index]
                                                .dateTime,
                                            category: _recordList[
                                                    _recordList.length -
                                                        1 -
                                                        index]
                                                .category,
                                            account: _recordList[
                                                    _recordList.length -
                                                        1 -
                                                        index]
                                                .account,
                                            toAccount: _recordList[
                                                    _recordList.length -
                                                        1 -
                                                        index]
                                                .toAccount,
                                            budget: _recordList[
                                                    _recordList.length -
                                                        1 -
                                                        index]
                                                .budget,
                                            amount: _recordList[
                                                    _recordList.length -
                                                        1 -
                                                        index]
                                                .amount,
                                            note: _recordList[
                                                    _recordList.length -
                                                        1 -
                                                        index]
                                                .note,
                                            isFav: _recordList[
                                                    _recordList.length -
                                                        1 -
                                                        index]
                                                .isFav,
                                          ),
                                      fullscreenDialog: true),
                                ).then((value) => setState(() {
                                      filterList();
                                    }));
                              },
                              //An if else statement is used to check whether it is an expense or income
                              //If it is expenses, add '-' in front of money, else add '+'
                              trailing: record.type == 'Expenses'
                                  ? Text(
                                      "- ${record.account.currency} " +
                                          record.amount.toString(),
                                      style: TextStyle(
                                          color: Colors.white, fontSize: 14.0),
                                    )
                                  : Text(
                                      "+ ${record.account.currency} " +
                                          record.amount.toString(),
                                      style: TextStyle(
                                          color: Colors.white, fontSize: 14.0),
                                    ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
            )
          : Center(
              child: Text(
                'No Records Added.',
                style: TextStyle(color: Colors.white, fontSize: 15.0),
              ),
            ),

      //This button can be navigated to add records page.
      floatingActionButton: FloatingActionButton(
        child: Text(
          "+",
          style:
              TextStyle(fontSize: 25.0, color: Color.fromRGBO(41, 41, 41, 1)),
        ),
        backgroundColor: Color.fromRGBO(255, 185, 49, 1),
        onPressed: () {
          // Navigator.pushNamed(context, '/addrecord');
          Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => AddRecord(
                      uid: user.uid,
                    ),
                fullscreenDialog: true),
            // The Greatest Mystery
          ).then((value) => setState(() {
                filterList();
              }));
        },
      ),
    );
  }
}
