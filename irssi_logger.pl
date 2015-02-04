use warnings;
use strict;
use DBI;
use Irssi;
use Irssi::Irc;
use POSIX qw/strftime/;

use vars qw($VERSION %IRSSI);

$VERSION = "1.0";
%IRSSI = (
        authors     => "Aaron Bieber",
        contact     => "deftly\@gmail.com",
        name        => "irssi_logger",
        description => "logs everything to a postgresql database",
        license     => "BSD",
        url         => "https://github.com/qbit/irssi_logger",
    );

my $user = $ENV{LOGNAME} || $ENV{USER} || getpwuid($<);
my $dbh;

sub connect_db {
    my $dbname = Irssi::settings_get_str('dbname') || $user;
    my $dbuser = Irssi::settings_get_str('dbuser') || $user;
    my $dbpass = Irssi::settings_get_str('dbpass') || "";

    return DBI->connect("dbi:Pg:dbname=$dbname", $dbuser, $dbpass) || Irssi::print("Can't connect to db!" . DBI::errstr);
}

my $sql = qq~
insert into logs (logdate, nick, log, channel) values (?, ?, ?, ?)
~;

sub log {
    my ($server, $message, $nick, $address, $target) = @_;
    my @vals;

    $dbh = connect_db() unless $dbh;

    push(@vals, strftime("%Y-%m-%d %H:%M:%S", localtime));
    push(@vals, $nick);
    push(@vals, $message);
    push(@vals, $target);

    defined or $_ = "" for @vals;

    $dbh->do($sql, undef, @vals) || Irssi::print("Can't log to DB! " . DBI::errstr);
}

Irssi::signal_add_last('message public', 'log');

Irssi::settings_add_str('irssi_logger', 'dbname', $user);
Irssi::settings_add_str('irssi_logger', 'dbuser', $user);
Irssi::settings_add_str('irssi_logger', 'dbpass', "");

Irssi::print("irssi_logger loaded!");


