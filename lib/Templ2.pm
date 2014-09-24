package Templ2;
use Mojo::Base 'Mojolicious::Controller';
use Mojo::Util qw(trim slurp);
use Templ2::MenuClient;
use Templ2::Archive;
use Templ2::RubricList;
use MyBlog::AuthorizeForm;
use MyBlog::CommentForm;
use MyBlog::AnswerForm;
#use MyBlog::Archive;
use MyBlog::CommentsTree;
use Data::Dumper;
#use Transliter;
use strict;
use warnings;

#----------------------------------
sub get_menu{
#----------------------------------
my($self, $c, $ref_hash_dir_subs) = @_;

return Templ2::MenuClient->menu($c, $ref_hash_dir_subs);
}#--------------

#----------------------------------
sub archive{
#----------------------------------
my($self, $c, $template) = @_;
require $template.'/Archive.pm';

return Archive->year_month($c);
}#--------------

#----------------------------------
sub menu_rewrite{
#----------------------------------
my($self, $c, $menu, $ref_levels_array) = @_;
my $db = DB->db();
my $db2 = $db;
$db->abstract = SQL::Abstract->new;
$db2->abstract = SQL::Abstract->new;

foreach my $table(reverse @$ref_levels_array){
    my $result = $db->select( $table, ['url', 'id'] );
    
        while( my($pattern, $id) = $result->list ){
        
            if( $table eq 'level0' || $table eq 'level1' ){
                my $curr_menu = $menu;
                $curr_menu =~ /(<li><a href=\"$pattern\")/;
                    next if(!$1);
                $curr_menu =~ s/$1/<li class\=\"active\"><a href=\"$pattern\"/;
                $db2->update( $table, {menu => "$curr_menu"}, {id => "$id"} );
            }else{
                $db2->update( $table, {menu => "$menu"}, {id => "$id"} );
            }
        
        }
}
}#--------------

#----------------------------------
sub index{
#----------------------------------
use MyBlog::ArticleProper;
my($c) = @_;

my $url = $c->req->url;
my $url_mod = $url;
my $language = $c->top_config->{'exist_langs'};
my $template = $c->template;
my $templ = lc($template).'/index';
#print "\$templ \= $templ\n"
my $table_comments = $c->top_config->{'table'}->{'comments'};
my $table_rubric = $c->top_config->{'table'}->{'rubric'};
my $table_archive_menu = $c->top_config->{'table'}->{'archive_menu'};
my $comments_levels_deep_file = 'conf/comments_deep';
my $pagination_attr_file = 'conf/pgn_articl';
my(%hash_id_subs, %hash_page_limit_str, %pagination_attr, $bread_crumbs, 
   $numb_items_of_address, $comments, $comments_tree, $message, $message_of_comment,
   $current_page, $total_pages, $offset, $rubric, $title_alias, $title, $menu, $list_enable,
   $top_chapter);
   
my $ref_article_proper = MyBlog::ArticleProper->new->article_proper($c, $template, 'index');
# Наявність чи відсутність ланцюжка навігації всередині розділу $bread_crumbs
my $bread_crumbs_indicr = $ref_article_proper->{'bread_crumbs'};
my $url_chaptr = $ref_article_proper->{'url_chaptr'};

my $file = Mojo::Asset::File->new( path => $pagination_attr_file );
my $pagination_attr = $file->slurp;
my @pgn_attr = split(/\|/, $pagination_attr);
$pagination_attr{ (split(/\:/, $pgn_attr[0]))[0] } = (split(/\:/, $pgn_attr[0]))[1];
$pagination_attr{ (split(/\:/, $pgn_attr[1]))[0] } = (split(/\:/, $pgn_attr[1]))[1];
$pagination_attr{ (split(/\:/, $pgn_attr[2]))[0] } = (split(/\:/, $pgn_attr[2]))[1];
$pagination_attr{ (split(/\:/, $pgn_attr[3]))[0] } = (split(/\:/, $pgn_attr[3]))[1];

# Кількість анотацій статей на одній сторінці
my $limit_str = $pagination_attr{'annot_numb'};
$current_page = 1;
$offset = ($current_page - 1) * $limit_str;

my $db = DB->db();
$db->abstract = SQL::Abstract->new;

#**********************************
if($c->param('page')){
#**********************************
    $current_page = $c->param('page');
    $offset = ($current_page - 1) * $limit_str;
    $offset = 0 if($current_page == 1 || !$current_page);
    $url_mod =~ s/\?page\=.*$//;
}#*************

my $table = $c->top_config->{'rel_numb_items_of_address'}->{scalar(split(/\//, $url))};
#print scalar(split(/\//, $url)), "\$table \= $table\n";

($title_alias, $title, $menu, $list_enable) = $db->select($table, ['title_alias', 'title', 'menu', 'list_enable'], {'url' => "$url_mod"})->list;
my $content = $db->select($title_alias, ['*'], {}, {-desc => 'curr_date'} )->hashes;

#********************************
if($list_enable eq 'yes'){
#********************************
    $total_pages = int( (scalar @$content)/$limit_str );
    $total_pages = $total_pages + 1 if( (scalar @$content)%$limit_str );

    $content = $db->query(qq[SELECT * FROM $title_alias ORDER BY curr_date DESC LIMIT $limit_str OFFSET $offset])->hashes;
}#********

#Підставляємо назву рубрики, що відповідає поточному 'rubric_id'
foreach(@$content){
    ($rubric) = $db->select( $table_rubric, ['rubric'], {'id' => "$_->{'rubric_id'}"} )->list if($_->{'rubric_id'} != 0);
    $_->{'rubric'} = uc $rubric if $rubric;
}

my $page_id = $content->[0]->{'id'};
my $title_actual = $title;
$title_actual = $content->[0]->{'head'} if($list_enable eq 'no');

#************************************
if($content->[0]->{'comment_enable'} eq 'yes'){
#************************************
    $comments = $db->select($table_comments, ['*'], {page_id => "$page_id", table_name => "$title_alias"}, {-desc => 'curr_date'} )->hashes;
    $message_of_comment = MyBlog::CommentForm->comment_form( $c, $table, $title_alias, $templ );
    if( $c->session('client') ){
        MyBlog::AnswerForm->answer_form( $c, $table, $title_alias, $templ );
    }
    $comments_tree = MyBlog::CommentsTree->comments_tree($c, $page_id);

}#**************

$message = MyBlog::AuthorizeForm->authorize_form( $c, $templ );
# Якщо необхідний ланцюжок навігації
if($bread_crumbs_indicr){
    my $top_level = 'level'.(substr($table, -1, 1) - 1);
    $top_chapter = $db->select('level'.(substr($table, -1, 1) - 1), ['title'], {'title_alias' => (split(/\//, $url_chaptr))[1]})->list;
$bread_crumbs=<<BRCR;
<ol class="breadcrumb" id="breadcrmb">
  <li class="active">$top_chapter</li>
  <li class="active">$title</li>
</ol>
BRCR

}
my $archive_menu = $db->select($table_archive_menu, ['menu'], {'url' => 'common'})->list;
my $ref_id_name_rubric = Templ2::RubricList->rubric_list($c);

$c->render(
template => $templ,
current_page => $current_page,
total_pages => $total_pages,
pagination_attr => {%pagination_attr},
message => $message,
message_of_comment => $message_of_comment,
language => $language,
bread_crumbs => $bread_crumbs,
menu => $menu,
archive_menu => $archive_menu,
title_alias => $title_alias,
url_chaptr => $url_mod,
content => $content,
comments => $comments,
comments_tree => $comments_tree,
redirect_to => $url,
list_enable => $list_enable,
title => $title_actual,
rubrics => $ref_id_name_rubric
);
}#--------------

#----------------------------------
sub article{
#----------------------------------
my($self, $c, $ref_article_proper) = @_;

my $language = $c->top_config->{'exist_langs'};
my $template = $c->template;
my $templ = lc($template).'/viewarticle';
my $table_comments = $c->top_config->{'table'}->{'comments'};
my $table_rubric = $c->top_config->{'table'}->{'rubric'};
my $table_archive_menu = $c->top_config->{'table'}->{'archive_menu'};
# Назва таблиці рівня ['level0', 'level1', 'level2']
my $table = $ref_article_proper->{'table'};
my $id = $ref_article_proper->{'id'};
my $url_chaptr = $ref_article_proper->{'url_chaptr'};
# Наявність чи відсутність ланцюжка навігації всередині розділу $bread_crumbs
my $bread_crumbs_indicr = $ref_article_proper->{'bread_crumbs'};
my($numb_items_of_address, $comments, $comments_tree, $message, $top_chapter, $title_alias, 
   $title, $menu, $bread_crumbs, $list_enable, $message_of_comment, $rubric);

my $db = DB->db();
$db->abstract = SQL::Abstract->new;

my $url = $c->req->url;

($title_alias, $title, $menu, $list_enable) = $db->select($table, ['title_alias', 'title', 'menu', 'list_enable'], {'url' => "$url_chaptr"})->list;
my $content = $db->select($title_alias, ['*'], {'id' => "$id"}, {-desc => 'curr_date'} )->hashes;
#Підставляємо назву рубрики, що відповідає поточному 'rubric_id'
($rubric) = $db->select( $table_rubric, ['rubric'], {'id' => "$content->[0]->{'rubric_id'}"} )->list if($content->[0]->{'rubric_id'} != 0);
$content->[0]->{'rubric'} = uc $rubric if $rubric;

    if($content->[0]->{'comment_enable'} eq 'yes'){

        $comments = $db->select($table_comments, ['*'], {page_id => "$id", table_name => "$title_alias"}, {-desc => 'curr_date'} )->hashes;
        $message_of_comment = MyBlog::CommentForm->comment_form( $c, $table, $title_alias, $id, $templ );
        if( $c->session('client') ){
            MyBlog::AnswerForm->answer_form( $c, $table, $title_alias, $templ );
        }
        $comments_tree = MyBlog::CommentsTree->comments_tree($c, $id);
    }

$message = MyBlog::AuthorizeForm->authorize_form( $c, $templ );
# Якщо необхідний ланцюжок навігації
if($bread_crumbs_indicr){
    my $top_level = 'level'.(substr($table, -1, 1) - 1);
    $top_chapter = $db->select('level'.(substr($table, -1, 1) - 1), ['title'], {'title_alias' => (split(/\//, $url_chaptr))[1]})->list;
$bread_crumbs=<<BRCR;
<ol class="breadcrumb" id="breadcrmb">
  <li class="active">$top_chapter</li>
  <li><a href="$url_chaptr">$title</a>
  </li>
</ol>
BRCR

}
my($archive_menu) = $db->select($table_archive_menu, ['menu'], {'url' => 'common'})->list;
my $ref_id_name_rubric = Templ2::RubricList->rubric_list($c);

$c->render(
template => $templ,
message => $message,
message_of_comment => $message_of_comment,
language => $language,
bread_crumbs => $bread_crumbs,
menu => $menu,
archive_menu => $archive_menu,
title_alias => $title_alias,
url_chaptr => $url_chaptr,
content => $content,
comments => $comments,
comments_tree => $comments_tree,
redirect_to => $url,
list_enable => 'no',
title => $content->[0]->{'head'},
rubrics => $ref_id_name_rubric
);
}#--------------

#----------------------------------
sub url_for_search{
#----------------------------------
my($self, $url, $id, $literal_ident, $list_enable) = @_;

my $url_mod = $url; $url_mod = "" if($url eq '/');
my $url_for_search = "$url_mod".'/'."$id".'/'."$literal_ident";
$url_for_search = $url if $list_enable eq 'no';

return $url_for_search;
}#--------------

#-----------------------------------
sub mytemplate{
#-----------------------------------
my $self = shift;

$self->render(
template => 'templ2/mytemplate',
title => 'TITLE'
);
}#-------------
1;