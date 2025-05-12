import csv
import argparse
from collections import defaultdict
from os.path import exists


def normalize_and_convert(input_file, output_file, stats_file, split_char='\t'):
    # Read all lines and flatten the numbers
    with open(input_file, 'r') as f:
        lines = [line.strip().split(split_char) for line in f if line.strip()]
        all_numbers = {int(num) for line in lines for num in line}

    # Create mapping from original numbers to 0-based continuous numbers
    number_mapping = {num: idx for idx, num in enumerate(all_numbers)}

    node_degrees = defaultdict(lambda: 0)

    # Apply mapping and write to CSV
    with open(output_file, 'w', newline='') as f:
        writer = csv.writer(f)
        for line in lines:
            new_line = [number_mapping[int(num)] for num in line]
            writer.writerow(new_line)
            for num in line:
                node_degrees[num] += 1

    stats_exists = exists(stats_file)
    with open(stats_file, 'a') as f:
        writer = csv.writer(f)
        if not stats_exists:
            writer.writerow(['filename', '|V|', '|E|', 'M', 'max_node_degree'])
        writer.writerow([output_file, len(node_degrees), len(lines), sum(node_degrees.values()), max(node_degrees.values())])


def main():
    parser = argparse.ArgumentParser(
        description="Convert a tab-separated file of natural numbers into a CSV with 0-based contiguous values."
    )
    parser.add_argument("input", help="Path to the input file (tab-separated)")
    parser.add_argument("output", help="Path to the output CSV file")
    parser.add_argument("split_char", help="Char to split numbers in input file", default='\t')

    args = parser.parse_args()
    normalize_and_convert(args.input, args.output, './../results/stats.csv', args.split_char)


if __name__ == "__main__":
    main()
