package MyBlog::Login;
use Mojo::Base 'Mojolicious::Controller';
use strict;
use warnings;

#---------------------------
sub logged_in {
#---------------------------
my $self = shift;    
    return $self->session('admin') || !$self->redirect_to('admin');
}#-----------

#----------------------------
sub logout {
#----------------------------
    my $self = shift;
    $self->session(expires => 1);
    $self->redirect_to('admin');
}#---------
1;