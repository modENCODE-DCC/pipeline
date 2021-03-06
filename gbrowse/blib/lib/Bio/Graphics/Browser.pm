package Bio::Graphics::Browser;
# $Id: Browser.pm,v 1.219 2008/11/26 18:33:02 lstein Exp $
# Globals and utilities for GBrowse and friends

use strict;
use warnings;
use base 'Bio::Graphics::FeatureFile';

use File::Spec;
use File::Path 'mkpath';
use File::Basename 'dirname','basename';
use Text::ParseWords 'shellwords';
use File::Path 'mkpath';
use Bio::Graphics::Browser::DataSource;
use Bio::Graphics::Browser::Session;
use GBrowse::ConfigData;
use Carp 'croak','carp';
use CGI 'redirect','url';

my %CONFIG_CACHE;

sub new {
  my $class            = shift;
  my $config_file_path = shift;

  # this code caches the config info so that we don't need to 
  # reparse in persistent (e.g. modperl) environment
  my $mtime            = (stat($config_file_path))[9];
  if (exists $CONFIG_CACHE{$config_file_path}
      && $CONFIG_CACHE{$config_file_path}{mtime} >= $mtime) {
    return $CONFIG_CACHE{$config_file_path}{object};
  }

  my $self = $class->SUPER::new(-file=>$config_file_path);

  # a little trick here -- force the setting of "config_base" from the config file
  # base if not explicitly overridden
  unless ($self->setting('general' => 'config_base')) {
    my $dir = dirname($config_file_path);
    $self->setting('general' => 'config_base',$dir);
  }

  $CONFIG_CACHE{$config_file_path}{object} = $self;
  $CONFIG_CACHE{$config_file_path}{mtime}  = $mtime;
  return $self;
}

## override setting to default to the [general] section
sub setting {
  my $self = shift;
  my @args = @_;
  if (@args == 1) {
    unshift @args,'general';
  }
  elsif (!defined $args[0]) {
    $args[0] = 'general';
  }
  else {
    $args[0] = 'general'
      if $args[0] ne 'general' && lc($args[0]) eq 'general';  # buglet
  }
  $self->SUPER::setting(@args);
}

## methods for dealing with paths
sub resolve_path {
  my $self = shift;
  my $path = shift;
  my $path_type = shift; # one of "config" "htdocs" or "url"
  return unless $path;
  return $path if $path =~ m!^/!;     # absolute path
  return $path if $path =~ m!\|\s*$!; # a pipe
  my $method = ${path_type}."_base";
  $self->can($method) or croak "path_type must be one of 'config','htdocs', or 'url'";
  my $base   = $self->$method or return $path;
  return File::Spec->catfile($base,$path);
}

sub config_path {
  my $self    = shift;
  my $option  = shift;
  $self->resolve_path($self->setting(general => $option),'config');
}

sub htdocs_path {
  my $self    = shift;
  my $option  = shift;
  $self->resolve_path($self->setting(general => $option),'htdocs') 
      || "$ENV{DOCUMENT_ROOT}/gbrowse2";
}

sub url_path {
  my $self    = shift;
  my $option  = shift;
  $self->resolve_path($self->setting(general => $option),'url');
}

sub config_base {$ENV{GBROWSE_CONF} 
		    || eval {shift->setting(general=>'config_base')}
			|| GBrowse::ConfigData->config('conf')
		              || '/etc/GBrowse2' }
sub htdocs_base {eval{shift->setting(general=>'htdocs_base')}
                    || GBrowse::ConfigData->config('htdocs')
		        || '/var/www/gbrowse2'     }
sub url_base    {eval{shift->setting(general=>'url_base')}   
                     || basename(GBrowse::ConfigData->config('htdocs'))
		        || '/gbrowse2'             }

sub tmp_base    {eval{shift->setting(general=>'tmp_base')}
                     || GBrowse::ConfigData->config('tmp')
			|| '/tmp' }
sub db_base     {eval{shift->setting(general=>'db_base')}
                    || GBrowse::ConfigData->config('databases')
			|| '//var/www/gbrowse2/databases' }

# these are url-relative options
sub button_url  { shift->url_path('buttons')            }
sub balloon_url { shift->url_path('balloons')           }
sub js_url      { shift->url_path('js')                 }
sub help_url    { shift->url_path('gbrowse_help')       }
sub stylesheet_url   { shift->url_path('stylesheet')    }

sub make_path {
    my $self = shift;
    my $path = shift;
    return unless $path =~ /^(.+)$/;
    $path = $1;
    mkpath($path,0,0777) unless -d $path;    
}

