import os
from PIL import Image

# Ask user for the main folder path
elements_dir = input("Enter the path to the folder containing subdirectories of images: ").strip().strip("'").strip('"')
output_file = "image_dimensions.txt"

# Image extensions to check
image_extensions = (".png", ".jpg", ".jpeg", ".bmp", ".gif")

results = []

if not os.path.isdir(elements_dir):
	print("❌ That path is not a valid directory.")
else:
	for folder_name in sorted(os.listdir(elements_dir)):
		folder_path = os.path.join(elements_dir, folder_name)
		if os.path.isdir(folder_path):
			# Get list of image files
			image_files = [f for f in os.listdir(folder_path) if f.lower().endswith(image_extensions)]
			if image_files:
				first_image_path = os.path.join(folder_path, image_files[0])
				with Image.open(first_image_path) as img:
					width, height = img.size
					results.append(f"{folder_name}: {width} x {height}")

	# Write results to a text file
	with open(output_file, "w") as f:
		f.write("\n".join(results))

	print(f"✅ Image dimensions written to {output_file}")