#
 # MIT License
 # 
 # Copyright (c) 2013 Andrey Astrelin
 # Copyright (c) 2020 The Holy Grail Sort Project
 # 
 # Permission is hereby granted, free of charge, to any person obtaining a copy
 # of this software and associated documentation files (the "Software"), to deal
 # in the Software without restriction, including without limitation the rights
 # to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 # copies of the Software, and to permit persons to whom the Software is
 # furnished to do so, subject to the following conditions:
 # 
 # The above copyright notice and this permission notice shall be included in all
 # copies or substantial portions of the Software.
 # 
 # THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 # IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 # FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 # AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 # LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 # OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 # SOFTWARE.
 #
 #
 # The Holy Grail Sort Project
 # Project Manager:      Summer Dragonfly
 # Project Contributors: 666666t
 #                       Anonymous0726
 #                       aphitorite
 #                       dani_dlg
 #                       EilrahcF
 #                       Enver
 #                       lovebuny
 #                       MP
 #                       phoenixbound
 #                       thatsOven
 #                       DeveloperSort
 #                       _fluffyy
 #                       Morwenn
 #                       
 # Special thanks to "The Studio" Discord community!
 #
# Editor : DeveloperSort

# importing Python\Amari Calipso's Rewritten Grailsort for Python\GrailSort.py
# i know, it looks messy.
import sys
originalPath = sys.path[0]
sys.path[0] += "\\..\\Amari Calipso's Rewritten Grailsort for Python\\"
import GrailSort
sys.path[0] = originalPath

######################################################################### Back to the code

from interface import implements, Interface # if you don't have python-interface, make sure to install it on pip! also, thanks https://stackoverflow.com/questions/2124190/how-do-i-implement-interfaces-in-python !

class IntegerPair(Interface):
    def getKey():
        pass
    def getValue():
        pass

class GrailPair(implements(IntegerPair)):
    def __init__(self,key, value):
        self.key = key
        self.value = value
    def getKey():
        return this.key
    def getValue():
        return this.value

class GrailComparator:
    def compare(o1,o2):
        if    o1.getKey() < o2.getKey(): return -1
        elif  o1.getKey() > o2.getKey(): return  1
        else:                            return  0

class Tester:
    seed = None
    keyArray = []
    referenceArray = []
    valueArray = []
    failReason = ""

    def Tester(self,maxLength,maxKeyCount):
        self.seed = 100000001
        this.KeyArray = [GrailPair()] * maxLength
        this.ValueArray = [int()] * maxKeyCount