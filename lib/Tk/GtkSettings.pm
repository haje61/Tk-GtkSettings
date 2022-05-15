package Tk::GtkSettings;

use strict;
use warnings;
our $VERSION = '0.01';

use Exporter;
our @ISA = qw(Exporter);
our %EXPORT_TAGS = ( 'all' => [ qw(
	$delete_output
	$gtkpath
	$verbose
	$out_file
	alterColor
	appName
	applyGtkSettings
	convertColorCode
	export2file
	export2Xdefaults
	export2Xresources
	export2xrdb
	groupAdd
	groupAll
	groupDelete
	groupExists
	groupMembers
	groupMembersAdd
	groupMembersReplace
	groupOption
	groupOptionAll
	groupOptionDelete
	gtkKey
	gtkKeyAll
	gtkKeyDelete
	hex2rgb
	hexstring
	initDefaults
	loadGtkInfo
	platformPermitted
	removefromFile
	removeFromXdefaults
	removeFromXresources
	removeFromxrdb
	resetAll
	rgb2hex
) ] );
our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} });

sub appName;
sub generateOutput;
sub loadGtkInfo;
sub platformPermitted;
sub resetAll;

our $delete_output = 1;
our $gtkpath;
our $verbose = 0;
our $out_file;

if (platformPermitted) {
	$gtkpath = $ENV{HOME} . "/.config/gtk-3.0/";
	$out_file = $ENV{HOME} . "/.tkgtk";
}

my $no_gtk = 0;
my %gtksettings = ();
my %groups = (main => [[''], {}]);
my $app_name = $0;
my $marker;

my @contentwidgets = qw(
	CodeText
	Entry
	FloatEntry
	PodText
	Spinbox
	Text
	TextUndo
	TextEditor
	ROText
);

my @listwidgets = qw(
	Dirlist
	DirTree
	HList
	IconList
	Listbox
	Tlist
	Tree
);

my %mainoptions = qw(
	background           theme_bg_color
	foreground           theme_fg_color
	font                 gtk-font-name
	activeBackground     tk-active-background
	activeForeground     theme_fg_color
	backPageColor        tk-through-color
	highlightBackground  theme_bg_color
	highlightColor			theme_hovering_selected_bg_color
	inactiveBackground   tk-through-color
	insertBackground     theme_fg_color
	selectBackground     theme_selected_bg_color
	selectForeground     theme_selected_fg_color
	troughColor          tk-through-color
);

my %contentoptions = qw(
	background           content_view_bg
	highlightColor			theme_bg_color
);

my %listoptions = qw(
	background           content_view_bg
	highlightColor			theme_bg_color
);


appName($0);


sub alterColor {
	my ($hex, $offset) = @_;
	my @rgb = hex2rgb($hex);
	my @rgba = ();
	for (@rgb) {
		if ($_ < 128) {
			my $c = $_ + $offset;
			$c = 0 if $c < 0;
			push @rgba, $c
		} else {
			my $c = $_ - $offset;
			$c = 255 if $c > 255;
			push @rgba, $c
		}
	}
	return rgb2hex(@rgba)
}

sub appName {
	if (@_ ) {
		$app_name = shift;
		$marker = "!$app_name Tk::GtkSettings section\n";
	}
	return $app_name
}

sub convertColorCode {
	my $input = shift;
	if ($input =~ /rgb\((\d+),(\d+),(\d+)\)/) {
		my $r = substr(sprintf("0x%X", $1), 2);
		my $g = substr(sprintf("0x%X", $2), 2);
		my $b = substr(sprintf("0x%X", $3), 2);
		return "#$r$g$b"
	}
}

sub export2file {
	my ($file, $remove) = @_;
	return if $no_gtk;
	return unless platformPermitted;
	$remove = 0 unless defined $remove;
	my $out = "";
	my $found = 0;
	if (-e $file) {
		unless (open(XDEF, "<$file")) { 
			warn "cannot open $file" if $verbose;
			return
		}
		my $inside = 0;
		while (my $l = <XDEF>) {
			if ($inside) {
				if ($l eq $marker) {
					$inside = 0;
				}
			} else {
				if ($l eq $marker) {
					$inside = 1;
					$found = 1;
					$out = "$out$l" . generateOutput . $l unless $remove;
				} else {
					$out = "$out$l";
				}
			}
		}
		close XDEF;
	}
	unless ($found) {
		$out = "$out\n$marker" . generateOutput . "$marker\n"
	}
	unless (open(XDEFO, ">$file")) { 
		warn "cannot open $file" if $verbose;
		return
	}
	print XDEFO $out;
	close XDEFO;
}

