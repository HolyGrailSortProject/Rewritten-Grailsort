class GrailComparator {
  constructor() {}
  compare(leftPair, rightPair) {
    if      (leftPair.getKey() < rightPair.getKey()) return -1;
    else if (leftPair.getKey() > rightPair.getKey()) return  1;
    else                                             return  0;
  }
}

module.exports = GrailComparator;
