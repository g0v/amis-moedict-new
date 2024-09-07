module V1
  class FeyAPI < Base
    resources :p do
      params do
        requires :name, type: String, desc: "詞彙，對應 Term#name"
      end
      get ":name" do
        {
          h:    [
            {
              name: params[:name],
              d:    [
                {
                  f:    "String, required",
                  e:    [
                    "String"
                  ],
                  s:    [
                    "String"
                  ],
                  r:    [
                    "String"
                  ],
                  type: "String, optional"
                }
              ]
            }
          ],
          t:    "String, required",
          stem: "String, optional",
          tag:  "String, optional"
        }
      end
    end
  end
end
