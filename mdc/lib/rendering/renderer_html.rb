# -*- coding: utf-8 -*-

require 'erb'

require_relative 'renderer'
require_relative '../messages'
require_relative '../constants'

module Rendering

  ##
  # Base class for rendering slides to HTML
  class RendererHTML < Renderer

    ## ERB templates to be used by the renderer
    TEMPLATES = {
        vertical_space: erb(
            %q|
            <br>
            |
        ),

        equation: erb(
            %q|
            \[
            <%= contents %>
            \]
            |
        ),

        ol_start: erb(
            %q|
            <ol start='<%= number %>'>
            |
        ),

        ol_item: erb(
            %q|
            <li><%= inline_code(content) %>
            |
        ),

        ol_end: erb(
            %q|
            </ol>
            |
        ),

        ul_start: erb(
            %q|
            <ul>
            |
        ),

        ul_item: erb(
            %q|
            <li><%= inline_code(content) %>
            |
        ),

        ul_end: erb(
            %q|
            </ul>
            |
        ),

        quote: erb(
            %q|
            <blockquote><%= inline_code(content) %>
            <% if !source.nil? %>
              <div class='quote_source'><%= source %></div>
            <% end %>
            </blockquote>
            |
        ),

        important: erb(
            %q|
            <blockquote class='important'><%= inline_code(content) %>
            </blockquote>
            |
        ),

        question: erb(
            %q|
            <blockquote class='question'><%= inline_code(content) %>
            </blockquote>
            |
        ),

        script: erb(
            %q|
            <script><%= content %></script>
            |
        ),

        code_start: erb(
            %q|<pre><code class='<%= language %>' contenteditable>|
        ),

        code: erb(
            %q|<%= entities(content) %>|
        ),

        code_end: erb(
            %q|</code></pre>|
        ),

        table_start: erb(
            %q|
            <table class='small content'>
            <thead><tr>
            |
        ),

        table_end: erb(
            %q|
            </tbody></table>
            |
        ),


        text: erb(
            %q|
            <p><%= inline_code(content) %></p>
            |
        ),

        heading: erb(
            %q|
            <h<%= level %>><%= title %></h<%= level %>>
            |
        ),

        toc_start: erb(
            %q|
            <section data-number='2'>
            <h1 class='title toc'><%= LOCALIZED_MESSAGES[:toc] %></h1>
            <ul>
            |
        ),

        toc_entry: erb(
            %q|
            <li><a href='#<%= anchor %>'><%= name %></a>
            |
        ),

        toc_end: erb(
            %q|
            </ul>
            </section>
            |
        ),

        toc_sub_entries_start: erb(
            %q|
            <ul class='subentry'>
            |
        ),

        toc_sub_entry: erb(
            %q|
            <li><a href='#<%= anchor %>'><%= name %></a>
            |
        ),

        toc_sub_entries_end: erb(
            %q|
            </ul>
            |
        ),

        index_start: erb(
            %q|
            <!DOCTYPE html>
            <html>
            <head>
              <meta charset='utf-8'>
              <title><%= title1 %></title>
              <%= include_javascript(INCLUDED_SCRIPTS) %>
              <%= include_css(INCLUDED_STYLESHEETS) %>
            </head>
            <body>
            <div class='title_first'><%= title1 %></div>
            <div class='title_second'>%= title2 %></div>
            <div class='copyright'>%= copyright%></div>
            <div class='description'>%= description%></div>
            <br>
            <table>
            <tr><th><%= LOCALIZED_MESSAGES[:chapter] %></th>
            <th colspan='2'><%= LOCALIZED_MESSAGES[:material] %></th></tr>
            |
        ),

        index_entry: erb(
            %q|
            <tr>
            <td><%= chapter_number %> - <%= chapter_name %></td>
            <td><a href='<%= slide_file %>'><%= slide_name %></a></td>
            <td><a href='<%= plain_file %>'><%= plain_name %></a></td>
            </tr>
            |
        ),

        index_end: erb(
            %q|
            </table>
            </div>
            </body>
            </html>
            |
        ),

        html: erb(
            %q|<%= content %>|
        ),

        css: erb(
            %q|<link rel='stylesheet' href='<%= css %>'>
            |
        ),

        js: erb(
            %q|<script src='<%= js %>'></script>
            |
        ),
    }

    CSS_PLAIN     = 'css/plain.css'
    CSS_BOOK      = 'css/book.css'
    CSS_ZENBURN   = 'css/zenburn.css'
    CSS_LIGHTNESS = 'css/ui-lightness/jquery-ui-1.10.3.css'
    CSS_THOMAS    = 'css/thomas.css'
    CSS_MAIN      = 'css/main.css'
    JS_HEAD       = 'lib/js/head.min.js'
    JS_THOMAS     = 'js/thomas.js'
    JS_HIGHLIGHT  = 'lib/js/highlight.js'
    JS_JQUERY     = 'lib/js/jquery-1.9.1.js'
    JS_MATHJAX    = 'lib/mathjax/MathJax.js?config=TeX-AMS_HTML'
    JS_JQUERY_UI  = 'lib/js/jquery-ui-1.10.3.js'
    JS_REVEAL     = 'lib/js/reveal.min.js'
    JS_SETTINGS   = 'js/settings.js'

    INCLUDED_STYLESHEETS = [
        CSS_PLAIN,
        CSS_BOOK,
        CSS_ZENBURN,
    ]

    INCLUDED_SCRIPTS = [
        JS_HEAD,
        JS_THOMAS,
        JS_HIGHLIGHT,
        JS_JQUERY,
        JS_MATHJAX,
    ]

    PREFERRED_IMAGE_FORMATS = %w(svg png jpg)

    ##
    # Initialize the renderer
    # @param [IO] io target of output operations
    # @param [String] language the default language for code snippets
    # @param [String] result_dir location for results
    # @param [String] image_dir location for generated images (relative to result_dir)
    # @param [String] temp_dir location for temporary files
    def initialize(io, language, result_dir, image_dir, temp_dir)
      super(io, language, result_dir, image_dir, temp_dir)
      @ul_level = 0
      @toc = nil            # table of contents
      @last_toc_name = ''   # last name of toc entry to skip double entries
    end

    ##
    # Replace inline elements like emphasis (_..._)
    #
    # @param [String] input Text to be replaced
    # @param [boolean] alternate alternate emphasis to be used
    # @return [String] Text with replacements performed
    def inline(input, alternate = false)

      parts = tokenize_line(input, /(\[.+?\]\(.+?\))/)
      result = ''

      parts.each do |p|
        if p.matched
          result << p.content.gsub(/\[(.+?)\]\((.+?)\)/, '<a href="\2">\1</a>')
        else
          result << inline_replacements(p.content, alternate)
        end
      end

      result
    end

    ##
    # Apply regular expressions to replace inline content
    # @param [String] input Text to be replaced
    # @param [boolean] alternate alternate emphasis to be used
    # @return [String] Text with replacements performed
    def inline_replacements(input, alternate = false)

      return ''  if input.nil?

      result = input

      result.gsub!(/ ([A-Za-z0-9])_([A-Za-z0-9]) /,  ' \1<sub>\2</sub> ')
      result.gsub!(/ ([A-Za-z0-9])\^([A-Za-z0-9]) /, ' \1<sup>\2</sup> ')
      result.gsub!( /([A-Za-z0-9])\^([A-Za-z0-9])$/, ' \1<sup>\2</sup>')
      result.gsub!( /([A-Za-z0-9])\^([A-Za-z0-9]) /, ' \1<sup>\2</sup> ')
      result.gsub!(/__(.+?)__/,           '<strong>\1</strong>')
      result.gsub!(/_(.+?)_/,             '<em>\1</em>')
      result.gsub!(/\*\*(.+?)\*\*/,       '<strong class="alternative">\1</strong>')
      result.gsub!(/\*(.+?)\*/,           '<em class="alternative">\1</em>')
      result.gsub!(/~~(.+?)~~/,           '<del>\1</del>')
      #result.gsub!(/s\[(.+?)\]\((.+?)\)/, '<a class="small" href="\2">\1</a>')
      #result.gsub!(/\[(.+?)\]\((.+?)\)/,  '<a href="\2">\1</a>')
      result.gsub!(/z\.B\./,              'z.&nbsp;B.')
      result.gsub!(/d\.h\./,              'd.&nbsp;h.')
      result.gsub!(/u\.a\./,              'u.&nbsp;a.')
      result.gsub!(/ -> /,                ' &rarr; ')
      result.gsub!(/ => /,                ' &rArr; ')
      result.gsub!(/---/,                 '&mdash;')
      result.gsub!(/--/,                  '&ndash;')
      result.gsub!(/\.\.\./,              '&hellip;')

      result
    end

    ##
    # Replace HTML entities in input
    # @param [String] input string to replace entities in
    # @return [String] string with replacements
    def entities(input)
      result = input
      result.gsub!(/&/,           '&amp;')
      result.gsub!(/</,           '&lt;')
      result.gsub!(/>/,           '&gt;')

      result
    end

    ##
    # Replace `inline code` in input
    # @param [String] input the input
    # @return the input with replaced code fragments
    def inline_code(input)
      parts = tokenize_line(input, /`(.+?)`/)
      result = ''

      parts.each { |p|
        if p.matched
          result << "<code class='inline #{@language}'>#{entities(p.content)}</code>"
        else
          result << inline(p.content)
        end
      }

      result
    end

    ##
    # Replace []() links in input
    # @param [String] input the input
    # @return the input with replaced code fragments
    def inline_links(input)
      parts = tokenize_line(input, /`(.+?)`/)
      result = ''

      parts.each do |p|
        if p.code
          result << "<code class='inline #{@language}'>#{entities(p.content)}</code>"
        else
          result << inline(p.content)
        end
      end

      result
    end

    ##
    # Vertical space
    def vertical_space
      @io << TEMPLATES[:vertical_space].result(binding)
    end

    ##
    # Equation
    # @param [String] contents LaTeX source of equation
    def equation(contents)
      @io << TEMPLATES[:equation].result(binding)
    end

    ##
    # Start of an ordered list
    # @param [Fixnum] number start number of list
    def ol_start(number = 1)
      @io << TEMPLATES[:ol_start].result(binding)
      @ul_level += 1
    end

    ##
    # End of ordered list
    def ol_end
      @io << TEMPLATES[:ol_end].result(binding)
      @ul_level -= 1
    end

    ##
    # Item of an ordered list
    # @param [String] content content
    def ol_item(content)
      @io << TEMPLATES[:ol_item].result(binding)
    end

    ##
    # Start of an unordered list
    def ul_start
      @io << TEMPLATES[:ul_start].result(binding)
      @ul_level += 1
    end

    ##
    # End of an unordered list
    def ul_end
      @io << TEMPLATES[:ul_end].result(binding)
      @ul_level -= 1
    end

    ##
    # Item of an unordered list
    # @param [String] content content
    def ul_item(content)
      @io << TEMPLATES[:ul_item].result(binding)
    end

    ##
    # Quote
    # @param [String] content the content
    # @param [String] source the source of the quote
    def quote(content, source)
      @io << TEMPLATES[:quote].result(binding)
    end

    ##
    # Important
    # @param [String] content the box
    def important(content)
      @io << TEMPLATES[:important].result(binding)
    end

    ##
    # Question
    # @param [String] content the box
    def question(content)
      @io << TEMPLATES[:question].result(binding)
    end

    ##
    # Script
    # @param [String] content the script to be included
    def script(content)
      @io << TEMPLATES[:script].result(binding)
    end

    ##
    # Start of a code fragment
    # @param [String] language language of the code fragment
    # @param [String] caption caption of the sourcecode
    def code_start(language, caption)
      @io << TEMPLATES[:code_start].result(binding)
    end

    ##
    # End of a code fragment
    # @param [String] caption caption of the sourcecode
    def code_end(caption)
      @io << TEMPLATES[:code_end].result(binding)
    end

    ##
    # Output code
    # @param [String] content the code content
    def code(content)
      @io << TEMPLATES[:code].result(binding)
    end

    ##
    # Return a css class for the given alignment constant
    # @param [Fixnum] alignment for the alignment
    # @return [String] css class string to be used in HTML page
    def class_for_constant(alignment)
      case alignment
        when Constants::LEFT then " class='left'"
        when Constants::RIGHT then " class='right'"
        when Constants::CENTER then " class='center'"
        when Constants::SEPARATOR then " class='separator'"
        else ''
      end
