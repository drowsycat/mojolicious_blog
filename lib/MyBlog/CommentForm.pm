package MyBlog::CommentForm;
use Mojo::Base 'Mojolicious::Controller';
use DB::Select;
use MyBlog::RegExp;
use Mojo::Util qw(trim);

#---------------------------
sub comment_form {
#---------------------------
my($self, $c, $menu_level, $title_alias, $templ) = @_;
my $language = $c->top_config->{'exist_langs'};
my $template = $c->template;
my $table_users = $c->top_config->{'table'}->{'users'};
my %err_hash;
my $message;

my $db = DB->db();
$db->abstract = SQL::Abstract->new;

my $page_id = $c->param('page_id');
my $login   = trim($c->param('log_in'));
$login      = $c->session('client')->[1] if( !$login && $c->session('client') );
my $password = trim($c->param('passw'));
$password    = $c->session('client')->[3] if( !$password && $c->session('client') );

# Переспрямування на сторінку реєстрації при наявності відповідного параметра
if($c->param('registration')){
    $c->redirect_to($c->url_for('/registration')->query(
                                                        redirect_to => $c->param('redirect_to')
                                                       )
                   );
}

########## Блок обробки запиту на авторизацію ######################################################################
# Масив полів форми, що обов'язково мають бути заповнені
my $comment_required_fields = $c->top_config->{'comment_required_fields'}->{$template};

#*********************************************           
if($c->param('send_respons')){
#*********************************************
    %err_hash = $c->serve->err_hash_fields_comments($c, $comment_required_fields);
    #print "scalar_err_hash \= ", scalar(keys %err_hash);
    
    if( $login && $password ){
        my($login_exist, $pass_exist) = $db->select('user', ['login', 'pass'], {'login' => "$login", 'pass' => "$password"})->list;

    # Попередження про те, що такого логіна або пароля не існує в БД
    $message = $c->lang_config->{'alert'}->{$language}->{'invalid_login_or_passw'} if( !($login_exist && $pass_exist) );

    if(!$message && scalar(keys %err_hash) <= 0){  
        my $data = $db->select( $table_users, ['id', 'email'], {'login' => "$login", 'pass' => "$password"} )->hashes;
        my $id    = $data->[0]->{'id'};
        my $email = $data->[0]->{'email'};
        
    $c->session(client => [$id, $login, $email, $password], expiration => 300) if( !$c->session('client') );
    
    $db->insert('comments_artcl', {
                                    curr_date => DB::Select->now_time,
                                    parent_id => 0,
                                    level => 0,
                                    menu_level => "$menu_level",
                                    nickname => "$login",
                                    name => "",
                                    table_name => "$title_alias",
                                    page_id => "$page_id",
                                    url => $c->req->url,
                                    comment => trim($c->param('response')),
                                    press_indicat => 'yes'
                                  });
    
    $c->redirect_to($c->req->url);     
                   
    }
    }
}#***************

foreach(@$comment_required_fields){
    # Додаємо в шаблон повідомлення про помилку (порожнє відповідне поле форми). Тут назва змінної для шаблону
    # формується з назви поля з приєднаним '_err'    
    $c->stash(template => $templ, $_.'_err' => $err_hash{$_});
}
################################################################################

return $message;
}#-------------
1;