class ApplicationAPI < Grape::API
  content_type   :text, "text/plain"
  content_type   :json, "application/json"
  default_format :json

  mount V1::Base
  mount V2::Base
end
