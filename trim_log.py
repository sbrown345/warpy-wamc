import sys

def trim_log_file(input_file, output_file, start_string):
    with open(input_file, 'r') as infile, open(output_file, 'w') as outfile:
        found_start = False
        for line in infile:
            if not found_start and start_string in line:
                found_start = True
            if found_start:
                outfile.write(line)

def main():
    if len(sys.argv) != 4:
        print("Usage: python script.py <log1.log> <log2.log> <start_string>")
        sys.exit(1)

    log1 = sys.argv[1]
    log2 = sys.argv[2]
    start_string = sys.argv[3]

    trim_log_file(log1, 'trimmed_' + log1, start_string)
    trim_log_file(log2, 'trimmed_' + log2, start_string)

    print(f"Trimmed logs saved as 'trimmed_{log1}' and 'trimmed_{log2}'")

if __name__ == "__main__":
    main()