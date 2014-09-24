package MyBlog::List;
use Mojo::Base 'Mojolicious::Controller';
use Mojo::Util qw(trim spurt encode);
use MyBlog::RegExp;
use MyBlog::RssArticles;
use Transliter;
use DB::Select;

#---------------------------------
sub list_content {
#---------------------------------
my $self = shift;

my(%err_hash, $message);
my $language = $self->top_config->{'exist_langs'};
my $template = $self->template;
require "$template/Archive.pm";
my $db = DB->db();
$db->abstract = SQL::Abstract->new;

my $table = $self->param('title_alias');

#*********************************
if( $self->param('add') ){
#*********************************
    my $head = MyBlog::RegExp->name_clean( trim( $self->param('head') ) ) || $self->lang_config->{'new_page_content'}->{$language};
    my($level, $level_id, $template) = $db->select( $table, ['level', 'level_id', 'template'] )->list;
    $db->insert($table, {
                                    'level'      => "$level",
                                    'level_id'   => $level_id,
                                    'rubric_id'  => 0,
                                    'curr_date'  => DB::Select->now_time,
                                    'head'       => $head,
                                    'announce'   => $self->lang_config->{'new_page_content'}->{$language},
                                    'content'    => $self->lang_config->{'new_page_content'}->{$language},
                                    'template'   => "$template",
                                    'comment_enable' => "yes"
                                   }
               );
$self->redirect_to($self->url_for("/list_content_manage")->query(
                                                            title_alias => $table,
                                                            title    => $self->param('title')
                                                         )
                   );
#Перезаписуємо меню архіву
#MyBlog::Archive->archive_menu($self);
Archive->archive_menu($self); 
}#**********

my $data_ref = $db->select( "$table", ['*'], {}, {-desc => 'curr_date'} )->hashes;

$self->render(
data_ref => $data_ref,
language => $language,
title_alias => $table,
header => $self->lang_config->{'labels'}->{$language}->{'masterroom'},
title => $self->param('title')
);
}#------------

