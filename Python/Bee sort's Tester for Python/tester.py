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
 #                       Bee sort
 #                       _fluffyy
 #                       Morwenn
 #                       
 # Special thanks to "The Studio" Discord community!
 #
# Editor : Bee sort

# importing Python\thatsOven's Rewritten Grailsort for Python\GrailSort.py
# i know, it looks messy.
import sys
originalPath = sys.path[0]
sys.path[0] += "\\..\\thatsOven's Rewritten Grailsort for Python\\"
import GrailSort
sys.path[0] = originalPath

######################################################################### Back to the code

from interface import implements, Interface # if you don't have python-interface, make sure to install it on pip! also, thanks https://stackoverflow.com/questions/2124190/how-do-i-implement-interfaces-in-python !

class IntegerPair(Interface):
    pass # not currently completed