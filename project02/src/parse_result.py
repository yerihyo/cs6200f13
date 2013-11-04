#!/usr/bin/python

import sys
import lib

def main():

    for ctf, df, tf_dict, doc_len_list in lib.file2results(sys.stdin):
        for doc_id, tf in tf_dict.iteritems():
            OKTF = tf/(tf + 0.5
        


if __name__ == "__main__":
    main()
