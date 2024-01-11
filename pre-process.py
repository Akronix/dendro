import os
import csv
import re
import sys

def is_valid_time_format(value):
    return re.match(r'.* \d{2}:\d{2}:\d{2}', value) is not None


def add_time_to_second_column(input_file, output_file):
    with open(input_file, 'r', newline='') as infile:
        reader = csv.reader(infile, delimiter=';')

        with open(output_file, 'w', newline='') as outfile:
            writer = csv.writer(outfile, delimiter=';')

            for row in reader:
                if len(row) >= 2 and not is_valid_time_format(row[1]):
                    row[1] += " 00:00:00"
                writer.writerow(row)

    print(f"Updated CSV written to {output_file}")


def process_csv_files(input_directory, output_directory):
    # Create the output directory if it doesn't exist
    if not os.path.exists(output_directory):
        os.makedirs(output_directory)

    # Iterate through all files in the input directory
    for filename in os.listdir(input_directory):
        if filename.endswith('.csv'):
            input_file = os.path.join(input_directory, filename)
            output_file = os.path.join(output_directory, f"{filename}")

            add_time_to_second_column(input_file, output_file)


if __name__ == "__main__":
    # Check if two directories are provided as command line arguments
    if len(sys.argv) != 3:
        print("Usage: python pre-process.py <pre-data-directory> <output-data-directory>")
        sys.exit(1)

    DATA_DIR = sys.argv[1]
    OUTPUT_DATA_DIR = sys.argv[2]

    # Check if the provided paths are directories
    if not os.path.isdir(DATA_DIR):
        print(f"${DATA_DIR} doesn't exist or is not a directory!")
        sys.exit(1)

    process_csv_files(DATA_DIR, OUTPUT_DATA_DIR)
