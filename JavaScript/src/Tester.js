const GrailComparator = require('./GrailComparator');
const GrailPair = require('./GrailPair');
const GrailSort = require('./GrailSort');

/*
 * MIT License
 *
 * Copyright (c) 2013 Andrey Astrelin
 * Copyright (c) 2020 The Holy Grail Sort Project
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in all
 * copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 * SOFTWARE.
 */

/*
 * The Holy Grail Sort Project
 * Project Manager:      Summer Dragonfly
 * Project Contributors: 666666t
 *                       Anonymous0726
 *                       aphitorite
 *                       dani_dlg
 *                       EilrahcF
 *                       Enver
 *                       lovebuny
 *                       MP
 *                       phoenixbound
 *                       thatsOven
 *
 * Special thanks to "The Studio" Discord community!
 */

// REWRITTEN GRAILSORT FOR JAVASCRIPT - A heavily refactored C/C++-to-JavaScript version of
//                                      Andrey Astrelin's GrailSort.h, aiming to be as
//                                      readable and intuitive as possible.
//
// ** Written and maintained by The Holy Grail Sort Project
//
// Primary author: Enver
//
// Current status: Finished. Potentially 100% working... Passing most tests, some tests capped by V8 Engine memory allocation limits

const getTimestamp = function () {
  return new Date().getTime();
};

class Tester {
  constructor(maxLength, maxKeyCount) {
    this.seed = 100000001;

    this.keyArray = new Array(maxLength);
    this.valueArray = new Array(maxKeyCount);
    this.referenceArray = new Array(maxLength);

    this.failReason = '';
  }

  getRandomNumber(key) {
    this.seed = this.seed * 1234565 + 1;
    return parseInt(((this.seed & 0x7fffffff) * key) >> 31);
  }

  generateTestArray(length, keyCount) {
    for (let i = 0; i < keyCount; i++) {
      this.valueArray[i] = 0;
    }

    for (let i = 0; i < length; i++) {
      if (keyCount != 0) {
        let key = this.getRandomNumber(keyCount);
        this.keyArray[i] = new GrailPair(key, this.valueArray[key]);
        this.valueArray[key]++;
      } else {
        this.keyArray[i] = new GrailPair(this.getRandomNumber(1000000000), 0);
      }
    }
  }

  testArray(length, test) {
    for (let i = 1; i < length; i++) {
      let compare = test.compare(this.keyArray[i - 1], this.keyArray[i]);
      if (compare > 0) {
        this.failReason = 'testArray[' + (i - 1) + '] and testArray[' + i + '] are out-of-order\n';
        return false;
      } else if (compare == 0 && this.keyArray[i - 1].getValue() > this.keyArray[i].getValue()) {
        this.failReason = 'testArray[' + (i - 1) + '] and testArray[' + i + '] are unstable\n';
        return false;
      } else if (!this.keyArray[i - 1] == this.referenceArray[i - 1]) {
        this.failReason = 'testArray[' + (i - 1) + '] does not match the reference array\n';
        return false;
      }
    }
    return true;
  }