sub export2Xdefaults {
	export2file('~/.Xdefaults');
}

sub export2Xresources {
	export2file('~/.Xresources');
}

sub export2xrdb {
	return unless platformPermitted;
	return if $no_gtk;
	if (open(OFILE, ">", $out_file)) {
		print OFILE generateOutput;
		close OFILE;
		system "xrdb $out_file";
		unlink $out_file if $delete_output;
	}
}

sub generateOutput {
	return if $no_gtk;
	return unless platformPermitted;
	my $output = '';
	for (sort keys %groups) {
		my $name = $_;
		my $group = $groups{$name};
		my $options = $group->[1];
		my $mem = $group->[0];
		for (@$mem) {
			my $member = $_;
			for (sort keys %$options) {
				my $val = gtkKey($options->{$_});
				$val = $_ unless defined $val;
				unless ($name eq 'main') {
					$output = $output . $app_name . "*$member." . $_ . ": " . $val . "\n";
				} else {
					$output = $output . $app_name . '*' . $_ . ": " . $val . "\n";
				}
			}
		}
	}
	return $output
}

sub groupAdd {
	my ($group, $members, $options) = @_;
	unless (defined $group) {
		warn "group is not defined" if $verbose;
		return
	}
	$members = [] unless defined $members;
	$options = {} unless defined $options;
	unless (exists $groups{$group}) {
		$groups{$group} = [$members, $options]
	} else {
		warn "group $group already exists" if $verbose
	}
}

sub groupAll {
	return keys %groups
}

sub groupDelete {
	my $group = shift;
	if (groupExists($group)) {
		if ($group eq 'main') {
			warn "deleting main group is not allowed" if $verbose;
			return 0
		}
		delete $groups{$group};
	}
	return 1
}

sub groupExists {
	my $group = shift;
	unless (defined $group) {
		warn "group not specified or is not defined" if $verbose;
		return 0
	}
	unless (exists $groups{$group}) {
		warn "group $group does not exist" if $verbose;
		return 0
	}
	return 1
}

sub groupMembers {
	my $group = shift;
	if (groupExists($group)) {
		if ($group eq 'main') {
			warn "no access to main group members";
			return
		}
		my $l = $groups{$group}->[0];
		return @$l;
	}
}

sub groupMembersAdd {
	my $group = shift;
	if (groupExists($group)) {
		if ($group eq 'main') {
			warn "no access to main group members";
			return
		}
		my $l = $groups{$group}->[0];
		push @$l, @_;
	}
}

sub groupMembersReplace {
	my $group = shift;
	if (groupExists($group)) {
		if ($group eq 'main') {
			warn "no access to main group members";
			return
		}
		my $l = $groups{$group}->[0];
		@$l = @_;
	}
}

sub groupOptionAll {
	my $group = shift;
	if (groupExists($group)) {
		my $opt = $groups{$group}->[1];
		return keys %$opt
	}
}

sub groupOption{
	my $group = shift;
	if (groupExists($group)) {
		my $option = shift;
		unless (defined $option) { 
			warn "option not defined or specified" if $verbose;
			return
		}
		if (@_) {
			my $value = shift;
			$groups{$group}->[1]->{$option} = $value;
		}
		return $groups{$group}->[1]->{$option}
	}
}

sub groupOptionDelete {
	my $group = shift;
	if (groupExists($group)) {
		my $option = shift;
		unless (defined $option) { 
			warn "option not defined or specified" if $verbose;
			return
		}
		delete $groups{$group}->[1]->{$option};
	}
}

sub gtkKey {
	my ($key, $val) = @_;
	return undef if $no_gtk;
	$gtksettings{$key} = $val if defined $val;
	if (exists $gtksettings{$key}) {
		return $gtksettings{$key}
	} else {
		warn "item $key not present in gtk settings" if $verbose;
	}
	return undef
}

