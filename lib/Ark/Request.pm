package Ark::Request;
use Mouse;

extends 'Plack::Request';

use URI::WithBase;
use URL::Encode;
use Path::AttrRouter::Match;

has match => (
    is      => 'rw',
    isa     => 'Path::AttrRouter::Match',
    handles => [qw/action args captures/],
);

{
    no warnings 'once';
    *arguments = \&args;
}

no Mouse;

sub wrap {
    my ($class, $req) = @_;

    return $class->new( $req->env );
}

sub uri_with {
    my ($self, $args) = @_;

    my $uri = $self->uri->clone;

    my %params = $uri->query_form;
    while (my ($k, $v) = each %$args) {
        $params{$k} = $v;
    }
    $uri->query_form(%params);

    return $uri;
}

sub body_parameters {
    my ($self) = @_;
    $self->{'request.body'} ||= $self->SUPER::body_parameters;
}

sub query_parameters {
    my ($self) = @_;
    $self->{'request.query'} ||= $self->raw_query_parameters;
}

sub parameters {
    my $self = shift;
    $self->{'request.merged'} ||= do {
        my $query = $self->query_parameters;
        my $body  = $self->body_parameters;
        Hash::MultiValue->new( $query->flatten, $body->flatten );
    };
}

sub raw_body_parameters {
    shift->SUPER::body_parameters;
}

sub raw_query_parameters {
    my $self = shift;
    my $env  = $self->{env};
    $env->{'plack.request.query'} ||= Hash::MultiValue->new(@{URL::Encode::url_params_flat($env->{'QUERY_STRING'})});
}

sub raw_parameters {
    my $self = shift;
    $self->{env}{'plack.request.merged'} ||= do {
        my $query = $self->raw_query_parameters;
        my $body  = $self->SUPER::body_parameters;
        Hash::MultiValue->new( $query->flatten, $body->flatten );
    };
}

sub raw_param {
    my $self = shift;

    return keys %{ $self->raw_parameters } if @_ == 0;

    my $key = shift;
    return $self->raw_parameters->{$key} unless wantarray;
    return $self->raw_parameters->get_all($key);
}

1;
