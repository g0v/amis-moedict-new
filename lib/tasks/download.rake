# frozen_string_literal: true

require "net/http"
require "uri"
require "open-uri"

namespace :download do
  desc "下載學習詞表 images 和 wav"
  task glossary: :environment do
    %w[
      南勢阿美語
      秀姑巒阿美語
      海岸阿美語
      馬蘭阿美語
      恆春阿美語
    ].each_with_index do |dict_name, i|
      dictionary = Dictionary.find_by(name: "學習詞表－#{dict_name}")

      dictionary.terms.each do |term|
        term.descriptions.each do |description|
          wav_url   = "https://ilrdc.tw/tow/2022/audio/word/#{i+1}/#{description.glossary_serial.sub('-', '_')}.wav"
          check_and_download(wav_url,   "tmp/glossary/wav/#{i+1}")

          image_url = "https://glossary-api.ilrdf.org.tw/glossary_2022/images/#{description.glossary_serial}.jpg"
          check_and_download(image_url, "tmp/glossary/images")
        end
      end
    end
  end

  desc "更新 glossary image 網址"
  task description_glossary_image: :environment do
    Description.where.not(glossary_serial: nil).each do |description|
      file_path = "tmp/glossary/images/#{description.glossary_serial}.jpg"
      if File.exist?(file_path)
        description.update(image: file_path.sub("tmp", ""))
      else
        description.update(image: nil)
      end
    end
  end

  desc "更新 glossary wav 網址"
  task description_glossary_wav: :environment do
    %w[
      南勢阿美語
      秀姑巒阿美語
      海岸阿美語
      馬蘭阿美語
      恆春阿美語
    ].each_with_index do |dict_name, i|
      dictionary = Dictionary.find_by(name: "學習詞表－#{dict_name}")

      dictionary.terms.each do |term|
        term.descriptions.each do |description|
          file_path = "/glossary/wav/#{i+1}/#{description.glossary_serial.sub('-', '_')}.wav"
          term.update(audio: file_path)
        end
      end
    end
  end

  desc "下載原住民族語言線上辭典的 mp3"
  task ilrdf_mp3: :environment do
    i = 0
    ilrdf_array = File.read("tmp/dict/ilrdf.txt").split("\n")
    ilrdf_array.each_with_index do |row, i|
      data = eval(row)["GenericData"]["DATA"]

      # mp3 download
      if data.is_a? Array
        data.each do |datum|
          if datum["File"].present?
            check_and_download(datum["File"]["Path"], "tmp/ilrdf/mp3")
          end
        end
      end

      if data.is_a?(Hash) && data["File"].present?
        check_and_download(data["File"]["Path"], "tmp/ilrdf/mp3")
      end
    end
  end

  desc "下載原住民族語言線上辭典的圖片"
  task ilrdf_images: :environment do
    ilrdf_array = File.read("tmp/dict/ilrdf.txt").split("\n")
    ilrdf_array.each do |row|
      data = eval(row)["GenericData"]["DATA"]

      if data.is_a? Hash
        if data["Explanation"].is_a? Array
          data["Explanation"].each do |ex|
            if ex["Img"].is_a? Array
              ex["Img"].each do |img|
                check_and_download(img["Src"], "tmp/ilrdf/images")
              end
            end

            if ex["Img"].is_a? String
              check_and_download(ex["Img"]["Src"], "tmp/ilrdf/images")
            end

            if ex["Sentence"].is_a? Array
              ex["Sentence"].each do |sentence|
                if sentence["File"].present?
                  check_and_download(sentence["File"]["Path"], "tmp/ilrdf/mp3")
                end
              end
            end

            if ex["Sentence"].is_a?(Hash) && ex["Sentence"]["File"].present?
              check_and_download(ex["Sentence"]["File"]["Path"], "tmp/ilrdf/mp3")
            end
          end
        end

        if data["Explanation"].is_a? Hash
          if data["Explanation"]["Img"].is_a? Array
            data["Explanation"]["Img"].each do |img|
              check_and_download(img["Src"], "tmp/ilrdf/images")
            end
          end

          if data["Explanation"]["Img"].is_a? String
            check_and_download(data["Explanation"]["Img"]["Src"], "tmp/ilrdf/images")
          end

          if data["Explanation"]["Sentence"].is_a? Array
            data["Explanation"]["Sentence"].each do |sentence|
              if sentence["File"].present?
                check_and_download(sentence["File"]["Path"], "tmp/ilrdf/mp3")
              end
            end
          end

          if data["Explanation"]["Sentence"].is_a?(Hash) && data["Explanation"]["Sentence"]["File"].present?
            check_and_download(data["Explanation"]["Sentence"]["File"]["Path"], "tmp/ilrdf/mp3")
          end
        end
      end
    end
  end
