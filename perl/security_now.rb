#!/usr/bin/env ruby

require 'rexml/document'

SOURCES = [

  { :file => 'sn.xml',
    :title_proc => lambda { |e| e.text.sub(/Episode /, '').sub(/ (\d):/, ' 0\1:') },
    :hacks => lambda { |pc|
      pc.title_sub('guid="security-now-special-edition-wmf-vulnerability-update"','Special Edition', '20SE')
      pc.title_sub('guid="security-now-episode-15vpn-pt-2"', ':V', ': V')
    } },

  { :file => 'twit.xml',
    :title_proc => lambda { |e| e.text },
    :hacks => lambda { |_| } },

  { :file => 'high.mp3.xml',
    :title_proc => lambda { |e| e.text.sub(/ - .*/, '').sub(/#00/, '').sub('Episode ', '') },
    :hacks => lambda { |pc|
      pc.get_cast('link="http://revision3.com/diggnation/2006-03-02"').remove
    } },

  { :file => 'episodes.rss',
    :title_proc => lambda { |e| e.text },
    :hacks => lambda { |pc|
      pc.doc.elements.each("rss/channel/item") do |item|
        season = ($1 if item.elements['enclosure/@url'].to_s.match(/season(\d+)/)) || '?'
        ep = ($1 if item.elements['enclosure/@url'].to_s.match(/ep(\d+)/)) || '?'
        item.elements['title'].text = format("LugRadio [%ix%02i] ", season, ep) + item.elements['title'].text 
      end
    } },

]

class PodPaster
  attr_accessor :doc

  def initialize(file, title_proc, hacks)
    @doc = REXML::Document.new File.open( file, "r" )
    @title_proc, @hacks = title_proc, hacks
  end

  def paste
    @hacks.call(self)
    @doc.elements.each("rss/channel/item/title") do |e|
      puts @title_proc.call(e)
    end
  end

  def get_cast(conditions)
    @doc.elements[%{rss/channel/item[#{conditions}]}]
  end

  def title_sub(conditions, *subargs)
    cast = get_cast(conditions)
    if cast
      title = cast.elements['title']
      title.text = title.text.sub(*subargs)
    end
  end
end

SOURCES.each do |source|
  PodPaster.new(source[:file], source[:title_proc], source[:hacks]).paste
end