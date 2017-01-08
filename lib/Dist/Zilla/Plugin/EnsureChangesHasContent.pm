package Dist::Zilla::Plugin::EnsureChangesHasContent;

use v5.10;

use strict;
use warnings;
use autodie;
use namespace::autoclean;

our $VERSION = '0.02';

use CPAN::Changes;

use Moose;

has filename => (
    is      => 'ro',
    isa     => 'Str',
    default => 'Changes',
);

with 'Dist::Zilla::Role::BeforeRelease';

sub before_release {
    my $self = shift;

    $self->log('Checking Changes');

    $self->zilla->ensure_built_in;

    my $file = $self->zilla->built_in->child( $self->file );

    if ( !-e $file ) {
        $self->log_fatal('No Changes file found');
    }
    elsif ( $self->_get_changes($file) ) {
        $self->log('Changes file has content for release');
    }
    else {
        $self->log_fatal(
            'Changes has no content for ' . $self->zilla->version );
    }

    return;
}

sub _get_changes {
    my $self = shift;
    my $file = shift;

    my $changes = CPAN::Changes->load($file);
    my $release = $changes->release( $self->zilla->version )
        or return;
    my $all = $release->changes
        or return;

    return 1 if grep { @{ $all->{$_} // [] } } keys %{$all};
    return 0;
}

__PACKAGE__->meta->make_immutable;

1;

# ABSTRACT: Checks Changes for content using CPAN::Changes

__END__

=head1 SYNOPSIS

  [EnsureChangesHasContent]
  filename = Changelog

=head1 DESCRIPTION

This is a C<BeforeRelease> phase plugin that ensures that the changelog file
I<in your distribution> has at least one change listed for the version you are
releasing.

It is an alternative to L<Dist::Zilla::Plugin::CheckChangesHasContent> that
uses L<CPAN::Changes> to parse the changelog file. If your file follows the
format described by L<CPAN::Changes::Spec>, then this method of checking for
changes is more reliable than the ad hoc parsing used by
L<Dist::Zilla::Plugin::CheckChangesHasContent>.

=head1 CONFIGURATION

This plugin offers one configuration option:

=head2 filename

The filename in the distribution containing the changelog. This defaults to
F<Changes>.
