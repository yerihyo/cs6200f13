#!/usr/bin/python

import sys
import lib

def main():

    doc2fv = {} # doc2feature_vector
    for term_id, (ctf, df, tf_dict, doc_len_list) in enumerate(lib.file2results(sys.stdin)):

        for doc_id, tf in tf_dict.iteritems():
            
            if doc_id not in doc2fv: doc2fv[doc_id] = {}
            doc_fv = doc2fv[doc_id]

            doc_len = doc_len_list[doc_id-1]
            if doc_len is None: raise Exception()
            OKTF = tf/(tf + 0.5 + 1.5 * doc_len / lib.avg_doc_len )

            doc_fv[term_id] = OKTF

    doc2fv


if __name__ == "__main__":
    main()
