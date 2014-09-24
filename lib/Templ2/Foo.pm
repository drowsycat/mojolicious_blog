package Templ2::Foo;
use Mojo::Base 'Mojolicious::Controller';

#----------------------------------
sub foo {
#----------------------------------
my $self = shift;
my $template = 'Templ2';

$self->render(
template => 'templ2/foo',
title => 'Title'
)
}#-------------
1;