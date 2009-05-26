class AddReporterWrapperClassToProjectTypes < ActiveRecord::Migration
  def self.up
    add_column :project_types, :reporter_wrapper_class, :string
    ProjectType.all.each { |pt|
      pt.reporter_wrapper_class = "ReportGeo"
      pt.save
    }
  end

  def self.down
    remove_column :project_types, :reporter_wrapper_class
  end
end
