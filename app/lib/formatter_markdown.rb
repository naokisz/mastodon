# https://gist.github.com/wate/7072365
class Formatter_Markdown
    def initialize(html)
        @html = html.dup
    end

    def formatted
        @html
            .gsub(/(  |　　)(\r\n|\r|\n)/, "<br />\n")
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
            raise "Formatter_MarkdownTester assertion failed: expected: " + expected + ", actual: " + actual
        end
    end

    def testAll
        testBR

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
end
