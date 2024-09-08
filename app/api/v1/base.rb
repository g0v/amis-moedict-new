module V1
  class Base < ApplicationAPI
    version :v1, using: :path

    mount FeyAPI
    mount PoinsotAPI
    mount SafoluAPI
  end
end
