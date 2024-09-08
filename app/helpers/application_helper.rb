# frozen_string_literal: true

module ApplicationHelper
  def title(page_title = nil)
    site_name = "阿美語萌典"

    if page_title.present?
      content_for(:title, page_title)
    else
      if content_for?(:title)
        content_for(:title) + " - #{site_name}"
      else
        site_name
      end
    end
  end

  def description(desc = nil, type: :meta)
    if desc.present?
      content_for(:meta_description, desc)
    else
      if content_for?(:meta_description)
        if type != :og
          content_for(:meta_description)
        else
          if content_for?(:og_description)
            content_for(:og_description)
          else
            safe_truncate_content(content_for(:meta_description), 200)
          end
        end
      else
        "阿美語萌典是一本線上的族語辭典，提供多項方便功能，有助於學習族語者和教學者更輕鬆地找到需要的詞彙和例句，以及原住民族語言保存與發揚。"
      end
    end
  end
end