end
    ##
    # Header of table
    # @param [Array] headers the headers
    # @param [Array] alignment alignments of the cells
    def table_start(headers, alignment)

      @io << TEMPLATES[:table_start].result(binding)

      headers.each_with_index do |e, i|

        css_class = class_for_constant(alignment[i])

        @io << "<th#{css_class}>#{inline_code(e)}</th>" << nl if alignment[i] != Constants::SEPARATOR
        @io << "<th#{css_class}></th>" << nl if alignment[i] == Constants::SEPARATOR
      end

      @io << '</tr></thead><tbody>' << nl
    end

    ##
    # Row of the table
    # @param [Array] row row of the table
    # @param [Array] alignment alignments of the cells
    def table_row(row, alignment)
      @io << '<tr>' << nl
      row.each_with_index do |e, i|

        css_class = class_for_constant(alignment[i])

        @io << "<td#{css_class}>#{inline_code(e)}</td>" << nl if alignment[i] != Constants::SEPARATOR
        @io << "<td#{css_class}></td>" << nl if alignment[i] == Constants::SEPARATOR
      end

      @io <<  '</tr>' << nl
    end

    ##
    # End of the table
    def table_end
      @io << TEMPLATES[:table_end].result(binding)
    end

    ##
    # Simple text
    # @param [String] content the text
    def text(content)
      @io << TEMPLATES[:text].result(binding)
    end

    ##
    # Heading of a given level
    # @param [Fixnum] level heading level
    # @param [String] title title of the heading
    def heading(level, title)
      @io << TEMPLATES[:heading].result(binding)
    end

    ##
    # Start of the TOC
    def toc_start
      @io << TEMPLATES[:toc_start].result(binding)
    end

    ##
    # Start of sub entries in toc
    def toc_sub_entries_start
      @io << TEMPLATES[:toc_sub_entries_start].result(binding)
    end

    ##
    # End of sub entries
    def toc_sub_entries_end
      @io << TEMPLATES[:toc_sub_entries_end].result(binding)
    end

    ##
    # Output a toc sub entry
    # @param [String] name name of the entry
    # @param [String] anchor anchor of the entry
    def toc_sub_entry(name, anchor)
      return  if name == @last_toc_name
      @last_toc_name = name
      @io << TEMPLATES[:toc_sub_entry].result(binding)
    end

    ##
    # Output a toc entry
    # @param [String] name name of the entry
    # @param [String] anchor anchor of the entry
    def toc_entry(name, anchor)
      @io << TEMPLATES[:toc_entry].result(binding)
    end

    ##
    # End of toc
    def toc_end
      @io << TEMPLATES[:toc_end].result(binding)
    end

    ##
    # Start of index file
    # @param [String] title1 title 1 of lecture
    # @param [String] title2 title 2 of lecture
    # @param [String] copyright copyright info
    # @param [String] description description
    def index_start(title1, title2, copyright, description)
      @io << TEMPLATES[:index_start].result(binding)
    end

    ##
    # End of index
    def index_end
      @io << TEMPLATES[:index_end].result(binding)
    end

    ##
    # Single index entry
    # @param [Fixnum] chapter_number number of chapter
    # @param [String] chapter_name name of chapter
    # @param [String] slide_file file containing the slides
    # @param [String] plain_file file containing the plain version
    def index_entry(chapter_number, chapter_name, slide_file, slide_name, plain_file, plain_name)
      @io << TEMPLATES[:index_entry].result(binding)
    end

    ##
    # HTML output
    # @param [String] content html
    def html(content)
      @io << TEMPLATES[:html].result(binding)
    end

    ##
    # Include CSS files
    # @param [Array] locations locations of the css files
    # @return [String] link tags
    def include_css(locations)
      result = ''
      locations.each { |l| result << css(l) }
      result
    end

    ##
    # Include JavaScript files
    # @param [Array] locations locations of the javscript files
    # @return [String] script tags
    def include_javascript(locations)
      result = ''
      locations.each { |l| result << js(l) }
      result
    end

    ##
    # Single css entry
    # @param [String] css location of css file
    def css(css)
      TEMPLATES[:css].result(binding)
    end

    ##
    # Single JavaScript entry
    # @param [String] js location of JavaScript file
    def js(js)
      TEMPLATES[:js].result(binding)
    end

    ##
    # Include inline scripts
    # @param [Array] s scripts to be added
    def scripts(s)
      result = ''
      s.each { |f| result << "<script>#{f}</script>" << nl }
      result
    end

    ##
    # Return the most suitable image file for the given
    # @param [String] file_name name of the image
    # @param [Array] formats available file formats
    # @return the most preferred image filen ame
    def choose_image(file_name, formats)

      format = formats.each { |f|
        break f  if PREFERRED_IMAGE_FORMATS.include?(f)
      }

      if /(.*?)\.[A-Za-z]{3,4}/ =~ file_name
        "#{$1}.#{format}"
      else
        "#{file_name}.#{format}"
      end
    end
  end
end
