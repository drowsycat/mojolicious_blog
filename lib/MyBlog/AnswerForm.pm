package MyBlog::AnswerForm;
use Mojo::Base 'Mojolicious::Controller';
use DB::Select;
use MyBlog::RegExp;
use Mojo::Util qw(trim);

#---------------------------
sub answer_form {
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
my $login   = $c->session('client')->[1];
my $password   = $c->session('client')->[3];

########## Блок обробки запиту на авторизацію ######################################################################
# Масив полів форми, що обов'язково мають бути заповнені
my $answer_required_fields = $c->top_config->{'answer_required_fields'}->{$template};
           
if($c->param('send_answ')){
    %err_hash = $c->serve->err_hash_fields($c, $answer_required_fields);


    if(scalar(keys %err_hash) <= 0){  
    
    $db->insert('comments_artcl', {
                                    curr_date => DB::Select->now_time,
                                    parent_id => $c->param('parent_id'),
                                    level => $c->param('level'),
                                    menu_level => "$menu_level",
                                    nickname => "$login",
                                    name => "",
                                    table_name => "$title_alias",
                                    page_id => $c->param('page_id'),
                                    url => $c->req->url,
                                    comment => trim($c->param('answer')),
                                    press_indicat => 'yes'
                                  });
    
    #$c->redirect_to($c->req->url);     
    $c->redirect_to($c->param('redirect_to'));               
    }

}

foreach(@$answer_required_fields){
    # Додаємо в шаблон повідомлення про помилку (порожнє відповідне поле форми). Тут назва змінної для шаблону
    # формується з назви поля з приєднаним '_err'    
    $c->stash(template => $templ, $_.'_err' => $err_hash{$_});
}
################################################################################

return $message;
}#-------------
1;