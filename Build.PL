use strict;

use 5.005;

use lib 'inc';

use AlzaboGUI::Mason::Build;

use File::Basename;
use File::Path;
use File::Spec;

config() unless grep { $_ eq '--dist' } @ARGV;

my $build =
    AlzaboGUI::Mason::Build->new( dist_name => 'AlzaboGUI-Mason',
				  dist_version => 0.03,
				  license   => 'perl',
				  requires  => { 'HTML::Mason' => 0.896,
						 'HTTP::BrowserDetect' => 0,
					       },
				);

$build->create_build_script;

sub config
{
    my $config;
    if ( eval { require AlzaboGUI::Mason::Config; 1; } )
    {
	$config = \%AlzaboGUI::Mason::Config::CONFIG;
    }
    elsif ( eval { require Alzabo::Config; 1; } )
    {
	$config = \%Alzabo::Config::CONFIG;
    }

    my $default = $config->{mason_web_dir};
    $default =~ s,/alzabo\Z,, if $default;

    do
    {
	print "\n *** The directory you selected does not exist ***\n"
	    if defined $config->{mason_web_dir};

	print <<'EOF';

Where would you like to install the mason components for this
interface (this must be under your component root)?  NOTE: The
installer will create an 'alzabo' subdirectory under the directory
given.
EOF

	$config->{mason_web_dir} =
	    Module::Build->prompt( '  Mason directory?', $default || '' );
    } while ( ! -d $config->{mason_web_dir} );

    $config->{mason_web_dir} = File::Spec->catdir( $config->{mason_web_dir}, 'alzabo' );

    print <<'EOF';

You can pick a custom file extension for the mason components.  Only
components called as top level components will be given this
extension.  Components intended only for use by other components have
no extension at all
EOF


    $config->{mason_extension} =
	Module::Build->prompt( '  Mason component file extension?',
			       $config->{mason_extension} || '.mhtml' );

    write_config_module($config);
}

sub write_config_module
{
    my $config = shift;

    my @keys =
        qw( mason_web_dir mason_extension );

    my $file = File::Spec->catfile( 'inc', 'AlzaboGUI', 'Mason', 'Config.pm.tmpl' );
    local *MOD;
    open MOD, "<$file"
	or die "can't open $file: $!\n";
    my $mod = join '', <MOD>;
    close MOD
	or die "can't close $file: $!\n";

    my $c = "(\n";
    foreach my $k (@keys)
    {
	my $val;
	if ( length $config->{$k} )
	{
	    $val = "'$config->{$k}'";
	}
	else
	{
	    $val = "undef";
	}

	$c .= "'$k' => $val,\n";
    }
    $c .= ")";

    $mod =~ s/"'CONFIG'"/$c/;

    my $config = File::Spec->catfile( 'lib', 'AlzaboGUI', 'Mason', 'Config.pm' );

    File::Path::mkpath( File::Basename::dirname($config), 1, 0755 );

    open MOD, ">$config"
	or die "can't write to $config: $!\n";
    print MOD $mod
	or die "can't write to $config: $!\n";
    close MOD
	or die "can't close $config: $!\n";
}
