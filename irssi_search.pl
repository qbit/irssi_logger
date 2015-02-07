use warnings;
use strict;
use DBI;
use Irssi;
use Irssi::Irc;

use vars qw($VERSION %IRSSI);

# Requirements:
# - postgresql
# - postgresql-contrib (pg_trgm)

$VERSION = "1.0";
%IRSSI = (
    authors     => "Aaron Bieber",
    contact     => "deftly\@gmail.com",
    name        => "irssi_search",
    description => "Searches chats from a PostgreSQL database.",
    license     => "BSD",
    url         => "https://github.com/qbit/irssi_logger",
    );

my $user = $ENV{LOGNAME} || $ENV{USER} || getpwuid($<);
my $dbh;
my $sql = qq~
select
 logdate,
 nick,
 log,
 ts_rank_cd(ts, query) as rank
from logs,
to_tsquery(?) query
where ts @@ query and channel = ? order by rank desc limit 1;
~;

sub query {
    my ($server, $message, $target) = @_;

    if ($message =~ /^:search/) {
	$message =~ s/^:search//;
	my @p = split(' ', $message);
	$message = join(' & ', @p);
    } else {
	return;
}
    my $dbname = Irssi::settings_get_str('il_dbname') || $user;
    my $dbuser = Irssi::settings_get_str('il_dbuser') || $user;
    my $dbpass = Irssi::settings_get_str('il_dbpass') || "";

    my $dbh = DBI->connect("dbi:Pg:dbname=$dbname", $dbuser, $dbpass) || Irssi::print("Can't connect to postgres! " . DBI::errstr);

    my $sth = $dbh->prepare($sql);
    $sth->execute($message, $target);
    my $row = $sth->fetchrow_hashref();

    Irssi::print("$target, $message");

    if ($row) {
	$server->command('msg '.$target. " $row->{logdate} <$row->{nick}> $row->{log}");
    }

    $sth->finish();
    $dbh->disconnect();
}

Irssi::signal_add('message own_public', 'query');

Irssi::settings_add_str('irssi_logger', 'il_dbname', $user);
Irssi::settings_add_str('irssi_logger', 'il_dbuser', $user);
Irssi::settings_add_str('irssi_logger', 'il_dbpass', "");

Irssi::print("irssi_search loaded!");
