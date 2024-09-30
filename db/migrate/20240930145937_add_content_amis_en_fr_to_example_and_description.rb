class AddContentAmisEnFrToExampleAndDescription < ActiveRecord::Migration[7.2]
  def change
    change_table :descriptions, bulk: true do |t|
      t.string :content_zh
      t.string :content_en
      t.string :content_fr
    end

    change_table :examples, bulk: true do |t|
      t.string :content_amis
      t.string :content_en
      t.string :content_fr
    end
  end
end
