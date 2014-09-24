package DeleteFile;
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
sub delete{
#-------------------------------------
my $self = shift;
my($c, $work_routn, $Admin, $dbh);

if(@_){ ($c, $work_routn, $Admin, $dbh) = @_; }

if($c->param('delete_illustr')){

    foreach my $file( $c->param('delete_illustr') ){
        $Admin->db_manip($dbh,
                         'DELETE_il_doc', #action
                         'illustrations', #table
                         "",
                         $file,
                         'illustr_file'
                        );
        unlink "public/".$c->top_config->{$work_routn}->{'article'}->{'illustration_path'}."/$file";
        unlink "public/".$c->top_config->{$work_routn}->{'article'}->{'illustration_path'}."/tn_$file";
    }
}

#print "delete_doc \= ", $c->param('delete_doc'), "\n";

if($c->param('delete_doc')){
    foreach my $file($c->param('delete_doc')){
    
        $Admin->db_manip($dbh,
                         'DELETE_il_doc', #action
                         'documents', #table
                         "",
                         $file,
                         'doc_file'
                        );
        unlink "public/".$c->top_config->{"$work_routn"}->{'article'}->{'document_path'}."/$file";
        unlink "public/".$c->top_config->{"$work_routn"}->{'article'}->{'document_path'}."/tn_$file";
    }
}
            
return;
}#---------------
1;