#!/usr/bin/python

import sys
import lib
import argparse

h_fe = {
    'OKTF': lib.get_OKTF,
}

def process_args():
    parser = argparse.ArgumentParser(description='Process options.')
    parser.add_argument('FE', type=str, help='feature extractor name')
    parser.add_argument('QUERY_NO', type=int, help='query no')
    parser.add_argument('QUERY_TERMS', type=str, help='query terms')
    args = parser.parse_args()
    return args

def file_2_doc2fv(f, fe):
    doc2fv = {} # doc2feature_vector
    for term_id, (ctf, df, tf_dict, doc_len_list) in enumerate(lib.file2results(f)):

        for doc_id, tf in tf_dict.iteritems():
            
            if doc_id not in doc2fv: doc2fv[doc_id] = {}
            doc_fv = doc2fv[doc_id]

            doc_len = doc_len_list[doc_id-1]
            if doc_len is None: raise Exception()

            v = fe(tf, doc_len, lib.avg_doc_len)
            doc_fv[term_id] = v

    return doc2fv

def q_terms2feature_vector(terms, fe):
    fv = {} #dict([(fe_name,{}) for fe_name in FEs])
    doc_len = len(terms)
    for term_id, term in enumerate(terms):
        v = fe(1, len(terms), len(terms))
        fv[term_id] = v
    return fv

def get_ranked_list(query_fv, doc2fv):
    query_fv_len = lib.vector2len(query_fv)

    results = []
    for doc_id, doc_fv in doc2fv.iteritems():
        score = lib.get_cosine(query_fv, doc_fv, query_fv_len)
        results.append( (doc_id,score) )
    results = sorted(results, key=lambda x:x[1], reverse=True)
    return results

def main():
    args = process_args()
    q_terms = lib.q_str2q_terms(args.QUERY_TERMS)

    fe = h_fe[args.FE]
    query_fv = q_terms2feature_vector(q_terms, fe)
    doc2fv = file_2_doc2fv(sys.stdin, fe)
    ranked_list = get_ranked_list(query_fv, doc2fv)

    for i, r in enumerate(ranked_list[:min(len(ranked_list),1000)]):
        doc_id, score = r
        tokens = ( args.QUERY_NO, 'Q0', doc_id, (i+1), score )
        print " ".join([str(x) for x in tokens])


        



if __name__ == "__main__":
    main()
