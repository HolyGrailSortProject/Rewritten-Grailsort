package sort;

import java.util.Arrays;
import java.util.Comparator;

interface IntegerPair {
    public Integer getKey();
    public Integer getValue();
}

class GrailPair implements IntegerPair {
    private Integer key;
    private Integer value;
    
    public GrailPair(Integer key, Integer value) {
        this.key = key;
        this.value = value;
    }
    @Override
    public Integer getKey() {
        return this.key;
    }
    @Override
    public Integer getValue() {
        return this.value;
    }
}

class GrailComparator implements Comparator<GrailPair> {
    @Override
    public int compare(GrailPair o1, GrailPair o2) {
        if     (o1.getKey() < o2.getKey()) return -1;
        else if(o1.getKey() > o2.getKey()) return  1;
        else                               return  0;
    }
}

public class Tester {
    private int seed;
    
    private GrailPair[] testArray;
    private Integer[] valueArray;
    
    public Tester(int maxLength, int maxKeyCount) {
        this.seed       = 100000001;
        this.testArray  = new GrailPair[maxLength];
        this.valueArray = new Integer[maxKeyCount];
    }

    private int getRandomNumber(int key) {
        this.seed = (this.seed * 1234565) + 1;
        return (int) (((long) (this.seed & 0x7fffffff) * key) >> 31);
    }
    
    private void generateTestArray(int length, int keyCount) {
        for(int i = 0; i < keyCount; i++) {
            this.valueArray[i] = 0;
        }
        
        for(int i = 0; i < length; i++) {
            if(keyCount != 0) {
                int key = this.getRandomNumber(keyCount);
                this.testArray[i] = new GrailPair(key, this.valueArray[key]);
                this.valueArray[key]++;
            }
            else {
                this.testArray[i] = new GrailPair(this.getRandomNumber(1000000000), 0);
            }
        }
    }
    
    private static boolean testArray(GrailPair[] testArray, int length, GrailComparator test) {
        for(int i = 1; i < length; i++) {
            int compare = test.compare(testArray[i - 1],
                                       testArray[i    ]);
            if(compare > 0) {
                return false;
            }
            else if(compare == 0 && testArray[i - 1].getValue() > testArray[i].getValue()) {
                return false;
            }
        }
        return true;
    }
    
    private void checkAlgorithm(int length, int keyCount, boolean grailSort, String grailStrategy, GrailComparator test) {
        this.generateTestArray(length, keyCount);
        
        if(grailSort) {
            System.out.println("\n* Grailsort, " + grailStrategy + " - length = " + length + ", unique items = " + keyCount);
        }
        else {
            System.out.println("* Arrays.sort           - length = " + length + ", unique items = " + keyCount);
        }
        
        long start;
        long time;
        
        if(grailSort) {
            GrailSort<GrailPair> grail = new GrailSort<>(test);
            
            start = System.nanoTime();
            grail.grailSortInPlace(this.testArray, 0, length);
            time = System.nanoTime() - start;
        }
        else {
            start = System.nanoTime();
            Arrays.sort(this.testArray, 0, length, test);
            time = System.nanoTime() - start;
        }
        
        System.out.print("- Sorted in " + time * 1e-6d + "ms...");
        
        boolean success = Tester.testArray(this.testArray, length, test);
        if(success) {
            System.out.print(" and the sort was successful!\n");
        }
        else {
            System.out.print(" but the sort was NOT successful!!\n");
        }
    }
    
    private void checkBoth(int length, int keyCount, String grailStrategy, GrailComparator test) {
        int tempSeed = this.seed;
        this.checkAlgorithm(length, keyCount, true, grailStrategy, test);
        
        this.seed = tempSeed;
        this.checkAlgorithm(length, keyCount, false, null, test);
    }
    
    public static void main(String[] args) {
        int maxLength   = 50000000;
        int maxKeyCount = 32767;
        
        Tester testClass = new Tester(maxLength, maxKeyCount);
        GrailComparator testCompare = new GrailComparator();
        
        testClass.checkBoth(     15,      4, "Opti.Gnome", testCompare);
        testClass.checkBoth(     15,      8, "Opti.Gnome", testCompare);
        
        testClass.checkBoth(1000000,      3, "Strategy 3", testCompare);
        testClass.checkBoth(1000000,   1023, "Strategy 2", testCompare);
        testClass.checkBoth(1000000,   2047, "Strategy 1", testCompare);
        
        testClass.checkBoth(10000000,     3, "Strategy 3", testCompare);
        testClass.checkBoth(10000000,  4095, "Strategy 2", testCompare);
        testClass.checkBoth(10000000,  8191, "Strategy 1", testCompare);
        
        testClass.checkBoth(50000000,     3, "Strategy 3", testCompare);
        testClass.checkBoth(50000000, 16383, "Strategy 2", testCompare);
        testClass.checkBoth(50000000, 32767, "Strategy 1", testCompare);
        
        testClass.checkBoth(50000000, 32767, "Strategy 1", testCompare);
        testClass.checkBoth(50000000, 16383, "Strategy 2", testCompare);
        testClass.checkBoth(50000000,     3, "Strategy 3", testCompare);
        
        testClass.checkBoth(10000000,  8191, "Strategy 1", testCompare);
        testClass.checkBoth(10000000,  4095, "Strategy 2", testCompare);
        testClass.checkBoth(10000000,     3, "Strategy 3", testCompare);
        
        testClass.checkBoth(1000000,   2047, "Strategy 1", testCompare);
        testClass.checkBoth(1000000,   1023, "Strategy 2", testCompare);
        testClass.checkBoth(1000000,      3, "Strategy 3", testCompare);
        
        testClass.checkBoth(     15,      8, "Opti.Gnome", testCompare);
        testClass.checkBoth(     15,      4, "Opti.Gnome", testCompare);
    }
}