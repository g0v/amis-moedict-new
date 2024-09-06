# frozen_string_literal: true

namespace :snap do
  task create: :environment do
    snapshot_dir = Rails.root.join("tmp")
    db_path = ActiveRecord::Base.connection_db_config.database
    db_filename = db_path.rpartition("/").last

    snap_path = Pathname(snapshot_dir).join(db_filename)
    FileUtils.touch(snap_path)

    source_db = SQLite3::Database.new(db_path)
    destination_db = SQLite3::Database.new(snap_path)
    backup = SQLite3::Backup.new(destination_db, "main", source_db, "main")
    backup.step(-1)
    backup.finish
  end
end
