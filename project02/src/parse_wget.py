#!/usr/bin/python

import sys
import lib
import argparse
import copy
h_fe = {
    'TFIDF_vanilla':       (lib.get_TFIDF_vanilla, lib.get_innerproduct),
    'TFIDF_vanilla_cos':   (lib.get_TFIDF_vanilla, lib.get_cosine),
    'TFIDF_wikipedia':     (lib.get_TFIDF_wikipedia, lib.get_innerproduct),
    'TFIDF_wikipedia_cos': (lib.get_TFIDF_wikipedia, lib.get_cosine),

    'TFIDF_CS6200': (lib.get_TFIDF_CS6200, lib.get_innerproduct),

    'OKTF': (lib.get_OKTF, lib.get_innerproduct),
    'OKTF_IDF': (lib.get_OKTF_IDF, lib.get_innerproduct),
    'LM_LAPLACE': (lib.get_LM_LAPLACE, lib.get_innerproduct),
    'LM_JM': (lib.get_LM_JM, lib.get_innerproduct),
    'BM25_log': (lib.get_BM25_log, lib.get_sum),
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

def file_2_doc2fv(f, func_fe, fe_kwargs, q_term_count=None):
    doc2fv = {} # doc2feature_vector
    stat_list = []

    kwargs = copy.copy(fe_kwargs)
    kwargs['doc_type'] = 'doc'

    for term_id, (ctf, df, tf_dict, doc_len_list) in enumerate(lib.file2results(f)):
        if not ctf: raise Exception(ctf)
        if not df: raise Exception(df)
        stat_list.append( {'df':df, 'ctf':ctf } )
        kwargs.update( {'df':df, 'ctf':ctf } )

        doc_len_list_not_none = filter(lambda x: x is not None, doc_len_list)
        #if q_term_count != len(doc_len_list_not_none):
        #    raise Exception("%d vs %d" % (q_term_count, len(doc_len_list_not_none) ) )

        for doc_id, tf in tf_dict.iteritems():

            kwargs['tf'] = tf

            if doc_id not in doc2fv: doc2fv[doc_id] = {}
            doc_fv = doc2fv[doc_id]

            kwargs['doc_len'] = doc_len_list[doc_id-1]
            if kwargs['doc_len'] is None: raise Exception()

            v = func_fe(**kwargs)
            doc_fv[term_id] = v

    if q_term_count is not None and term_id+1 != q_term_count:
        raise Exception("%d vs %d" % (term_id, q_term_count) )

    return (doc2fv,stat_list)

def q_terms2feature_vector(terms, func_fe, stat_list, fe_kwargs):
    kwargs = copy.copy(fe_kwargs)
    kwargs['tf'] = 1
    kwargs['doc_len'] = len(terms)
    kwargs['doc_type'] = 'query'

    fv = {} #dict([(fe_name,{}) for fe_name in FEs])
    doc_len = len(terms)
    for term_id, term in enumerate(terms):
        kwargs.update(stat_list[term_id])

        #v = func_fe(1, len(terms), len(terms), df, uniq_term_count)
        v = func_fe(**kwargs)
        fv[term_id] = v
    if term_id+1 != len(stat_list): raise Exception("%d vs %d" % (term_id,stat_list) )
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

    q_terms = lib.q_str2q_terms(args.QUERY_TERMS, args)
    print >>sys.stderr, "TERMS:", " ".join(q_terms)
    with open(args.DOCLIST) as f:
        docid_int2ext = list(lib.file2tokens(f,1,token_count_per_line=2))

        
    dbid = lib.get_DBID(args)
    fe_kwargs = copy.copy(lib.corpus_stats[dbid])

    fe = h_fe[args.FE]
    doc2fv, stat_list = file_2_doc2fv(sys.stdin, fe[0], fe_kwargs, q_term_count=len(q_terms))
    query_fv = q_terms2feature_vector(q_terms, fe[0], stat_list, fe_kwargs)
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
