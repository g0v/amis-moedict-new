module V1
  class Base < ApplicationAPI
    format :json
    formatter :json, Grape::Formatter::Json
    version :v1, using: :path

    mount FeyAPI
    mount PoinsotAPI
    mount SafoluAPI
  end
end
