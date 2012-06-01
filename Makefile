# This file was originally authored by Andrew Harvey <andrew.harvey4@gmail.com>

# To the extent possible under law, the person who associated CC0
# with this work has waived all copyright and related or neighboring
# rights to this work.
# http://creativecommons.org/publicdomain/zero/1.0/

# README
# This script is still a work in progress and still experimental. Don't
# just run each target in here without understanding what it does.

all : 

00_clean :
	rm -rf 0* 1*

# do a wildcard search for all items matching nla.map*
01_search :
	mkdir -p 01-search_results
	curl 'http://catalogue.nla.gov.au/Search/Home?lookfor=pi:nla.map*&type=all&sort=sort_title_asc&view=rss&page=[1-200]' -o 01-search_results/nla.map-#1.xml

# search through the search results and extract record urls
02_records :
	xml_grep --text_only link 01-search_results/nla.map-*.xml | grep 'Record' | sort | uniq > 02-record-urls.txt

# for each record download the bibtex metadata
03_bibtex :
	cat 02-record-urls.txt | sed "s/$$/\/Export\?style=bibtex/" > 03-record-bibtex-urls.txt
	mkdir -p 04-record-bibtex
	wget --directory-prefix=04-record-bibtex -i 03-record-bibtex-urls.txt

# from the bibtex find the nla.map reference IDs
04_nla_map_refs :
	cat 04-record-bibtex/* | grep '^url' | grep -o '{[^}]*}' | sed 's/{\s*//' | sed 's/\s*}//' | sed 's/http\:\/\/nla.gov.au\///g' | sed "s/\s+/ /g" | tr " " "\n" | sort | uniq > 05-bibtex-url-refs.txt
	cat 05-bibtex-url-refs.txt | grep -v 'nla.map' > 06-bibtex-url-non-nla-map.txt
	cat 05-bibtex-url-refs.txt | grep 'nla.map' > 07-nla-map-refs.txt

# grab the moreinfo pages for the known map ids
05_nla_map_moreinfo :
	cat 07-nla-map-refs.txt | sed 's/^/http\:\/\/www.nla.gov.au\/apps\/cdview\//' | sed 's/\&mode=moreinfo//' > 08-nla_map_moreinfo-urls.txt
	mkdir -p 09-map-more-info
	wget --no-clobber --directory-prefix=09-map-more-info -i 08-nla_map_moreinfo-urls.txt 2> 09-wget-errors.txt
	cat 09-wget-errors.txt | grep -v 'already there' | uniq | grep -o 'http://www\.nla.*' > 09-wget-possible-404.txt

# generate urls for the map landing page (which can have just a single map or many parts)
06_nla_map_landing :
	cat 07-nla-map-refs.txt | sed 's/^/http\:\/\/www.nla.gov.au\/apps\/cdview\/?pi=/' > 10-nla_map_landing-urls.txt
	mkdir -p 11-map-landing
	wget --no-clobber --directory-prefix=11-map-landing -i 10-nla_map_landing-urls.txt 2> 10-wget-errors.txt
	cat 10-wget-errors.txt | grep -v 'already there' | uniq | grep -o 'http://www\.nla.*' > 10-wget-possible-404.txt

# determine if the landing page from above is for map with just one part or multiple parts
07_nla_map_split_parts :
	grep --files-without-match --extended-regexp '<!-- Select (part|map) -->' 11-map-landing/* | grep -o 'nla\.map.*' > 12-landing-pages-one-part.txt
	grep --files-with-matches --extended-regexp '<!-- Select (part|map) -->' 11-map-landing/* | grep -o 'nla\.map.*' > 13-landing-pages-many-parts.txt
	
	mkdir -p 14-map-landing-single 15-map-landing-many
	# for just one map part pages add -sd and then look for the .sid file
	./split-11.sh

# grab the .sid urls for all images by fist grabbing -sd pages
08_nla_map_sid_url_pages :
	cat 15-map-landing-many/* | grep -o 'http://www.nla.gov.au/apps/cdview?[^"]*' | sort | uniq | sed "s/-[ve]$$/-sd/" > 16-sd-links.txt
	cat 12-landing-pages-one-part.txt | sed 's/^/http\:\/\/www.nla.gov.au\/apps\/cdview?pi=/' | sed "s/$$/-sd/" >> 16-sd-links.txt
	mkdir -p 17-sd-pages
	# set a wait time of 1 second because,
	#   server will close the connection after each request so by waiting between requests we aren't consuming server resources
	#   we are a robot and hence don't mind if our requests take a while (compared to a human users who deserves 1st preference) so we will try to ease the load
	wget --no-clobber --directory-prefix=17-sd-pages --wait=1 -i 16-sd-links.txt 2> 16-wget-errors.txt
	cat 16-wget-errors.txt | grep -v 'already there' | uniq | grep -o 'http://www\.nla.*' > 16-wget-possible-404.txt

# generate a list of all the .sid URLs
09_nla_map_sid_urls :
	cat 17-sd-pages/* | grep -o 'src=".*lizardtech[^"]*' | grep -o '&img=[^&]*' | sed 's/^&img=//' | sed "s/^/http\:\/\/www.nla.gov.au/" > 18-sid-filenames.txt

# download those .sid files
10_nla_map_sids_download :
	mkdir -p 19-sids
	wget --no-clobber -directory-prefix=19-sids -i 18-sid-filenames.txt
