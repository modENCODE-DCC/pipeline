class AddPreviewBrowserToProjectTypes < ActiveRecord::Migration
  def self.up
    add_column :project_types, :preview_browser, :string
    add_column :project_types, :preview_params, :string
    ProjectType.all.each { |pt|
      pt.preview_browser = "/srv/www/pipeline/submit/script/preview_browser/scripts/process_uploads.pl"
      pt.save
    }
  end

  def self.down
    remove_column :project_types, :preview_params
    remove_column :project_types, :preview_browser
  end
end
