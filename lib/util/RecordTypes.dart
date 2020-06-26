class RecordTypes {
  String typeName, typeDesc, onayDurumu;
  int count;

  RecordTypes(String typeName, String typeDesc, int count) {
    List<String> typeNameList = new List();
    typeNameList = typeName.split("|");
    this.typeName = typeNameList[0];
    this.typeDesc = typeNameList[1];
    this.count = count;
  }

  RecordTypes.overloadedContructor(
      String typeName, String typeDesc, String onayDurumu, int count) {
    this.typeName = typeName;
    this.typeDesc = typeDesc;
    this.count = count;
    this.onayDurumu = onayDurumu;
  }

  // RecordTypes(String typeName,String typeDesc,String onayDurumu, String Count);

  int get getCount => count;

  set setCount(int value) {
    count = value;
  }

  get getTypeDesc => typeDesc;

  set setTypeDesc(value) {
    typeDesc = value;
  }

  String get getTypeName => typeName;

  set setTypeName(String value) {
    typeName = value;
  }
}