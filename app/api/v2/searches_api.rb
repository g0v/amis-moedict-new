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
            Term.select(:id, :name).ransack(lower_name_cont: params[:q]).result.group(:name).each do |term|
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
