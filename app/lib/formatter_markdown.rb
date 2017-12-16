class Formatter_Markdown
    def initialize(html)
        @html = html.dup
    end

    def formatted
        @html
    end
end
