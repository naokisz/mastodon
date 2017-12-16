# https://gist.github.com/wate/7072365
class Formatter_Markdown
    def initialize(html)
        @html = html.dup
    end

    def formatted
        formattedSimple = @html
            .gsub(/(?:\r\n|\r|\n)/, "\n") # normalize new line
            .gsub(/(?:  |　　)\n/, "<br />\n") # br
            .gsub(/(^|\n)(.+)\n={3,}\n/, "\\1<h1>\\2</h1>\n") # headings Setext h1
            .gsub(/(^|\n)(.+)\n-{3,}\n/, "\\1<h2>\\2</h2>\n") # headings Setext h2
            .gsub(/(^|\n)[#]{1} (.+)\n/, "\\1<h1>\\2</h1>\n") # headings Atx h1
            .gsub(/(^|\n)[#]{2} (.+)\n/, "\\1<h2>\\2</h2>\n") # headings Atx h2
            .gsub(/(^|\n)[#]{3} (.+)\n/, "\\1<h3>\\2</h3>\n") # headings Atx h3
            .gsub(/(^|\n)[#]{4} (.+)\n/, "\\1<h4>\\2</h4>\n") # headings Atx h4
            .gsub(/(^|\n)[#]{5} (.+)\n/, "\\1<h5>\\2</h5>\n") # headings Atx h5
            .gsub(/(^|\n)[#]{6} (.+)\n/, "\\1<h6>\\2</h6>\n") # headings Atx h6
            .gsub(/[*_]{2}([^*_\n]+)[*_]{2}/, "<strong>\\1</strong>") # strong
            .gsub(/[*_]{1}([^*_\n]+)[*_]{1}/, "<em>\\1</em>") # em
            .gsub(/(^|\n)`{3,}([^\n]*)(\n(?:.|\n)+\n)`{3,}($|\n)/, "\\1<code class=\"\\2\">\\3</code>\\4") # block code
            .gsub(/`([^`]+)`/, "<code class=\"inline-code\">\\1</code>") # inline code
            .gsub(/(^|\n)[-*_]{3,}\n/, "\\1<hr>\n") # hr
        
        listFormatted = formatList(formattedSimple)

        quoteFormatted = formatQuote(listFormatted)

        quoteFormatted
    end

    def formatQuote(s)
        html = s

        quoteLinePattern = /(?:^|\n)>\s*([^\n]*)/

        loop do
            unless quoteLinePattern =~ html
                break
            end

            quote = ""

            isInQuote = false

            html.lines do |line|
                if quoteLinePattern =~ line
                    if isInQuote
                        quote += $1 + "\n"
                    else
                        quote += "<blockquote>\n" + $1 + "\n"
                        isInQuote = true
                    end
                else
                    if isInQuote
                        quote += "</blockquote>\n" + line
                        isInQuote = false
                    else
                        quote += line
                    end
                end
            end

            if isInQuote
                quote += "</blockquote>\n"
            end

            html = quote
        end

        html
    end

    #def formatQuoteElem()

    def formatList(s)
        processedLines = Array.new

        listLinePattern = /([ 　]*)([*+-]|\d+\D) +(.+)/
        listIndentLevels = Array.new
        listLastHeading = ""
        listContents = Array.new
        
        s.lines(chomp: true) do |line|
            if listLinePattern =~ line
                indent = $1
                heading = $2
                content = $3

                listIndentLevels << indent.length
                listLastHeading = heading
                listContents << content
            elsif listIndentLevels.empty? || listLastHeading.empty? || listContents.empty?
                processedLines << line
            else
                if /^\d+\D/ =~ listLastHeading
                    processedLines << formatOL(listIndentLevels, listContents)
                else
                    processedLines << formatUL(listIndentLevels, listContents)
                end

                listIndentLevels = Array.new
                listLastHeading = ""
                listContents = Array.new

                processedLines << line
            end
        end

        unless listIndentLevels.empty? || listLastHeading.empty? || listContents.empty?
            if /^\d+\D/ =~ listLastHeading
                processedLines << formatOL(listIndentLevels, listContents)
            else
                processedLines << formatUL(listIndentLevels, listContents)
            end
        end

        processedLines.join("\n")
    end

    def formatUL(indentLevels, contents)
        formatListElem(indentLevels, contents, "ul", 0).contentHTML
    end

    def formatOL(indentLevels, contents)
        formatListElem(indentLevels, contents, "ol", 0).contentHTML
    end

    class FormatListResult
        def initialize(contentHTML, endIndex)
            @contentHTML = contentHTML
            @endIndex = endIndex
        end

        def contentHTML
            @contentHTML
        end

        def endIndex
            @endIndex
        end
    end

    def formatListElem(indentLevels, contents, tagName, startIndex)
        lastIndentLevel = indentLevels[startIndex]

        currentHTML = " " * lastIndentLevel + "<" + tagName + ">\n"
        currentIndex = startIndex

        loop do
            if currentIndex >= indentLevels.length || lastIndentLevel > indentLevels[currentIndex]
                break
            end

            if lastIndentLevel < indentLevels[currentIndex]
                innerResult = formatListElem(indentLevels, contents, tagName, currentIndex)

                currentHTML += innerResult.contentHTML

                currentIndex = innerResult.endIndex
                lastIndentLevel = indentLevels[currentIndex]
            else
                currentHTML += " " * indentLevels[currentIndex] + "<li>" + contents[currentIndex] + "</li>\n"

                lastIndentLevel = indentLevels[currentIndex]
                currentIndex += 1
            end
        end

        currentHTML += " " * lastIndentLevel + "</" + tagName + ">\n"

        FormatListResult.new(currentHTML, currentIndex)
    end
end

=begin
for unit testing on irb

$ cd app/lib
$ irb

irb > load "./formatter_markdown.rb"
irb > tester = Formatter_MarkdownTester.new
irb > tester.testAll
=end
class Formatter_MarkdownTester
    def newFM(rawString)
        Formatter_Markdown.new(rawString)
    end

    def assert(expected, actual)
        unless expected.strip == actual.strip
            raise "Formatter_MarkdownTester assertion failed: expected: \n" + expected + ", actual: \n" + actual
        end
    end

    def testAll
        testBR
        testHeadings
        testEm
        testList
        testInlineCode
        testBlockCode
        testQuote
        testHr

        "Succeeded!!!"
    end

    def testBR
=begin
        段落と改行

        空白行に囲まれた複数行の文章がまとめて一つの段落として扱われます。
        段落中で改行を行いたい場合は、
        その行の末尾に二つ以上のスペースを記述することにより改行することが出来ます。
=end

        expected = <<~EOS
        半角改行<br />
        全角改行<br />
        EOS

        fm = newFM(<<~EOS
        半角改行  
        全角改行　　
        EOS
        )

        assert(expected, fm.formatted)
    end

    def testHeadings
=begin
        見出し

        MarkdowwnはSetextとatxという、二つの形式をサポートしています。

        Setext形式

        見出し1です
        =============
        見出し2です
        -------------

        Atx形式
        Atx形式は見出しの行頭に1つから6つまでの#(ハッシュ記号)を用いる方法です。
        #(ハッシュ記号)の数が見出しレベルと一致します。

        # 見出し1です
        ## 見出し2です
        ### 見出し3です
        #### 見出し4です
        ##### 見出し5です
        ###### 見出し6です

        ※Atx形式は「閉じる」ことができます。
        この表現が好みであれば使うことができますが、単純に見栄えの問題です。

        ※Setext形式とAtx形式を混在させることも可能です
=end

        expected = <<~EOS
        <h1>見出し1です</h1>
        <h2>見出し2です</h2>

        <h1>見出し1です</h1>
        <h2>見出し2です</h2>
        <h3>見出し3です</h3>
        <h4>見出し4です</h4>
        <h5>見出し5です</h5>
        <h6>見出し6です</h6>
        EOS

        fm = newFM(<<~EOS
        見出し1です
        =============
        見出し2です
        -------------

        # 見出し1です
        ## 見出し2です
        ### 見出し3です
        #### 見出し4です
        ##### 見出し5です
        ###### 見出し6です
        EOS
        )

        assert(expected, fm.formatted)
    end

    def testEm
=begin
        強調

        *(アスタリスク)や_(アンダースコア)は強調記号として扱われます。

        *や_によって囲まれた文字列は、<em>タグで囲まれたものに変換され、
        **や__によって囲まれた文字列は、<strong>タグで囲まれたものに変換されます。

        *ここがemタグで強調されます*
        _ここがemタグで強調されます_

        **ここがstrongタグで強調されます**
        __ここがstrongタグで強調されます__
=end
        expected = <<~EOS
        <em>ここがemタグで強調されます</em>
        <em>ここがemタグで強調されます</em>

        <strong>ここがstrongタグで強調されます</strong>
        <strong>ここがstrongタグで強調されます</strong>
        EOS

        fm = newFM(<<~EOS
        *ここがemタグで強調されます*
        _ここがemタグで強調されます_

        **ここがstrongタグで強調されます**
        __ここがstrongタグで強調されます__
        EOS
        )

        assert(expected, fm.formatted)
    end

    def testList
=begin
        リスト

        印付きのリストの場合はアスタリスク(*)やプラス記号(+)、
        またはハイフン記号(-)を使用します。

        リストの番号もしくは記号は通常左端からはじまりますが、
        冒頭に3つのスペー スまでは許されています。
        リストを綺麗に見せるために、リストの内容の二行目以降を揃えることができます。

        番号なしリスト

        * 1番目
        * 2番目
        * 3番目

        または

        + 1番目
        + 2番目
	        + 2番目-1
	        + 2番目-2
	        + 2番目-3
        + 3番目

        または

        - 1番目
        - 2番目
        - 3番目

        番号付きリスト

        1. 1番目
        2. 2番目
        3. 3番目
=end        

        expected = <<~EOS
        番号なしリスト
        
        <ul>
        <li>1番目</li>
        <li>2番目</li>
        <li>3番目</li>
        </ul>
        EOS

        fm = newFM(<<~EOS
        番号なしリスト

        * 1番目
        * 2番目
        * 3番目
        EOS
        )

        assert(expected, fm.formatted)

        expected = <<~EOS
        または

        <ul>
        <li>1番目</li>
        <li>2番目</li>
            <ul>
	        <li>2番目-1</li>
	        <li>2番目-2</li>
            <li>2番目-3</li>
            </ul>
        <li>3番目</li>
        </ul>
        EOS

        fm = newFM(<<~EOS
        または

        + 1番目
        + 2番目
	        + 2番目-1
	        + 2番目-2
	        + 2番目-3
        + 3番目
        EOS
        )

        assert(expected.gsub(/ /, ""), fm.formatted.gsub(/ /, ""))

        expected = <<~EOS
        または

        <ul>
        <li>1番目</li>
        <li>2番目</li>
        <li>3番目</li>
        </ul>
        EOS

        fm = newFM(<<~EOS
        または

        - 1番目
        - 2番目
        - 3番目
        EOS
        )

        assert(expected, fm.formatted)

        expected = <<~EOS
        番号付きリスト

        <ol>
        <li>1番目</li>
        <li>2番目</li>
        <li>3番目</li>
        </ol>
        EOS

        fm = newFM(<<~EOS
        番号付きリスト

        1. 1番目
        2. 2番目
        3. 3番目
        EOS
        )

        assert(expected, fm.formatted)
    end

    def testInlineCode
=begin
        ソースコード (inline)

        文中にインラインで表現する場合は該当部分をバッククォートで囲みます。
=end
        expected = <<~EOS
        <code class="inline-code">printf("Hello world!");</code>
        EOS

        fm = newFM(<<~EOS
        `printf("Hello world!");`
        EOS
        )

        assert(expected, fm.formatted)
    end

    def testBlockCode
        # GitHub flavored code block
        expected = <<~EOS
        <code class="rb">
        num = 0
        while num < 2 do
            print("num = ", num)
        end
        print("End")
        </code>
        EOS

        fm = newFM(<<~EOS
        ```rb
        num = 0
        while num < 2 do
            print("num = ", num)
        end
        print("End")
        ```
        EOS
        )

        assert(expected, fm.formatted)
    end

    def testQuote
=begin
        引用

        Markdownで引用を表現するときにはEメールと同じ方法で>を用います。
        もしあなたがEメールで引用をすることになじんでいるのであればMarkdownでの使用は容易です。

        > これは引用です
        > これは引用ですこれは引用です
        > これは引用ですこれは引用です、これは引用ですこれは引用です
=end
        expected = <<~EOS
        <blockquote>
        これは引用です
        <blockquote>
        これは引用ですこれは引用です
        </blockquote>
        これは引用ですこれは引用です、これは引用ですこれは引用です
        </blockquote>
        EOS

        fm = newFM(<<~EOS
        > これは引用です
        > > これは引用ですこれは引用です
        > これは引用ですこれは引用です、これは引用ですこれは引用です
        EOS
        )

        assert(expected, fm.formatted)
    end

    def testHr
=begin
        区切り線

        3つ以上のハイフン(-)やアスタリスク(*)、アンダースコア(_)だけで構成されている行は
        罫線となります。

        ------------------------------------
        ********
        _________
=end

        expected = <<~EOS
        <hr>
        <hr>
        <hr>
        EOS

        fm = newFM(<<~EOS
        ------------------------------------
        ********
        _________
        EOS
        )

        assert(expected, fm.formatted)
    end
end
