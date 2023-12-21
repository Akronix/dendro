import os
import csv
import re

DATA_DIR = 'pre-dataD-dic'
OUTPUT_DATA_DIR = 'dataD-dic'


def is_valid_time_format(value):
    return re.match(r'.* \d{2}:\d{2}:\d{2}', value) is not None

def add_time_to_second_column(input_file, output_file):
    with open(input_file, 'r', newline='') as infile:
        reader = csv.reader(infile, delimiter=';')
        header = next(reader)

        with open(output_file, 'w', newline='') as outfile:
            writer = csv.writer(outfile, delimiter=';')
            writer.writerow(header)

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

process_csv_files(DATA_DIR, OUTPUT_DATA_DIR)
