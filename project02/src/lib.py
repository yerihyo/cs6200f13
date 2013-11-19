#!/usr/bin/python

import sys
import re
import math
import os

# directories
FILE_DIR = os.path.dirname(os.path.realpath(__file__))
BASE_DIR = os.path.normpath(os.path.join(FILE_DIR, os.pardir))
DATA_DIR = os.path.join(BASE_DIR,'data')


doc_count=84678

#67.521221569 # got it from dump.result
corpus_stats=[
    {'NUM_DOCS':84678, 'NUM_TERMS':41802513, 'NUM_UNIQUE_TERMS':207615, 'AVE_LEN':{'doc':493} },
    {'NUM_DOCS':84678, 'NUM_TERMS':41802513, 'NUM_UNIQUE_TERMS':166242, 'AVE_LEN':{'doc':493} }, 
    {'NUM_DOCS':84678, 'NUM_TERMS':24401877, 'NUM_UNIQUE_TERMS':207224, 'AVE_LEN':{'doc':288,'query':7.12}, }, 
    {'NUM_DOCS':84678, 'NUM_TERMS':24401877, 'NUM_UNIQUE_TERMS':166054, 'AVE_LEN':{'doc':288,'query':7.12}, }, 
    ]
# avg_doc_len_list=[493,493,288,288]
# uniq_term_count_list=[207615,166242,207224,166054]

non_alnum = re.compile('[\W_]+')
"""
def q_str2terms(q_str):
    #raw = q_str.split('.',1)
    raw = q_str.strip().rstrip('.').replace('.','')
    raw = non_alnum.sub(' ',raw)
    terms = raw.split(" ")[3:]
    return (int(no.strip()),terms)
    """
def get_stem_dict():
    filename = os.path.join(DATA_DIR, 'stem-classes.lst')
    h = {}
    with open(filename) as f:
        for i, l in enumerate(f):
            if i==0: continue
            tokens = re.split("\s*\|\s*",l.strip())
            if len(tokens)!=2: raise Exception()
            for w in tokens[1].split():
                h[w] = tokens[0]

    return h

def get_stopwords():
    filename = os.path.join(DATA_DIR, 'stoplist.txt')
    with open(filename) as f:
        return set([l.strip() for l in f])
            
def q_str2q_terms(q_str,args):
    #raw = q_str.split('.',1)
    raw = q_str.strip().rstrip('.').replace('.','').lower()
    raw = non_alnum.sub(' ',raw)
    terms = set(raw.split(" ")[3:])

    if args.p:
        stopwords = get_stopwords()
        terms = terms - stopwords

    if args.m:
        h = get_stem_dict()
        terms = set([h[x] for x in terms])

            
    return sorted(terms)

### Feature Extraction
def get_TFIDF_vanilla(**kwargs):
    return kwargs['tf']/kwargs['df']

def get_TFIDF_wikipedia(**kwargs):
    return (0.5 + 0.5*kwargs['tf']) * ( math.log(kwargs['NUM_DOCS']) - math.log(kwargs['df']) )

def get_TFIDF_CS6200(**kwargs):
    return kwargs['tf']/(kwargs['tf'] + 0.5 + 1.5 * kwargs['doc_len'])

def get_OKTF(**kwargs):
    return kwargs['tf']/(kwargs['tf'] + 0.5 + 1.5 * kwargs['doc_len'] / kwargs['AVE_LEN'][kwargs['doc_type']] )

def get_OKTF_IDF(**kwargs):
    return kwargs['tf']/(kwargs['tf'] + 0.5 + 1.5 * kwargs['doc_len'] / kwargs['AVE_LEN'][kwargs['doc_type']] )/kwargs['df']

def get_LM_LAPLACE(**kwargs):
    return float(kwargs['tf']+1)/(kwargs['doc_len']+kwargs['NUM_UNIQUE_TERMS'])

def get_LM_JM(**kwargs):
    l = 0.25
    return l*float(kwargs['tf'])/kwargs['doc_len'] + (1-l)*kwargs['ctf']/kwargs['NUM_TERMS']


def get_BM25_log(**kwargs):
    k1 = 1.2
    b = 0.75
    k2 = 100

    if kwargs['doc_type'] == 'doc':
        k_top = k1
        k_bottom = k1*((1-b) + b*kwargs['doc_len']/kwargs['AVE_LEN'][kwargs['doc_type']] ) 
        c = math.log(kwargs['NUM_DOCS']-kwargs['df']+0.5) - math.log(kwargs['df']+0.5)
    elif kwargs['doc_type'] == 'query':
        k_top = k2
        k_bottom = k2
        c = 0
    else: raise Exception()

    return c + math.log(k_top+1) + math.log(kwargs['tf']) - math.log(k_bottom+kwargs['tf'])




def file2tokens(f, indices, delim=None, token_count_per_line=None):
    for l in f:
        l = l.strip()
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

def get_DBID(args):
    dbid = 0
    if args.p: dbid +=2
    if args.m: dbid +=1
    return dbid

def vector2len(v):
    return math.sqrt(sum([v[x]**2 for x in v.keys()]))

def get_innerproduct(vec1, vec2):
    intersection = set(vec1.keys()) & set(vec2.keys())
    return sum([vec1[x] * vec2[x] for x in intersection])

def get_log_sum(vec1, vec2):
    intersection = set(vec1.keys()) & set(vec2.keys())
    return sum([ math.log(vec1[x]) + math.log(vec2[x]) for x in intersection])

def get_sum(vec1, vec2):
    intersection = set(vec1.keys()) & set(vec2.keys())
    return sum([ vec1[x] + vec2[x] for x in intersection])

def get_cosine(vec1, vec2, len1=None, len2=None):
    numerator = get_innerproduct(vec1,vec2)

    if len1 is None: len1 = vector2len(vec1)
    if len2 is None: len2 = vector2len(vec2)
    denominator = len1 * len2

    if not denominator:
        return 0.0
    else:
        return float(numerator) / denominator
