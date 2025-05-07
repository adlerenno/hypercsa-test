import csv
import argparse

def normalize_and_convert(input_file, output_file):
    # Read all lines and flatten the numbers
    with open(input_file, 'r') as f:
        lines = [line.strip().split('\t') for line in f if line.strip()]
        all_numbers = {int(num) for line in lines for num in line}

    # Create mapping from original numbers to 0-based continuous numbers
    number_mapping = {num: idx for idx, num in enumerate(all_numbers)}

    # Apply mapping and write to CSV
    with open(output_file, 'w', newline='') as f:
        writer = csv.writer(f)
        for line in lines:
            new_line = [number_mapping[int(num)] for num in line]
            writer.writerow(new_line)

def main():
    parser = argparse.ArgumentParser(
        description="Convert a tab-separated file of natural numbers into a CSV with 0-based contiguous values."
    )
    parser.add_argument("input", help="Path to the input file (tab-separated)")
    parser.add_argument("output", help="Path to the output CSV file")

    args = parser.parse_args()
    normalize_and_convert(args.input, args.output)

if __name__ == "__main__":
    main()
