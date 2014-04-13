# -*- coding: utf-8 -*-

require_relative 'renderer_latex'
require_relative '../messages'

module Rendering

  ##
  # Render the presentation into a latex file for further processing
  # using LaTeX
  class RendererLatexPresentation < RendererLatex

    ##
    # Initialize the renderer
    # @param [IO] io target of output operations
    # @param [String] language the default language for code snippets
    # @param [String] result_dir location for results
    # @param [String] image_dir location for generated images (relative to result_dir)
    # @param [String] temp_dir location for temporary files
    def initialize(io, language, result_dir, image_dir, temp_dir)
      super(io, language, result_dir, image_dir, temp_dir)
      @ul_level = 1
    end

    ##
    # Indicates whether the renderer handles animations or not. false indicates
    # that slides should not be repeated.
    def handles_animation?
      true
    end

    ##
    # Start a chapter
    # @param [String] title the title of the chapter
    # @param [String] number the number of the chapter
    # @param [String] id the uniquie id of the chapter (for references)
    def chapter_start(title, number, id)
      @io << <<-ENDOFTEXT
      \\section{#{title}}\\label{#{id}}
      \\begin{frame}
        \\separator{#{title}}
      \\end{frame}
      ENDOFTEXT
    end

    ## End of a chapter
    def chapter_end
      @io << nl
    end

    ##
    # Start of presentation
    # @param [String] title1 first title
    # @param [String] title2 second title
    # @param [String] section_number number of the section
    # @param [String] section_name name of the section
    # @param [String] copyright copyright information
    # @param [String] author author of the presentation
    # @param [String] term the current term of the lecture/presentation
    # @param [String] description additional description
    def presentation_start(title1, title2, section_number, section_name, copyright, author, description, term = '')
      @io << <<-ENDOFTEXT
      \\include{preambel}
      \\include{lst_javascript}
      \\include{lst_console}
      \\include{lst_css}
      \\include{lst_html}
      \\mode<presentation>{\\input{beamer-template}}
      \\newcommand{\\copyrightline}[0]{#{title1} | #{copyright}}
      \\title{#{title1} \\\\ \\small #{title2} \\\\ \\Large \\vspace{8mm} #{section_name}}
      \\author{\\small #{author}}
      \\date{\\color{grau} \\small #{term}}
      \\begin{document}
      \\begin{frame}
        \\maketitle
      \\end{frame}

      \\begin{frame}
        \\separator{#{LOCALIZED_MESSAGES[:toc]}}
      \\end{frame}

      \\begin{frame}\\frametitle<presentation>{#{LOCALIZED_MESSAGES[:toc]}}
        \\tableofcontents
      \\end{frame}
      ENDOFTEXT
    end

    ##
    # Simple text
    # @param [String] content the text
    def text(content)
      @io <<  "#{inline_code(content)}" << nl << nl
      @io << '\vspace{1mm}' << nl
    end

    ##
    # End of presentation
    # @param [String] title1 first title
    # @param [String] title2 second title
    # @param [String] section_number number of the section
    # @param [String] section_name name of the section
    # @param [String] copyright copyright information
    # @param [String] author author of the presentation
    def presentation_end(title1, title2, section_number, section_name, copyright, author)
      @io << '\end{document}' << nl
    end

    ##
    # Start of slide
    # @param [String] title the title of the slide
    # @param [String] number the number of the slide
    # @param [String] id the unique id of the slide (for references)
    # @param [Boolean] contains_code indicates whether the slide contains code fragments
    def slide_start(title, number, id, contains_code)
      @io << "\\begin{frame}[fragile]{#{inline_code(title)}}\\label{#{id}}" << nl
      @slide_ended = false
    end

    ##
    # End of slide
    def slide_end
      @io << nl << '\end{frame}' << nl << nl  unless @slide_ended
    end

    ##
    # Beginning of a comment section, i.e. explanations to the current slide
    def comment_start
      @io << nl << '\end{frame}' << nl << nl
      @slide_ended = true
    end

    ##
    # End of comment section
    def comment_end
    end

    ##
    # Render an image
    # @param [String] location path to image
    # @param [Array] formats available file formats
    # @param [String] alt alt text
    # @param [String] title title of image
    # @param [String] width_slide width for slide
    # @param [String] width_plain width for plain text
    # @param [String] source source of the image
    def image(location, formats, alt, title, width_slide, width_plain, source = nil)
      # alt contains source, title the description of the image
      # we only render the source
      image_latex(location, alt, width_slide, source)
    end

    ##
    # Start of an unordered list
    def ul_start
      @io << '\vspace{0.2mm}' << nl  if @ul_level == 1
      @io << '\vspace{0.2mm}' << nl  if @ul_level == 2
      @io << "\\begin{ul#{@ul_level}}" << nl
      @ul_level += 1
    end
  end
end
