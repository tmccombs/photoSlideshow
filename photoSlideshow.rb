#!/usr/bin/ruby

require 'optparse'
require 'tmpdir'

Dimensions = Struct.new(:width, :height) do 
    def to_s
        return "#{width}x#{height}"
    end
end

def parse_dimensions(dim_str)
    /(\d+)x(\d+)/ =~ dim_str
    return Dimensions.new($1.to_i, $2.to_i)
end


dimensions = nil
outputFile = nil
rate = "0.2"

option_parser = OptionParser.new do |opts|
    opts.banner = "Usage photoSlideshow.rb [options] [input]"

    opts.on("-d","--dim DIM", "Output dimensions in the format {w}x{h}") do |dims|
        dimensions = parse_dimensions(dims)
    end

    opts.on("-o", "--output OUTPUT", "Output file") do |output|
        outputFile = output
    end

    opts.on("-r","--rate RATE", "Input frame rate (images/second)") do |r|
        rate = r
    end
end

option_parser.parse!

if not (dimensions and outputFile)
    puts option_parser
    exit 1
end

puts "Dimensions: #{dimensions}\nOutput: #{outputFile}"
    

Dir.mktmpdir do |tdir|
    i = 0
    ARGF.each do |line|
        out = "#{tdir}/image%06d.jpg" % [i]
        #todo: parallelize this by not waiting for the individual processes to finish
        line.chomp!
        `convert #{line} -resize #{dimensions} -background black -gravity center -extent #{dimensions} #{out}`
        i += 1
    end
    `ffmpeg -r #{rate} -i #{tdir}/image%06d.jpg -c:v libx264 -r 30 #{outputFile}`
end

