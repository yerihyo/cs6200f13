#!/usr/bin/python

import sys
import lib
import argparse

h_fe = {
    'OKTF': (lib.get_OKTF, lib.get_innerproduct),
    'OKTF_IDF': (lib.get_OKTF_IDF, lib.get_innerproduct),
}

def process_args():
    parser = argparse.ArgumentParser(description='Process options.')
    parser.add_argument('DOCLIST', type=str, help='internal2external doc id mapping file')
    parser.add_argument('FE', type=str, help='feature extractor name')
    parser.add_argument('QUERY_NO', type=int, help='query no')
    parser.add_argument('QUERY_TERMS', type=str, help='query terms')
    parser.add_argument('-p', action='store_true')
    parser.add_argument('-m', action='store_true')
    args = parser.parse_args()
    return args

def file_2_doc2fv(f, func_fe, avg_doc_len, term_count=None):
    doc2fv = {} # doc2feature_vector
    df_list = []

    for term_id, (ctf, df, tf_dict, doc_len_list) in enumerate(lib.file2results(f)):
        if not df: raise Exception(df)
        df_list.append(df)

        for doc_id, tf in tf_dict.iteritems():
            
            if doc_id not in doc2fv: doc2fv[doc_id] = {}
            doc_fv = doc2fv[doc_id]

            doc_len = doc_len_list[doc_id-1]
            if doc_len is None: raise Exception()

            v = func_fe(tf, doc_len, avg_doc_len, df)
            doc_fv[term_id] = v

    if term_count is not None and term_id+1 != term_count:
        raise Exception("%d vs %d" % (term_id, term_count) )

    return (doc2fv,df_list)

def q_terms2feature_vector(terms, func_fe, df_list):
    fv = {} #dict([(fe_name,{}) for fe_name in FEs])
    doc_len = len(terms)
    for term_id, term in enumerate(terms):
        df = df_list[term_id]
        if not df: raise Exception(df_list)

        v = func_fe(1, len(terms), len(terms), df)
        #v = func_fe(1, len(terms), lib.avg_doc_len)
        fv[term_id] = v
    if term_id+1 != len(df_list): raise Exception("%d vs %d" % (term_id,df_list) )
    return fv

def get_ranked_list(query_fv, doc2fv, func_sim):
    query_fv_len = lib.vector2len(query_fv)

    results = []
    for doc_id, doc_fv in doc2fv.iteritems():
        score = func_sim(query_fv, doc_fv)
        results.append( (doc_id,score) )
    results = sorted(results, key=lambda x:x[1], reverse=True)
    return results

def main():
    args = process_args()
    dbid = lib.get_DBID(args)
    avg_doc_len = lib.avg_doc_len_list[dbid]

    q_terms = lib.q_str2q_terms(args.QUERY_TERMS, args)
    print >>sys.stderr, "TERMS:", " ".join(q_terms)
    with open(args.DOCLIST) as f:
        docid_int2ext = list(lib.file2tokens(f,1,token_count_per_line=2))

    fe = h_fe[args.FE]
    doc2fv,df_list = file_2_doc2fv(sys.stdin, fe[0], avg_doc_len, term_count=len(q_terms))
    query_fv = q_terms2feature_vector(q_terms, fe[0], df_list)
    #print >>sys.stderr, query_fv
    
    ranked_list = get_ranked_list(query_fv, doc2fv, fe[1])

    for i, r in enumerate(ranked_list[:min(len(ranked_list),1000)]):
        doc_id, score = r
        #doc_fullid = doc_id
        doc_fullid = docid_int2ext[doc_id-1]
        tokens = ( args.QUERY_NO, 'Q0', doc_fullid, (i+1), score, 'Exp')
        print " ".join([str(x) for x in tokens])


        



if __name__ == "__main__":
    main()
