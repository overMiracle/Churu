import 'dart:async';

import 'package:currency_text_input_formatter/currency_text_input_formatter.dart';
import 'package:innout/resource/keys.dart';
import 'package:innout/ui/settings_page.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_multi_formatter/flutter_multi_formatter.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:innout/model/display_type.dart';
import 'package:innout/bloc/bill_bloc.dart';
import 'package:innout/ui/components/type_picker.dart';
import 'package:innout/ui/type_detail_page.dart';
import 'components/spring_curve.dart';

const String noto = 'noto';

class MainPage extends StatefulWidget {
  @override
  _MainPageState createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  final scrollController = ScrollController();
  final textEditingController = TextEditingController();
  var type = TransactionType.values.elementAt(0);
  DisplayType displayType = DisplayType.single;
  String buttonStr = '日';
  Color backgroundColor, foregroundColor, subForegroundColor;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      goToWelcome();
      Timer(Duration(milliseconds: 600), () {
        if (scrollController.hasClients &&
            scrollController.position.maxScrollExtent >= 240) {
          scrollController.animateTo(240,
              duration: Duration(milliseconds: 300),
              curve: SpringCurve.underDamped);
        }
      });
    });

    BillBloc.instance.init();
  }

  void goToWelcome() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    var dbAddr = prefs.getString(Keys.dbAddr);
    if (dbAddr == null || dbAddr == '') {
      goToSettings();
    }
  }

  @override
  Widget build(BuildContext context) {
    localizations = AppLocalizations(Localizations.localeOf(context));
    backgroundColor =
        MediaQuery.of(context).platformBrightness == Brightness.light
            ? Colors.white
            : Colors.black;
    foregroundColor =
        MediaQuery.of(context).platformBrightness == Brightness.light
            ? Colors.black
            : Colors.white;
    subForegroundColor =
        MediaQuery.of(context).platformBrightness == Brightness.light
            ? Colors.black54
            : Colors.grey;

    return Scaffold(
        backgroundColor: backgroundColor,
        body: Container(
          height: MediaQuery.of(context).size.height,
          width: MediaQuery.of(context).size.width,
          child: Stack(
            children: <Widget>[
              StreamBuilder(
                stream: BillBloc.instance.allTransactions,
                builder: (_, AsyncSnapshot<List<Transaction>> snapshot) {
                  if (snapshot.hasData) {
                    if (snapshot.data.isEmpty) {
                      return ListView(
                        controller: scrollController,
                        keyboardDismissBehavior:
                            ScrollViewKeyboardDismissBehavior.onDrag,
                        children: <Widget>[
                          Container(
                              height: 240,
                              child: Column(
                                children: <Widget>[
                                  SizedBox(height: 24),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: <Widget>[
                                      Text(
                                        '¥0.00',
                                        style: TextStyle(
                                            fontSize: 64,
                                            color: foregroundColor),
                                      )
                                    ],
                                  ),
                                  SizedBox(
                                    height: 24,
                                  ),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceEvenly,
                                    children: <Widget>[
                                      Text(
                                        '总入¥0.00',
                                        style: TextStyle(
                                            fontSize: 30,
                                            color: foregroundColor),
                                      ),
                                      Text(
                                        '总出¥0.00',
                                        style: TextStyle(
                                            fontSize: 30,
                                            color: foregroundColor),
                                      ),
                                    ],
                                  ),
                                ],
                              )),
                          Container(
                              height: 480,
                              child: Center(
                                child: Text(
                                  '空',
                                  style: TextStyle(
                                      fontSize: 16, color: Colors.grey),
                                ),
                              )),
                        ],
                      );
                    }

                    var transactions = snapshot.data.reversed.toList();
                    double totalOut = 0, totalIn = 0;

                    if (transactions.first.amount < 0)
                      totalOut += transactions.first.amount;
                    else
                      totalIn += transactions.first.amount;

                    double total = transactions
                        .map((e) => e.amount)
                        .toList()
                        .reduce((value, element) {
                      print(element);
                      if (element < 0)
                        totalOut += element;
                      else
                        totalIn += element;

                      return value + element;
                    });

                    String totalStr = total.abs().toCurrencyString(),
                        totalOutStr = totalOut.abs().toCurrencyString(),
                        totalInStr = totalIn.toCurrencyString();

                    double mainSizeFactor = 1 + ((10 - totalStr.length) / 10);
                    double subSizeFactor = 1 +
                        ((20 - (totalInStr.length + totalOutStr.length)) / 20);

                    print('the size is ' + subSizeFactor.toString());

                    if (mainSizeFactor > 1) mainSizeFactor = 1;
                    if (subSizeFactor > 1) subSizeFactor = 1;

                    return ListView(
                      controller: scrollController,
                      keyboardDismissBehavior:
                          ScrollViewKeyboardDismissBehavior.onDrag,
                      children: <Widget>[
                        Container(
                            height: 240,
                            child: Column(
                              children: <Widget>[
                                SizedBox(height: 24),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: <Widget>[
                                    Container(
                                        width:
                                            MediaQuery.of(context).size.width,
                                        child: Center(
                                            child: Padding(
                                          padding: EdgeInsets.symmetric(
                                              horizontal: 12),
                                          child: AutoSizeText(
                                            '${total < 0 ? '-' : ''}¥$totalStr',
                                            style: TextStyle(
                                                fontSize: 58,
                                                color: foregroundColor),
                                            maxFontSize: 58,
                                            maxLines: 1,
                                          ),
                                        )))
                                  ],
                                ),
                                SizedBox(
                                  height: 24,
                                ),
                                Column(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceEvenly,
                                  children: <Widget>[
                                    Container(
                                      width: MediaQuery.of(context).size.width,
                                      child: Flex(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        direction: Axis.horizontal,
                                        children: [
                                          Expanded(
                                              flex: 1,
                                              child: Center(
                                                child: Text(
                                                  '总入',
                                                  style: TextStyle(
                                                      fontSize: 24,
                                                      color: foregroundColor),
                                                ),
                                              )),
                                          Expanded(
                                              flex: 1,
                                              child: Center(
                                                child: Text(
                                                  '总出',
                                                  style: TextStyle(
                                                      fontSize: 24,
                                                      color: foregroundColor),
                                                ),
                                              )),
                                        ],
                                      ),
                                    ),
                                    Container(
                                      width: MediaQuery.of(context).size.width,
                                      child: Flex(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        direction: Axis.horizontal,
                                        children: [
                                          Expanded(
                                            flex: 1,
                                            child: Container(
                                              width: MediaQuery.of(context)
                                                      .size
                                                      .width /
                                                  2,
                                              child: Center(
                                                  child: Padding(
                                                padding: EdgeInsets.symmetric(
                                                    horizontal: 12),
                                                child: AutoSizeText(
                                                  '¥$totalInStr',
                                                  style: TextStyle(
                                                      fontSize: 30,
                                                      color: foregroundColor),
                                                  maxLines: 1,
                                                ),
                                              )),
                                            ),
                                          ),
                                          Expanded(
                                            flex: 1,
                                            child: Container(
                                              width: MediaQuery.of(context)
                                                      .size
                                                      .width /
                                                  2,
                                              child: Center(
                                                  child: Padding(
                                                padding: EdgeInsets.symmetric(
                                                    horizontal: 12),
                                                child: AutoSizeText(
                                                  '¥$totalOutStr',
                                                  style: TextStyle(
                                                      fontSize: 30,
                                                      color: foregroundColor),
                                                  maxLines: 1,
                                                ),
                                              )),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            )),
                        ...buildChildren(transactions),
                        SizedBox(
                          height: 600,
                        )
                      ],
                    );
                  }
                  return Container(
                    width: MediaQuery.of(context).size.width,
                    height: MediaQuery.of(context).size.height,
                    child: Center(
                      child: CupertinoActivityIndicator(),
                    ),
                  );
                },
              ),
              Positioned(
                bottom: 24,
                right: 0,
                left: 0,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    ElevatedButton(
                      onLongPress: goToSettings,
                      onPressed: outgoingPressed,
                      style: OutlinedButton.styleFrom(
                          backgroundColor: Colors.white, shape: CircleBorder()),
                      child: Padding(
                        padding: EdgeInsets.all(12),
                        child: Container(
                          width: 36,
                          height: 36,
                          child: Center(
                            child: Text('出',
                                style: TextStyle(
                                    fontFamily: 'noto',
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold)),
                          ),
                        ),
                      ),
                    ),
                    ElevatedButton(
                      onLongPress: goToSettings,
                      onPressed: incomePressed,
                      style: OutlinedButton.styleFrom(
                          backgroundColor: Colors.white, shape: CircleBorder()),
                      child: Padding(
                        padding: EdgeInsets.all(12),
                        child: Container(
                          width: 36,
                          height: 36,
                          child: Center(
                            child: Text('入',
                                style: TextStyle(
                                    fontFamily: 'noto',
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold)),
                          ),
                        ),
                      ),
                    ),
                    FutureBuilder(
                        future: getCurrentPage(),
                        builder: (_, AsyncSnapshot<int> snapshot) {
                          if (snapshot.hasData) {
                            var curPage = snapshot.data;

                            return TypePicker(
                              initialPage: curPage,
                              onTypeChanged: (type) {
                                setState(() {
                                  this.displayType = type;
                                });
                              },
                              onLongPress: goToSettings,
                            );
                          }

                          return ElevatedButton(
                              child: Padding(
                                  padding: EdgeInsets.all(12),
                                  child: Container(height: 36, width: 36)),
                              style: OutlinedButton.styleFrom(
                                  backgroundColor: Colors.white,
                                  shape: CircleBorder()),
                              onLongPress: goToSettings,
                              onPressed: null);
                        })
                  ],
                ),
              ),
            ],
          ),
        ));
  }

  List<Widget> buildChildren(List<Transaction> transactions) {
    if (displayType == DisplayType.single) {
      transactions.sort((a, b) => b.createdDate.compareTo(a.createdDate));
      return transactions.map((e) {
        return Dismissible(
          key: UniqueKey(),
          onDismissed: (direction) {
            if (direction == DismissDirection.startToEnd) {}
          },
          confirmDismiss: (direction) {
            return showCupertinoModalPopup<bool>(
                context: context,
                builder: (_) {
                  return CupertinoActionSheet(
                    actions: <Widget>[
                      CupertinoActionSheetAction(
                          onPressed: () {
                            BillBloc.instance.removeTransaction(e);
                            Navigator.pop(context, true);
                          },
                          child: Text('删除', style: TextStyle(fontFamily: noto)),
                          isDestructiveAction: true)
                    ],
                    cancelButton: CupertinoActionSheetAction(
                        onPressed: () {
                          Navigator.pop(context, false);
                        },
                        child: Text('取消', style: TextStyle(fontFamily: noto)),
                        isDefaultAction: true),
                  );
                });
          },
          background: Container(
            child: Align(
                alignment: Alignment.centerLeft,
                child: Padding(
                  padding: EdgeInsets.only(left: 16),
                  child: Text(
                    '删',
                    style: TextStyle(
                        fontFamily: noto, fontSize: 18, color: Colors.white),
                  ),
                )),
            color: Colors.redAccent,
          ),
          child: ListTile(
            title: Text(
                '${e.amount < 0 ? '出' : '入'}¥${e.amount.abs().toCurrencyString()}',
                style: TextStyle(fontSize: 20, color: foregroundColor)),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  localizations.transactionTypeToString(e.transactionType),
                  style: TextStyle(color: subForegroundColor),
                ),
                Text(
                  '${e.createdDate.year}年${e.createdDate.month}月${e.createdDate.day}日 ${e.createdDate.toString().substring(11, 16)}',
                  style: TextStyle(color: subForegroundColor),
                ),
              ],
            ),
            onTap: () {},
          ),
        );
      }).toList();
    }

    if (displayType == DisplayType.day) {
      Map<DateTime, List<Transaction>> dateToTransactionMap = {};
      for (var t in transactions) {
        var date = DateTime(
            t.createdDate.year, t.createdDate.month, t.createdDate.day);

        if (dateToTransactionMap.containsKey(date))
          dateToTransactionMap[date].add(t);
        else {
          dateToTransactionMap[date] = [t];
        }
      }
      var dates = dateToTransactionMap.keys.toList()
        ..sort((a, b) => b.compareTo(a));

      return dates.map((d) {
        var trans = dateToTransactionMap[d];
        double totalOut = 0, totalIn = 0;

        if (trans.first.amount < 0)
          totalOut += trans.first.amount;
        else
          totalIn += trans.first.amount;

        double total =
            trans.map((e) => e.amount).toList().reduce((value, element) {
          if (element < 0)
            totalOut += element;
          else
            totalIn += element;

          return value + element;
        });

        return ListTile(
          title: AutoSizeText(
            '${total < 0 ? '出' : '入'}¥${total.abs().toCurrencyString()}',
            style: TextStyle(fontSize: 20, color: foregroundColor),
            maxLines: 1,
            maxFontSize: 20,
          ),
          subtitle: Text(
            '${d.year}年${d.month}月${d.day}日',
            style: TextStyle(color: subForegroundColor),
          ),
          trailing: Container(
            width: 140,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                AutoSizeText(
                  '日出¥${totalOut.abs().toCurrencyString()}',
                  style: TextStyle(color: subForegroundColor),
                  maxLines: 1,
                ),
                AutoSizeText(
                  '日入¥${totalIn.abs().toCurrencyString()}',
                  style: TextStyle(color: subForegroundColor),
                  maxLines: 1,
                ),
              ],
            ),
          ),
          onTap: () {},
        );
      }).toList();
    }

    if (displayType == DisplayType.month) {
      Map<DateTime, List<Transaction>> dateToTransactionMap = {};
      for (var t in transactions) {
        var date = DateTime(t.createdDate.year, t.createdDate.month, 1);

        if (dateToTransactionMap.containsKey(date))
          dateToTransactionMap[date].add(t);
        else {
          dateToTransactionMap[date] = [t];
        }
      }
      var months = dateToTransactionMap.keys.toList()
        ..sort((a, b) => b.compareTo(a));

      return months.map((d) {
        var trans = dateToTransactionMap[d];
        double totalOut = 0, totalIn = 0;

        if (trans.first.amount < 0)
          totalOut += trans.first.amount;
        else
          totalIn += trans.first.amount;

        double total =
            trans.map((e) => e.amount).toList().reduce((value, element) {
          if (element < 0)
            totalOut += element;
          else
            totalIn += element;

          return value + element;
        });

        return ListTile(
          title: AutoSizeText(
            '${total < 0 ? '出' : '入'}¥${total.abs().toCurrencyString()}',
            style: TextStyle(fontSize: 20, color: foregroundColor),
            maxLines: 1,
            maxFontSize: 20,
          ),
          subtitle: Text(
            '${d.year}年${d.month}月',
            style: TextStyle(color: subForegroundColor),
          ),
          trailing: Container(
            width: 140,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                AutoSizeText('月出¥${totalOut.abs().toCurrencyString()}',
                    style: TextStyle(color: subForegroundColor), maxLines: 1),
                AutoSizeText('月入¥${totalIn.abs().toCurrencyString()}',
                    style: TextStyle(color: subForegroundColor), maxLines: 1),
              ],
            ),
          ),
          onTap: () {},
        );
      }).toList();
    }

    if (displayType == DisplayType.year) {
      Map<DateTime, List<Transaction>> dateToTransactionMap = {};
      for (var t in transactions) {
        var date = DateTime(t.createdDate.year, 1, 1);

        if (dateToTransactionMap.containsKey(date))
          dateToTransactionMap[date].add(t);
        else {
          dateToTransactionMap[date] = [t];
        }
      }
      var months = dateToTransactionMap.keys.toList()
        ..sort((a, b) => b.compareTo(a));

      return months.map((d) {
        var trans = dateToTransactionMap[d];
        double totalOut = 0, totalIn = 0;

        if (trans.first.amount < 0)
          totalOut += trans.first.amount;
        else
          totalIn += trans.first.amount;

        double total =
            trans.map((e) => e.amount).toList().reduce((value, element) {
          if (element < 0)
            totalOut += element;
          else
            totalIn += element;

          return value + element;
        });

        return ListTile(
          title: AutoSizeText(
            '${total < 0 ? '出' : '入'}¥${total.abs().toCurrencyString()}',
            style: TextStyle(fontSize: 20, color: foregroundColor),
            maxLines: 1,
            maxFontSize: 20,
          ),
          subtitle: Text(
            '${d.year}年',
            style: TextStyle(color: subForegroundColor),
          ),
          trailing: Container(
            width: 140,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                AutoSizeText('年出¥${totalOut.abs().toCurrencyString()}',
                    style: TextStyle(color: subForegroundColor), maxLines: 1),
                AutoSizeText('年入¥${totalIn.abs().toCurrencyString()}',
                    style: TextStyle(color: subForegroundColor), maxLines: 1),
              ],
            ),
          ),
          onTap: () {},
        );
      }).toList();
    }

    if (displayType == DisplayType.category) {
      var categories = TransactionType.values;
      Map<TransactionType, List<Transaction>> typeToTransactionsMap = {};

      for (var t in transactions) {
        if (typeToTransactionsMap.containsKey(t.transactionType)) {
          typeToTransactionsMap[t.transactionType].add(t);
        } else {
          typeToTransactionsMap[t.transactionType] = [t];
        }
      }

      List<Widget> children = [];

      for (var c in categories) {
        var ts = typeToTransactionsMap[c];
        if (ts == null) continue;

        ts.sort((a, b) => b.createdDate.compareTo(a.createdDate));

        double totalOut = 0, totalIn = 0;

        if (ts.first.amount < 0)
          totalOut += ts.first.amount;
        else
          totalIn += ts.first.amount;

        double total =
            ts.map((e) => e.amount).toList().reduce((value, element) {
          if (element < 0)
            totalOut += element;
          else
            totalIn += element;

          return value + element;
        });

        String title = localizations.transactionTypeToString(c);

        children.add(ListTile(
          title: Text(title, style: TextStyle(color: foregroundColor)),
          subtitle: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                '总出¥${totalOut.abs().toCurrencyString()}',
                style: TextStyle(color: subForegroundColor),
              ),
              Text(
                '总入¥${totalIn.abs().toCurrencyString()}',
                style: TextStyle(color: subForegroundColor),
              ),
            ],
          ),
          onTap: () {
            Navigator.push(
                context,
                CupertinoPageRoute(
                    builder: (_) => TypeDetailPage(
                          transactions: ts,
                          title: title,
                        )));
          },
        ));
      }

      return children;
    }

    return [];
  }

  void incomePressed() {
    showGeneralDialog(
      barrierLabel: "Barrier",
      barrierDismissible: true,
      barrierColor: Colors.black.withOpacity(0.5),
      transitionDuration: Duration(milliseconds: 300),
      context: context,
      pageBuilder: (_, __, ___) {
        return Align(
          alignment: Alignment.topCenter,
          child: Container(
            height: 360,
            //child: SizedBox.expand(child: FlutterLogo()),
            margin: EdgeInsets.only(top: 48, left: 12, right: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(40),
            ),
            child: Column(
              children: <Widget>[
                Padding(
                  padding: EdgeInsets.only(top: 24, left: 24, right: 24),
                  child: CupertinoTextField(
                    controller: textEditingController,
                    autofocus: true,
                    textAlign: TextAlign.center,
                    prefix: Material(
                        color: Colors.white,
                        child: Text(
                          '¥',
                          style: TextStyle(fontSize: 36),
                        )),
                    style: TextStyle(fontSize: 36, fontFamily: 'noto'),
                    decoration: BoxDecoration(color: Colors.transparent),
                    keyboardType:
                        TextInputType.numberWithOptions(decimal: true),
                    keyboardAppearance:
                        MediaQuery.of(context).platformBrightness,
                    maxLength: 16,
                    maxLengthEnforcement: MaxLengthEnforcement.enforced,
                    inputFormatters: [CurrencyTextInputFormatter(symbol: '')],
                  ),
                ),
                Padding(
                    padding: EdgeInsets.only(top: 12, left: 24, right: 24),
                    child: Container(
                      height: 164,
                      child: CupertinoPicker(
                        itemExtent: 24,
                        magnification: 1.4,
                        onSelectedItemChanged: (index) {
                          type = TransactionType.values.elementAt(index);
                        },
                        children: TransactionType.values
                            .map(
                              (e) => Text(
                                localizations.transactionTypeToString(e),
                                style:
                                    TextStyle(fontFamily: 'noto', fontSize: 14),
                              ),
                            )
                            .toList(),
                        useMagnifier: true,
                      ),
                    )),
                Padding(
                    padding: EdgeInsets.only(top: 12, left: 24, right: 24),
                    child: Material(
                      color: Colors.transparent,
                      child: ElevatedButton(
                        child: Padding(
                          padding: EdgeInsets.only(
                              top: 12, left: 24, right: 24, bottom: 12),
                          child: Text('入账',
                              style:
                                  TextStyle(fontSize: 24, fontFamily: 'noto')),
                        ),
                        style: OutlinedButton.styleFrom(
                          backgroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(40),
                          ),
                        ),
                        onPressed: () {
                          print(
                              "the text editing value is ${double.parse(textEditingController.text.replaceAll(',', ''))}");
                          var t = Transaction.create(
                              amount: double.parse(textEditingController.text
                                  .replaceAll(',', '')),
                              transactionType: type);
                          BillBloc.instance.addTransaction(t);
                          Navigator.pop(context);
                          textEditingController.clear();
                          // AppReview.requestReview;
                        },
                      ),
                    ))
              ],
            ),
          ),
        );
      },
      transitionBuilder: (_, anim, __, child) {
        return SlideTransition(
          position: Tween(begin: Offset(0, 1), end: Offset(0, 0)).animate(
              CurvedAnimation(parent: anim, curve: SpringCurve.underDamped)),
          child: child,
        );
      },
    );
  }

  void outgoingPressed() {
    showGeneralDialog(
      barrierLabel: "Barrier",
      barrierDismissible: true,
      barrierColor: Colors.black.withOpacity(0.5),
      transitionDuration: Duration(milliseconds: 300),
      context: context,
      pageBuilder: (_, __, ___) {
        return Align(
          alignment: Alignment.topCenter,
          child: Container(
            height: 360,
            //child: SizedBox.expand(child: FlutterLogo()),
            margin: EdgeInsets.only(top: 48, left: 12, right: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(40),
            ),
            child: Column(
              children: <Widget>[
                Padding(
                  padding: EdgeInsets.only(top: 24, left: 24, right: 24),
                  child: CupertinoTextField(
                    controller: textEditingController,
                    autofocus: true,
                    textAlign: TextAlign.center,
                    prefix: Material(
                        color: Colors.white,
                        child: Text(
                          '¥',
                          style: TextStyle(fontSize: 36),
                        )),
                    style: TextStyle(fontSize: 36, fontFamily: 'noto'),
                    smartQuotesType: SmartQuotesType.enabled,
                    decoration: BoxDecoration(color: Colors.transparent),
                    keyboardType:
                        TextInputType.numberWithOptions(decimal: true),
                    keyboardAppearance:
                        MediaQuery.of(context).platformBrightness,
                    maxLength: 16,
                    maxLengthEnforcement: MaxLengthEnforcement.enforced,
                    inputFormatters: [CurrencyTextInputFormatter(symbol: '')],
                  ),
                ),
                Padding(
                    padding: EdgeInsets.only(top: 12, left: 24, right: 24),
                    child: Container(
                      height: 164,
                      child: CupertinoPicker(
                        itemExtent: 24,
                        magnification: 1.4,
                        onSelectedItemChanged: (index) {
                          type = TransactionType.values.elementAt(index);
                        },
                        children: TransactionType.values
                            .map(
                              (e) => Text(
                                localizations.transactionTypeToString(e),
                                style:
                                    TextStyle(fontFamily: 'noto', fontSize: 14),
                              ),
                            )
                            .toList(),
                        useMagnifier: true,
                      ),
                    )),
                Padding(
                    padding: EdgeInsets.only(top: 12, left: 24, right: 24),
                    child: Material(
                      color: Colors.transparent,
                      child: ElevatedButton(
                        child: Padding(
                          padding: EdgeInsets.only(
                              top: 12, left: 24, right: 24, bottom: 12),
                          child: Text('出账',
                              style:
                                  TextStyle(fontSize: 24, fontFamily: 'noto')),
                        ),
                        style: OutlinedButton.styleFrom(
                          backgroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(40),
                          ),
                        ),
                        onPressed: () {
                          var t = Transaction.create(
                              amount: -double.parse(textEditingController.text
                                  .replaceAll(',', '')),
                              transactionType: type);
                          BillBloc.instance.addTransaction(t);
                          Navigator.pop(context);
                          textEditingController.clear();
                        },
                      ),
                    ))
              ],
            ),
          ),
        );
      },
      transitionBuilder: (_, anim, __, child) {
        return SlideTransition(
          position: Tween(begin: Offset(0, 1), end: Offset(0, 0)).animate(
              CurvedAnimation(parent: anim, curve: SpringCurve.underDamped)),
          child: child,
        );
      },
    );
  }

  Future<int> getCurrentPage() {
    return SharedPreferences.getInstance()
        .then((value) => value.getInt("lastVisitedPage") ?? 0);
  }

  void goToSettings() async {
    await Navigator.of(context)
        .push(MaterialPageRoute(builder: (ctx) => SettingsPage()));
    BillBloc.instance.init();
  }
}
