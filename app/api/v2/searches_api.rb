module V2
  class SearchesAPI < Base
    resources :searches do
      params do
        requires :q, type: String, desc: "搜尋族語/漢語關鍵字，族語 1~3 字使用精確搜尋，超過 3 字用 sql LIKE 搜尋。漢語一律用 sql LIKE 搜尋 Description#content。"
      end
      get ":q" do
        result = []

        if params[:q].match?(/\A[a-zA-Z'’ʼ^ ]+\z/) # 族語搜尋
          case params[:q].size
          when 1, 2, 3
            Term.includes(:descriptions).select(:id, :name).where(lower_name: params[:q]).group(:name).each do |term|
              result << { term: term.name, description: term.short_description }
            end

            if result.blank?
              result << {
                term:        "族語長度 4 以下是精確搜尋，結果較少。繼續輸入，開始模糊搜尋。",
                description: ""
              }
            end
          else
            searched_terms = Term.ransack(lower_name_cont: params[:q]).result.distinct.pluck(:name)

            if searched_terms.include?(params[:q])
              searched_terms -= [ params[:q] ]

              # TODO: 未來要把 dictionary_id 改成吃參數
              q_term = Term.where(name: params[:q]).order(:dictionary_id).first

              if q_term.is_stem
                q_stem = q_term.stem
                stem_terms = q_stem.terms.distinct.pluck(:name)
                if stem_terms.present?
                  stem_terms.sort!
                  searched_terms -= stem_terms

                  arel_term = Term.arel_table
                  stem_case_statement = Arel::Nodes::Case.new(arel_term[:name])
                  stem_terms.each_with_index do |stem_term, i|
                    stem_case_statement.when(stem_term).then(i+1)
                  end
                  stem_case_statement.else(10000)

                  Term.select(:id, :name).includes(:descriptions).where(lower_name: stem_terms).group(:name).order(stem_case_statement).each do |term|
                    result << { term: term.name, description: term.short_description }
                  end
                end
              else
                result << { term: q_term.name, description: q_term.short_description }
              end
            end

            searched_terms.sort!
            arel_term = Term.arel_table
            searched_case_statement = Arel::Nodes::Case.new(arel_term[:name])
            searched_terms.each_with_index do |searched_term, i|
              searched_case_statement.when(searched_term).then(i+1)
            end
            searched_case_statement.else(10000)

            Term.select(:id, :name).includes(:descriptions).where(name: searched_terms).group(:name).order(searched_case_statement).each do |term|
              result << { term: term.name, description: term.short_description }
            end
          end
        else # 漢語搜尋
          term_ids = Description.ransack(content_cont: params[:q]).result.pluck(:term_id)
          Term.includes(:descriptions).select(:id, :name).where(id: term_ids).group(:name).order(:dictionary_id).each do |term|
            result << { term: term.name, description: term.short_description }
          end
        end

        if result.present?
          result.sort_by { |element| element[:term].size }
        else
          [ {
            term:        "Awaay. 找不到。",
            description: ""
          } ]
        end
      end
    end
  end
end