  checkAlgorithm(length, keyCount, grailSort, grailBufferType, grailStrategy, test) {
    this.generateTestArray(length, keyCount);
    this.referenceArray = this.keyArray.slice();

    let grailType = 'w/o External Buffer';
    if (grailBufferType == 1) {
      grailType = 'w/ O(1) Buffer     ';
    } else if (grailBufferType == 2) {
      grailType = 'w/ O(sqrt n) Buffer';
    }

    if (grailSort) {
      console.log(
        '\n* Grailsort ' +
          grailType +
          ', ' +
          grailStrategy +
          ' \n* length = ' +
          length +
          ', unique items = ' +
          keyCount
      );
    } else {
      console.log(
        '\n* Arrays.sort (Timsort)  \n* length = ' + length + ', unique items = ' + keyCount
      );
    }

    let start;
    let time;

    if (grailSort) {
      let grail = new GrailSort(test);

      let buffer = null;
      let bufferLen = 0;

      // Grailsort with static buffer
      if (grailBufferType == 1) {
        buffer = new Array(GrailSort.GRAIL_STATIC_EXT_BUF_LEN);
        bufferLen = GrailSort.GRAIL_STATIC_EXT_BUF_LEN;
      }
      // Grailsort with dynamic buffer
      else if (grailBufferType == 2) {
        bufferLen = 1;
        while (bufferLen * bufferLen < length) {
          bufferLen *= 2;
        }
        buffer = new Array(bufferLen);
      }

      start = getTimestamp();
      grail.grailCommonSort(this.keyArray, 0, length, buffer, bufferLen);
      time = getTimestamp() - start;
    } else {
      start = getTimestamp();
      this.keyArray.sort();
      time = getTimestamp() - start;
    }

    console.log('- Sorted in ' + time + 'ms...');
    this.referenceArray.sort();

    let success = this.testArray(length, test);
    if (success) {
      console.log(' and the sort was successful!\n');
    } else {
      console.log(' but the sort was NOT successful!!\nReason: ' + this.failReason);
      throw new Error();
    }

    // Sometimes the garbage collector wasn't cooperating.
    this.keyArray.fill(null);
    this.valueArray.fill(null);
    this.referenceArray.fill(null);
  }

  checkBoth(length, keyCount, grailStrategy, test) {
    let tempSeed = this.seed;
    for (let i = 0; i < 3; i++) {
      this.checkAlgorithm(length, keyCount, true, i, grailStrategy, test);
      this.seed = tempSeed;
    }

    this.checkAlgorithm(length, keyCount, false, 0, null, test);
  }
}

function main() {
  let maxLength = 5000000;
  let maxKeyCount = 2500000;

  let testClass = new Tester(maxLength, maxKeyCount);
  let testCompare = new GrailComparator();

  console.log('Warming-up...');

  try {
    for (let u = 5; u <= maxLength / 100; u *= 10) {
      for (let v = 2; v <= u && v <= maxKeyCount / 100; v *= 2) {
        for (let i = 0; i < 3; i++) {
          testClass.checkAlgorithm(u, v - 1, true, i, 'All Strategies', testCompare);
        }
      }
    }

    console.log('\n*** Testing Grailsort against Timsort ***');

    testClass.checkBoth(15, 4, 'Opti.Gnome', testCompare);
    testClass.checkBoth(15, 8, 'Opti.Gnome', testCompare);

    testClass.checkBoth(1000000, 3, 'Strategy 3', testCompare);
    testClass.checkBoth(1000000, 1023, 'Strategy 2', testCompare);
    testClass.checkBoth(1000000, 500000, 'Strategy 1', testCompare);

    testClass.checkBoth(10000000, 3, 'Strategy 3', testCompare);
    testClass.checkBoth(10000000, 4095, 'Strategy 2', testCompare);
    testClass.checkBoth(10000000, 5000000, 'Strategy 1', testCompare);
/*
    testClass.checkBoth(50000000, 3, 'Strategy 3', testCompare);
    testClass.checkBoth(50000000, 16383, 'Strategy 2', testCompare);
    testClass.checkBoth(50000000, 25000000, 'Strategy 1', testCompare);

    testClass.checkBoth(50000000, 25000000, 'Strategy 1', testCompare);
    testClass.checkBoth(50000000, 16383, 'Strategy 2', testCompare);
    testClass.checkBoth(50000000, 3, 'Strategy 3', testCompare);
*/
    testClass.checkBoth(10000000, 5000000, 'Strategy 1', testCompare);
    testClass.checkBoth(10000000, 4095, 'Strategy 2', testCompare);
    testClass.checkBoth(10000000, 3, 'Strategy 3', testCompare);

    testClass.checkBoth(1000000, 500000, 'Strategy 1', testCompare);
    testClass.checkBoth(1000000, 1023, 'Strategy 2', testCompare);
    testClass.checkBoth(1000000, 3, 'Strategy 3', testCompare);

    testClass.checkBoth(15, 8, 'Opti.Gnome', testCompare);
    testClass.checkBoth(15, 4, 'Opti.Gnome', testCompare);

    console.log('\nAll tests passed successfully!!');
  } catch (e) {
    console.log('\nTesting failed!!\n');
    console.log(e);
  }
}

main();
