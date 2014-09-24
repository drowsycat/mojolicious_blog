package Transform;
use Mojo::Base 'Mojolicious::Controller';
use Mojo::Util qw(trim);

#----------------------------------------------
sub new{
#----------------------------------------------
   my $proto = shift;
   my $class = ref($proto) || $proto;

   my $self = {};

   bless($self, $class);
return $self;
}#-------------

#-------------------------------------------------------
sub param_value{
#-------------------------------------------------------
my $self = shift;
my $c = shift;
my %result;
my($params, $not_modified_arr_params, $arr_params);

if(@_){ ($params, $not_modified_arr_params, $arr_params) = @_; }

foreach(@$not_modified_arr_params){
    $result{$_} = trim($params->{$_});
}
foreach(@$arr_params){
    $result{$_} = $c->alias_modif( trim($params->{$_}) );
}

return %result;       
}#------------
1;