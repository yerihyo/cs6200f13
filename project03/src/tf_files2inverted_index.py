#!/usr/bin/python

import sys
import re
import os
import argparse

def tf2ctf(ctf,tf,docid):
    for t,c_str in tf.iteritems():
        c = int(c_str)
        if t not in ctf: ctf[t] = {'ctf':0, 'ii':[]}
        ctf[t]['ctf'] += c
        ctf[t]['ii'].append( (docid,c) )
    
def file2tf(f):
    tf = {}
    for l in f:
        c,w = l.strip().split()
        if w in tf: raise Exception()
        tf[w] = int(c)
    return tf

def main():
    corpus = {}
    ctf = {}
    doc = {}

    for i, filename in enumerate(sys.stdin):
        filename = filename.strip()
        print >>sys.stderr, "Working on file", filename

        b = os.path.basename(filename)
        docid = b.split('.')[0].split('-')[1]

        with open(filename) as f: tf = file2tf(f)
        tf2ctf(ctf, tf, docid)
        doc[docid] = {'doc_len':sum(tf.values()) }
        #break

    corpus = {
        'NUM_DOCS':i+1,
        'NUM_UNIQUE_TERMS':len(ctf),
        'NUM_TERMS':sum(ctf[k]['ctf'] for k in ctf),
        }

    #print >>sys.stderr, corpus
    #print >>sys.stderr, ctf
    #print >>sys.stderr, doc
 

if __name__ == "__main__":
    main()

