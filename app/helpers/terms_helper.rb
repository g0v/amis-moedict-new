module TermsHelper
  def linked_term(record:, dictionary:)
    html = ""

    content = case record
              when Synonym then record.content
              when Example then record.content_amis
              end

    content.split(/(\s)/).each_with_index do |term, i|
      linked_terms = term.scan(/`([^`~]+)~/).flatten
      pattern = Regexp.union(linked_terms)

      pure_term = term.gsub(/\`|\~/, "")
      term_parts = pure_term.split(/(#{pattern})/).reject(&:empty?)
      if i == 0 # 句子第一個字的 term 需要連結時，要把 term_part 轉成小寫
        term_parts.each_with_index do |term_part, j|
          if linked_terms.include?(term_part) &&
             term_part.match(/^[\p{Alnum}'^]+$/) && # 用 regex 跳過中文
             term_part != params[:id] # 本頁的詞不需要連結

            # 產生網址用的 term_part_for_url
            # 遇到 term_part 是句首時，將 term_part 轉成小寫
            term_part_for_url = if pure_term[0..term_part.size-1] == term_part
                                  term_part.downcase
                                else
                                  term_part
                                end

            if dictionary.present? # 網址有指定字典時，路徑也要在網址內
              term_path = dictionary_term_path(dictionary.id, term_part_for_url)
            else
              term_path = term_path(term_part_for_url)
            end

            html += "<a href=\"#{term_path}\" data-term=\"#{term_part_for_url}\" class=\"hoverable-term border-b border-gray-300 text-gray-800 hover:bg-gray-300 focus:bg-gray-300 hover:text-[#0070a3] focus:text-[#0070a3] focus:outline focus:outline-1 focus:outline-[#69d2fc]\">#{term_part}</a>"
          else
            html += term_part
          end
        end
      else
        term_parts.each do |term_part|
          if linked_terms.include?(term_part) &&
             term_part.match(/^[\p{Alnum}'^]+$/) && # 用 regex 跳過中文
             term_part != params[:id] # 本頁的詞不需要連結

            if dictionary.present? # 網址有指定字典時，路徑也要在網址內
              term_path = dictionary_term_path(dictionary.id, term_part)
            else
              term_path = term_path(term_part)
            end

            html += "<a href=\"#{term_path}\" data-term=\"#{term_part}\" class=\"hoverable-term border-b border-gray-300 text-gray-800 hover:bg-gray-300 focus:bg-gray-300 hover:text-[#0070a3] focus:text-[#0070a3] focus:outline focus:outline-1 focus:outline-[#69d2fc]\">#{term_part}</a>"
          else
            html += term_part
          end
        end
      end
    end

    if record.class == Example
      html += "<br>#{record.content_zh}" if record.content_zh.present?
      html += "<br>#{record.content_en}" if record.content_en.present?
      html += "<br>#{record.content_fr}" if record.content_fr.present?
    end

    html
  end
end
