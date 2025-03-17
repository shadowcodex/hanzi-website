"""
This file is used to test flash card generations from AI 
to make sure it doesn't forget or miss any items 
from the original file.
"""

def read_first_column(file_path):
    """Reads the first column (tab-separated) from a file into a set."""
    with open(file_path, 'r', encoding='utf-8') as file:
        return {line.split('\t')[0].strip() for line in file if line.strip()}

# Read both files into sets
file1_path = 'file1.txt'  # Change to your file path
file2_path = 'file2.txt'  # Change to your file path

set1 = read_first_column(file1_path)
set2 = read_first_column(file2_path)

# Find unique items
unique_to_file1 = set1 - set2
unique_to_file2 = set2 - set1

# Print results
print("Items unique to file1:")
print('\n'.join(unique_to_file1))

print("\nItems unique to file2:")
print('\n'.join(unique_to_file2))