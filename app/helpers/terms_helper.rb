module TermsHelper
  def linked_term(record:, dictionary:)
    html = ""

    parts = record.content.split(/[`~]/).reject(&:empty?)
    parts.each_with_index do |part, i|
      if part.match(/^[\p{Alnum}]+$/) && part != params[:id]
        term_path = if i == 0
                      "terms/#{part.downcase}"
                    else
                      "terms/#{part}"
                    end
        term_path = "dictionaries/#{dictionary.id}/#{term_path}" if dictionary.present?

        html += "<a href=\"/#{term_path}\" class=\"hoverable-term border-b border-gray-300 text-gray-800 hover:bg-gray-300 focus:bg-gray-300 hover:text-[#0070a3] focus:text-[#0070a3] focus:outline focus:outline-1 focus:outline-[#69d2fc]\">#{part}</a>"
      else
        html += part
      end
    end

    html
  end
end
