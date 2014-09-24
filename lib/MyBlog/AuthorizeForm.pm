package MyBlog::AuthorizeForm;
use Mojo::Base 'Mojolicious::Controller';

#---------------------------
sub authorize_form {
#---------------------------
my($self, $c, $templ) = @_;
my $language = $c->top_config->{'exist_langs'};
my $template = $c->template;
my $table_users = $c->top_config->{'table'}->{'users'};
my %err_hash;
my $message;

my $db = DB->db();
$db->abstract = SQL::Abstract->new;

my $login    = $c->param('login');
my $password = $c->param('pass');

# Переспрямування на сторінку реєстрації при наявності відповідного параметра
if($c->param('registration')){
    $c->redirect_to($c->url_for('/registration')->query(
                                                        redirect_to => $c->param('redirect_to')
                                                       )
                   );
}

########## Блок обробки запиту на авторизацію ######################################################################
# Масив полів форми, що обов'язково мають бути заповнені
my $authorize_required_fields = $c->top_config->{'authorize_required_fields'}->{$template};
           
if($c->param('authorize')){
    %err_hash = $c->serve->err_hash_fields($c, $authorize_required_fields);
    
    if( $login && $password ){
        my($login_exist, $pass_exist) = $db->select('user', ['login', 'pass'], {'login' => "$login", 'pass' => "$password"})->list;

    # Попередження про те, що такого логіна або пароля не існує в БД
    $message = $c->lang_config->{'alert'}->{$language}->{'invalid_login_or_passw'} if( !($login_exist && $pass_exist) );
    #print "\$valid_login_passw_check \= $valid_login_passw_check\n \$message \= $message\n";
    if(!$message){  
        my $data = $db->select( $table_users, ['id', 'email'], {'login' => "$login", 'pass' => "$password"} )->hashes;
        my $id    = $data->[0]->{'id'};
        my $email = $data->[0]->{'email'};
        
        $c->session(client => [$id, $login, $email, $password], expiration => 180);
    $c->redirect_to($c->req->url);                
    }
    }
}

foreach(@$authorize_required_fields){
    # Додаємо в шаблон повідомлення про помилку (порожнє відповідне поле форми). Тут назва змінної для шаблону
    # формується з назви поля з приєднаним '_err'    
    $c->stash(template => $templ, $_.'_err' => $err_hash{$_});
}
################################################################################

return $message;
}#-------------
1;