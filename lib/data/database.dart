import 'package:hive_flutter/hive_flutter.dart';
class ToDoDatabase{
  List toDoList = [];
  // reference our box

  final _myBox = Hive.box('mybox');

  //1st time ever user
  void createInitialData(){
    toDoList = [
      ["Make tutorials",false],
      ["Do Exercise",false]
    ];
  }
  //load the data from database
void loadData(){
    toDoList = _myBox.get("TODOLIST");
}
//update the database
void updateDataBase(){
    _myBox.put("TODOLIST", toDoList);
}

}