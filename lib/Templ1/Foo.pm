package Templ1::Foo;
use Mojo::Base 'Mojolicious::Controller';

#----------------------------------
sub foo {
#----------------------------------
my $self = shift;
my $template = 'Templ1';

$self->render(
template => 'templ1/foo',
title => 'Title'
)
}#-------------
1;