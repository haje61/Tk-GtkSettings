use strict;
use warnings;

use Test::More tests => 16;
BEGIN { use_ok('Tk::GtkSettings') };

use Tk::GtkSettings qw(
	$delete_output
	$gtkpath
	$verbose
	$out_file
	alterColor
	applyGtkSettings
	convertColorCode
	groupAdd
	groupAll
	groupDelete
	groupExists
	groupMembers
	groupMembersAdd
	groupMembersReplace
	groupOptionAll
	groupOption
	groupOptionDelete
	gtkKey
	gtkKeyAll
	gtkKeyDelete
	hex2rgb
	hexstring
	initDefaults
	loadGtkInfo
	merge2Xdefaults
	rgb2hex
);

$verbose = 0;
$gtkpath = './t/Gtk/';
loadGtkInfo;
my $size = gtkKeyAll;
ok (($size eq 88), "Gtk info loaded");

initDefaults;
my @groups = groupAll;
@groups = sort @groups;
ok ((($groups[0] eq 'content') and ($groups[1] eq 'list') and ($groups[2] eq 'main')), "Groups set");

my $color1 = alterColor('#000000', 1);
ok (($color1 eq '#010101'), 'Alter color');

my $color2 = convertColorCode('rgb(255,255,255)');
ok (($color2 eq '#FFFFFF'), 'Convert color Code');

groupAdd('NewGroup', [], {});
ok ((groupExists('NewGroup')), 'Adding group');

groupDelete('NewGroup');
ok ((not groupExists('NewGroup')), 'Deleting group');

groupDelete('main');
ok ((groupExists('main')), 'Cannot delete main group');

groupMembersAdd(qw[content Member1 Member2]);
my $groupsize1 = groupMembers('content');
ok (($groupsize1 eq 11), 'Adding members');

groupMembersReplace(qw[content Member1 Member2]);
my $groupsize2 = groupMembers('content');
ok (($groupsize2 eq 2), 'Replacing members');

my $optionsize1 = groupOptionAll('content');
ok (($optionsize1 eq 2), 'Groupt content options 1');

groupOption('content', 'blobber', 'blubber');
ok ((groupOption('content', 'blobber') eq 'blubber'), 'Setting option');

my $optionsize2 = groupOptionAll('content');
ok (($optionsize2 eq 3), 'Group content options 2');

groupOptionDelete('content', 'blobber');
ok ((not defined groupOption('content', 'blobber')), 'Deleting option');

gtkKey('blobber', 'blubber');
ok ((gtkKey('blobber') eq 'blubber'), 'Setting gtk key');

gtkKeyDelete('blobber');
ok ((not defined gtkKey('blobber')), 'Deleting gtk key');



