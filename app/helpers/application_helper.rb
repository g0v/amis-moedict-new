# frozen_string_literal: true

module ApplicationHelper
  def title(page_title = nil)
    if page_title.present?
      content_for(:title, page_title)
    else
      if content_for?(:title)
        content_for(:title) + " - 阿美語萌典"
      else
        "阿美語萌典"
      end
    end
  end

  def description(desc = nil)
    if desc.present?
      content_for(:meta_description, desc)
    else
      if content_for?(:meta_description)
        content_for(:meta_description)
      else
        "阿美語萌典是一本線上的族語辭典，提供多項方便功能，有助於學習族語者和教學者更輕鬆地找到需要的詞彙和例句，以及原住民族語言保存與發揚。"
      end
    end
  end

  def canonical(url = nil)
    if url.present?
      content_for(:canonical, url)
    else
      if content_for?(:canonical)
        content_for(:canonical)
      else
        request.url
      end
    end
  end
end
