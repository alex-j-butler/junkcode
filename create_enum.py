import csv
import sys
import errno

if len(sys.argv) != 4:
	print "usage: {} <enum name> <input file> <output file>".format(sys.argv[0])
	sys.exit()

enum_name = sys.argv[1]
input_file_name = sys.argv[2]
output_file_name = sys.argv[3]


try:
	f = open(input_file_name, "r")
except (OSError, IOError) as e:
	if getattr(e, 'errno', 0) == erno.ENOENT:
		print "input file not found"
		sys.exit()

output_file = open(output_file_name, "w")

reader = csv.reader(f)

# c++ enum header
output_file.write("enum class {} : int {{\n".format(enum_name))

# write each entry in the csv
for r in reader:
	output_file.write("\t{} = {},\n".format(r[0], r[1]))

# write closing bracket & close output file.
output_file.write("}\n")
output_file.close()

# close input file.
f.close()
