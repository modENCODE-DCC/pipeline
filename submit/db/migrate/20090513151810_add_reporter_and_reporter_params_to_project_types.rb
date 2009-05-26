class AddReporterAndReporterParamsToProjectTypes < ActiveRecord::Migration
  def self.up
    add_column :project_types, :reporter, :string
    add_column :project_types, :reporter_params, :string

    ProjectType.all.each { |pt|
      pt.reporter = "/srv/www/pipeline/submit/script/reporters/modencode/chado2GEO.pl"
      pt.reporter_params = "-config /srv/www/pipeline/submit/script/reporters/modencode/chado2GEO.ini -make_tarball 1"
      pt.save
    }
  end

  def self.down
    remove_column :project_types, :reporter_params
    remove_column :project_types, :reporter
  end
end
