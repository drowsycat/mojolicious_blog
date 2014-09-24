package MyBlog::Pagination;
use Mojo::Base 'Mojolicious::Controller';
use Mojo::Util qw(slurp spurt);

#---------------------------
sub pgn_articl {
#---------------------------
my $self = shift;
my $language = $self->top_config->{'exist_langs'};
my $template = $self->template;
my $pagination_attr_file = 'conf/pgn_articl';
my $list_of_round_attr = $self->top_config->{'round_num_list'};
my $list_of_outer_attr = $self->top_config->{'outer_num_list'};
my $list_of_pgn_place = $self->top_config->{'pagination_place'};
my %pagination_attr;

if($self->param('pgn_round')){
    my $str_for_store = 'round:'.$self->param('pgn_round').'|outer:'.$self->param('pgn_outer').'|annot_numb:'.$self->param('annot_numb').'|pgn_place:'.$self->param('pgn_place');
    spurt $str_for_store, $pagination_attr_file;
}

my $file = Mojo::Asset::File->new( path => $pagination_attr_file );
my $pagination_attr = $file->slurp;
my @pgn_attr = split(/\|/, $pagination_attr);
$pagination_attr{ (split(/\:/, $pgn_attr[0]))[0] } = (split(/\:/, $pgn_attr[0]))[1];
$pagination_attr{ (split(/\:/, $pgn_attr[1]))[0] } = (split(/\:/, $pgn_attr[1]))[1];
$pagination_attr{ (split(/\:/, $pgn_attr[2]))[0] } = (split(/\:/, $pgn_attr[2]))[1];
$pagination_attr{ (split(/\:/, $pgn_attr[3]))[0] } = (split(/\:/, $pgn_attr[3]))[1];

$self->render(
language => $language,
list_of_round_attr => $list_of_round_attr,
list_of_outer_attr => $list_of_outer_attr,
list_of_pgn_place => $list_of_pgn_place,
pagination_attr => {%pagination_attr},
header => $self->lang_config->{'labels'}->{$language}->{'masterroom'},
title => $self->lang_config->{'labels'}->{$language}->{'pagination_attr'},
head => $self->lang_config->{'labels'}->{$language}->{'pagination_attr'},
);
}#-------------
1;