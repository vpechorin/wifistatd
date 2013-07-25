#!/usr/bin/perl -w

# WiFistatd - v. 0.1a

# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
# 

use POSIX;
use RRDs;

#
# Basic setup
#

my $iface               = 'eth1';   # wireless interface
my $step                = 10;       # sec
my $next1_factor        = 60;       # $step * $next1_factor = 10*60  = 600 sec  = 10 min
my $next2_factor        = 360;      # $step * $next2_factor = 10*360 = 3600 sec = 1 hour
my $update_graph_period = 10;       # How often will be graph updated (1..1000)

#
# Setup files locations
# 

my $wifi_proc_file='/proc/net/wireless';
my $rrd='./db01.rrd';
my $output_image='res.png';
my $pid_file='./wifistatd.pid';

#
# End setup
#
############################################################

my $start=time;
my $switcher=$ARGV[0];
if (!($switcher)) { $switcher='undef'; }

if ($switcher eq 'start') {
    &start();
}
elsif ($switcher eq 'stop') {
    &stop();
}
elsif ($switcher eq 'graph') {
    &update_graph();
}
elsif ($switcher eq 'install') {
    &install();
}
else {
    print qq(Usage: ./wifistatd.pl option
    option: start   - Starting daemon
            stop    - Stopping daemon
            graph   - Get the latest graph
            install - Init database);
    print "\n";
}

###############################################################
sub install {
    my $sec_in_the_day=86400;
    my $sec_in_the_week=$sec_in_the_day*7;
    my $sec_in_the_month=$sec_in_the_day*31;
    my $minvalue=0;
    my $maxvalue=255;
    my $xfiles_factor=0.5;
    my $max_interval=$step/$xfiles_factor;
    my $number_steps_day=floor($sec_in_the_day/$step);
    my $number_steps_week=floor($sec_in_the_week/($step*$next1_factor));
    my $number_steps_month=floor($sec_in_the_month/($step*$next2_factor));
    RRDs::create ($rrd, "--start",$start-1, "--step",$step,
          "DS:link:GAUGE:$max_interval:$minvalue:$maxvalue",
          "DS:level:GAUGE:$max_interval:$minvalue:$maxvalue",
          "DS:noise:GAUGE:$max_interval:$minvalue:$maxvalue",
          "RRA:AVERAGE:$xfiles_factor:1:$number_steps_day",
          "RRA:AVERAGE:$xfiles_factor:$next1_factor:$number_steps_week",
          "RRA:AVERAGE:$xfiles_factor:$next2_factor:$number_steps_month");
    my $ERROR = RRDs::error;
    die "$0: unable to create `$rrd': $ERROR\n" if $ERROR;
    print "Done.\n";
}

###############################################################
sub start {
    $pid=fork;
    exit if $pid;
    die "Could't fork: $!" unless defined($pid);
    POSIX::setsid() or die "Can't start a new session: $!";
    $SIG{INT}=$SIG{TERM}=$SIG{HUP}=\&syncro_handler;
    $syncrorun=1;
    my $pid_id=$$;
    open(FILE, ">>$pid_file") || die "Cant write to $pid_file file: $!";
    print FILE $pid_id;
    close(FILE);
    my $counter=0;
    while ($syncrorun) {
        $counter++;
        if (!( -e $pid_file)) { $syncrorun=0; }
        &get_data();
        if ($counter == $update_graph_period) {
            &update_graph();
            $counter=0;
        }
        sleep($step);
    }
}

##############################################################
sub stop {
    my $pid=`cat $pid_file`;
    `kill $pid`;
}

##############################################################
sub update_graph {
    RRDs::graph "$output_image",
      "--title", " $iface statistics",
      "--start", "now-10h",
      "--end", "now",
      "--lower-limit=0",
      "--interlace",
      "--imgformat","PNG",
      "--width=450",
      "DEF:link=$rrd:link:AVERAGE",
      "DEF:level=$rrd:level:AVERAGE",
      "DEF:noise=$rrd:noise:AVERAGE",
      "AREA:link#00b6e4:link",
      "LINE1:level#0022e9:level",
      "LINE1:noise#cc0000:noise"
    ;
    if ($ERROR = RRDs::error) { print "ERROR: $ERROR\n"; };
}

###############################################################
sub get_data {
    open(FILE, "$wifi_proc_file") || die "Cant open $wifi_proc_file file: $!";
    while (my $line=<FILE>) {
        if ($line=~/\s*?$iface\:\s+?\d+?\s+?(\d+)\.*?\d*?\s+?(\d+)\.*?\d*?\s+?(\d+)\.*?\d*?.*/) {
            # $1 - link, $2 - level, $3 - noise
            RRDs::update ("$rrd", "--template", "link:level:noise", "N:$1:$2:$3");
            if ($ERROR = RRDs::error) { print "ERROR: $ERROR\n"; };
        }
    }
    close(FILE);
}

###############################################################
sub syncro_handler {
    unlink($pid_file) || die "Cant unlink $pid_file file: $!";
    $syncrorun=0;
}
