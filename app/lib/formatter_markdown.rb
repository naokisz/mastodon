# https://gist.github.com/wate/7072365
class Formatter_Markdown
    def initialize(html)
        @html = html.dup
    end

    def formatted
        @html
            .gsub(/(?:  |　　)(?:\r\n|\r|\n)/, "<br />\n") # <br />
            .gsub(/(.+)(?:\r\n|\r|\n)={3,}(?:\r\n|\r|\n)/, "<h1>\\1</h1>\n") # headings Setext h1
            .gsub(/(.+)(?:\r\n|\r|\n)-{3,}(?:\r\n|\r|\n)/, "<h2>\\1</h2>\n") # headings Setext h2
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
end
