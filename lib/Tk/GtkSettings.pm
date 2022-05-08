package Tk::GtkSettings.pm;

use strict;
use warnings;

use Exporter;
our @ISA = qw(Exporter);
use Tk;


our @EXPORT_OK = qw(
	%gtkcolors
	%gtksettings
	LoadGtkInfo
);

our @EXPORT = qw(
);

our $VERSION = '0.01';

my $gtkpath = $ENV{HOME} . "/.config/gtk-3.0/";

our %gtksettings = ();

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
	DirTree
	HList
	IconList
	Listbox
	Tlist
	Tree
);

my %namecollection = qw(
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

my %contentcollection = qw(
	background           content_view_bg
	highlightColor			theme_bg_color
);

my %listcollection = qw(
	background           content_view_bg
	highlightColor			theme_bg_color
);

my $file = $ENV{HOME} . "/.tkgtk";

sub CollectGtkSettings {
# 	if (-e $file) {
# 		system "xrdb -remove $file"
# 	}
	if (open(OFILE, ">", $file)) {
		for (keys %namecollection) {
			print OFILE '*' . $_ . ": ", $gtksettings{$namecollection{$_}}, "\n";
		}
		for (@contentwidgets) {
			my $cw = $_;
			for (keys %contentcollection) {
				print OFILE "*$cw." . $_ . ": ", $gtksettings{$contentcollection{$_}}, "\n";
			}
		}
		for (@listwidgets) {
			my $cw = $_;
			for (keys %listcollection) {
				print OFILE "*$cw." . $_ . ": ", $gtksettings{$listcollection{$_}}, "\n";
			}
		}
		close OFILE;
		system "xrdb $file"
	}
}

sub ConvertColorCode {
	my $input = shift;
	if ($input =~ /rgb\((\d+),(\d+),(\d+)\)/) {
		my $r = substr(sprintf("0x%X", $1), 2);
		my $g = substr(sprintf("0x%X", $2), 2);
		my $b = substr(sprintf("0x%X", $3), 2);
		return "#$r$g$b"
	}
}

sub LoadGtkInfo {
	my $cf = $gtkpath . "colors.css";
	if (open(OFILE, "<", $cf)) {
		print "colors.css open\n";
		while (<OFILE>) {
			my $line = $_;
			if ($line =~ s/\@define-color\s//) {
				if ($line =~ /([^\s]+)\s([^;]+);/) {
					my $key = $1;
					my $color = $2;
					$color = ConvertColorCode($color) if $color =~ /^rgb\(/;
					$gtksettings{$key} = $color
				}
			}
		}
		close OFILE
	} else {
		warn "cannot open Gtk colors.css"
	}
	my $sf = $gtkpath . "settings.ini";
	if (open(OFILE, "<", $sf)) {
		while (<OFILE>) {
			my $line = $_;
			if ($line =~ /([^=]+)=([^\n]+)/) {
				$gtksettings{$1} = $2
			}
		}
		close OFILE
	} else {
		warn "cannot open Gtk settings.ini"
	}
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

sub rgb2hex {
	my ($red, $green, $blue) = @_;
	my $r = hexstring($red);
	my $g = hexstring($green);
	my $b = hexstring($blue);
	return "#$r$g$b"

}

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

LoadGtkInfo;

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
$gtksettings{'tk-active-background'} = alterColor($gtksettings{'theme_bg_color'}, -20);
$gtksettings{'tk-through-color'} = alterColor($gtksettings{'theme_bg_color'}, 20);

CollectGtkSettings;

1;
__END__
