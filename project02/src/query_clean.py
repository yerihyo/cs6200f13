#!/usr/bin/python

import sys
import lib

def main():
    for l in sys.stdin:
        print " ".join( lib.q_str2terms(l) )
    
if __name__ == "__main__":
    main()
