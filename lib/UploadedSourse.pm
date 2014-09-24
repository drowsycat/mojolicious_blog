package UploadedSourse;
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

#-------------------------------------
sub get_uploaded{
#-------------------------------------
my $self = shift;
my($Obj_db, $dbh, $ation, $type_sourse_ref, $where_sring);
my @data_arr;

if(@_){ ($Obj_db, $dbh, $action, $type_sourse_ref, $where_sring) = @_; }

my $i = 0;
foreach(@$type_sourse_ref){

$data_arr[$i] = $Obj_db->get_data($dbh, 
                                    $action, #action
                                    $_, #table
                                    $where_sring
                                  );
$i++;
}
            
return @data_arr;
}#---------------
1;