package MyBlog::Upload;
use Mojo::Base 'Mojolicious::Controller';
#use Mojo::Parameters;

#---------------------------
sub upload {
#---------------------------
my $self = shift;

my(%err_hash, $message, $level, $level_id, $head);
my $language = $self->top_config->{'exist_langs'};
my $template = $self->template;
use RewriteImage;
use Cwd;
my $range = 10000;
my $minimum = 100;


my $cwd = cwd();
my $RewrImag = RewriteImage->new;    
my $chapter = $self->param('title_alias');
my $sourse_key = $self->param('sourse_key');
my $request = $self->param('request'); # Вид запиту для отримання даних з таблиці
my $redirect_to = $self->param('redirect_to');
my $page_id     = $self->param('id');

my $indicr;
my @err_arr;
my @err_indicatr;
my $get_valid_list_func = $self->param('valid_format_func');
my $template_for_upload = $self->param('template_for_upload');
my $path_for_upload     = $self->param('path_for_upload');

my $db = DB->db();
$db->abstract = SQL::Abstract->new;
($level, $level_id, $head) = $db->select($chapter, ['level', 'level_id', 'head'], {id => $page_id})->list;

foreach(('c', 'd', 'e', 'f')){
    # Додаємо в шаблон повідомлення про помилку (порожнє відповідне поле форми). Тут назва змінної для шаблону
    # формується з назви поля з приєднаним '_err'
    $self->stash(template => $template_for_upload, $_.'_err' => '');
}

#***********************************
if( $self->param('upload') ){
#***********************************

# Перебираємо масив об'єктів вибраних для завантаження файлів
foreach my $param_name(('c', 'd', 'e', 'f')){

my $upload_obj = $self->req->upload($param_name);

    my $uploaded_filename = $upload_obj->filename;
    
    if($uploaded_filename){
        $uploaded_filename =~ /(\.\w+)$/;
    
    foreach my $valid_format(@{$self->$get_valid_list_func}){
        if(lc($1) eq $valid_format){ 
            $indicr = 1;
            #print "\$valid_format \= $valid_format \$indicr \= $indicr\n"; 
            last;
        }
        # Якщо формат неправильний, присвоюємо $indicr значенн 'err' і виходимо з поточного циклу
        $indicr = 'err'; # if(!$indicr);
    }
    #print "indicr \=\> $indicr\n";
        if($indicr eq 'err'){
            # Якщо поточний вибраний для завантаження файл неправильного формату, формуємо елемент хешу помилок для вказаного файлу і продовжуємо 
            # зовнішній цикл
            $err_hash{$param_name} = $self->serve->err_hash_fields_plus($self, $param_name, $self->lang_config->{'alert'}->{$language}->{'invalid_format'}.' '.$uploaded_filename);
            push @err_arr, $indicr;
            next;
        }else{
            # Якщо формат правильний, відповідний елемент хешу помилок матиме пусте значення
            $err_hash{$param_name} = $self->serve->err_hash_fields_plus($self, $param_name, '');
        }
    }

}
#print "\@err_arr \= @err_arr\n";
#$self->stash(template => 'upload_image', $_.'_err' => '');
#goto M;

# Якщо змінна $indicr не пуста, додаємо в шаблон елементи хешу помилок
if(@err_arr){

    foreach(('c', 'd', 'e', 'f')){
        # Додаємо в шаблон повідомлення про помилку (неправильний формат). Тут назва змінної для шаблону
        # формується з назви поля з приєднаним '_err'
        $self->stash(template => $template_for_upload, $_.'_err' => $err_hash{$_});
    }
# Переходимо до видачі шаблона з повідомленнями про помилки
goto M;
}
# Якщо помилок немає, шаблон приймає хеш помилок з пустими значеннями
if(!@err_arr){
    foreach(('c', 'd', 'e', 'f')){
        # Додаємо в шаблон повідомлення про помилку (порожнє відповідне поле форми). Тут назва змінної для шаблону
        # формується з назви поля з приєднаним '_err'
        $self->stash(template => $template_for_upload, $_.'_err' => '');
    }
}
###############################################

# Цикл з перебором масиву вибраних для завантаження файлів
foreach my $param_name(('c', 'd', 'e', 'f')){

    my $upload_obj = $self->req->upload($param_name);
    my $uploaded_filename = $upload_obj->filename;
    
    if($uploaded_filename){
    
        my $random_number = int(rand($range)) + $minimum;
        if($template_for_upload =~ /\_image$/){
            $uploaded_filename =~ s/(\.\w+)$/_$random_number\.jpg/;
        }
        else{
            $uploaded_filename =~ s/\.(\w+)$/_$random_number\.$1/;
        }
        $upload_obj->move_to("public/$path_for_upload/$uploaded_filename");

        if($template_for_upload =~ /\_image$/){
            # "Полегшуємо" зображення, перетворюючи їх до оптимальних розмірів
            $RewrImag->illustration($self, "$cwd/public"."$path_for_upload", $uploaded_filename, 'resize');
        }
        
        $db->insert( $self->top_config->{'upload_populate_options'}->{$template_for_upload}->{'table'},
                               {
                                'level'        => "$level",
                                'level_id'     => "$level_id",
                                'title_alias'  => "$chapter",
                                'page_id'      => "$page_id",
                                'path'         => "$path_for_upload",
                                'file'         => "$uploaded_filename"
                               } 
                   );
    }

}

$self->redirect_to($self->url_for("/$redirect_to")->query(
                                                            title_alias  => $chapter,
                                                            id           => $page_id
                                                         )
                   );

}#**************

###################################
M:
$indicr = "";
return $self->render(
        template     => $template_for_upload, 
        language     => $language, 
        redirect_to  => $redirect_to,
        title_alias  => $chapter,
        request      => $request,
        id => $page_id,
        head => $head,
        valid_format_func => $get_valid_list_func,
        template_for_upload => $template_for_upload,
        path_for_upload => $path_for_upload,
        title       => $self->lang_config->{'buttons'}->{$language}->{$sourse_key},
        header => $self->lang_config->{'labels'}->{$language}->{'masterroom'}
        );
}#-------------
1;