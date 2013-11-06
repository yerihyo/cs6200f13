#!/usr/bin/python

import sys
import argparse
import urllib
import re
import lib

def process_args():
    parser = argparse.ArgumentParser(description='Process options.')
    parser.add_argument('BASE_URL', type=str, help='OUT DIR')
    parser.add_argument('-p', type=str, help='stopwords file')
    parser.add_argument('-m', type=str, help='stemlist file')
    args = parser.parse_args()
    return args

def get_DBID(args):
    dbid = 0
    if args.p: dbid +=2
    if args.m: dbid +=1
    return dbid

def main():
    args = process_args()
    dbid = get_DBID(args)
    params = [('d',dbid), ('g','p')]
    t = 'v' #if args.m else 'c'

    for q_str in sys.stdin:
        q_terms = lib.q_str2q_terms(q_str)
    
        for q_term in q_terms:
            params.append( (t,q_term) )

        print "%s?%s" % (args.BASE_URL,urllib.urlencode(params))


if __name__ == "__main__":
    main()
