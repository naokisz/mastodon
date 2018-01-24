require 'uri'
require 'redcarpet'

# https://gist.github.com/mignonstyle/083c9e1651d7734f84c99b8cf49d57fa
# https://gist.github.com/wate/7072365
class Formatter_Markdown
    def initialize(html)
        @html = html.dup
    end

    def formatted
        render_options = {
            escape_html: true,
            safe_links_only: true,
            with_toc_data: true,
            hard_wrap: true,
            xhtml: false,
            prettify: true,
            link_attributes: true
        }
        mdRenderer = CustomMDRenderer.new

        extensions = {
            space_after_headers: true,
            no_intra_emphasis: true,
            tables: true,
            fenced_code_blocks: false,
            autolink: true,
            disable_indented_code_blocks: false,
            strikethrough: false,
            lax_spacing: true,
            superscript: true,
            underline: true,
            highlight: true,
            quote: false,
            footnotes: true
        }
        md = Redcarpet::Markdown.new(
            mdRenderer,
            space_after_headers: true,
            no_intra_emphasis: true,
            no_links: true,
            no_styles: true,
            no_images: true,
            filter_html: true,
            escape_html: true,
            safe_links_only: true,
            with_toc_data: true,
            hard_wrap: true,
            xhtml: false,
            prettify: true,
            link_attributes: true
        )

        renderedMD = md.render(@html)

        result = renderedMD
        result.gsub!(/[~]{2,}([^~\n]+)[~]{2,}/) { "<s>#{encode($1)}</s>" } # strikethrough
        result.gsub!(/(<\w+)([^>]*>)/) { "#{$1} data-md='true' #{$2}" }

        result
    end

    class CustomMDRenderer < Redcarpet::Render::HTML
        def image(link, title, alt_text)
            %(<img src="#{URI.encode_www_form_component(link)}" alt="#{alt_text}">)
        end

        def link(link, title, content)
            %(<a href="#{URI.encode_www_form_component(link)}">#{content}</a>)
        end

        def paragraph(text)
            text.strip
        end

        def linebreak()
            %(\n)
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
            %(<em>#{encode(text)}</em>)
        end

        def double_emphasis(text)
            %(<strong>#{encode(text)}</strong>)
        end

        def triple_emphasis(text)
            %(<em><strong>#{encode(text)}</strong></em>)
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
    end

    def encode(html)
        HTMLEntities.new.encode(html)
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

class MDExtractor
    def initialize(html)
        @html = html.dup
    end

    def extractEntities
        [
            extractByHTMLTagName("h1"),
            extractByHTMLTagName("h2"),
            extractByHTMLTagName("h3"),
            extractByHTMLTagName("h4"),
            extractByHTMLTagName("h5"),
            extractByHTMLTagName("h6"),
            extractByHTMLTagName("em"),
            extractByHTMLTagName("strong"),
            extractByHTMLTagName("ul", false, false, "li"),
            extractByHTMLTagName("ol", false, false, "li"),
            extractByHTMLTagName("code"),
            extractByHTMLTagName("blockquote", false),
            extractByHTMLTagName("hr", false, true),
            extractByHTMLTagName("a"),
            extractByHTMLTagName("img", false, true),
            extractByHTMLTagName("s"),
            extractByHTMLTagName("sup"),
            extractByHTMLTagName("u"),
            extractByHTMLTagName("mark")
        ].flatten.compact
    end

    def extractByHTMLTagName(tagName, isNoNest = true, isSingle = false, itemTagName = nil)
        entities = []

        @html.to_s.scan(htmlTagPatternByCond(tagName, isNoNest, isSingle, itemTagName)) do
            match = $~

            beginPos = match.char_begin(0)
            endPos = match.char_end(0)

            entity = {
                :markdown => true,
                :indices => [beginPos, endPos]
            }

            entities.push(entity)
        end

        entities
    end

    def htmlTagPatternByCond(tagName, isNoNest, isSingle, itemTagName)
        if isSingle
            htmlTagPatternSingle(tagName)
        elsif isNoNest
            htmlTagPatternNoNest(tagName)
        elsif itemTagName && itemTagName.length > 0
            htmlTagPatternOuterMostWithItem(tagName, itemTagName)
        else
            htmlTagPatternOuterMost(tagName)
        end
    end

    def htmlTagPattern(tagName)
        Regexp.compile("<#{tagName} data-md=[^>]*>(?:[^<]|<#{tagName} data-md=[^>]*>|<\\/#{tagName}>)*(?:<\\/#{tagName}>)*")
    end

    def htmlTagPatternNoNest(tagName)
        Regexp.compile("<#{tagName} data-md=[^>]*>(?:.|\n)*?<\\/#{tagName}>")
    end

    def htmlTagPatternSingle(tagName)
        Regexp.compile("<#{tagName} data-md=[^>]*>")
    end

    # https://stackoverflow.com/questions/546433/regular-expression-to-match-outer-brackets
    def htmlTagPatternOuterMost(tagName)
        Regexp.compile("<#{tagName} data-md=[^>]*>(?:[^<>]|(\\g<0>))*<\/#{tagName}>")
    end

    def htmlTagPatternOuterMostWithItem(tagName, itemTagName)
        Regexp.compile("<#{tagName} data-md=[^>]*>(?:[^<>]|<#{itemTagName} data-md=[^>]*>|<\\/#{itemTagName}>|(\\g<0>))*<\/#{tagName}>")
    end
end
