module V2
  class TermsAPI < Base
    resources :terms do
      params do
        requires :name, type: String, desc: "詞彙，對應 Term#name"
      end
      get ":name" do
        {
          name: params[:name]
        }
      end
    end
  end
end
