package Templ2::UrlFor;
use Mojo::Base 'Mojolicious::Controller';

#----------------------------------------------
sub new{
#----------------------------------------------
   my $proto = shift;
   my $class = ref($proto) || $proto;

   my $self = {};

   bless($self, $class);
return $self;
}#-------------

#----------------------------------
sub url_for_search{
#----------------------------------
my($self, $url, $id, $literal_ident, $list_enable) = @_;

my $url_mod = $url; $url_mod = "" if($url eq '/');
my $url_for_search = "$url_mod".'/'."$id".'/'."$literal_ident";
$url_for_search = $url if $list_enable eq 'no';

return $url_for_search;
}#--------------
1;