package MyBlog::Comments;
use Mojo::Base 'Mojolicious::Controller';
use Mojo::Util qw(slurp spurt);

#---------------------------
sub comments_setting {
#---------------------------
my $self = shift;
my $language = $self->top_config->{'exist_langs'};
my $template = $self->template;
my $table_comments = $self->top_config->{'table'}->{'comments'};
my $comments_levels_deep_file = 'conf/comments_deep';
my $list_of_levels = $self->top_config->{'comments_deep_levels'};
my $db = DB->db();
$db->abstract = SQL::Abstract->new;

if($self->param('comments_deep')){
    $db->update( $table_comments, {level => $self->param('comments_deep')}, 
                                  { level => {'>', $self->param('comments_deep')} } );
    spurt $self->param('comments_deep'), $comments_levels_deep_file;
}

my $file = Mojo::Asset::File->new( path => $comments_levels_deep_file );
my $exist_comments_deep = $file->slurp;

$self->render(
language => $language,
list_of_levels => $list_of_levels,
exist_comments_deep => $exist_comments_deep,
header => $self->lang_config->{'labels'}->{$language}->{'masterroom'},
title => $self->lang_config->{'labels'}->{$language}->{'comments_setting'},
head => $self->lang_config->{'labels'}->{$language}->{'comments_setting'},
);
}#-------------
1;