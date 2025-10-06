# docx內已將箭頭符號取代為@
# $ bundle exec ruby lib/namoh-docx-to-txt.rb

# 使用 binding.irb 時需要打開
# Encoding.default_external = Encoding::UTF_8
# Encoding.default_internal = Encoding::UTF_8
# $stdout.set_encoding(Encoding::UTF_8)

require 'zip'
require 'nokogiri'

# Read the docx file
def parse_docx(filename)
  text_content = ""

  # Open the docx file (it's a zip archive)
  Zip::File.open(filename) do |zip_file|
    # Find the document.xml file which contains the text
    entry = zip_file.glob('word/document.xml').first

    if entry
      # Read and parse the XML content
      xml_content = entry.get_input_stream.read
      doc = Nokogiri::XML(xml_content)

      # Extract text from main body paragraphs only, excluding text boxes and floating content
      doc.xpath('//w:body//w:p[not(ancestor::w:txbxContent)]', 'w' => 'http://schemas.openxmlformats.org/wordprocessingml/2006/main').each do |para|
        para_text = ""
        current_bold = false
        chinese_encountered = false  # Track if we've seen Chinese or certain punctuation in this paragraph

        para.xpath('.//w:r', 'w' => 'http://schemas.openxmlformats.org/wordprocessingml/2006/main').each do |run|
          text = run.xpath('.//w:t').map(&:text).join
          next if text.empty?

          # Check for formatting
          props = run.xpath('.//w:rPr', 'w' => 'http://schemas.openxmlformats.org/wordprocessingml/2006/main').first

          is_bold = false
          vert_align = nil

          if props
            # 排除 header 或側邊的浮動文字方塊
            next if props.xpath('.//w:noProof', 'w' => 'http://schemas.openxmlformats.org/wordprocessingml/2006/main').any?

            # Check for bold
            is_bold = props.xpath('.//w:b', 'w' => 'http://schemas.openxmlformats.org/wordprocessingml/2006/main').any? ||
                      props.xpath('.//w:bCs', 'w' => 'http://schemas.openxmlformats.org/wordprocessingml/2006/main').any? ||
                      props.xpath('.//w:rStyle[@w:val="afa"]', 'w' => 'http://schemas.openxmlformats.org/wordprocessingml/2006/main').any? ||
                      props.xpath('.//w:rStyle[@w:val="afb"]', 'w' => 'http://schemas.openxmlformats.org/wordprocessingml/2006/main').any?
            vert_align = props.xpath('.//w:vertAlign', 'w' => 'http://schemas.openxmlformats.org/wordprocessingml/2006/main').first
          end

          # Process text character by character
          text.each_char do |char|
            # Check if this is a circled number (①-⑳ ㉑-㉟ ㊱-㊿, covering 1-50)
            if char.match?(/[\u2460-\u2473\u3251-\u325F\u32B1-\u32BF]/)
              # Add newline before circled number if there's already content
              if para_text.length > 0 && !para_text.end_with?("\n")
                # Close bold if it's open before adding newline
                if current_bold
                  para_text += "</b>"
                  current_bold = false
                end
                para_text += "\n"
                chinese_encountered = false  # Reset for new line
              end
            end

            # Check if this is a Chinese character or double quote
            if char.match?(/[\u4e00-\u9fff\u3400-\u4dbf]/) || char == '“'
              # Close bold if it's open
              if current_bold
                para_text += "</b>"
                current_bold = false
              end
              chinese_encountered = true
              para_text += char
            else
              # If Chinese/quote has been encountered in this paragraph, don't process bold anymore
              if chinese_encountered
                para_text += char
              else
                # Handle bold state changes
                if is_bold && !current_bold
                  para_text += "<b>"
                  current_bold = true
                elsif !is_bold && current_bold
                  para_text += "</b>"
                  current_bold = false
                end

                # Apply vertical alignment (only superscript)
                if vert_align && vert_align['w:val'] == 'superscript'
                  para_text += "<sup>#{char}</sup>"
                else
                  para_text += char
                end
              end
            end
          end
        end

        # Close any open formatting at end of paragraph
        para_text += "</b>" if current_bold

        text_content += para_text + "\n" unless para_text.strip.empty?
      end
    end
  end

  text_content
end

FILENAME_MAPPING = {
  "3-01 阿美族語辭典[A]-頁001-015" => "namoh-A",
  "3-02 阿美族語辭典[B]-頁016" => "namoh-B",
  "3-03 阿美族語辭典[C]-頁017-072" => "namoh-C",
  "3-04 阿美族語辭典[D]-頁073-095" => "namoh-D",
  "3-05 阿美族語辭典[E]-頁096-101" => "namoh-E",
  "3-06 阿美族語辭典[F]-頁102-155" => "namoh-F",
  "3-07 阿美族語辭典[G]-頁156" => "namoh-G",
  "3-08 阿美族語辭典[H]-頁157-215" => "namoh-H",
  "3-09 阿美族語辭典[I]-頁216-227" => "namoh-I",
  "3-10 阿美族語辭典[K]-頁228-293" => "namoh-K",
  "3-11 阿美族語辭典[L]-頁294-360" => "namoh-L",
  "3-12 阿美族語辭典[M]-頁361-464" => "namoh-M",
  "3-13 阿美族語辭典[N]-頁465-486" => "namoh-N",
  "3-14 阿美族語辭典[Ng]-頁487-497" => "namoh-Ng",
  "3-15 阿美族語辭典[O]-頁498-503" => "namoh-O",
  "3-16 阿美族語辭典[P]-頁504-578" => "namoh-P",
  "3-17 阿美族語辭典[' ]-頁579-631" => "namoh-'",
  "3-18 阿美族語辭典[R]-頁632-660" => "namoh-R",
  "3-19 阿美族語辭典[S]-頁661-736" => "namoh-S",
  "3-20 阿美族語辭典[T]-頁737-856" => "namoh-T",
  "3-21 阿美族語辭典[U]-頁857" => "namoh-U",
  "3-22 阿美族語辭典[W]-頁858-865" => "namoh-W"
}

FILENAME_MAPPING.keys.each do |filename|
  content = parse_docx("tmp/dict/namoh-docx/#{filename}.docx")
  File.write("tmp/dict/namoh-txt/#{FILENAME_MAPPING[filename]}.txt", content)
end