sub gtkKeyAll {
	return 0 if $no_gtk;
	return keys %gtksettings
}

sub gtkKeyDelete {
	my $key = shift;
	return 0 if $no_gtk;
	if (exists $gtksettings{$key}) {
		delete $gtksettings{$key}
	} else {
		warn "item $key not present in gtk settings" if $verbose;
	} 
}

sub initDefaults {
	resetAll;
	loadGtkInfo;
	gtkKey('tk-active-background', alterColor(gtkKey('theme_bg_color'), 20));
	gtkKey('tk-through-color', alterColor(gtkKey('theme_bg_color'), 20));
	for (keys %mainoptions) {
		groupOption('main', $_, $mainoptions{$_})
	}
	my @cw = @contentwidgets;
	my %co = %contentoptions;
	groupAdd('content', \@cw, \%co);
	my @lw = @listwidgets;
	my %lo = %listoptions;
	groupAdd('list', \@lw, \%lo);
}

sub hex2rgb {
	my $hex = shift;
	$hex =~ s/^(\#|Ox)//;
	$_ = $hex;
	my ($r, $g, $b) = m/(\w{2})(\w{2})(\w{2})/;
	my @rgb = ();
	$rgb[0] = CORE::hex($r);
	$rgb[1] = CORE::hex($g);
	$rgb[2] = CORE::hex($b);
	return @rgb
}

sub hexstring {
	my $num = shift;
	my $hex = substr(sprintf("0x%X", $num), 2);
	if (length($hex) < 2) { $hex = "0$hex" }
	return $hex
}

sub loadGtkInfo {
	%gtksettings = ();
	my $cf = $gtkpath . "colors.css";
	if (open(OFILE, "<", $cf)) {
		while (<OFILE>) {
			my $line = $_;
			if ($line =~ s/\@define-color\s//) {
				if ($line =~ /([^\s]+)\s([^;]+);/) {
					my $key = $1;
					my $color = $2;
					$color = convertColorCode($color) if $color =~ /^rgb\(/;
					$gtksettings{$key} = $color
				}
			}
		}
		close OFILE
	} else {
		warn "cannot open Gtk colors.css" if  $verbose;
		$no_gtk = 1;
	}
	my $sf = $gtkpath . "settings.ini";
	if (open(OFILE, "<", $sf)) {
		while (<OFILE>) {
			my $line = $_;
			if ($line =~ /([^=]+)=([^\n]+)/) {
				$gtksettings{$1} = $2
			}
		}
		close OFILE;
		if (exists $gtksettings{'gtk-font-name'}) {
			my $rawfont = $gtksettings{'gtk-font-name'};
			if ($rawfont =~ /(\D+)(\d+)/) {
				my $name = $1;
				my $size = $2;
				$name =~ s/\s!//;
				$name =~ s/,//;
				$name =~ s/\s/-/;
				$gtksettings{'gtk-font-name'} = "$name $size";
			}
		}
	} else {
		warn "cannot open Gtk settings.ini" if $verbose;
		$no_gtk = 1;
	}
}

sub platformPermitted {
	my $platform = $^O;
	return 0 if (($^O eq 'MSWin32') or ($^O eq 'darwin'));
	return 1
}

sub removeFromfile {
	my $f = shift;
	export2file($f, 1);
}

sub removeFromXdefaults {
	export2file('~/.Xdefaults', 1);
}

sub removeFromXresources {
	export2file('~/.Xresouces', 1);
}

sub removeFromxrdb {
	return unless platformPermitted;
	return if $no_gtk;
	if (open(OFILE, ">", $out_file)) {
		print OFILE generateOutput;
		close OFILE;
		system "xrdb -remove $out_file";
		unlink $out_file if $delete_output;
	}
}

sub resetAll {
	%groups = (
		main => [[''], {}]
	)
}

sub rgb2hex {
	my ($red, $green, $blue) = @_;
	my $r = hexstring($red);
	my $g = hexstring($green);
	my $b = hexstring($blue);
	return "#$r$g$b"

}

1;
__END__
