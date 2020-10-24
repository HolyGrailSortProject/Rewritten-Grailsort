package sort;

import java.lang.reflect.Array;
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
    
    private GrailPair[] keyArray;
    private GrailPair[] referenceArray;
    private Integer[]   valueArray;
    
    private String failReason;
    
    public Tester(int maxLength, int maxKeyCount) {
        this.seed       = 100000001;
        this.keyArray  = new GrailPair[maxLength];
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
                this.keyArray[i] = new GrailPair(key, this.valueArray[key]);
                this.valueArray[key]++;
            }
            else {
                this.keyArray[i] = new GrailPair(this.getRandomNumber(1000000000), 0);
            }
        }
    }
    
    private boolean testArray(int length, GrailComparator test) {
        for(int i = 1; i < length; i++) {
            int compare = test.compare(this.keyArray[i - 1],
                                       this.keyArray[i    ]);
            if(compare > 0) {
                this.failReason = "testArray[" + (i - 1) + "] and testArray[" + i + "] are out-of-order\n"; 
                return false;
            }
            else if(compare == 0 && this.keyArray[i - 1].getValue() > this.keyArray[i].getValue()) {
                this.failReason = "testArray[" + (i - 1) + "] and testArray[" + i + "] are unstable\n";
                return false;
            }
            else if(!this.keyArray[i - 1].equals(this.referenceArray[i - 1])) {
                this.failReason = "testArray[" + (i - 1) + "] does not match the reference array\n";
                return false;
            }
        }
        return true;
    }
    
    private void checkAlgorithm(int length, int keyCount, boolean grailSort, int grailBufferType, String grailStrategy, GrailComparator test) throws Exception {
        this.generateTestArray(length, keyCount);
        this.referenceArray = Arrays.copyOf(this.keyArray, length);
        
        String grailType = "w/o External Buffer";
        if(grailBufferType == 1) {
            grailType = "w/ O(1) Buffer     ";
        }
        else if(grailBufferType == 2) {
            grailType = "w/ O(sqrt n) Buffer";
        }
        
        if(grailSort) {
            System.out.println("\n* Grailsort " + grailType + ", " + grailStrategy + " \n* length = " + length + ", unique items = " + keyCount);
        }
        else {
            System.out.println("\n* Arrays.sort (Timsort)  \n* length = " + length + ", unique items = " + keyCount);
        }
        
        long start;
        long time;
        
        if(grailSort) {
            GrailSort<GrailPair> grail = new GrailSort<>(test);
            
            GrailPair[] buffer = null;
            int bufferLen = 0;

            // Grailsort with static buffer
            if(grailBufferType == 1) {
                buffer    = (GrailPair[]) Array.newInstance(this.keyArray[0].getClass(), GrailSort.GRAIL_STATIC_EXT_BUF_LEN);
                bufferLen = GrailSort.GRAIL_STATIC_EXT_BUF_LEN;
            }
            // Grailsort with dynamic buffer
            else if(grailBufferType == 2) {
                bufferLen = 1;
                while((bufferLen * bufferLen) < length) {
                    bufferLen *= 2;
                }
                buffer = (GrailPair[]) Array.newInstance(this.keyArray[0].getClass(), bufferLen);
            }
            
            start = System.nanoTime();
            grail.grailCommonSort(this.keyArray, 0, length, buffer, bufferLen);
            time = System.nanoTime() - start;
        }
        else {
            start = System.nanoTime();
            Arrays.sort(this.keyArray, 0, length, test);
            time = System.nanoTime() - start;
        }
        
        System.out.print("- Sorted in " + time * 1e-6d + "ms...");
        Arrays.sort(this.referenceArray, 0, length, test);
        
        boolean success = this.testArray(length, test);
        if(success) {
            System.out.print(" and the sort was successful!\n");
        }
        else {
            System.out.print(" but the sort was NOT successful!!\nReason: " + this.failReason);
            throw new Exception();
        }
        
        // Sometimes the garbage collector wasn't cooperating.
        Arrays.fill(this.keyArray,       null);
        Arrays.fill(this.valueArray,     null);
        Arrays.fill(this.referenceArray, null);
        System.gc();
    }
    
    private void checkBoth(int length, int keyCount, String grailStrategy, GrailComparator test) throws Exception {
        int tempSeed = this.seed;
        for(int i = 0; i < 3; i++) {
            this.checkAlgorithm(length, keyCount, true, i, grailStrategy, test);
            this.seed = tempSeed;
        }

        this.checkAlgorithm(length, keyCount, false, 0, null, test);
    }
    
    public static void main(String[] args) {
        int maxLength   = 50000000;
        int maxKeyCount = 25000000;
        
        Tester testClass = new Tester(maxLength, maxKeyCount);
        GrailComparator testCompare = new GrailComparator();
        
        System.out.println("Warming-up the JVM...");
        
        try {
            for(int u = 5; u <= (maxLength / 100); u *= 10) {
                for(int v = 2; v <= u && v <= (maxKeyCount / 100); v *= 2) {
                    for(int i = 0; i < 3; i++) {
                        testClass.checkAlgorithm(u, v - 1, true, i, "All Strategies", testCompare);
                    }
                }
            }

            System.out.println("\n*** Testing Grailsort against Timsort ***");

            testClass.checkBoth(      15,        4, "Opti.Gnome", testCompare);
            testClass.checkBoth(      15,        8, "Opti.Gnome", testCompare);

            testClass.checkBoth( 1000000,        3, "Strategy 3", testCompare);
            testClass.checkBoth( 1000000,     1023, "Strategy 2", testCompare);
            testClass.checkBoth( 1000000,   500000, "Strategy 1", testCompare);

            testClass.checkBoth(10000000,        3, "Strategy 3", testCompare);
            testClass.checkBoth(10000000,     4095, "Strategy 2", testCompare);
            testClass.checkBoth(10000000,  5000000, "Strategy 1", testCompare);

            testClass.checkBoth(50000000,        3, "Strategy 3", testCompare);
            testClass.checkBoth(50000000,    16383, "Strategy 2", testCompare);
            testClass.checkBoth(50000000, 25000000, "Strategy 1", testCompare);

            testClass.checkBoth(50000000, 25000000, "Strategy 1", testCompare);
            testClass.checkBoth(50000000,    16383, "Strategy 2", testCompare);
            testClass.checkBoth(50000000,        3, "Strategy 3", testCompare);

            testClass.checkBoth(10000000,  5000000, "Strategy 1", testCompare);
            testClass.checkBoth(10000000,     4095, "Strategy 2", testCompare);
            testClass.checkBoth(10000000,        3, "Strategy 3", testCompare);

            testClass.checkBoth( 1000000,   500000, "Strategy 1", testCompare);
            testClass.checkBoth( 1000000,     1023, "Strategy 2", testCompare);
            testClass.checkBoth( 1000000,        3, "Strategy 3", testCompare);

            testClass.checkBoth(      15,        8, "Opti.Gnome", testCompare);
            testClass.checkBoth(      15,        4, "Opti.Gnome", testCompare);
            
            System.out.println("\nAll tests passed successfully!!");
        }
        catch (Exception e) {
            System.out.println("\nTesting failed!!\n");
            e.printStackTrace();
        }
    }
}