import csv, re, os
from os.path import isfile


def parse_filename():
    pass


def get_success_indicator(filename):
    if 'partdna' in filename:
        return '1'
    if os.path.isfile(filename):
        with open(filename, 'r') as f:
            for line in f:
                return line[0]
    else:
        print(f'indicator "{filename}" is missing. I assume failure.')
        return '0'
        # raise FileNotFoundError(f'File indicators/{filename}.{file_extension}.{approach} not found.')

def combine_comp(FILES, DATA_SETS, APPROACHES, out_file):
    with open(out_file, "w") as f:
        writer = csv.writer(f, delimiter="\t")
        writer.writerow(['algorithm', 'dataset', 'successful', 's', 'h:m:s', 'max_rss', 'max_vms', 'max_uss', 'max_pss', 'io_in', 'io_out', 'mean_load', 'cpu_time'])
        for data_set in DATA_SETS:
            for approach in APPROACHES:
                bench = f'bench/{data_set}.{approach}.csv'
                indicator = get_success_indicator(f'indicators/{data_set}.{approach}')
                file_original_size = os.path.getsize('')
                file_compressed_size = os.path.getsize('')
                if not isfile(bench):
                    raise FileNotFoundError(f'Benchmark file "{bench}" does not exist.')
                with open(bench, 'r') as g:
                    reader = csv.reader(g, delimiter="\t")
                    next(reader)  # Headers line
                    writer.writerow([approach, data_set, indicator] + next(reader))

def combine_query(FILES, DATA_SETS, APPROACHES, out_file):
    with open(out_file, "w") as f:
        writer = csv.writer(f, delimiter="\t")
        writer.writerow(
            ['algorithm', 'dataset', 'successful', 's', 'h:m:s', 'max_rss', 'max_vms', 'max_uss', 'max_pss', 'io_in',
             'io_out', 'mean_load', 'cpu_time'])
        for data_set in DATA_SETS:
            for approach in APPROACHES:
                bench = f'bench/{data_set}.{approach}.csv'
                indicator = get_success_indicator(f'indicators/{data_set}.{approach}')
                if not isfile(bench):
                    raise FileNotFoundError(f'Benchmark file "{bench}" does not exist.')
                with open(bench, 'r') as g:
                    reader = csv.reader(g, delimiter="\t")
                    next(reader)  # Headers line
                    writer.writerow([approach, data_set, indicator] + next(reader))