#---------------------------------
sub article {
#---------------------------------
my $self = shift;
use RewriteImage;
use Cwd;

my(%err_hash, $data_ref, $message);
my $language = $self->top_config->{'exist_langs'};
my $template = $self->template;
require "$template.pm";
my $Template = $template->new;
require $template.'/Archive.pm';
my $search_table = $self->top_config->{'table'}->{'search_artcl'};
my $redirect_to = 'article_manage';
my $cwd = cwd();

my $type_of_upload          = $self->top_config->{'type_of_upload'};
my $template_for_upload     = $self->top_config->{'template_for_type_upload'};
my $tables_of_sourse_upload = $self->top_config->{'tables_of_upload'};
my $table_rubric = $self->top_config->{'table'}->{'rubric'};
my($search_id, $data_in_search);
my $db = DB->db();
$db->abstract = SQL::Abstract->new;

my $table = $self->param('title_alias');
my $id    = $self->param('id') || $db->select($table, ['id'], {level_id => $self->param('level_id')})->list;

my($level, $level_id, $head) = $db->select($table, ['level', 'level_id', 'head'], {id => "$id"})->list;
my($title_chapter, $list_enable, $url) = $db->select($level, ['title', 'list_enable', 'url'], {id => $level_id})->list;

# Масив полів форми, що обов'язково мають бути заповнені
my $article_required_fields = $self->top_config->{'adm'}->{'article_required_fields'}->{$template};

if( $self->param('edit') ){
    %err_hash = $self->serve->err_hash_fields($self, $article_required_fields);
}
    foreach(@$article_required_fields){
        # Додаємо в шаблон повідомлення про помилку (порожнє відповідне поле форми). Тут назва змінної для шаблону
        # формується з назви поля з приєднаним '_err'
        $self->stash($_.'_err' => $err_hash{$_});
    }
#*******************************************************    
if( $self->param('edit') && scalar(keys %err_hash) <= 0 ){
#*******************************************************
    my $content = trim($self->param('cont_text'));
    my $head    = MyBlog::RegExp->new->name_clean( trim($self->param('head')) );
   $db->abstract = SQL::Abstract->new;
   
   my $path_for_upload = $self->top_config->{$self->top_config->{'path_upload_hash'}->{'img'}};

    if( $self->param('lead_img') ){
        my($lead_img_exist) = $db->select( $table, ['lead_img'], {id => "$id"} )->list;
        
        # "Полегшуємо" зображення, перетворюючи їх до оптимальних розмірів
        RewriteImage->lead_img($self, "$cwd/public/$path_for_upload", $self->param('lead_img'));
    }
   
   $db->update( $table, {
                        description => MyBlog::RegExp->new->name_clean( trim($self->param('description')) ),
                        keywords => MyBlog::RegExp->new->name_clean( trim($self->param('keywords')) ),
                        head      => $head,
                        curr_date => trim($self->param('curr_date')),
                        rubric_id => $self->param('rubric') || 0,
                        lead_img  => $self->param('lead_img') || "",
                        announce  => trim($self->param('announce')),
                        content   => "$content",
                        author    => trim($self->param('author')),
                        comment_enable => $self->param('comment_enable')
                        }, {id => "$id"} );
                        
    #Чистимо текст статті для індексації
    $content = $self->clean_text($content);

    my $literal_ident = Transliter->transliter($head);
    $literal_ident =~ s/\_/\-/g if($literal_ident =~ /\_/);
    
    # Визначаємо url для таблиці індексування в залежності від шаблона і особливостей сторінки $list_enable #############
    my $url_for_data = $Template->url_for_search($url, $id, $literal_ident, $list_enable);
    #####################################################################################################################
    #my $url_for_data = "$url_mod".'/'."$id".'/'."$literal_ident";
    #$url_for_data = $url if $list_enable eq 'no';
                        
    eval{                    
    ($search_id, $data_in_search) = $db->select($search_table, ['id', 'search_text'], {table_name => "$table", page_id => "$id"})->list;
    };
    #Індексуємо статтю ########################################
    if(!$data_in_search){
        $db->insert($search_table, {
                                    url => $url_for_data,
                                    table_name => "$table",
                                    page_id => "$id",
                                    head => "$head",
                                    description => MyBlog::RegExp->new->name_clean( trim($self->param('description')) ),
                                    search_text => lc($head).'. '.lc(MyBlog::RegExp->new->name_clean( trim($self->param('description')) )).'. '.lc($content)
                                   });
    }else{
        $db->update($search_table, {
                                    url => $url_for_data,
                                    table_name => "$table",
                                    page_id => "$id",
                                    head => "$head",
                                    description => MyBlog::RegExp->new->name_clean( trim($self->param('description')) ),
                                    search_text => lc($head).' '.lc(MyBlog::RegExp->new->name_clean( trim($self->param('description')) )).' '.lc($content)
                                   }, {table_name => "$table", page_id => "$id"});
    }###########################################################

#Перезаписуємо меню архіву
#MyBlog::Archive->archive_menu($self);
Archive->archive_menu($self); 
# Записуємо файл RSS для публікацій
MyBlog::RssArticles->rss_articles($self);  
}#***************

$data_ref = $db->select($table, ['*'], {id => "$id"})->hashes;

#-- Отримуємо дані про завантажені файли, пов'язані з даною публікацією ---------------------------------------------- 
my($ref_illustr, $ref_docs, $ref_media) = DB::Select->page_media_data($self, $db, $id, $table);
# Дістаємо список наявних рубрик @rubric_list
my $id_rubric_ref = $db->select( $table_rubric, ['*'], {}, 'id' )->hashes;

$self->render(
language => $language,
title_chapter => $title_chapter,
title_alias => $table,
list_enable => $list_enable,
id => $id,
url => $url,
list_enable => $list_enable,
redirect_to => $redirect_to,
head => $data_ref->[0]->{'head'},
rubric_list => $id_rubric_ref,
lead_img => $data_ref->[0]->{'lead_img'},
content => $data_ref,
type_of_upload => $type_of_upload,
header => $self->lang_config->{'labels'}->{$language}->{'masterroom'},
title => $data_ref->[0]->{'head'},
illustr_arr => $ref_illustr,
docs_arr    => $ref_docs,
media_arr   => $ref_media,
);
}#------------
1;