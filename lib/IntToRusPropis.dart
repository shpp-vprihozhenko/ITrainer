class IntToRusPropis {
  List groups, names;

  IntToRusPropis() {
    this.groups = new List(10);

    this.groups[0] = new List(10);
    this.groups[1] = new List(10);
    this.groups[2] = new List(10);
    this.groups[3] = new List(10);
    this.groups[4] = new List(10);

    this.groups[9] = new List(10);

    this.groups[1][9] = 'тысяч';
    this.groups[1][1] = 'тысяча';
    this.groups[1][2] = 'тысячи';
    this.groups[1][3] = 'тысячи';
    this.groups[1][4] = 'тысячи';

    this.groups[2][9] = 'миллионов';
    this.groups[2][1] = 'миллион';
    this.groups[2][2] = 'миллиона';
    this.groups[2][3] = 'миллиона';
    this.groups[2][4] = 'миллиона';

    this.groups[3][1] = 'миллиард';
    this.groups[3][2] = 'миллиарда';
    this.groups[3][3] = 'миллиарда';
    this.groups[3][4] = 'миллиарда';

    this.groups[4][1] = 'триллион';
    this.groups[4][2] = 'триллиона';
    this.groups[4][3] = 'триллиона';
    this.groups[4][4] = 'триллиона';

    this.names = new List(901);

    this.names[1] = 'один';
    this.names[2] = 'два';
    this.names[3] = 'три';
    this.names[4] = 'четыре';
    this.names[5] = 'пять';
    this.names[6] = 'шесть';
    this.names[7] = 'семь';
    this.names[8] = 'восемь';
    this.names[9] = 'девять';
    this.names[10] = 'десять';
    this.names[11] = 'одиннадцать';
    this.names[12] = 'двенадцать';
    this.names[13] = 'тринадцать';
    this.names[14] = 'четырнадцать';
    this.names[15] = 'пятнадцать';
    this.names[16] = 'шестнадцать';
    this.names[17] = 'семнадцать';
    this.names[18] = 'восемнадцать';
    this.names[19] = 'девятнадцать';
    this.names[20] = 'двадцать';
    this.names[30] = 'тридцать';
    this.names[40] = 'сорок';
    this.names[50] = 'пятьдесят';
    this.names[60] = 'шестьдесят';
    this.names[70] = 'семьдесят';
    this.names[80] = 'восемьдесят';
    this.names[90] = 'девяносто';
    this.names[100] = 'сто';
    this.names[200] = 'двести';
    this.names[300] = 'триста';
    this.names[400] = 'четыреста';
    this.names[500] = 'пятьсот';
    this.names[600] = 'шестьсот';
    this.names[700] = 'семьсот';
    this.names[800] = 'восемьсот';
    this.names[900] = 'девятьсот';
  }

  String intToPropis(int x) {
    if (x == 0) {
      return 'ноль';
    }
    var r = '';
    var i, j;

    //List names = this.names;
    //List groups = this.groups;

    var y = x.floor();

    var t = new List(5);

    for (i = 0; i <= 4; i++) {
      t[i] = y % 1000;
      y = (y / 1000).floor();
    }

    var d = new List(5);

    for (i = 0; i <= 4; i++) {
      d[i] = new List(101);
      d[i][0] = t[i] % 10; // единицы
      d[i][10] = t[i] % 100 - d[i][0]; // десятки
      d[i][100] = t[i] - d[i][10] - d[i][0]; // сотни
      d[i][11] = t[i] % 100; // две правых цифры в виде числа
    }

    for (i = 4; i >= 0; i--) {
      if (t[i] > 0) {
        if (names[d[i][100]] != null) r += ' ' + names[d[i][100]];

        if (names[d[i][11]] != null) {
          r += ' ' + names[d[i][11]];
        } else {
          if (names[d[i][10]] != null) r += ' ' + names[d[i][10]];
          if (names[d[i][0]] != null) r += ' ' + names[d[i][0]];
        }

        if (names[d[i][11]] != null) // если существует числительное
          j = d[i][11];
        else
          j = d[i][0];

        if (i > 0) {
          if (groups[i][j] != null) {
            r += ' ' + groups[i][j];
          } else {
            r += ' ' + groups[i][9];
          }
        }
      }
    }

    r = r.replaceAll('сорок', '40');

    return r;
  }
}