sub tmpdir {
    my $self       = shift;
    my @components = @_;
    my $path = File::Spec->catfile($self->tmp_base,@components);
    $self->make_path($path) unless -d $path;
    return $path;
}
sub tmpimage_dir {
    my $self  = shift;
    return $self->tmpdir('images',@_);
}

sub image_url {
    my $self = shift;
    my $path = File::Spec->catfile($self->url_base,'i');
    return $path;
}

sub cache_dir {
    my $self  = shift;
    my $path  = File::Spec->catfile($self->tmp_base,'cache',@_);
    $self->make_path($path) unless -d $path;
    return $path;
}

sub session_locks {
    my $self = shift;
    my $path  = File::Spec->catfile($self->tmp_base,'locks',@_);
    $self->make_path($path) unless -d $path;
    return $path;
}

sub session_dir {
    my $self = shift;
    my $path  = File::Spec->catfile($self->tmp_base,'sessions',@_);
    $self->make_path($path) unless -d $path;
    return $path;
}

sub slave_dir {
    my $self = shift;
    my $path = $self->setting(general=>'tmp_slave') || '/tmp/gbrowse_slave';
    $self->make_path($path) unless -d $path;
    return $path;
}

# these are relative to the config base
sub plugin_path    { shift->config_path('plugin_path')     }
sub language_path  { shift->config_path('language_path')   }
sub templates_path { shift->config_path('templates_path')  }
sub moby_path      { shift->config_path('moby_path')       }

sub global_timeout         { shift->setting(general=>'global_timeout')         }
sub remember_source_time   { shift->setting(general=>'remember_source_time')   }
sub remember_settings_time { shift->setting(general=>'remember_settings_time') }
sub cache_time             { shift->setting(general=>'cache time')             }
sub url_fetch_timeout      { shift->setting(general=>'url_fetch_timeout')      }
sub url_fetch_max_size     { shift->setting(general=>'url_fetch_max_size')     }

sub session_driver         { shift->setting(general=>'session driver') || 'driver:file;serializer:default' }
sub session_args    {
  my $self = shift;
  my %args = shellwords($self->setting(general=>'session args')||'');
  return \%args if %args;
  return {Directory=>$self->session_dir};
}

## methods for dealing with data sources
sub data_sources {
  return sort shift->SUPER::configured_types();
}

sub data_source_description {
  my $self = shift;
  my $dsn  = shift;
  $self->setting($dsn=>'description');
}

sub data_source_path {
  my $self = shift;
  my $dsn  = shift;
  $self->resolve_path($self->setting($dsn=>'path'),'config');
}

sub create_data_source {
  my $self = shift;
  my $dsn  = shift;
  my $path = $self->data_source_path($dsn) or return;
  return Bio::Graphics::Browser::DataSource->new($path,$dsn,$self->data_source_description($dsn),$self);
}

sub default_source {
  my $self    = shift;
  my $source  = $self->setting(general => 'default source');
  return $source if $self->valid_source($source);
  return ($self->data_sources)[0];
}

sub valid_source {
  my $self            = shift;
  my $proposed_source = shift;
  return unless exists $self->{config}{$proposed_source};
  my $path =  $self->data_source_path($proposed_source) or return;
  return -e $path || $path =~ /\|\s*$/;
}

sub get_source_from_cgi {
    my $self = shift;

    my $source = CGI::param('source') || CGI::param('src') || CGI::path_info();
    $source    =~ s!^/+!!;  # get rid of leading & trailing / from path_info()
    $source    =~ s!/+$!!;
    
    $source;
}

sub update_data_source {
  my $self    = shift;
  my $session    = shift;
  my $new_source = shift;
  my $old_source = $session->source || $self->default_source;

  $new_source ||= $self->get_source_from_cgi();

  my $source;
  if ($self->valid_source($new_source)) {
    $session->source($new_source);
    $source = $new_source;
  } else {
    carp "Invalid source $new_source";
    my $fallback_source = $self->valid_source($old_source) 
	? $old_source
	: $self->default_source;
    $session->source($fallback_source);
    $source = $fallback_source;
  }

  return $source;
}

## methods for dealing with the session
sub session {
  my $self = shift;
  my $id   = shift;
  return Bio::Graphics::Browser::Session->new(driver  => $self->session_driver,
					      id      => $id||undef,
					      args    => $self->session_args,
					      source  => $self->default_source,
					      lockdir => $self->session_locks,
					     );
}

1;
