# -*- coding: utf-8 -*-

module Rendering

  ##
  # Base class for all renderer used by the markdown compiler
  class Renderer

    ##
    # Class representing the parts of a line
    class LinePart

      attr_accessor :code, :content

      ##
      # Create a new instance
      # @param [String] content content of the part
      # @param [Boolean] code indicates whether we have code or normal text
      def initialize(content, code)
        @code, @content = code, content
      end

      ##
      # @return [String] representation
      def to_s
        @content
      end
    end

    ##
    # Initialize the renderer
    # @param [IO] io target of output operations
    # @param [String] language the default language for code snippets
    def initialize(io, language)
      @io, @language = io, language
    end

    ##
    # Split the line into tokens. One token for each code / non-code fragment
    # is created
    # @param [String] input the input
    # @return [Renderer::LinePart[]] the input tokenized
    def tokenize_line(input)
      parts = [ ]
      remainder = input

      while /`(.+?)`/ =~ remainder
        parts << LinePart.new($`, false)
        parts << LinePart.new($1, true)
        remainder = $'
      end

      parts << LinePart.new(remainder, false)

      parts
    end

    ##
    # Return a newline character
    # @return [String] newline character
    def nl
      "\n"
    end

    ##
    # Render the table of contents
    # @param [Domain::TOC] toc to be rendered
    def render_toc(toc)
      @toc = toc
      toc_start
      toc.each { |e| toc_entry(e.name, e.id) }
      toc_end
    end

    ##
    # Equation
    # @param [String] contents LaTeX source of equation
    def equation(contents); end

    ##
    # Start of an ordered list
    # @param [Fixnum] number start number of list
    def ol_start(number = 1); end

    ##
    # End of ordered list
    def ol_end; end

    ##
    # Item of an ordered list
    # @param [String] content content
    def ol_item(content); end

    ##
    # Indent output
    # @param [Fixnum] level the indentation
    def indent(level)
      [0..level].each { @io << ' '}
    end

    ##
    # Start of an unordered list
    def ul_start; end

    ##
    # End of an unordered list
    def ul_end; end

    ##
    # Item of an unordered list
    # @param [String] content content
    def ul_item(content); end

    ##
    # Quote
    # @param [String] content the content
    def quote(content); end

    ##
    # Script
    # @param [String] content the script to be included
    def script(content); end

    ##
    # Start of a code fragment
    # @param [String] language language of the code fragment
    def code_start(language); end

    ##
    # End of a code fragment
    def code_end; end

    ##
    # Output code
    # @param [String] content the code content
    def code(content); end

    ##
    # Start of a table
    def table_start(num_columns); end

    ##
    # Header of table
    # @param [Array] headers the headers
    def table_header(headers); end

    ##
    # Row of the table
    # @param [Array] row row of the table
    def table_row(row); end

    ##
    # End of the table
    def table_end; end

    ##
    # Simple text
    # @param [String] content the text
    def text(content); end

    ##
    # Heading of a given level
    # @param [Fixnum] level heading level
    # @param [String] title title of the heading
    def heading(level, title); end

    ##
    # Start of the TOC
    def toc_start; end

    ##
    # Start of sub entries in toc
    def toc_sub_entries_start; end

    ##
    # End of sub entries
    def toc_sub_entries_end; end

    ##
    # Output a toc sub entry
    # @param [String] name name of the entry
    # @param [String] anchor anchor of the entry
    def toc_sub_entry(name, anchor); end

    ##
    # Output a toc entry
    # @param [String] name name of the entry
    # @param [String] anchor anchor of the entry
    def toc_entry(name, anchor); end

    ##
    # End of toc
    def toc_end; end

    ##
    # Start of index file
    # @param [String] title1 title 1 of lecture
    # @param [String] title2 title 2 of lecture
    # @param [String] copyright copyright info
    # @param [String] description description
    def index_start(title1, title2, copyright, description); end

    ##
    # End of index
    def index_end; end

    ##
    # Single index entry
    # @param [Fixnum] chapter_number number of chapter
    # @param [String] chapter_name name of chapter
    # @param [String] slide_file file containing the slides
    # @param [String] plain_file file containing the plain version
    def index_entry(chapter_number, chapter_name, slide_file, plain_file); end

    ##
    # HTML output
    # @param [String] content html
    def html(content); end

    ##
    # Render a button
    # @param [String] line_id internal ID of the line
    def button(line_id); end

    ##
    # Start a chapter
    # @param [String] title the title of the chapter
    # @param [String] number the number of the chapter
    # @param [String] id the unique id of the chapter (for references)
    def chapter_start(title, number, id); end

    ## End of a chapter
    def chapter_end; end

    ##
    # Render a button with log area
    # @param [String] line_id internal ID of the line
    def button_with_log(line_id); end

    ##
    # Render a button with output
    # @param [String] line_id internal ID of the line
    def button_with_log_pre(line_id); end

    ##
    # Link to previous slide (for active HTML)
    # @param [String] line_id internal ID of the line
    def link_previous(line_id); end

    ##
    # Link to previous slide (for active CSS)
    # @param [String] line_id internal ID of the line
    # @param [String] fragment HTML fragment used for CSS styling
    def live_css(line_id, fragment); end

    ##
    # Link to previous slide (for active CSS)
    # @param [String] line_id internal ID of the line
    # @param [String] fragment HTML fragment used for CSS styling
    def live_preview(line_id); end

    ##
    # Perform a live preview
    # @param [String] line_id internal ID of the line
    def live_preview_float(line_id); end

    ##
    # Beginning of a comment section, i.e. explanations to the current slide
    def comment_start; end

    ##
    # End of comment section
    def comment_end; end

    ##
    # Render an image
    # @param [String] location path to image
    # @param [String] alt alt text
    # @param [String] title title of image
    # @param [String] width_slide width for slide
    # @param [String] width_plain width for plain text
    def image(location, alt, title, width_slide, width_plain); end

    ##
    # Start of presentation
    # @param [String] title1 first title
    # @param [String] title2 second title
    # @param [String] section_number number of the section
    # @param [String] section_name name of the section
    # @param [String] copyright copyright information
    # @param [String] author author of the presentation
    def presentation_start(title1, title2, section_number, section_name, copyright, author); end

    ##
    # End of presentation
    # @param [String] title1 first title
    # @param [String] title2 second title
    # @param [String] section_number number of the section
    # @param [String] section_name name of the section
    # @param [String] copyright copyright information
    # @param [String] author author of the presentation
    def presentation_end(title1, title2, section_number, section_name, copyright, author); end

    ##
    # Small TOC menu for presentation slides for quick navigation
    def toc_menu; end

    ##
    # Start of slide
    # @param [String] title the title of the slide
    # @param [String] number the number of the slide
    # @param [String] id the unique id of the slide (for references)
    # @param [Boolean] contains_code indicates whether the slide contains code fragments
    def slide_start(title, number, id, contains_code); end

    ##
    # End of slide
    def slide_end; end
  end
end