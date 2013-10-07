#!/usr/bin/python

import sys,math
import argparse

def get_degree(filename):
    #in_degree = {}
    out_degree = {}
    with open(filename) as f:
        for l in f:
            l = l.rstrip()
            words = l.split(' ')
            for i,p in enumerate(words):
                if p not in out_degree:
                    out_degree[p] = 0
                #if p not in in_degree:
                #    in_degree[p] = 0

                if i!=0: out_degree[p] += 1
                #else: in_degree[p] = len(words)-1
            
    return (out_degree)

def extract_nodegree(degree):
    N = len(degree)
    nodegree_list = filter(lambda x: degree[x]==0, degree.keys())
    return dict(zip(nodegree_list, [True,]*N))

def calc_entropy(probs):
    return sum([-1*p*math.log(p,2) for p in probs])
    #print >>sys.stderr, "entropy", entropy

    #return math.pow(2,entropy)

def next_pr(filename, pr, out_degree, sinks=None, d=0.85):
    if sinks is None: sinks = extract_nodegree(out_degree)

    # calculate total sink PR
    sinkPR = sum([pr[p] for p in sinks])
    N = len(pr)

    # Init probs with jump
    new_pr = {}
    for p in out_degree:
        new_pr[p] = (1-d)/N + d*sinkPR/N

    # Add prob if there is inlink
    with open(filename) as f:
        for l in f:
            l = l.rstrip()
            pages = l.split(' ')
            p = pages[0]
            for q in pages[1:]:
                new_pr[p] += d*pr[q]/out_degree[q]
    return new_pr

def calc_stats(pr):
    prob_sum = sum(pr.values())
    entropy = calc_entropy(pr.values())
    perp = math.pow(2,entropy)
    return [('prob_sum',prob_sum), ('entropy',entropy), ('perp',perp)]


def main():
    #if len(sys.argv)<2: raise Exception(" ".join(["usage:",sys.argv[0],"<input file>"]))
    #filename = sys.argv[1]

    parser = argparse.ArgumentParser(description='Input options for program.')
    parser.add_argument('graph_filename', help="Input graph file")
    parser.add_argument('--halt_perplexity', help="Halt process when perplexity stop changing more than given value", type=float)
    parser.add_argument('--halt_iteration', help="Halt process when iteration reaches give value", type=int)
    parser.add_argument('--print_probs', help="Print probabilities of each iteration to file")
    parser.add_argument('--print_perp', help="Print perplexity of each iteration to file")
    parser.add_argument('--print_result', help="Print pagerank result")
    parser.add_argument('--print_urls', help="Print urls to pages")
    args = parser.parse_args()

    out_degree = get_degree(args.graph_filename)
    sinks = extract_nodegree(out_degree)
    N = len(out_degree)
    pr = dict(zip(out_degree.keys(), [1.0/N,]*N))
    prev_perp = None

    i = 0
    stats = calc_stats(pr)

    # For debugging, print Iteration info
    print >>sys.stderr, "Iteration",i,": "," ".join(["%s(%.4f)" % (x[0],x[1]) for x in stats])

    if args.print_probs: prob_ofile = open(args.print_probs,'w')
    if args.print_perp: perp_ofile = open(args.print_perp,'w')

    while True:
        i += 1
        # Run single iteration of PageRank
        pr = next_pr(args.graph_filename, pr, out_degree, sinks)

        # Print probs
        if args.print_probs:
            sorted_pr = sorted(pr.items(), key=lambda x:x[0])
            print >>prob_ofile, " ".join(["%s:%.4f" % (k,v) for k,v in sorted_pr])

        # Calculate statistics (prob_sum, entropy, perplexity)
        stats = calc_stats(pr)
        print >>sys.stderr, "Iteration",i,": "," ".join(["%s(%.4f)" % (x[0],x[1]) for x in stats])

        # Print perplexity
        perp = stats[2][1]
        if args.print_perp:
            print >>perp_ofile, stats[2][1]

        # Error checking (if prob_sum fluctuates)
        if abs(stats[0][1]-1)>0.1: raise "Values fluctuating!"

        # Halting conditions
        if args.halt_iteration is not None and i>=args.halt_iteration: break
        if prev_perp and args.halt_perplexity is not None \
                and abs(perp-prev_perp)<args.halt_perplexity: break
        prev_perp = perp

    if args.print_probs: prob_ofile.close()
    if args.print_perp: perp_ofile.close()


    pr_sorted = sorted(pr.items(), key=lambda x:x[1],reverse=True)
    if args.print_result:
        with open(args.print_result, 'w') as result_ofile:
            for p,v in pr_sorted:
                print >>result_ofile, p, v

    if args.print_urls:
        with open(args.print_urls, 'w') as url_ofile:
            for p,v in pr_sorted:
                url = "http://fiji4.ccs.neu.edu/~zerg/lemurcgi_IRclass/lemur.cgi?d=0&e=%s" % p
                print >>url_ofile, "<a href='%s'>%s</a> %.4f<br/>" % (url,p,v)



if __name__ == "__main__":
    main()
