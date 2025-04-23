class DeviseLocaleMiddleware
  def initialize(app)
    @app = app
  end

  def call(env)
    I18n.locale = :'zh-TW'
    status, headers, body = @app.call(env)
  end
end
