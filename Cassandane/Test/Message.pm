#!/usr/bin/perl

use strict;
use warnings;
package Cassandane::Test::Message;
use base qw(Test::Unit::TestCase);
use Cassandane::Message;
use Cassandane::Address;

sub new
{
    my $class = shift;
    my $self = $class->SUPER::new(@_);
    return $self;
}

# Test default ctor
sub test_empty
{
    my ($self) = @_;
    my $m = Cassandane::Message->new();
    $self->assert(!defined $m->get_headers('from'));
    $self->assert(!defined $m->get_headers('to'));
    $self->assert(!defined $m->get_body());

    my $exp = <<'EOF';

EOF
    $exp =~ s/\n/\r\n/g;

    $self->assert($m->as_string eq $exp);
    $self->assert("" . $m eq $exp);
}

# Test case sensitivity of header names
sub test_header_case
{
    my ($self) = @_;
    my $m = Cassandane::Message->new();
    $m->add_header('SUBJECT', 'Hello World');
    $self->assert(!defined $m->get_headers('from'));
    $self->assert(!defined $m->get_headers('to'));
    $self->assert(!defined $m->get_body);
    $self->assert($m->get_headers('SUBJECT')->[0] eq 'Hello World');
    $self->assert($m->get_headers('Subject')->[0] eq 'Hello World');
    $self->assert($m->get_headers('subject')->[0] eq 'Hello World');
    $self->assert($m->get_headers('sUbJeCt')->[0] eq 'Hello World');

    my $exp = <<'EOF';
Subject: Hello World

EOF
    $exp =~ s/\n/\r\n/g;

    $self->assert($m->as_string eq $exp);
    $self->assert("" . $m eq $exp);
}

# Test implicit stringification of Addresses when passing to headers
sub test_address_stringification
{
    my ($self) = @_;
    my $m = Cassandane::Message->new();
    $m->add_header('subject', 'Hello World');
    $m->add_header('From', Cassandane::Address->new(
	    name => 'Fred J. Bloggs',
	    localpart => 'fbloggs',
	    domain => 'fastmail.fm'));
    $self->assert(!defined $m->get_headers('to'));
    $self->assert(!defined $m->get_body);
    $self->assert($m->get_headers('from')->[0] eq 'Fred J. Bloggs <fbloggs@fastmail.fm>');
    my $exp = <<'EOF';
Subject: Hello World
From: Fred J. Bloggs <fbloggs@fastmail.fm>

EOF
    $exp =~ s/\n/\r\n/g;
    $self->assert($m->as_string eq $exp);
    $self->assert("" . $m eq $exp);
}

# Test stringification of a list of Addresses when passing to headers
sub test_address_list_stringification
{
    my ($self) = @_;
    my $m = Cassandane::Message->new();
    $m->add_header('subject', 'Hello World');
    my @tos = (
	Cassandane::Address->new(
	    name => 'Sarah Jane Smith',
	    localpart => 'sjsmith',
	    domain => 'tard.is'),
	Cassandane::Address->new(
	    name => 'Genghis Khan',
	    localpart => 'gkhan',
	    domain => 'horde.mo'),
	);
    $m->add_header('To', join(', ', @tos));
    $self->assert(!defined $m->get_body());
    $self->assert(!defined $m->get_headers('from'));
    $self->assert($m->get_headers('to')->[0] eq
		  'Sarah Jane Smith <sjsmith@tard.is>, Genghis Khan <gkhan@horde.mo>');
    my $exp = <<'EOF';
Subject: Hello World
To: Sarah Jane Smith <sjsmith@tard.is>, Genghis Khan <gkhan@horde.mo>

EOF
    $exp =~ s/\n/\r\n/g;
    $self->assert($m->as_string eq $exp);
    $self->assert("" . $m eq $exp);
}

