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
        print(f'indicator "{filename}" is missing. I assume failure.')
        return '0'
        # raise FileNotFoundError(f'File indicators/{filename}.{file_extension}.{approach} not found.')


def get_file_size(filename) -> int:
    if os.path.isfile(filename):
        return os.path.getsize(filename)
    else:
        return -1


def combine_comp(DATA_SETS, APPROACHES, out_file):
    with open(out_file, "w") as f:
        writer = csv.writer(f, delimiter="\t")
        writer.writerow(['algorithm', 'dataset', 'successful', 'original_file_size', 'compressed_file_size', 's', 'h:m:s', 'max_rss', 'max_vms', 'max_uss', 'max_pss', 'io_in', 'io_out', 'mean_load', 'cpu_time'])
        for data_set in DATA_SETS:
            for approach in APPROACHES:
                bench = f'bench/{data_set}.{approach}.csv'
                indicator = get_success_indicator(f'indicators/{data_set}.{approach}')
                file_original_size = get_file_size(f'data/{data_set}')
                file_compressed_size = get_file_size(f'compressed/{approach}/{data_set}')
                if not isfile(bench):
                    raise FileNotFoundError(f'Benchmark file "{bench}" does not exist.')
                with open(bench, 'r') as g:
                    reader = csv.reader(g, delimiter="\t")
                    next(reader)  # Headers line
                    writer.writerow([approach, data_set, indicator, str(file_original_size), str(file_compressed_size)] + next(reader))


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
                if not isfile(bench_exact):
                    raise FileNotFoundError(f'Benchmark file "{bench_exact}" does not exist.')
                with open(bench_exact, 'r') as g:
                    reader = csv.reader(g, delimiter="\t")
                    next(reader)  # Headers line
                    writer.writerow([approach, data_set, 'exact', '100', indicator_exact] + next(reader))

                for k in range(1, QUERY_LENGTH_OF_DATA_SET[data_set]):
                    bench_contains = f'bench/{data_set}.{approach}.contains.{k}.csv'
                    indicator_contains = get_success_indicator(f'indicators/{data_set}.{approach}.contains.{k}')
                    if not isfile(bench_contains):
                        raise FileNotFoundError(f'Benchmark file "{bench_contains}" does not exist.')
                    with open(bench_contains, 'r') as g:
                        reader = csv.reader(g, delimiter="\t")
                        next(reader)  # Headers line
                        writer.writerow([approach, data_set, str(k), str(query_count[k]), indicator_contains] + next(reader))
