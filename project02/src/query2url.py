#!/usr/bin/python

import sys
import argparse
import urllib
import re


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

non_alnum = re.compile('[\W_]+')
def q_str2terms(q_str):
    raw = q_str.split('.',1)
    raw = raw.strip().rstrip('.').replace('.','')
    raw = non_alnum.sub(' ',raw)
    terms = raw.split(" ")[3:]
    return (int(no.strip()),terms)

def main():
    args = process_args()
    dbid = get_DBID(args)
    params = [('d',dbid), ('g','p')]
    t = 'v' #if args.m else 'c'

    for q_str in sys.stdin:
        q_terms = q_str2terms(q_str)
    
        for q_term in q_terms:
            params.append( (t,q_term) )

        print "%s?%s" % (args.BASE_URL,urllib.urlencode(params))


if __name__ == "__main__":
    main()
