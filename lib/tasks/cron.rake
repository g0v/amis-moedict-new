# frozen_string_literal: true

namespace :cron do
  desc "匯出所有的 Term#name 到 tmp/terms.txt"
  task export_terms_txt: :environment do
    terms = Term.distinct
                .pluck(:name)
                .reject { |name| name.match?(/\s|\(|\)/) }
                .group_by(&:size)
    File.write("tmp/terms.txt", terms.to_json)
  end
end
