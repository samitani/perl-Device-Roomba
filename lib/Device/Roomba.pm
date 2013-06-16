#!/usr/bin/perl -w

package Device::Roomba;

use strict;
use warnings;
use vars '$VERSION';
use Carp;
use Time::HiRes qw( sleep );

$VERSION = '1.0.0';

sub Version {
    our $VERSION;
}

sub new {
    my $pkg  = shift;
    my $hash = shift;

    if (!-e $hash->{'port'}) {
        return undef;
    }

    my $stty_args = '115200 raw -parenb -parodd cs8 -hupcl -cstopb clocal';
    # pick operating system (in case there are people using Linux for this)
    my $port = $hash->{'port'};
    my $uname = `uname`; chomp $uname;
    if( $uname eq 'Linux' ) {
        print "stty -F $port $stty_args\n";
        system("stty -F $port $stty_args");
    } elsif( $uname eq 'Darwin' ) {  # aka Mac OS X
        system("stty -f $port $stty_args");
    }

    open my $roomba, "+>$port" or die "couldn't open port: $!";

    select $roomba;
    $| =1;  # make unbuffered

    $hash->{'roomba'} = $roomba;

    bless $hash, $pkg;
}

sub start() {
    my $self = shift;

    my $roomba = $self->{'roomba'};
    print $roomba "\x80\x82"; # start and control
}

sub baud() {
    my $self = shift;

    croak 'not implement yet.';
} 

sub safe() {
    my $self = shift;

    my $roomba = $self->{'roomba'};
    print $roomba "\x83";
}

sub full() {
    my $self = shift();

    my $roomba = $self->{'roomba'};
    print $roomba "\x84";
}

sub clean() {
    my $self = shift;

    my $roomba = $self->{'roomba'};
    print $roomba "\x87";
}

sub max() {
    my $self = shift;

    my $roomba = $self->{'roomba'};
    print $roomba "\x88";
}

sub spot() {
    my $self = shift;

    my $roomba = $self->{'roomba'};
    print $roomba "\x86";
}

sub seek_dock() {
    my $self = shift;

    my $roomba = $self->{'roomba'};
    print $roomba "\x8f";
}

sub schedule() {
    my $self = shift;

    croak 'not implement yet.';
}

sub set_clock() {
    my $self = shift;

    croak 'not implement yet.';
}

sub power_off($) {
    my $self = shift;
    my $roomba = $self->{'roomba'};
    print $roomba "\x85";
}

sub drive() {
    my $self = shift();
    my $vel = shift();
    my $rad = shift();

    my $vh = ($vel>>8)&0xff;  my $vl = ($vel&0xff);
    my $rh = ($rad>>8)&0xff;  my $rl = ($rad&0xff);

    my $roomba = $self->{'roomba'};
    printf $roomba "\x89%c%c%c%c", $vh,$vl,$rh,$rl;      # DRIVE + 4 databytes
}

sub led() {
    my $self = shift;

    croak 'not implement yet.';
}

sub scheduling_led() {
    my $self = shift;

    croak 'not implement yet.';
}

sub digit_led_raw() {
    my $self = shift;

    croak 'not implement yet.';
}

sub digit_led_ascii() {
    my $self = shift;
    my @args = split //, shift;

    if (scalar(@args) > 4) {
        croak 'string length is too long.';
    }

    my %digit_map = (''  => 32,
                     ' ' => 32,
                     '!' => 33,
                     '"' => 34,
                     '#' => 35,
                     '%' => 37,
                     '&' => 38,
                     "'" => 39,
                     ',' => 44,
                     '-' => 45,
                     '.' => 46,
                     '/' => 47,
                     '0' => 48,
                     '1' => 49,
                     '2' => 50,
                     '3' => 51,
                     '4' => 52,
                     '5' => 53,
                     '6' => 54,
                     '7' => 55,
                     '8' => 56,
                     '9' => 57,
                     'A' => 65);

    my @digits = ($digit_map{''}, $digit_map{''}, $digit_map{''}, $digit_map{''});
    for (my $i = 0; $i < scalar(@args); $i++) {
        if (!defined($digit_map{$args[$i]})) {
            croak 'not supported character.';
        }
        $digits[$i] = $digit_map{$args[$i]};
    }
    my $roomba = $self->{'roomba'};
    printf $roomba "\xA4%c%c%c%c", @digits;
}

sub buttons {
    my $self = shift;

    croak 'not implement yet.';
}

sub song() {
    my $self = shift;
    my ($song_num, $song_len, @song_data) = @_;

    if ($song_len != (scalar(@song_data) / 2)) {
        croak 'invalid song length or song data.';
    }
    if (!($song_num < 16)) {
        croak 'invalid song num. song number must be < 16';
    }

    my $roomba = $self->{'roomba'};
    my $song_data_fmt;
    for (my $i = 0; $i < $song_len; $i++) {
        $song_data_fmt .= "%c%c";
    }

    printf $roomba "\x8C%c%c$song_data_fmt", $song_num, $song_len, @song_data;
}

sub play() {
    my $self = shift;
    my $song_num = shift;

    my $roomba = $self->{'roomba'};
    printf $roomba "\x8D%c", $song_num;
}


sub vacuum() {
    my $self = shift;

    my $roomba = $self->{'roomba'};
    printf $roomba "\x8A%c", 14;
    sleep(5);
    printf $roomba "\x8A%c", 0;
}

sub forward() {
    my $self = shift;
    $self->drive(0x00c8, 0x8000); # 0x00c8= 200 mm/s, 0x8000=straight
}

sub backward($) {
    my $self = shift;
    $self->drive(0xff38, 0x8000); # 0xff38=-200 mm/s, 0x8000=straight 
}

sub spinleft($) {
    my $self = shift;
    $self->drive(0x00c8, 0x0001); # 0x00c8= 200 mm/s, 0x0001=spinleft
}

sub spinright($) {
    my $self = shift;
    $self->drive(0x00c8, 0xffff); # 0x00c8= 200 mm/s, 0xffff=spinright
}

sub stop($) {
    my $self = shift;
    $self->drive(0x0000, 0x0000); # all zeros means stop
}


1;

__END__

=pod

=head1 NAME

Device::Roomba - Control your Roomba

=head1 SYNOPSIS

    use Device::Roomba;

    # Constructors
    $roomba = Device::Roomba->new('/dev/ttyUSB0');
    $roomba->forward();

=head1 DESCRIPTION


This module have methods to control your Roomba's wheel, LED, brush or etc.
ROI(Roomba Open Interface)

Note that this module only tested on Roomba 500 serise.

=cut