end

def check_and_download(url, folder)
  filename  = url.split("/").last
  file_path = File.join(folder, filename)

  return if %w[
    01-34.jpg
    01-38.jpg
    01-39.jpg
    01-40.jpg
    01-41.jpg
    01-42.jpg
    01-43.jpg
    01-44.jpg
    01-45.jpg
    02-01.jpg
    02-02.jpg
    02-03.jpg
    02-04.jpg
    02-05.jpg
    02-06.jpg
    02-07.jpg
    02-08.jpg
    02-09.jpg
    02-10.jpg
    02-11.jpg
    02-12.jpg
    02-13.jpg
    02-14.jpg
    02-15.jpg
    02-16.jpg
    02-17.jpg
    02-18.jpg
    02-19.jpg
    02-20.jpg
    03-01.jpg
    03-02.jpg
    03-03.jpg
    03-04.jpg
    03-05.jpg
    03-06.jpg
    03-07.jpg
    03-08.jpg
    03-09.jpg
    03-10.jpg
    03-11.jpg
    03-12.jpg
    03-13.jpg
    03-14.jpg
    04-03.jpg
    04-06.jpg
    04-13.jpg
    05-01.jpg
    06-09.jpg
    06-25.jpg
    06-26.jpg
    06-29.jpg
    06-30.jpg
    06-32.jpg
    06-35.jpg
    06-36.jpg
    06-37.jpg
    07-29.jpg
    07-36.jpg
    07-40.jpg
    07-45.jpg
    07-57.jpg
    07-58.jpg
    08-28.jpg
    08-35.jpg
    08-50.jpg
    09-21.jpg
    09-28.jpg
    09-30.jpg
    09-31.jpg
    09-46.jpg
    10-21.jpg
    10-22.jpg
    11-33.jpg
    12-12.jpg
    12-19.jpg
    13-01.jpg
    13-03.jpg
    13-04.jpg
    13-05.jpg
    13-06.jpg
    13-08.jpg
    13-09.jpg
    13-10.jpg
    13-12.jpg
    13-13.jpg
    13-14.jpg
    13-15.jpg
    13-16.jpg
    13-17.jpg
    13-18.jpg
    13-19.jpg
    13-20.jpg
    13-21.jpg
    13-22.jpg
    13-23.jpg
    13-24.jpg
    13-25.jpg
    13-26.jpg
    13-27.jpg
    13-28.jpg
    13-29.jpg
    13-30.jpg
    13-31.jpg
    14-01.jpg
    14-02.jpg
    14-03.jpg
    14-04.jpg
    14-05.jpg
    14-06.jpg
    14-07.jpg
    14-08.jpg
    14-09.jpg
    14-12.jpg
    14-13.jpg
    14-14.jpg
    14-15.jpg
    14-16.jpg
    15-02.jpg
    15-05.jpg
    15-13.jpg
    16-09.jpg
    16-10.jpg
    16-12.jpg
    17-01.jpg
    17-02.jpg
    17-03.jpg
    17-05.jpg
    17-06.jpg
    17-07.jpg
    17-08.jpg
    18-05.jpg
    18-06.jpg
    18-08.jpg
    18-13.jpg
    18-14.jpg
    18-15.jpg
    18-18.jpg
    18-19.jpg
    18-20.jpg
    18-22.jpg
    18-25.jpg
    18-26.jpg
    18-27.jpg
    18-30.jpg
    18-31.jpg
    18-32.jpg
    19-01.jpg
    21-03.jpg
    21-11.jpg
    23-02.jpg
    24-01.jpg
    24-02.jpg
    24-03.jpg
    24-04.jpg
    24-05.jpg
    24-06.jpg
    24-07.jpg
    24-08.jpg
    24-09.jpg
    24-10.jpg
    24-11.jpg
    24-12.jpg
    24-13.jpg
    24-14.jpg
    24-15.jpg
    24-16.jpg
    24-17.jpg
    25-01.jpg
    25-02.jpg
    25-03.jpg
    25-04.jpg
    25-05.jpg
    25-06.jpg
    25-07.jpg
    25-08.jpg
    25-09.jpg
    25-10.jpg
    25-15.jpg
    25-16.jpg
    25-17.jpg
    25-18.jpg
    25-19.jpg
    25-20.jpg
    25-21.jpg
    25-22.jpg
    25-23.jpg
    25-24.jpg
    25-25.jpg
    25-26.jpg
    25-27.jpg
    25-28.jpg
    25-29.jpg
    25-30.jpg
    25-32.jpg
    25-33.jpg
    25-34.jpg
    25-36.jpg
    25-37.jpg
    25-38.jpg
    25-42.jpg
    25-46.jpg
    25-47.jpg
    25-48.jpg
    25-49.jpg
    25-50.jpg
    25-52.jpg
    26-03.jpg
    26-04.jpg
    26-06.jpg
    26-10.jpg
    26-17.jpg
    26-22.jpg
    26-24.jpg
    26-25.jpg
    26-26.jpg
    26-28.jpg
    26-30.jpg
    26-32.jpg
    26-46.jpg
    26-47.jpg
    26-48.jpg
    26-51.jpg
    26-52.jpg
    26-53.jpg
    26-54.jpg
    26-57.jpg
    26-59.jpg
    26-60.jpg
    26-61.jpg
    26-62.jpg
    26-63.jpg
    26-66.jpg
    26-67.jpg
    26-68.jpg
    26-69.jpg
    26-70.jpg
    26-71.jpg
    26-73.jpg
    26-75.jpg
    26-76.jpg
    26-79.jpg
    26-80.jpg
    26-81.jpg
    26-84.jpg
    26-85.jpg
    26-86.jpg
    26-88.jpg
    26-98.jpg
    26-101.jpg
    26-103.jpg
    26-104.jpg
    26-105.jpg
    27-02.jpg
    27-10.jpg
    27-11.jpg
    27-12.jpg
    27-13.jpg
    27-16.jpg
    27-17.jpg
    27-18.jpg
    28-01.jpg
    28-02.jpg
    28-05.jpg
    28-06.jpg
    28-07.jpg
    28-08.jpg
    28-09.jpg
    28-10.jpg
    28-11.jpg
    28-12.jpg
    28-13.jpg
    28-14.jpg
    28-15.jpg
    28-16.jpg
    28-18.jpg
    28-21.jpg
    28-23.jpg
    28-24.jpg
    28-25.jpg
    28-26.jpg
    28-27.jpg
    28-29.jpg
    29-01.jpg
    29-02.jpg
    29-03.jpg
    29-04.jpg
    29-05.jpg
    29-06.jpg
    29-07.jpg
    29-08.jpg
    29-09.jpg
    30-01.jpg
    30-03.jpg
    30-04.jpg
    30-05.jpg
    30-06.jpg
    30-07.jpg
    30-10.jpg
    30-15.jpg
    30-20.jpg
    30-21.jpg
    30-22.jpg
    30-24.jpg
    30-25.jpg
    30-26.jpg
    30-27.jpg
    30-28.jpg
    30-29.jpg
    30-30.jpg
    30-31.jpg
    30-32.jpg
    30-33.jpg
    30-35.jpg
    30-39.jpg
    30-40.jpg
    30-41.jpg
    30-42.jpg
    30-44.jpg
    30-45.jpg
    30-47.jpg
    30-48.jpg
    30-49.jpg
    30-50.jpg
    30-51.jpg
    30-52.jpg
    30-53.jpg
    30-55.jpg
    30-56.jpg
    30-57.jpg
    30-63.jpg
    31-01.jpg
    31-02.jpg
    31-03.jpg
    31-04.jpg
    31-05.jpg
    31-06.jpg
    31-08.jpg
    31-10.jpg
    31-11.jpg
    31-12.jpg
    31-13.jpg
    31-17.jpg
    31-18.jpg
    31-20.jpg
    32-11.jpg
    32-12.jpg
    32-13.jpg
    32-15.jpg
    32-17.jpg
    32-18.jpg
    32-21.jpg
    32-22.jpg
    32-23.jpg
    32-24.jpg
    32-25.jpg
    32-26.jpg
    32-27.jpg
    32-28.jpg
    32-29.jpg
    32-30.jpg
    32-31.jpg
    32-32.jpg
    32-33.jpg
    32-34.jpg
    32-35.jpg
    32-36.jpg
    32-37.jpg
    32-38.jpg
    32-40.jpg
    32-41.jpg
    32-43.jpg
    32-44.jpg
    32-45.jpg
    32-46.jpg
    32-47.jpg
    32-48.jpg
    32-50.jpg
    32-51.jpg
    32-52.jpg
    32-53.jpg
    32-54.jpg
    32-56.jpg
    32-57.jpg
    32-58.jpg
    32-59.jpg
    32-61.jpg
    32-62.jpg
    32-63.jpg
    32-64.jpg
    32-65.jpg
    32-66.jpg
    32-67.jpg
    32-68.jpg
    32-69.jpg
    32-70.jpg
    32-71.jpg
    32-72.jpg
    32-73.jpg
    32-74.jpg
    32-75.jpg
    32-76.jpg
    32-77.jpg
    32-78.jpg
    32-79.jpg
    32-80.jpg
    33-01.jpg
    33-02.jpg
    33-03.jpg
    33-04.jpg
    33-05.jpg
    33-06.jpg
    33-07.jpg
    34-01.jpg
    34-02.jpg
    34-03.jpg
    34-04.jpg
    34-05.jpg
    34-06.jpg
    34-07.jpg
    34-08.jpg
    34-09.jpg
    34-10.jpg
    34-11.jpg
    34-12.jpg
    34-13.jpg
    34-14.jpg
    34-15.jpg
    34-16.jpg
    34-17.jpg
    34-18.jpg
    34-19.jpg
    34-21.jpg
    34-22.jpg
    34-23.jpg
    34-24.jpg
    34-25.jpg
    34-26.jpg
    34-27.jpg
    34-28.jpg
    34-29.jpg
    34-30.jpg
    34-31.jpg
    34-32.jpg
    34-33.jpg
    34-34.jpg
    34-35.jpg
    34-36.jpg
    34-37.jpg
    34-38.jpg
    35-01.jpg
    35-02.jpg
    35-03.jpg
    35-04.jpg
    35-05.jpg
    35-06.jpg
    36-01.jpg
    36-02.jpg
    36-03.jpg
    36-04.jpg
    36-05.jpg
    36-06.jpg
    36-07.jpg
    36-08.jpg
    36-09.jpg
    36-10.jpg
    36-11.jpg
    36-12.jpg
    36-13.jpg
    36-14.jpg
    36-15.jpg
    36-16.jpg
    36-17.jpg
    36-18.jpg
    36-19.jpg
    36-20.jpg
    36-21.jpg
    36-22.jpg
    36-23.jpg
    36-24.jpg
    36-25.jpg
    36-26.jpg
    36-27.jpg
    36-28.jpg
    36-29.jpg
    36-30.jpg
    36-31.jpg
    36-32.jpg
    36-33.jpg
    36-34.jpg
    36-35.jpg
    36-36.jpg
    36-37.jpg
  ].include?(filename)

  unless File.exist?(file_path)
    # puts file_path
    download_url = url.gsub(/({|})/) { "\\#{$1}" }
    spawn("curl -O --output-dir #{folder} \"#{download_url}\"")
    # sleep(1)
  end
end
