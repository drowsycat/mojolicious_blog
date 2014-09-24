package TitleAliasList;
use Mojo::Base 'Mojolicious::Controller';
use DB::Select;

#---------------------------
sub title_alias_list {
#---------------------------
my($self, $c) = @_;
my $language = $c->top_config->{'exist_langs'};
my $template = $c->template;
my(@title_alias, @levels);
@title_alias = ();

my $db = DB->db();
$db->abstract = SQL::Abstract->new;

my $levels_obj = DB::Select->like_table_obj_list('level');
while( my($level) = $levels_obj->list ){
    push @levels, $level;
}

foreach(@levels){
    my @title_alias_curr = $db->select($_, ['distinct(title_alias)'], {'children' => undef})->flat;
    push @title_alias, @title_alias_curr;
}
return \@title_alias;
}#-------------
1;