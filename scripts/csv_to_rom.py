import csv

# Input and output file paths
input_csv = 'train.csv'  # Change this to your CSV filename
output_txt = 'X.txt'
test_row_num = 1 # Change this to the desired row number of the training data you want to process (row 1 is the first entry after the header)


# Read the CSV and extract first row
with open(input_csv, 'r') as csvfile:
    reader = csv.reader(csvfile)
    for i in range(test_row_num):
        next(reader)
    first_row = next(reader)  # Get the first row

# Process the data (skip first column, process remaining 784 columns)
# with open(output_txt, 'w') as outfile:
#     for i, value in enumerate(first_row[1:]):  # Skip first column with [1:]
#         # Convert to integer and right-shift by 2
#         data = int(value)
#         shifted_data = data >> 2
#         shifted_data = shifted_data * 1040

#         new_data = float(shifted_data) / 65536.0
#         new_data = round(new_data, 5)
#         # Write the assignment line
#         line = f"{new_data}\n"
#         outfile.write(line)
with open(output_txt, 'w') as outfile:
    outfile.write("`timescale 1ns / 1ps\nmodule test_image(\n\toutput logic [5:0] pixels [0:783]\n\t);\n")
    for i, value in enumerate(first_row[1:]):  # Skip first column with [1:]
        # Convert to integer and right-shift by 2
        data = int(value)
        shifted_data = data >> 2
        
        # Write the assignment line
        line = f"assign pixels[{i}] = 6'd{shifted_data};\n"
        outfile.write(line)
    outfile.write("\nendmodule")

print(f"Successfully processed {len(first_row) - 1} pixels")
print(f"Output written to {output_txt}")