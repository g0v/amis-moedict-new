module V2
  class SearchesAPI < Base
    helpers do
      def update_result(result, term_name, description)
        new_entry = { term: term_name, description: description }

        # 尋找是否已有同名的 term
        existing_index = result.find_index { |item| item[:term] == term_name }

        if existing_index
          # 如果已存在，比較 description 長度，如果既有的較短，用新的取代
          if result[existing_index][:description].length < new_entry[:description].length
            result[existing_index] = new_entry
          end
        else
          result << new_entry # 如果不存在，直接加入
        end
      end
    end

    resources :searches do
      params do
        requires :q, type: String, desc: "搜尋族語/漢語關鍵字，族語 1~3 字使用精確搜尋，超過 3 字用 sql LIKE 搜尋。漢語一律用 sql LIKE 搜尋 Description#content_zh。"
      end
      get ":q", requirements: { q: /.*/ } do
        result = []

        params[:q] = params[:q].force_encoding("UTF-8")
        if params[:q].match?(/\A[a-zA-Z'’ʼ^ ,….:;\-\(\)]+\z/) # 族語搜尋
          case params[:q].size
          when 1, 2, 3
            Term.includes(:descriptions)
                .select(:id, :name)
                .where(lower_name: params[:q])
                .each do |term|
              update_result(result, term.name, term.short_description)
            end

            if result.blank?
              update_result(result, "族語長度 4 以下是精確搜尋，結果較少。繼續輸入，開始模糊搜尋。", "")
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

                  stem_terms_for_field = stem_terms.map { |t| ActiveRecord::Base.connection.quote(t) }.join(',')
                  Term.select(:id, :name)
                      .includes(:descriptions)
                      .where(lower_name: stem_terms)
                      .order(Arel.sql("FIELD(name,#{stem_terms_for_field})"))
                      .each do |term|
                    update_result(result, term.name, term.short_description)
                  end
                end
              else
                update_result(result, q_term.name, q_term.short_description)
              end
            end

            searched_terms.sort!
            searched_terms_for_field = searched_terms.map { |t| ActiveRecord::Base.connection.quote(t) }.join(',')
            Term.select(:id, :name)
                .includes(:descriptions)
                .where(name: searched_terms)
                .order(Arel.sql("FIELD(name,#{searched_terms_for_field})"))
                .each do |term|
              update_result(result, term.name, term.short_description)
            end
          end
        else # 漢語搜尋
          term_ids = Description.ransack(content_zh_cont: params[:q]).result.pluck(:term_id)
          Term.includes(:descriptions)
              .select(:id, :name)
              .where(id: term_ids)
              .order(:dictionary_id)
              .each do |term|
            update_result(result, term.name, term.short_description)
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
