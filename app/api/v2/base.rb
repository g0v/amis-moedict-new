module V2
  class Base < ApplicationAPI
    format :json
    formatter :json, Grape::Formatter::Json
    version :v2, using: :path

    helpers do
      def fail400(data: nil)
        error!({ status: "fail", data: data }, 400)
      end

      def fail403(data: nil)
        error!({ status: "fail", data: data }, 403)
      end

      def fail404(data: nil)
        error!({ status: "fail", data: data }, 404)
      end

      def success200(data: nil)
        { status: "success", data: data }
      end

      def error500(error: nil, message: "something_went_wrong!")
        if Rails.env.development? && error.present?
          env["api.format"] = :txt
          error!("Grape caught this error: #{error.message} (#{error.class})\n#{error.backtrace.join("\n")}")
        else
          error!({ status: "error", message: message }, 500)
        end
      end
    end

    mount TermsAPI
    mount SearchesAPI
  end
end
