# frozen_string_literal: true
require "open3"

namespace :cron do
  desc "匯出所有的 Term#name 到 tmp/terms.txt"
  task export_terms_txt: :environment do
    terms = Term.distinct
                .pluck(:name)
                .reject { |name| name.match?(/\s|\(|\)/) }
                .group_by(&:size)
    File.write("tmp/terms.txt", terms.to_json)
  end

  desc "Example 和 Synonym 更新 linked term"
  task update_linked_terms_to_examples_and_synonyms: :environment do
    terms_txt = File.read("tmp/terms.txt")
    terms_hash = JSON.parse(terms_txt)

    total_examples = Example.count
    batch_size = 1000 # default by find_in_batches
    Example.find_in_batches.with_index do |examples, i|
      puts "Example: #{batch_size*(i+1)}/#{total_examples}"
      Example.transaction do
        examples.each do |example|
          if example.content_amis.present?
            # binding.irb if example.content_amis_raw != example.content_amis.gsub(/`|~/, "")
            example.update(content_amis_raw: example.content_amis.gsub(/`|~/, "")) if example.content_amis_raw.blank?
          else
            next
          end

          content_amis = create_link(example.content_amis_raw, terms_hash)
          # binding.irb if example.content_amis != content_amis
          example.update(content_amis: content_amis)
        end
      end
    end

    total_synonyms = Synonym.count
    Synonym.find_in_batches.with_index do |synonyms, i|
      puts "Synonym: #{batch_size*(i+1)}/#{total_synonyms}"
      Synonym.transaction do
        synonyms.each do |synonym|
          if synonym.content.present?
            # binding.irb if synonym.content_raw != synonym.content.gsub(/`|~/, "")
            synonym.update(content_raw: synonym.content.gsub(/`|~/, "")) if synonym.content_raw.blank?
          else
            next
          end

          content = create_link(synonym.content_raw, terms_hash)
          # binding.irb if synonym.content != content
          synonym.update(content: content)
        end
      end
    end
  end

  desc "更新蔡中涵大辭典"
  task update_safolu_from_old_amis_moedict: :environment do
    system("rm -rf tmp/dict/s;cd /tmp;rm master.zip;rm -rf amis-moedict-master;curl -L -O https://github.com/g0v/amis-moedict/archive/refs/heads/master.zip;unzip -q master.zip 'amis-moedict-master/docs/s/*' -d .;mkdir -p /srv/web/tmp/dict/;mv amis-moedict-master/docs/s /srv/web/tmp/dict/")

    # 確認舊版 amis-moedict 蔡中涵大辭典的檔案數量
    command = "cd /srv/web;ls tmp/dict/s|wc -l"
    stdout, stderr, status = Open3.capture3(command)
    puts "#{command} #=> #{stdout}"

    Rake::Task["import:safolu"].invoke
    Rake::Task["cron:export_terms_txt"].invoke
    Rake::Task["cron:update_linked_terms_to_examples_and_synonyms"].invoke
  end
end

def create_link(content, terms_hash)
  # Capture both words and the punctuation/spaces between them
  content_parts = content.scan(/[^".,:?!\/ -]+|[".,:?!\/ -]+/)

  content_parts.map do |content_part|
    next content_part if content_part.match?(/^[".,:?!\/ -]+$/)

    word = content_part
    linked_word = ""

    terms = terms_hash[word.size.to_s]
    # 試著連結完整的term
    if terms.present? && (terms.include?(word) || terms.include?(word.downcase))
      linked_word = "`#{word}~"
    else
      # 試著連結完整的term
      linked = false

      (2..word.size).to_a.reverse.each do |term_size|
        break if linked
        next if terms_hash[term_size.to_s].nil?

        terms_hash[term_size.to_s].each do |term|
          if word.match?(term)
            linked = true
            linked_word = word.sub(term, "`#{term}~")
            break
          end
        end
      end

      # 試著連結剩餘的部分
      if linked
        parts = linked_word.scan(/`[^~]*~|[^`~]+/)
        linked_word = parts.map do |part|
          if part.include?("`")
            part
          else
            terms = terms_hash[part.size.to_s]
            if terms.present? && (terms.include?(part) || terms.include?(part.downcase))
              "`#{part}~"
            else
              part
            end
          end
        end.join
      end
    end

    linked_word.present? ? linked_word : word
  end.join
end
