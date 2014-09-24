package Templ1::RubricList;
use Mojo::Base 'Mojolicious::Controller';
use MyBlog::Rubric;
use MyBlog::AuthorizeForm;
use DB::Select;

#------------------------------------
sub rubric_list {
#------------------------------------
my($self, $c) = @_;
my $language = $c->top_config->{'exist_langs'};
my $template = $c->template;
my $table_rubric = $c->top_config->{'table'}->{'rubric'};
use lib 'lib/Templ1';
use TitleAliasList;
my(%exist, %id_name_rubric, @rubrics);

my $db = DB->db();
$db->abstract = SQL::Abstract->new;

my @title_alias = @{TitleAliasList->title_alias_list($c)};

foreach my $curr_table(@title_alias){
    my $result = $db->select($curr_table, ['distinct(rubric_id)']);
    while(my $rubric_id = $result->list){
        next if $exist{$rubric_id};
        my $rubric_name = $db->select($table_rubric, ['rubric'], {'id' => $rubric_id})->list;
        push @rubrics, $rubric_id;
        $id_name_rubric{$rubric_id} = $rubric_name;
        $exist{$rubric_id} = 1;
    }
}

return \%id_name_rubric;
}#-------------

#--------------------------------------
sub show_rubrics {
#--------------------------------------
my $self = shift;

my $language = $self->top_config->{'exist_langs'};
my $template = $self->template;
my $table_rubric = $self->top_config->{'table'}->{'rubric'};
my $table_archive_menu = $self->top_config->{'table'}->{'archive_menu'};
my($message);

my $url = $self->req->url;
my $id = (split(/\//, $url))[-1];
my $db = DB->db();
$db->abstract = SQL::Abstract->new;

my($menu) = $db->select('level0', ['menu'], {'url' => '/'})->list;
$menu =~ s/\s+class\=\"active\"//;
$message = MyBlog::AuthorizeForm->authorize_form( $self, 'templ1/show_rubric' );
my $archive_menu = $db->select($table_archive_menu, ['menu'], {'url' => 'common'})->list;
my $ref_id_name_rubric = __PACKAGE__->rubric_list($self);

my $content = __PACKAGE__->get_content($self, $db, $id);

$self->render(
template => 'templ1/show_rubric',
language => $language,
message => $message,
id => $$ref_id_name_rubric{$id}.' '.$id,
menu => $menu,
rubric => $$ref_id_name_rubric{$id},
content => $content,
archive_menu => $archive_menu,
title => $self->lang_config->{'rubric'}->{$language}.' "'.$$ref_id_name_rubric{$id}.'"',
rubrics => $ref_id_name_rubric
);
}#--------------

#---------------------------------------
sub get_content{
#---------------------------------------
my($self, $c, $db, $id) = @_;
my @title_alias = @{TitleAliasList->title_alias_list($c)};
my @content;

foreach my $curr_table(@title_alias){
    my $result = $db->select($curr_table, ['id', 'level', 'curr_date', 'head', 'announce'],
                                          {
                                           'rubric_id' => $id
                                          });
    while(my $data_ref = $result->hash){
        my $url_chaptr = $db->select($data_ref->{'level'}, ['url'], {'title_alias' => $curr_table})->list;
        $data_ref->{'url_chaptr'} = $url_chaptr;
        push @content, $data_ref;
    }
}
return [@content];
}#-------------

#---------------------------------------
sub rubric_link {
#---------------------------------------
my($self, $c, $rubric_id) = @_;
my $language = $c->top_config->{'exist_langs'};
my $table_rubric = $c->top_config->{'table'}->{'rubric'};
my $db = DB->db();
$db->abstract = SQL::Abstract->new;

my $rubric_name = uc($db->select($table_rubric, ['rubric'], {'id' => $rubric_id})->list);
my $rubric_link = "<a href=\"/rubric/$rubric_id\">$rubric_name</a>\n";

return $rubric_link;
}#-------------
1;