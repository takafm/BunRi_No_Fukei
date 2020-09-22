from icrawler.builtin import BingImageCrawler
import sys
import os

argv = sys.argv

if not os.path.isdir(argv[1]):
    os.makedirs(argv[1])


crawler = BingImageCrawler(storage = {"root_dir" : argv[1]})
crawler.crawl(keyword = argv[2], max_num = 200)