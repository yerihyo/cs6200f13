#!/usr/bin/python

import sys
import lib

def main():
    for result in lib.file2results(sys.stdin):
        pass
    _,_,_,doc_len_list = result


    total_tf = sum(filter(lambda x: x is not None, doc_len_list))
    print float(total_tf)/lib.doc_count

    for i, x in enumerate(doc_len_list):
        if x is not None: continue
        doc_id = i+1
        print >>sys.stderr, "Invalid doc:", doc_id

    #print >>sys.stderr, len( filter(lambda x: x is not None, doc_len_list) )
    

if __name__ == "__main__":
    main()
