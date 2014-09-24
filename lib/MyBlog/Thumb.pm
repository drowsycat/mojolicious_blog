package MyBlog::Thumb;
use Mojo::Base 'Mojolicious::Controller';
use Mojo::Util qw(slurp spurt trim);

#---------------------------------
sub thumb_img {
#---------------------------------
my $self = shift;

my(%err_hash, $message);
my $language = $self->top_config->{'exist_langs'};
my $template = $self->template;
my $thumb_img_style_file = 'conf/thumb_img_style';
my $db = DB->db();
$db->abstract = SQL::Abstract->new;

my $table = $self->param('title_alias');
my $id    = $self->param('id');

my($level, $level_id, $head) = $db->select($table, ['level', 'level_id', 'head'], {id => $self->param('id')})->list;
my $list_of_styles = $self->top_config->{'thumb_img'};

if( $self->param('set_style') ){
    spurt $self->param('thumb_img_style'), $thumb_img_style_file;
}

my $file = Mojo::Asset::File->new( path => $thumb_img_style_file );
my $style = $file->slurp;

$self->render(
language => $language,
title_alias => $table,
head => $head,
id => $id,
exist_style => $style,
styles_list => $list_of_styles,
header => $self->lang_config->{'labels'}->{$language}->{'masterroom'},
title => $self->lang_config->{'miniature_style'}->{$language}
);
}#------------
1;