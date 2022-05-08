
use strict;
use warnings;

use Test::More tests => 1;
BEGIN { use_ok('Tk::Gtk') };

use Tk;
# use Tk::Xrm;
use Tk::Gtk qw(%gtkcolors %gtksettings LoadGtkInfo);
require Tk::NoteBook;
require Tk::Pane;

my $app = MainWindow->new;
my $nb = $app->NoteBook->pack(-expand => 1, -fill => 'both');
my $gtk = $nb->add('GtkSettings', -label => 'GtkSettings');
my $wdg = $nb->add('Widgets', -label => 'Widgets');

my $pan = $gtk->Scrolled('Pane', -width => 500, -height => 400)->pack(-expand => 1, -fill => 'both');

my $row = 0;
for (sort keys %gtksettings) {
	$pan->Entry(-width => 30, -text => $_)->grid(-row => $row, -column => 0);
	my $val = $gtksettings{$_};
	if ($val =~ /^#(?:[0-9a-fA-F]{3}){1,2}$/) {
		$pan->Label(-width => 20, -background => $val)->grid(-row => $row, -column => 1);
	} else {
		$pan->Label(-width => 20, -text => $val)->grid(-row => $row, -column => 1);
	}
	$row ++
}


my $panw = $wdg->Scrolled('Pane', -width => 500, -height => 400)->pack(-expand => 1, -fill => 'both');

$panw->Button(-text => 'Button')->grid(-row => 0, -column => 0);
$panw->Entry(-text => 'Entry')->grid(-row => 0, -column => 1);

$app->MainLoop;
