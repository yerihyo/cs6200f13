#!/usr/bin/python

import sys,math


def get_out_degree(filename):
    out_degree = {}
    with open(filename) as f:
        for l in f:
            for i,p in enumerate(l.split(' ')):
                if p not in out_degree:
                    out_degree[p] = 0

                if i!=0: out_degree[p] += 1
            
    return out_degree

def out_degree2sinks(out_degree):
    N = len(out_degree)
    sink_list = filter(lambda x: out_degree[x]==0, out_degree.keys())
    return dict(zip(sink_list, [True,]*N))

def calc_perp(probs):
    entropy = sum([-1*math.log(p,2) for p in probs])/len(probs)
    print >>sys.stderr, "entropy", entropy

    return math.pow(2,entropy)

def next_pr(filename, pr, out_degree, sinks=None, d=0.85):
    if sinks is None: sinks = out_degree2sinks(out_degree)

    # calculate total sink PR
    sinkPR = sum([pr[p] for p in sinks])
    N = len(pr)

    new_pr = {}
    with open(filename) as f:
        for l in f:
            pages = l.split(' ')
            p = pages[0]
            new_pr[p] = (1-d)/N + d*sinkPR/N
            for q in pages[1:]:
                new_pr[p] += d*pr[q]/out_degree[q]
    return new_pr


def main():
    filename = sys.argv[1]

    out_degree = get_out_degree(filename)
    sinks = out_degree2sinks(out_degree)
    N = len(out_degree)

    pr = dict(zip(out_degree.keys(), [1.0/N,]*N))
    prev_perp = calc_perp(pr.values())
    i = 0
    while True:
        i += 1
        pr = next_pr(filename, pr, out_degree, sinks)
        perp = calc_perp(pr.values())
        print >>sys.stderr, "perp", perp
        if int(perp)==int(prev_perp): break

if __name__ == "__main__":
    main()
