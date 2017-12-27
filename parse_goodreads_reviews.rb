#!/usr/bin/env ruby

re = Regexp.new('^"*(?<title>[\w\s:\.\(\)#\',\?-]+)"*,(?<author>[\w\s:\.\(\)#\',\?-]+),\d{4}\/\d{2}\/\d{2},(?<review>["\w\s:_\.,\/\(\)\!\;\'-]+)*')

f = File.readlines('goodreads_reviews_2017.csv')
f.each do |line|
  line.chomp!
  if matches = re.match(line)
    puts "\n* **#{matches['title']}** by *#{matches['author']}*"
    puts # Blank line
    # Iterate over the words and build up lines less than 80 characters long.
    words = matches['review'].split(/\s/)
    words[0].gsub!(/^"/, '') # Strip leading quotes
    words[-1].gsub!(/"$/, '') # Strip trailing quotes
    newline = []
    while words.length > 0
      newline_str = newline.join(' ')
      if newline_str.length <= 75
        # If adding the word keeps us under limit, add it.
        if (newline_str.length + words[0].length) <= 75
          newline << words.shift # Pull the word out of the array
          # If we've reached the end of the word count, print the new line.
          if words.length == 0
            newline_str = newline.join(' ')
            puts "    #{newline_str}"
          end
        else
          # If we'd be over the limit, print the new line.
          newline_str = newline.join(' ')
          puts "    #{newline_str}"
          newline = []
          newline << words.shift # Pull the word out of the array
        end
      else
        # We're over the limit. Print the new line.
        newline_str = newline.join(' ')
        puts "     #{newline_str}"
        newline = []
        newline << words.shift # Pull the word out of the array
      end
    end
  else
    #puts "NO MATCH: #{line}" # Help find unmatched lines.
  end
end

