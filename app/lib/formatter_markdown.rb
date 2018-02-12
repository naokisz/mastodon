require 'uri'
require 'redcarpet'
require 'redcarpet/render_strip'

# https://gist.github.com/mignonstyle/083c9e1651d7734f84c99b8cf49d57fa
# https://gist.github.com/wate/7072365
class Formatter_Markdown
    def initialize(html)
        @html = html.dup
    end

    def formatted
        mdRenderer = CustomMDRenderer.new(
            strikethrough: true,
            hard_wrap: true,
            autolink: true,
            superscript:false,
            fenced_link: true,
            fenced_image: true,
            no_intra_emphasis: true,
            no_links: true,
            no_styles: true,
            no_images: true,
            filter_html: true,
            escape_html: true,
            safe_links_only: true,
            with_toc_data: true,
            xhtml: false,
            prettify: true,
            link_attributes: true
        )

        md = Redcarpet::Markdown.new(
            mdRenderer,
            strikethrough: true,
            hard_wrap: true,
            superscript:false,
            autolink: true,
            space_after_headers: true,
            no_intra_emphasis: true,
            no_links: true,
            no_styles: true,
            no_images: true,
            filter_html: true,
            escape_html: true,
            safe_links_only: true,
            with_toc_data: true,
            xhtml: false,
            prettify: true,
            link_attributes: true
        )

        renderedMD = md.render(@html)

        result = renderedMD
        result.gsub!(/(<\w+)([^>]*>)/) { "#{$1} data-md='true' #{$2}" }

        result

    end

    class CustomMDRenderer < Redcarpet::Render::HTML

        def image(link, title, alt_text)
            imgcheck = "#{link}"
            if imgcheck !~ /\Ahttps:\/\/[^<>"\[\]  ]+\z/
                %("ERROR")
            else
                %(<a href="#{URI.encode_www_form_component(link)}"><img src="#{URI.encode_www_form_component(link)}"></a>)
            end
        end

        def link(link, title, content)
            linkcheck = "#{link}"
            if linkcheck !~ /\Ahttps:\/\/[^<>"\[\]  ]+\z/
                %("ERROR")
            else
                %(<a href="#{URI.encode_www_form_component(link)}">#{content}</a>)
            end
        end

        def paragraph(text)
            %(#{text.strip})
        end

        def linebreak()
            %(<br>)
        end

        def block_code(code, language)
            %(<code class="#{language}">#{code.strip}</code>)
        end

        def block_quote(quote)
            %(<blockquote>#{quote.strip}</blockquote>)
        end

        def list(contents, list_type)
            if list_type == :unordered
                %(<ul>#{contents.strip}</ul>)
            elsif list_type == :ordered
                %(<ol>#{contents.strip}</ol>)
            else
                %(<#{list_type}>#{contents.strip}</#{list_type}>)
            end
        end

        def list_item(text, list_type)
            %(<li>#{text.strip}</li>)
        end

        def emphasis(text)
            %(<sup>#{encode(text)}</sup>)
        end

        def double_emphasis(text)
            %(<sub>#{encode(text)}</sub>)
        end

        def triple_emphasis(text)
            %(<small>#{encode(text)}</small>)
        end

        def strikethrough(text)
            %(<s>#{encode(text)}</s>)
        end

        def superscript(text)
            %(<sup>#{encode(text)}</sup>)
        end

        def underline(text)
            %(<u>#{encode(text)}</u>)
        end

        def highlight(text)
            %(<mark>#{encode(text)}</mark>)
        end

        def encode(html)
            HTMLEntities.new.encode(html)
        end

        def autolink(link, link_type)
           links  = link.gsub(/$\[\//," [/")
            %(#{links})
        end

    end

end

class MDLinkDecoder
    def initialize(html)
        @html = html.dup
    end

    def decode
        imageDecoded = @html.gsub(/<img data-md='true'\s+src="([^"]+)"([^>]*)>/) { "<img data-md='true' src=\"" + URI.decode_www_form_component($1) + "\"" + $2 + ">" }

        imageDecoded.gsub(/<a data-md='true'\s+href="([^"]+)"([^>]*)>/) { "<a data-md='true' href=\"" + URI.decode_www_form_component($1) + "\"" + $2 + ">" }
    end
end
