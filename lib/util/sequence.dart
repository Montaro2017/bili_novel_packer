class Sequence {
  final int start;
  int step;
  int nowVal;

  Sequence({
    this.start = 1,
    this.step = 1,
  }) : nowVal = start - step;

  int get next {
    return nowVal = nowVal + step;
  }

  void reset() {
    nowVal = start - step;
  }
}
