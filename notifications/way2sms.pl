#!/usr/bin/perl
use strict;
use warnings;

use Getopt::Std;
use POSIX;
use HTTP::Tiny;
use JSON::PP qw(encode_json decode_json);

my $MESSAGE_LENGTH = 160;

my $api_key = "<YOUR API KEY>";
my $secret_key = "<YOUR SECRET KEY>";
my $use_type = "prod";
my $sender_id = "<YOUR CAMPAIGN ID a.k.a. SENDER ID";

my $message;
my $phone;

my $show_usage = 0;

my %options=();
getopts("hn:m:", \%options);

$show_usage = 1 if defined $options{h};

if (defined $options{n}) {
    $phone = $options{n};
    # if length is 10 characters and does not have non-digits
    if ((length $phone != 10) || ($phone =~ /\D/)) {
        print "Mobile number should be 10 digit numeric\n";
        exit 1;
    }
} else {
    print "-n needs to be specified with a mobile number\n";
    $show_usage = 1;
}

if (defined $options{m}) {
    $message = $options{m};
    if (length $message > $MESSAGE_LENGTH) {
        print "Message length cannot exceed $MESSAGE_LENGTH characters.\n";
        exit 1;
    }
} else {
    print "-m needs to be specified with a message\n";
    $show_usage = 1;
}

if ($show_usage == 1) {
    showUsage();
    exit 0;
}

# Create an agent
my $agent = HTTP::Tiny->new(
    default_headers => {
        "content-type" => "application/json",
    },
);

# To do - Check for message length - it should not exceed 160 characters
my $response = $agent->post('http://www.way2sms.com/api/v1/sendCampaign', {
    content => encode_json {
        "phone" => $phone,
        "message" => $message,
        "apikey" => $api_key,
        "secret" => $secret_key,
        "usetype" => $use_type,
        "senderid" => $sender_id,
    }
});

my $result = $response->{content} ? decode_json $response->{content} : {};

unless($response->{success}) {
    die "$response->{status}: $result->{code} ($result->{message})\n";
}

print $response->{status}, ", ";
print $result->{code}, ", ", $result->{message}, ", ", $result->{smscost}, ", ", $result->{balacne}, "\n";


sub showUsage {
    print "Usage: $0 [-h] -n xxxxxxxxxx -m 'a message'\n";
    print "where, xxxxxxxxxx is the 10 digit mobile number\n";
}

sub validateMobile {
    # if length is 10 characters and does not have non-digits
    if ((length $_[0] == 10) && !( $_[0] =~ /\D/)) {
        return 0;
    } else {
        print "Mobile Number should be a 10 digit numeric.\n";
        print "Your input: $_[0]\n";
        return 1;
    }
}