# Test multiple headers with the same name
sub test_multiple_headers
{
    my ($self) = @_;
    my $m = Cassandane::Message->new();
    $m->add_header('subject', 'Hello World');
    $m->add_header("received", "from mail.quux.com (mail.quux.com [10.0.0.1]) by mail.gmail.com (Software); Fri, 29 Oct 2010 13:05:01 +1100");
    $m->add_header("received", "from mail.bar.com (mail.bar.com [10.0.0.1]) by mail.quux.com (Software); Fri, 29 Oct 2010 13:03:03 +1100");
    $m->add_header("received", "from mail.fastmail.fm (mail.fastmail.fm [10.0.0.1]) by mail.bar.com (Software); Fri, 29 Oct 2010 13:01:01 +1100");
    $self->assert($m->get_headers('received')->[0] eq "from mail.quux.com (mail.quux.com [10.0.0.1]) by mail.gmail.com (Software); Fri, 29 Oct 2010 13:05:01 +1100");
    $self->assert($m->get_headers("received")->[1] eq "from mail.bar.com (mail.bar.com [10.0.0.1]) by mail.quux.com (Software); Fri, 29 Oct 2010 13:03:03 +1100");
    $self->assert($m->get_headers("received")->[2] eq "from mail.fastmail.fm (mail.fastmail.fm [10.0.0.1]) by mail.bar.com (Software); Fri, 29 Oct 2010 13:01:01 +1100");
    my $exp = <<'EOF';
Subject: Hello World
Received: from mail.quux.com (mail.quux.com [10.0.0.1]) by mail.gmail.com (Software); Fri, 29 Oct 2010 13:05:01 +1100
Received: from mail.bar.com (mail.bar.com [10.0.0.1]) by mail.quux.com (Software); Fri, 29 Oct 2010 13:03:03 +1100
Received: from mail.fastmail.fm (mail.fastmail.fm [10.0.0.1]) by mail.bar.com (Software); Fri, 29 Oct 2010 13:01:01 +1100

EOF
    $exp =~ s/\n/\r\n/g;
    $self->assert($m->as_string eq $exp);
    $self->assert("" . $m eq $exp);
}


# Test replacing headers
sub test_replacing_headers
{
    my ($self) = @_;
    my $m = Cassandane::Message->new();
    $m->add_header('subject', 'Hello World');
    $self->assert($m->get_header('subject') eq 'Hello World');
    $m->set_headers('subject', 'No, scratch that');
    $self->assert($m->get_header('subject') eq 'No, scratch that');
    my $exp = <<'EOF';
Subject: No, scratch that

EOF
    $exp =~ s/\n/\r\n/g;
    $self->assert($m->as_string eq $exp);
    $self->assert("" . $m eq $exp);
}

# Test deleting headers
sub test_deleting_headers
{
    my ($self) = @_;
    my $m = Cassandane::Message->new();
    $m->add_header('subject', 'Hello World');
    $m->add_header("received", "from mail.quux.com (mail.quux.com [10.0.0.1]) by mail.gmail.com (Software); Fri, 29 Oct 2010 13:05:01 +1100");
    $m->add_header("received", "from mail.bar.com (mail.bar.com [10.0.0.1]) by mail.quux.com (Software); Fri, 29 Oct 2010 13:03:03 +1100");
    $m->add_header("received", "from mail.fastmail.fm (mail.fastmail.fm [10.0.0.1]) by mail.bar.com (Software); Fri, 29 Oct 2010 13:01:01 +1100");
    $self->assert($m->get_header('subject') eq 'Hello World');
    $m->remove_headers('subject');
    $self->assert(!defined $m->get_header('subject'));
    my $exp = <<'EOF';
Received: from mail.quux.com (mail.quux.com [10.0.0.1]) by mail.gmail.com (Software); Fri, 29 Oct 2010 13:05:01 +1100
Received: from mail.bar.com (mail.bar.com [10.0.0.1]) by mail.quux.com (Software); Fri, 29 Oct 2010 13:03:03 +1100
Received: from mail.fastmail.fm (mail.fastmail.fm [10.0.0.1]) by mail.bar.com (Software); Fri, 29 Oct 2010 13:01:01 +1100

EOF
    $exp =~ s/\n/\r\n/g;
    $self->assert($m->as_string eq $exp);
    $self->assert("" . $m eq $exp);
}

# Test adding a body -- only plain text for now, no MIME
sub test_add_body
{
    my ($self) = @_;
    my $m = Cassandane::Message->new();
    $m->add_header('subject', 'Hello World');
    $m->set_body("This is a message to let you know\r\nthat I'm alive and well\r\n");
    my $exp = <<'EOF';
Subject: Hello World

This is a message to let you know
that I'm alive and well
EOF
    $exp =~ s/\n/\r\n/g;
    $self->assert($m->as_string eq $exp);
    $self->assert("" . $m eq $exp);
}

