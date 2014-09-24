package MyBlog::Rss;
use Mojo::Base 'Mojolicious::Controller';
use Mojo::Util qw(slurp spurt);
use MyBlog::RssArticles;

#---------------------------
sub rss_setting {
#---------------------------
my $self = shift;
my $language = $self->top_config->{'exist_langs'};
my $template = $self->template;
require $template.'/TitleAliasList.pm';
my $table_rss_setting = $self->top_config->{'table'}->{'rss_setting'};
my $table_rss_data = $self->top_config->{'table'}->{'rss_data'};
my $table_rubric = $self->top_config->{'table'}->{'rubric'};
my $list_of_artcl_numb = $self->top_config->{'artcl_numb_rss'};
my(%err_hash, %date_Data_hash);
my $limit_links = $self->param('artcl_numb');

my $db = DB->db();
$db->abstract = SQL::Abstract->new;
my $db2 = $db;
$db2->abstract = SQL::Abstract->new;

# Масив полів форми, що обов'язково мають бути заповнені
my $rss_setting_required_fields = $self->top_config->{'adm'}->{'rss_setting_required_fields'}->{$template};
if( $self->param('set_rss_descr') ){
    %err_hash = $self->serve->err_hash_fields($self, $rss_setting_required_fields);
}
    foreach(@$rss_setting_required_fields){
        # Додаємо в шаблон повідомлення про помилку (порожнє відповідне поле форми). Тут назва змінної для шаблону
        # формується з назви поля з приєднаним '_err'
        $self->stash($_.'_err' => $err_hash{$_});
    }
    
#*******************************************************    
if( $self->param('set_rss_descr') && scalar(keys %err_hash) <= 0 ){
#*******************************************************

my($title) = $db->select($table_rss_setting, ['title'])->list;
if($title){
    $db->update($table_rss_setting, {
                                'title' => $self->param('title'), 
                                'description' => $self->param('description'),
                                'list_number' => $self->param('artcl_numb')
                                }, {'title' => $title});
}else{
    $db->insert($table_rss_setting, {
                                'title' => $self->param('title'), 
                                'description' => $self->param('description'),
                                'list_number' => $self->param('artcl_numb')
                                });
}
}#***********
my($title, $description, $list_number) = $db->select($table_rss_setting, ['title', 'description', 'list_number'])->list;
goto EN if(!$title);

# Записуємо файл RSS для публікацій
MyBlog::RssArticles->rss_articles($self);
# Записуємо файл RSS для коментарів
MyBlog::RssArticles->rss_comments($self);

my $data_ref = $db->select($table_rss_setting, ['*'])->hash;

EN:
$self->render(
language => $language,
list_of_artcl_numb => $list_of_artcl_numb,
data_ref => $data_ref,
header => $self->lang_config->{'labels'}->{$language}->{'masterroom'},
title => $self->lang_config->{'labels'}->{$language}->{'rss_setting'},
head => $self->lang_config->{'labels'}->{$language}->{'rss_setting'},
);
}#-------------

#------------------------------------
sub articles_feed {
#------------------------------------
my $self = shift;
$self->res->headers->content_type('text/xml');
$self->res->content->asset(Mojo::Asset::File->new(path => $self->top_config->{'rss_articles_path'}));
$self->rendered(200);
}#-----------

#------------------------------------
sub comments_feed {
#------------------------------------
my $self = shift;
$self->res->headers->content_type('text/xml');
$self->res->content->asset(Mojo::Asset::File->new(path => $self->top_config->{'rss_comments_path'}));
$self->rendered(200);
}#-----------
1;