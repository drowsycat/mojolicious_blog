package DB::Templ1::Insert;
use base 'DB';
use Mojo::Base 'Mojolicious::Controller';

use strict;
use warnings;

#----------------------------------------------
sub new{
#----------------------------------------------
   my $proto = shift;
   my $class = ref($proto) || $proto;

   my $self = {};

   bless($self, $class);
return $self;
}#-------------
1;