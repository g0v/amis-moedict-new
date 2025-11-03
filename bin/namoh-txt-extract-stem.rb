# $ bundle exec ruby lib/namoh-txt-extract-stem.rb

# 使用 binding.irb 時需要打開
# Encoding.default_external = Encoding::UTF_8
# Encoding.default_internal = Encoding::UTF_8
# $stdout.set_encoding(Encoding::UTF_8)

FILENAMES = [
  "namoh-A.txt",
  "namoh-B.txt",
  "namoh-C.txt",
  "namoh-D.txt",
  "namoh-E.txt",
  "namoh-F.txt",
  "namoh-G.txt",
  "namoh-H.txt",
  "namoh-I.txt",
  "namoh-K.txt",
  "namoh-L.txt",
  "namoh-M.txt",
  "namoh-N.txt",
  "namoh-Ng.txt",
  "namoh-O.txt",
  "namoh-P.txt",
  "namoh-'.txt",
  "namoh-R.txt",
  "namoh-S.txt",
  "namoh-T.txt",
  "namoh-U.txt",
  "namoh-W.txt",
  "namoh-X.txt",
  "namoh-Y.txt",
  "namoh-Z.txt"
]

stems = Set.new

FILENAMES.each do |filename|
  filepath = "tmp/dict/namoh-txt/#{filename}"
  next unless File.exist?(filepath)

  lines = File.readlines(filepath, encoding: "utf-8")
  File.foreach(filepath, encoding: "utf-8").with_index(0) do |line, index|
    line = line.strip
    next if line.empty?

    # Case 1: 處理有 @ 引用的行（提取被引用的詞根）
    # 範例: <b>dacefan(T)(</b>@<b> dacef) </b>
    # 範例: <b>aatangan(N)(</b>@<b> atang) = papamatangen(G)(</b>@<b> matang)</b>
    if line.include?("@")
      # 使用更新的正則表達式，支援含空格的詞根
      referenced_stems = line.scan(/[@](?:\s*<b>)?\s*([^)<]+?)(?=\s*[)<])/).flatten.map(&:strip)
      referenced_stems.each do |stem|
        stems << stem unless stem.empty?
      end
    end

    # Case 2: 主詞條（沒有 @ 引用）
    # 範例: <b>dadahal(N.T) = kakahad(S)</b>
    # 看下一行有沒有 /^①<b>/
    if line =~ /^<b>(.*?)<\/b>/
      next_line = lines[index+1].strip if index+1 < lines.size
      next unless !next_line.nil? && next_line.match?(/^①<b>/)

      # 移除所有 HTML 標籤（<sup>, </sup> 等）
      full_term = $1.gsub(/<[^>]+>/, "").strip

      stem = full_term.gsub(/\d+/, "")        # 移除數字（上標）
                      .split(/\s*=\s*/).first # 取第一個詞條
                      .gsub(/\([^)]*\)/, "")  # 移除括號
                      .strip
      stems << stem if stem
    end
  end
end

output_file = "tmp/dict/namoh-txt/stems.txt"
File.write(output_file, stems.join("\n"), encoding: "utf-8")
