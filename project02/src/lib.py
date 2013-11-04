#!/usr/bin/python

import sys

doc_count=84678
avg_doc_len=467.521221569 # got it from dump.result


def file2results(f):
    lines_left = ctf = df = None
    doc_len_list = [None]*doc_count
    tf_dict = {}

    for i, l in enumerate(f):
        l = l.strip()
        tokens = l.split()

        if len(tokens) not in [2,3]: raise Exception(l)
        if len(tokens)==2:
            if lines_left==0: yield (ctf, df, tf_dict, None)
            elif lines_left is not None: raise Exception()

            ctf, df = (int(w) for w in tokens)
            lines_left = df
            tf_dict = {}
        else:
            doc_id, doc_len, tf = (int(w) for w in tokens)
            
            doc_len_known = doc_len_list[doc_id-1]
            if doc_len_known is not None and doc_len!=doc_len_known: raise Exception()
            doc_len_list[doc_id-1] = doc_len

            tf_dict[doc_id] = tf

            lines_left -= 1
            
    if lines_left==0: yield (ctf, df, tf_dict, doc_len_list)
    elif lines_left is not None: raise Exception("%d @ %d" % (lines_left, i) )

