module V2
  class SearchesAPI < Base
    resources :searches do
      params do
        requires :q, type: String, desc: "搜尋關鍵字"
      end
      get ":q" do
        {
          name: params[:q]
        }
      end
    end
  end
end
