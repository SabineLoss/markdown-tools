# -*- coding: utf-8 -*-

module Parsing

  ##
  # Wrapper around a single line to ease matching of special elements that
  # indicate a new parser state or action
  class MarkdownLine

    ## Create a new class wrapped around a single line
    # @param [String] line line to wrap around
    def initialize(line)
      @line = line
    end

    ##
    # Return the wrapped string
    # @return [String] the wrapped string
    def string
      @line
    end

    ##
    # Return the length in character of the line
    # @return [Fixnum] length of the line
    def length
      @line.length
    end

    ##
    # Cut away the first characters
    # @param [Fixnum] from number of characters to be removed
    def substr!(from)
      @line = @line[from..-1]
    end

    ##
    # Remove the code prefix (i.e. four blanks) from the line
    def trim_code_prefix!
      if @line.length > 4
        substr!(4)
      end
    end

    ## HTML comment
    def comment; @line.strip[/<!--(.*)-->/, 1]; end

    ## HTML comment
    def comment?; !!comment; end

    ## Special Space comment
    def space_comment
      /<!-- Spacing: ([0-9]*) -->/ =~ @line.strip
      $1
    end

    ## Special Space comment
    def space_comment?; !!space_comment; end

    ## Vertical space
    def vertical_space?; /^<br>$/ === @line.strip; end

    ## Source code prefixed by four blanks
    def source?; /^ {4}[^*\-](.*)/ === @line; end

    ## Row of a table
    def table_row?; /^\|(.*)\| *$/ === @line; end

    ## A quote
    def quote?; /^> (.*)$/ === @line; end

    # The source of a quote
    def quote_source?; /^>> (.*)$/ === @line; end

    ## A box for important content
    def important?; /^>! (.*)$/ === @line; end

    ## A box for a question
    def question?; /^>\? (.*)$/ === @line; end

    ## A generic box
    def box?; /^>: (.*)$/ === @line; end

    ## An empty line
    def empty?; /^$/ === @line.strip; end

    ## A normal line
    def normal?; /^[^ ].*$/ === @line; end

    ## Just text
    def text?; /^[=\-A-Za-z0-9_ÄÖÜäöüß`*"].*$/ === @line; end

    ## Multiple choice
    def multiple_choice
      if /^\[([ Xx*])\](\.?) (.*)/ =~ @line
        [$1 != ' ', $2 == '.', $3]
      end
    end

    ## Multiple choice
    def multiple_choice?; !!multiple_choice; end

    ## HTML code
    def html?; /^<.*$/ === @line; end

    ## Image
    def image?; /!\[.*\]\(.+\)/ === @line; end

    ## Beginning of a fenced code block
    def fenced_code_start; @line.strip[/^```([a-zA-Z0-9]*)(\[[1-9]\])?({.*?})?/, 1]; end

    ## Beginning of a fenced code block
    def fenced_code_start?; !!fenced_code_start; end

    ## Beginning of a fenced code block with order mark
    def fenced_code_order; @line.strip[/^```[a-zA-Z0-9]*\[([1-9])\]({.*?})?/, 1]; end

    ## Beginning of a fenced code block with order mark
    def fenced_code_order?; !!fenced_code_order; end

    ## Caption annotated for a fenced code block
    def fenced_code_caption; @line.strip[/^```([a-zA-Z0-9]*)(\[[1-9]\])?{(.*?)}/, 3]; end

    ## End of a fenced code block
    def fenced_code_end?; /^```$/ === @line.strip; end

    ## Slide to be skipped
    def skipped_slide?; /.*--skip--.*/ === @line.strip; end

    ## Start of a script
    def script_start?; /^<script>$/ === @line.strip; end

    ## End of a script
    def script_end?; /^<\/script>$/ === @line.strip; end

    ## Start of an equation
    def equation_start?; /^\\\[$/ === @line.strip; end

    ## End of an equation
    def equation_end?; /^\\\]$/ === @line.strip; end

    ## Separator of slide and comment
    def separator?; /^---.*/ === @line; end

    ## Separator of table headers
    def table_separator?; /^\|[-]{2,}\|.*/ === @line.strip; end

    ## unordered list, level 1
    def ul1; @line[/^ {2}[*\-] (.*)/, 1]; end

    ## unordered list, level 1
    def ul1?; !!ul1; end

    ## unordered list, level 2
    def ul2; @line[/^ {4}[*\-] (.*)/, 1]; end

    ## unordered list, level 2
    def ul2?; !!ul2; end

    ## unordered list, level 3
    def ul3; @line[/^ {6}[*\-] (.*)/, 1]; end

    ## unordered list, level 3
    def ul3?; !!ul3; end

    ## ordered list, level 1
    def ol1; @line[/^ {2}[0-9]+\. (.*)/, 1]; end

    ## ordered list, level 1
    def ol1?; !!ol1; end

    ## ordered list, level 1 with number
    def ol1_number; @line[/^ {2}([0-9]+)\..*/, 1]; end

    ## ordered list, level 2
    def ol2; @line[/^ {4}[0-9]+\. (.*)/, 1]; end

    ## ordered list, level 2
    def ol2?; !!ol2; end

    ## ordered list, level 2 with number
    def ol2_number; @line[/^ {4}([0-9]+)\..*/, 1]; end

    ## ordered list, level 3
    def ol3; @line[/^ {6}[1-9]+\. (.*)/, 1]; end

    ## ordered list, level 3
    def ol3?; !!ol3; end

    ## ordered list, level 2 with number
    def ol3_number; @line[/^ {6}([0-9]+)\. .*/, 1]; end

    ## Title of a slide
    def slide_title
      title = @line[/^ *## (.*)/, 1]
      title.nil? ? nil : title.sub(/##/, '').strip
    end

    ## Title of a slide
    def slide_title?; !!slide_title; end

    ## Title of a chapter
    def chapter_title;
      title = @line[/^ *# (.*)/, 1]
      title.nil? ? nil : title.sub(/#/, '').strip
    end

    ## Title of a chapter
    def chapter_title?; !!chapter_title; end

    ## Beginning of UML block
    def uml_start?; /^@startuml.*$/ === @line.strip; end

    ## Beginning of UML block
    def uml_start
      if /^@startuml\[(.*?)\]\[(.*?)\]$/ === @line
        return $1, $2
      elsif /^@startuml\[(.*)\]$/ === @line
        return $1, $1
      end
    end

    ## End of UML block
    def uml_end?; /^@enduml$/ === @line.strip; end

    ## Include of sources
    def code_include
      if /^!INCLUDESRC\[([0-9]*?)\] "(.*?)" (.*?)$/ =~ @line.strip
        [$2, $1.to_i, $3]
      elsif /^!INCLUDESRC\[([0-9]*?)\] "(.*?)"$/ =~ @line.strip
        [$2, $1.to_i, '']
      elsif /^!INCLUDESRC "(.*?)" (.*?)$/ =~ @line.strip
        [$1, 0, $2]
      elsif /^!INCLUDESRC "(.*?)"$/ =~ @line.strip
        [$1, 0, '']
      else
        nil
      end
    end

    ## Include of sources
    def code_include?; !!code_include; end

    ## Forwarding of String's sub method
    def sub(pattern, replacement)
      @line.sub(pattern, replacement)
    end

    ## String representation
    def to_s; @line; end
  end
end
