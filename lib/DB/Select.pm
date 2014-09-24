package DB::Select;
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

#----------------------------------------------
sub now_time{
#----------------------------------------------
my $self = shift;
return DB->db->query(qq[SELECT NOW()])->list;
}#---------------

#----------------------------------------------
sub like_table{
#----------------------------------------------
my($self, $table) = @_;
return DB->db->query(qq[SHOW TABLES LIKE "$table"])->list;
}#---------------

#----------------------------------------------
sub like_table_obj_list{
#----------------------------------------------
my($self, $table) = @_;
return DB->db->query(qq[SHOW TABLES LIKE "$table%"]);
}#---------------

#----------------------------------------------
sub like_begin{
#----------------------------------------------
my($self, $key) = @_;
return DB->db->query(qq[SHOW TABLES LIKE "$key\%"])->arrays;
}#---------------

#----------------------------------------------
sub count_rows{
#----------------------------------------------
my($self, $table) = @_;
return DB->db->query(qq[SELECT COUNT(*) FROM $table])->list;
}#---------------

#----------------------------------------------
sub level_id{
#----------------------------------------------
my($self, $table, $arg) = @_;
my($id) = DB->db->query(qq[ SELECT id FROM $table WHERE title_alias = "$arg" ])->list;
return $id;
}#---------------

#----------------------------------------------
sub page_media_data{
#----------------------------------------------
my($self, $c, $db, $id, $table) = @_;
my @data_arr;
my $i = 0;
foreach( @{$c->top_config->{'tables_of_upload'}} ){    
    $data_arr[$i] = $db->select($_, ['*'], {page_id => "$id", title_alias => "$table"})->hashes;
$i++;    
}
return @data_arr;
}#---------------

#----------------------------------------------
sub drop_table{
#----------------------------------------------
my $self = shift;
my $table = shift;
print "TABLE \= $table\n";
eval{ DB->db->query(qq[ DROP TABLE $table ]); };
return;
}#---------------
1;