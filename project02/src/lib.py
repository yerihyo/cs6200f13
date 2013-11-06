#!/usr/bin/python

import sys
import re
import math

doc_count=84678

#67.521221569 # got it from dump.result
avg_doc_len_list=[493,493,288,288]

non_alnum = re.compile('[\W_]+')
"""
def q_str2terms(q_str):
    #raw = q_str.split('.',1)
    raw = q_str.strip().rstrip('.').replace('.','')
    raw = non_alnum.sub(' ',raw)
    terms = raw.split(" ")[3:]
    return (int(no.strip()),terms)
    """
def q_str2q_terms(q_str):
    #raw = q_str.split('.',1)
    raw = q_str.strip().rstrip('.').replace('.','')
    raw = non_alnum.sub(' ',raw)
    terms = raw.split(" ")[3:]
    return sorted(set(terms))

def get_OKTF(tf, doc_len, avg_doc_len):
    return tf/(tf + 0.5 + 1.5 * doc_len / avg_doc_len )

def file2tokens(f, indices, delim=None, token_count_per_line=None):
    for l in f:
        if delim is None: tokens = l.split()
        else: tokens = l.split(delim)

        if token_count_per_line is not None and len(tokens)!=token_count_per_line:
            raise Exception(len(tokens))

        if isinstance(indices,int): yield tokens[indices]
        else: yield tuple(tokens[i] for i in indices)
        
def file2results(f):
    lines_left = ctf = df = None
    doc_len_list = [None]*doc_count
    tf_dict = {}

    for i, l in enumerate(f):
        l = l.strip()
        tokens = l.split()

        if len(tokens) not in [2,3]: raise Exception(l)
        if len(tokens)==2:
            if lines_left==0: yield (ctf, df, tf_dict, doc_len_list) # doc_len_list is incomplete
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


def vector2len(v):
    return math.sqrt(sum([v[x]**2 for x in v.keys()]))

def get_innerproduct(vec1, vec2):
    intersection = set(vec1.keys()) & set(vec2.keys())
    return sum([vec1[x] * vec2[x] for x in intersection])

def get_cosine(vec1, vec2, len1=None, len2=None):
    numerator = get_innerproduct(vec1,vec2)

    if len1 is None: len1 = vector2len(vec1)
    if len2 is None: len2 = vector2len(vec2)
    denominator = len1 * len2

    if not denominator:
        return 0.0
    else:
        return float(numerator) / denominator
