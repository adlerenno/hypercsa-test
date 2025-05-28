import csv, re, os
from collections import defaultdict
from os.path import isfile


def parse_filename():
    pass


def get_success_indicator(filename) -> str:
    if os.path.isfile(filename):
        with open(filename, 'r') as f:
            for line in f:
                return line[0]
    else:
        # print(f'indicator "{filename}" is missing. I assume failure.')
        return '0'
        # raise FileNotFoundError(f'File indicators/{filename}.{file_extension}.{approach} not found.')


def get_file_size(filename) -> int:
    if os.path.isfile(filename):
        return os.path.getsize(filename)
    else:
        return -1


def get_file_size_for_approach(approach, filename) -> int:
    if approach in ('reordering_unordering', 'reordering_vertices', 'reordering_hyperedges', 'reordering_vertices_hyperedges'):
        sum_fs = 0
        for appendix in ('-vertexSet', '-hyperedgeSet', '-edgeID', '-edgeSet'):
            fs = get_file_size(filename + appendix)
            if fs == -1:
                return -1
            sum_fs += fs
        return sum_fs
    else:
        return get_file_size(filename)


def combine_comp(DATA_SETS, APPROACHES, out_file):
    with open(out_file, "w") as f:
        writer = csv.writer(f, delimiter="\t")
        writer.writerow(['algorithm', 'dataset', 'successful', 'original_file_size', 'compressed_file_size', 's', 'h:m:s', 'max_rss', 'max_vms', 'max_uss', 'max_pss', 'io_in', 'io_out', 'mean_load', 'cpu_time'])
        for data_set in DATA_SETS:
            for approach in APPROACHES:
                bench = f'bench/{data_set}.{approach}.csv'
                indicator = get_success_indicator(f'indicators/{data_set}.{approach}')
                file_original_size = get_file_size(f'data/{data_set}')
                file_compressed_size = get_file_size_for_approach(approach, f'compressed/{approach}/{data_set}')
                if isfile(bench):
                    with open(bench, 'r') as g:
                        reader = csv.reader(g, delimiter="\t")
                        next(reader)  # Headers line
                        bench_data = next(reader)
                else:
                    bench_data = ['NA' for _ in range(10)]
                writer.writerow([approach, data_set, indicator, str(file_original_size), str(file_compressed_size)] + bench_data)


def combine_query(DATA_SETS, APPROACHES, QUERY_LENGTH_OF_DATA_SET, out_file):
    with (open(out_file, "w") as f):
        writer = csv.writer(f, delimiter="\t")
        writer.writerow(
            ['algorithm', 'dataset', 'type', 'query_count', 'successful', 's', 'h:m:s', 'max_rss', 'max_vms', 'max_uss', 'max_pss', 'io_in',
             'io_out', 'mean_load', 'cpu_time'])
        for data_set in DATA_SETS:
            query_count = defaultdict(lambda: 0)
            for k in range(1, QUERY_LENGTH_OF_DATA_SET[data_set]):
                query_count[k] = sum(1 for _ in open(f'queries/{data_set}_c_{k}'))

            for approach in APPROACHES:
                bench_exact = f'bench/{data_set}.{approach}.exact.csv'
                indicator_exact = get_success_indicator(f'indicators/{data_set}.{approach}.exact')
                if isfile(bench_exact):
                    with open(bench_exact, 'r') as g:
                        reader = csv.reader(g, delimiter="\t")
                        next(reader)  # Headers line
                        bench_data = next(reader)
                else:
                    bench_data = ['NA' for _ in range(10)]
                writer.writerow([approach, data_set, 'exact', '100', indicator_exact] + bench_data)

                for k in range(1, QUERY_LENGTH_OF_DATA_SET[data_set]):
                    bench_contains = f'bench/{data_set}.{approach}.contains.{k}.csv'
                    indicator_contains = get_success_indicator(f'indicators/{data_set}.{approach}.contains.{k}')
                    if isfile(bench_contains):
                        with open(bench_contains, 'r') as g:
                            reader = csv.reader(g, delimiter="\t")
                            next(reader)  # Headers line
                            bench_data = next(reader)
                    else:
                        bench_data = ['NA' for _ in range(10)]
                    writer.writerow([approach, data_set, str(k), str(query_count[k]), indicator_contains] + bench_data)


if __name__ == '__main__':
    comp_bench = 'results/comp_benchmark.csv'
    query_bench = 'results/query_benchmark.csv'
    APPROACHES = [
        'hypercsa',
        'ligra',
        'incidence_matrix',
        'plain_list',
        # 'itr',
        'reordering_unordering',
        'reordering_vertices',
        'reordering_hyperedges',
        'reordering_vertices_hyperedges',
        'incidence_list'
    ]
    APPROACHES_QUERIES = [
        'hypercsa',
        'incidence_matrix',
        'plain_list'
        # 'itr'
    ]
    APPROACHES_QUERIES_ONLY_1 = [
        'reordering_unordering',
        'reordering_vertices',
        'reordering_hyperedges',
        'reordering_vertices_hyperedges',
        'incidence_list'
    ]
    DATA_SETS = [
        'amazon-reviews.txt',
        'house-bills.txt',
        'house-committees.txt',
        'mathoverflow-answers.txt',
        'senate-committees.txt',
        'senate-bills.txt',
        'stackoverflow-answers.txt',
        'trivago-clicks.txt',
        'walmart-trips.txt',
        'com-orkut.txt',
        'com-friendster.txt',
    ]
    QUERY_LENGTH_OF_DATA_SET = {
        'amazon-reviews.txt': 15,
        'house-bills.txt': 15,
        'house-committees.txt': 15,
        'mathoverflow-answers.txt': 15,
        'senate-committees.txt': 15,
        'senate-bills.txt': 15,
        'stackoverflow-answers.txt': 150,
        'trivago-clicks.txt': 15,
        'walmart-trips.txt': 15,
        'com-orkut.txt': 20,
        'com-friendster.txt': 25,
    }
    combine_comp(DATA_SETS, APPROACHES, comp_bench)
    combine_query(DATA_SETS, APPROACHES_QUERIES + APPROACHES_QUERIES_ONLY_1, QUERY_LENGTH_OF_DATA_SET, query_bench)
