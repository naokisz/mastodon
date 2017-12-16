# https://gist.github.com/wate/7072365
class Formatter_Markdown
    def initialize(html)
        @html = html.dup
    end

    def formatted
        @html
            .gsub(/(?:  |　　)(?:\r\n|\r|\n)/, "<br />\n") # <br />
            .gsub(/(^|\r\n|\r|\n)(.+)(?:\r\n|\r|\n)={3,}(?:\r\n|\r|\n)/, "\\1<h1>\\2</h1>\n") # headings Setext h1
            .gsub(/(^|\r\n|\r|\n)(.+)(?:\r\n|\r|\n)-{3,}(?:\r\n|\r|\n)/, "\\1<h2>\\2</h2>\n") # headings Setext h2
            .gsub(/(^|\r\n|\r|\n)[#]{1} (.+)(?:\r\n|\r|\n)/, "\\1<h1>\\2</h1>\n") # headings Atx h1
            .gsub(/(^|\r\n|\r|\n)[#]{2} (.+)(?:\r\n|\r|\n)/, "\\1<h2>\\2</h2>\n") # headings Atx h2
            .gsub(/(^|\r\n|\r|\n)[#]{3} (.+)(?:\r\n|\r|\n)/, "\\1<h3>\\2</h3>\n") # headings Atx h3
            .gsub(/(^|\r\n|\r|\n)[#]{4} (.+)(?:\r\n|\r|\n)/, "\\1<h4>\\2</h4>\n") # headings Atx h4
            .gsub(/(^|\r\n|\r|\n)[#]{5} (.+)(?:\r\n|\r|\n)/, "\\1<h5>\\2</h5>\n") # headings Atx h5
            .gsub(/(^|\r\n|\r|\n)[#]{6} (.+)(?:\r\n|\r|\n)/, "\\1<h6>\\2</h6>\n") # headings Atx h6
            .gsub(/[*_]{2}([^*_]+)[*_]{2}/, "<strong>\\1</strong>") # strong
            .gsub(/[*_]{1}([^*_]+)[*_]{1}/, "<em>\\1</em>") # em
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
        unless expected == actual
            raise "Formatter_MarkdownTester assertion failed: expected: \n" + expected + ", actual: \n" + actual
        end
    end

    def testAll
        testBR
        testHeadings
        testEm

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
end
