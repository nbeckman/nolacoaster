#! /usr/bin/python
# Keep Photo Dump is meant to get your photos out of Google Keep pages
# as exported from Google Takeout.
#
# The photos are base64 encoded.
# This script goes through a given html file and finds all the base64
# encoded image tags and writes them to disk as JPG. It should work just
# as well for extracting photos out of any web page with base64 encoded images.
# May use lots of RAM!
#
# Usage:
# ./keep_photo_dump.py my_keep_file.html my_keep_file_2.html ...
#
import argparse
import base64
import os

from HTMLParser import HTMLParser

# Writes a base64 encoded string to a file, as binary.
#
# Args:
#   base64_img: An image encoded as base 64.
#   filename: The name of the file to write to.
def decode_and_write_file(base64_img, filename):
  decoded_img = base64.b64decode(base64_img)
  with open(filename, 'wb') as file:
    file.write(decoded_img)


# The string that corresponds to a base64 encoded jpg.
base64_jpg_prefix = "data:image/jpeg;base64"


# Is the given stirng a base64 encoded image from the <img src=""> tag
# and attribute?
def is_base64_encoded_src(src):
  # I'm assuming there can be other image types that I might want to
  # decode here. But for now, we only recognize this one string.
  return src.startswith(base64_jpg_prefix)


# For an encoded image src attribute, returns the encoding type and
# the data as a part.
def encoding_data_pair(src):
  partition = src.partition(',')
  return (partition[0], partition[2])


# Returns the value of the src attribute or None.
# Args:
#   attrs: A list of (attribute name, value) pairs.
# Returns:
#   The value corresponding to 'src' or None if src is not in the list.
def find_source_attribute(attrs):
  for (attr_name, attr_value) in attrs:
    if attr_name == "src":
      return attr_value
  return None


# This class is an HTML parser that looks for <img> tags containing
# base64 images (i.e., those whose source starts with
# "data:image/jpeg;base64,"). When the feed() method completes on an
# HTML string, the encoding_pairs() method will return those images.
class Base64ImgGrabber(HTMLParser):
  def __init__(self):
    HTMLParser.__init__(self)
    self.__encoding_pairs = []

  def handle_starttag(self, tag, attrs):
    if tag == "img":
      src_value = find_source_attribute(attrs)
      if src_value and is_base64_encoded_src(src_value):
        encoding_pair = encoding_data_pair(src_value)
        self.__encoding_pairs.append(encoding_pair)

  # Returns the images and their encodings seen during parsing.
  #
  # Returns:
  #   A list of pairs. The key in each pair is the encoding type. The value
  #   is the data.
  def encoding_pairs(self):
    return self.__encoding_pairs


# From a path, returns the file name without extension or path.
# "/a/b/c.txt" --> "c"
def file_base(path):
  base = os.path.basename(path)
  return os.path.splitext(base)[0]

# Parses the html file, dumps all its images to disk.
#
# Args:
#   html_file: The html file to parse.
#   file_suffix: When writing image files to disk, use this suffix.
def parse_html_dump_images(html_file, file_suffix):
  html_parser = Base64ImgGrabber()
  html_parser.feed(html_file.read())
  file_index = 1
  for (encoding, data) in html_parser.encoding_pairs():
    filename = file_base(html_file.name) + str(file_index) + file_suffix
    decode_and_write_file(data, filename)
    file_index = file_index + 1

# The "main" function.
#
# Set up flags.
parser = argparse.ArgumentParser(description="""
In a Google Keep HTML file, finds all the images encoded as base64 and writes
them to disk as JPG images.
""")
parser.add_argument('keep_html_file', metavar='keep_html_file',
                    type=file,
                    help='the input html file path')
args = parser.parse_args()
# Parse html and dump.
parse_html_dump_images(args.keep_html_file, ".jpg")