# Test setting lines.
sub test_setting_lines
{
    my ($self) = @_;
    my $m = Cassandane::Message->new();

    my $txt = <<'EOF';
From: Fred J. Bloggs <fbloggs@fastmail.fm>
To: Sarah Jane Smith <sjsmith@tard.is>, Genghis Khan <gkhan@horde.mo>
Subject: Hello World
Received: from mail.quux.com (mail.quux.com [10.0.0.1]) by mail.gmail.com (Software);
	Fri, 29 Oct 2010 13:05:01 +1100
Received: from mail.bar.com (mail.bar.com [10.0.0.1])
	by mail.quux.com (Software); Fri, 29 Oct 2010 13:03:03 +1100
Received: from mail.fastmail.fm (mail.fastmail.fm [10.0.0.1]) by
	mail.bar.com (Software); Fri, 29 Oct 2010 13:01:01 +1100

This is a message to let you know
that I'm alive and well
EOF
    my @lines = split(/\n/, $txt);
    map { $_ .= "\r\n" } @lines;

    my $exp = <<'EOF';
From: Fred J. Bloggs <fbloggs@fastmail.fm>
To: Sarah Jane Smith <sjsmith@tard.is>, Genghis Khan <gkhan@horde.mo>
Subject: Hello World
Received: from mail.quux.com (mail.quux.com [10.0.0.1]) by mail.gmail.com (Software); Fri, 29 Oct 2010 13:05:01 +1100
Received: from mail.bar.com (mail.bar.com [10.0.0.1]) by mail.quux.com (Software); Fri, 29 Oct 2010 13:03:03 +1100
Received: from mail.fastmail.fm (mail.fastmail.fm [10.0.0.1]) by mail.bar.com (Software); Fri, 29 Oct 2010 13:01:01 +1100

This is a message to let you know
that I'm alive and well
EOF
    $exp =~ s/\n/\r\n/g;

    $m->set_lines(@lines);
    $self->assert($m->get_headers('from')->[0] eq 'Fred J. Bloggs <fbloggs@fastmail.fm>');
    $self->assert($m->get_headers('to')->[0] eq 'Sarah Jane Smith <sjsmith@tard.is>, Genghis Khan <gkhan@horde.mo>');
    $self->assert($m->get_headers('Subject')->[0] eq 'Hello World');
    $self->assert($m->get_headers('received')->[0] eq "from mail.quux.com (mail.quux.com [10.0.0.1]) by mail.gmail.com (Software); Fri, 29 Oct 2010 13:05:01 +1100");
    $self->assert($m->get_headers("received")->[1] eq "from mail.bar.com (mail.bar.com [10.0.0.1]) by mail.quux.com (Software); Fri, 29 Oct 2010 13:03:03 +1100");
    $self->assert($m->get_headers("received")->[2] eq "from mail.fastmail.fm (mail.fastmail.fm [10.0.0.1]) by mail.bar.com (Software); Fri, 29 Oct 2010 13:01:01 +1100");
    $self->assert($m->as_string eq $exp);
    $self->assert("" . $m eq $exp);

    $m = Cassandane::Message->new(lines => \@lines);
    $self->assert($m->get_headers('from')->[0] eq 'Fred J. Bloggs <fbloggs@fastmail.fm>');
    $self->assert($m->get_headers('to')->[0] eq 'Sarah Jane Smith <sjsmith@tard.is>, Genghis Khan <gkhan@horde.mo>');
    $self->assert($m->get_headers('Subject')->[0] eq 'Hello World');
    $self->assert($m->get_headers('received')->[0] eq "from mail.quux.com (mail.quux.com [10.0.0.1]) by mail.gmail.com (Software); Fri, 29 Oct 2010 13:05:01 +1100");
    $self->assert($m->get_headers("received")->[1] eq "from mail.bar.com (mail.bar.com [10.0.0.1]) by mail.quux.com (Software); Fri, 29 Oct 2010 13:03:03 +1100");
    $self->assert($m->get_headers("received")->[2] eq "from mail.fastmail.fm (mail.fastmail.fm [10.0.0.1]) by mail.bar.com (Software); Fri, 29 Oct 2010 13:01:01 +1100");
    $self->assert($m->as_string eq $exp);
    $self->assert("" . $m eq $exp);
}

# Test message attributes
sub test_attributes
{
    my ($self) = @_;
    my $m = Cassandane::Message->new();

    $self->assert(!defined $m->get_attribute('uid'));
    $self->assert(!defined $m->get_attribute('UID'));
    $self->assert(!defined $m->get_attribute('uId'));
    $self->assert(!defined $m->get_attribute('internaldate'));

    $m->set_attribute('uid', 123);
    $self->assert($m->get_attribute('uid') == 123);
    $self->assert($m->get_attribute('UID') == 123);
    $self->assert($m->get_attribute('uId') == 123);
    $self->assert(!defined $m->get_attribute('internaldate'));

    $m->set_attribute('uid');
    $self->assert(!defined $m->get_attribute('uid'));
    $self->assert(!defined $m->get_attribute('UID'));
    $self->assert(!defined $m->get_attribute('uId'));
    $self->assert(!defined $m->get_attribute('internaldate'));

    $m = Cassandane::Message->new(attrs => { UID => 456 });
    $self->assert($m->get_attribute('uid') == 456);
    $self->assert($m->get_attribute('UID') == 456);
    $self->assert($m->get_attribute('uId') == 456);
    $self->assert(!defined $m->get_attribute('internaldate'));
}

1;
