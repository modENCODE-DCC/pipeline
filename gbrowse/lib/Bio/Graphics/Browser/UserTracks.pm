package Bio::Graphics::Browser::UserTracks;

# $Id: UserTracks.pm,v 1.3 2009/08/27 19:13:19 idavies Exp $
use strict;
use Bio::Graphics::Browser::DataSource;
use File::Spec;
use File::Basename 'basename';
use File::Path 'mkpath','rmtree';
use Carp 'croak';

# The intent of this is to provide a single unified interface for managing
# a user's uploaded and shared tracks.

# It works on the basis of a file-based database with the following structure:
#    base      -- e.g. /var/tmp/gbrowse2/userdata
#    uploadid  -- e.g. dc39b67fb5278c0da0e44e9e174d0b40
#    source    -- e.g. volvox
#    concatenated path /var/tmp/gbrowse2/userdata/volvox/dc39b67fb5278c0da0e44e9e174d0b40

# The concatenated path contains a series of directories named after the track.
# Each directory has a .conf file that describes its contents and configuration.
# There will also be data files associated with the configuration.

sub new {
    my $self = shift;
    my ($config,$state,$lang) = @_;

    return bless {
	config   => $config,
	state    => $state,
	language => $lang,
    },ref $self || $self;
}

sub config   { shift->{config}    }
sub state    { shift->{state}     }    
sub language { shift->{language}  }

sub path {
    my $self   = shift;
    $self->config->userdata($self->state->{uploadid});
}

sub tracks {
    my $self = shift;
    my $path = $self->path;
    my @result;
    opendir D,$path;
    while (my $dir = readdir(D)) {
	next if $dir =~ /^\.+$/;
	push @result,$dir;
    }
    return @result;
}

sub conf_files {
    my $self = shift;
    my $path = $self->path;
    return grep {-e $_} map {File::Spec->catfile($path,$_,"$_.conf")} $self->tracks;
}

sub track_path {
    my $self  = shift;
    my $track = shift;
    return File::Spec->catfile($self->path,$track);
}

sub track_conf {
    my $self  = shift;
    my $track = shift;
    return File::Spec->catfile($self->path,$track,"$track.conf");
}

sub delete_track {
    my $self  = shift;
    my $track = shift;

    # remove all path elements from track (security)
    $track = basename($track);

    my $dir  = File::Spec->catfile($self->path,$track);
    rmtree($dir);
}

sub trackname_from_url {
    my $self = shift;
    my $url  = shift;

    (my $track_name = $url) =~ tr!a-zA-Z0-9_%^@.!_!cs;

    mkpath $self->track_path($track_name);
    return $track_name;
}

sub add_remote_track {
    my $self = shift;
    my $url  = shift;

    my $key  = "Shared track from $url";
    my $track_name = $self->trackname_from_url($url);

    my $conf = $self->track_conf($track_name);
    open my $f,">",$conf or croak "Couldn't open $conf: $!";
    print $f <<END;
[$track_name]
remote feature = $url
category = My Tracks:Remote Tracks
key      = $key
END
    close $f;
}

sub upload_track {
    my $self = shift;
    my ($file_name,$fh) = @_;
    
    my $track_name = $self->trackname_from_url($file_name);

    # guess the file type from the first non-blank line
    my ($type,$lines)   = $self->guess_upload_type($fh);

    croak "Could not guess the type of the file $file_name"
	unless $type;

    my $loader = $self->get_loader($type);
    my $load   = $loader->new($track_name,
			      $self->track_path($track_name),
			      $self->track_conf($track_name),
			      $self->config,
	);
    $load->load($lines,$fh);
}

sub get_loader {
    my $self   = shift;
    my $type   = shift;
    my $module = "Bio::Graphics::Browser::DataLoader::$type";
    eval "require $module; 1" or croak $@;
    return $module;
}

sub guess_upload_type {
    my $self = shift;
    my $fh   = shift;

    my @lines;
    while (my $line = <$fh>) {
	push @lines,$line;
	return ('featurefile',\@lines) if $line =~ /^\[.+\]$/;
	return ('gff2',\@lines)        if $line =~ /^\#\#gff-version\s+2/;
	return ('gff3',\@lines)        if $line =~ /^\#\#gff-version\s+3/;
	return ('wiggle',\@lines)      if $line =~ /type=wiggle/;
	return ('bed',\@lines)         if $line =~ /^\w+\s+\d+\s+\d+/;
	return ('sam',\@lines)         if $line =~ /^\@[A-Z]{2}/;
	return ('sam',\@lines)         if $line =~ /^[^ \t\n\r]+\t[0-9]+\t[^ \t\n\r@=]+\t[0-9]+\t[0-9]+\t(?:[0-9]+[MIDNSHP])+|\*/;
	return ('bam',\@lines)         if $line =~ /^BAM\001/;
    }

    return;
}

1;
