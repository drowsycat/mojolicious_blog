package MyBlog::Menu;
use Mojo::Base 'Mojolicious::Controller';
use Mojo::Util qw(trim);
#use Data::Dumper;
use MyBlog::RegExp;
use MyBlog::MenuForm;
use DB::Create;
use DB::Insert;
use DB::Select;
use Transliter;

#---------------------------------
sub menu_manage {
#---------------------------------
my $self = shift;

my(%err_hash, $message);
my $language = $self->top_config->{'exist_langs'};
my $template = $self->template;
require "$template.pm";
my @levels_array = ();
my $ref_levels_arr = $self->top_config->{$template}->{'levels'};
my @levels_arr = @{$ref_levels_arr};

#*********************************	
if( $self->param('edit') ){
#*********************************
my @items_for_delete;
my @levels = ();
    #*********************************
    if( $self->param('del_chapter') ){
    #*********************************
    my @tables = @{DB::Select->like_begin('level')};
    foreach(@tables){
        push @levels, ${$_}[0];
    }
    my $max_level = $levels[-1];
    
    @items_for_delete = $self->serve->data_explore( $self->param('title_alias'), $self->param('level'), $max_level);
        
    }#**********
    else{ 
        my $title = trim($self->param('title'));
        #my $title_alias = Transliter->transliter( $title );
        my $list_enable = $self->param('list_enable');
        say "LIST_enable \= ", $self->param('list_enable'), "level \= ", $self->param('level'), "id \= ", $self->param('id');
        my $db = DB->db;
        $db->abstract = SQL::Abstract->new;
        $db->update( $self->param('level'), {title       => $title,
                                             template    => $self->param('template'),
                                             description => trim($self->param('description')),
                                             keywords    => trim($self->param('keywords')),
                                             list_enable => "$list_enable",
                                             queue       => $self->param('queue')
                                            },
                                            {
                                             id => $self->param('id')
                                            }
                   );
    
    }#**********

$self->redirect_to('/menu_manage');		
}#*********** 

#***********************************
if( $self->param('add') ){
#***********************************
my $parent_dir = $self->param('title_alias');
my $title = MyBlog::RegExp->name_clean( trim($self->param('new_title')) );
my $new_title_alias = Transliter->transliter( $title ); # Перевірити, чи існує така директорія !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
my $templ   = $self->param('template');
$templ      = 'article' if(!$templ || $templ eq 'gallery'); # Змінити, коли буде можливість додавати шаблон 'gallery' !!!!!!!!!!!!!
my $list_enable = $self->param('new_list_enable');
$list_enable   = 'no' if(!$list_enable);

my $description = $self->param('description');
my $keywords   = $self->param('keywords');
my $separator;
    
	my $table_for_insert = 'level'.(substr($self->param( 'level' ), -1, 1) + 1);
	my($table_live) = DB::Select->like_table($table_for_insert);
	# Якщо таблиці, що відповідає вищому на порядок рівню, немає, створюємо її
	if( !$table_live ){
        DB::Create->create_table($table_for_insert, 'level');
    }
    DB::Create->create_table($new_title_alias, 'main');
    
    $separator = '/' if( $table_for_insert ne 'level1' && $table_for_insert ne 'level0' );
    my $url_for_insert = $self->param('url').$separator.$new_title_alias;
    
    my $db = DB->db();
    $db->abstract = SQL::Abstract->new;
    
    $db->insert($table_for_insert, {
                                    'level'      => "$table_for_insert",
                                    'parent_dir' => "$parent_dir",
                                    'title'      => "$title",
                                    'title_alias' => "$new_title_alias",
                                    'url'        => "$url_for_insert",
                                    'template'   => "$templ",
                                    'description' => "$description",
                                    'keywords'   => "$keywords",
                                    'list_enable' => "$list_enable",
                                    'queue'      => "1"
                                   }
               );
    my $last_insert_id = $db->last_insert_id('', '', $table_for_insert, 'level');
    
    $db->insert($new_title_alias, {
                                    'level'      => "$table_for_insert",
                                    'level_id'   => $db->last_insert_id('', '', $table_for_insert, 'level'),
                                    'rubric_id'  => 0,
                                    'curr_date'  => DB::Select->now_time,
                                    'head'       => $self->lang_config->{'new_page_content'}->{$language},
                                    'announce'   => $self->lang_config->{'new_page_content'}->{$language},
                                    'content'    => $self->lang_config->{'new_page_content'}->{$language},
                                    'template'   => "$templ",
                                    'comment_enable' => "yes"
                                   }
               );
	
$self->redirect_to('/menu_manage');
}#************

foreach(@levels_arr){
    my($table_live) = DB::Select->like_table($_);
    push @levels_array, $_ if( $table_live );    
}
my $max_level = $self->top_config->{$template}->{'max_level'};

# Сортуємо масив таблиць рівнів у порядку зменшення рівня (найвищий рівень - головна сторінка сайту)
@levels_array = reverse sort @levels_array;

my($menu_form, $menu) = MyBlog::MenuForm->menu_tree( $self, $self->serve->select_struct(\@levels_array) );
$menu = $template->get_menu( $self, $self->serve->select_struct(\@levels_array) );
#print "\$menu \= $menu\n";
$template->menu_rewrite( $self, $menu, [@levels_array] );

$self->render(
language => $language,
levels   => $self->top_config->{$template}->{'levels'},
message  => 'OK!',
menu => $menu,
menu_form => $menu_form,
header => $self->lang_config->{'labels'}->{$language}->{'masterroom'},
title => $self->lang_config->{'labels'}->{$language}->{'menu'}
);
}#---------------

1;
