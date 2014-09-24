package MyBlog::CommentsTree;
use Mojo::Base 'Mojolicious::Controller';
use Data::Dumper;

#-----------------------------------------------
sub comments_tree {
#-----------------------------------------------
my($self, $c, $page_id) = @_;
my($comments, $next_level);
my $table_comments = $c->top_config->{'table'}->{'comments'};
my $comments_levels_deep_file = 'conf/comments_deep';
my $file = Mojo::Asset::File->new( path => $comments_levels_deep_file );
my $max_level = $file->slurp; ################################
my $img_path = $c->top_config->{'img_path'};
my $button_val = $c->lang_config->{'buttons'}->{$c->top_config->{'exist_langs'}}->{'send'};
my $response_from_label = $c->lang_config->{'labels'}->{$c->top_config->{'exist_langs'}}->{'response_from'}.' <b class="nickname">'.$c->session('client')->[1].'</b>:' if($c->session('client'));
my $url = $c->req->url;
my $db = DB->db();
$db->abstract = SQL::Abstract->new;

####################################################################
my $exist_comments_deep = $file->slurp;

my @levels_arr = reverse(1..$exist_comments_deep);
my(%hash_id_subs, %hash_id_subs_mod);
my %parent_id_ID_hash;
my %exist;
my @parent_id = ();
#goto TEST2;

#goto TEST2; ################################################

#my @hashref_arr = $db->query(qq[SELECT * FROM $table_comments
#                                WHERE url = "$url" ORDER BY curr_date DESC ])->hashes;
                                
my @hashref_arr = $db->select($table_comments, ['*'], {url => "$url"}, {-desc => 'curr_date'})->hashes;
                                
my $result = $db->select($table_comments, ['distinct parent_id'], {
                                                                    url => "$url",
                                                                    page_id => "$page_id"
                                                                  }, {-desc => 'curr_date'});
                               
    while(my($parent_id) = $result->list){
        push @parent_id, $parent_id;
        $exist{$parent_id} = 1;
    }
    #print "\@parent_id \= @parent_id exist \= ", %exist, "\n";
    
my %node_hash;

foreach(@hashref_arr){
    #print "id \= $_->{id}";
    #next if($_->{parent_id} == 0);
    $hash_id_subs{$_->{id}} = $_;
    if($exist{$_->{parent_id}}){
        if( $_->{parent_id} != 0 ){
        
            my($parent_nickname) = $db->select($table_comments, 
                                    ['nickname'], 
                                    {url     => "$url",
                                     page_id => "$page_id",
                                     id      => $_->{parent_id}
                                    })->list;
            $_->{parent_nickname} = $parent_nickname;
        }
        
        my $result = $db->query(qq[SELECT id FROM $table_comments
                                   WHERE url = "$url" 
                                   AND parent_id = "$_->{parent_id}"
                                   AND parent_id <> "0" ORDER BY curr_date DESC ]);
                                   
        my @id_arr = ();
        while(my($id) = $result->list){
            push @id_arr, $id;
        }
        $node_hash{$_->{parent_id}} = [@id_arr];
    }
}
#print "NODE \= ", %node_hash, "\n";

foreach(@hashref_arr){

    my @subs_arr = ();
    if($node_hash{$_->{id}}){
        $hash_id_subs_mod{$_->{id}} = $_;
        #say $_->{id}, " \= ", @{$node_hash{$_->{id}}};
        foreach my $item(@{$node_hash{$_->{id}}}){
            #print "\$item \= $item\n";
            push @subs_arr, __PACKAGE__->select_next_sub($c, $item, $_->{level}, [@subs_arr], \%hash_id_subs);
            delete $hash_id_subs{$item};
            #print "\@subs_arr \= ", Dumper(@subs_arr), "\n";
            $hash_id_subs_mod{$_->{id}}->{subs} = [@subs_arr];
        }
    }
}

#print "hash_id_subs_mod \= ", Dumper(\%hash_id_subs_mod), "\n";
####################################################################

foreach( reverse sort keys %hash_id_subs ){

    my $share_alt_obj = "<span class=\"parent_nickname\"><img src=\"$img_path/share_alt.png\"> 
    <a href=\"${url}#$hash_id_subs{$_}->{'parent_id'}\">$hash_id_subs{$_}->{'parent_nickname'}</a>
    </span>\n"
    if( $hash_id_subs{$_}->{'parent_id'} != 0 );
    my $id_coomment_accord = $hash_id_subs{$_}->{'id'}.'_comment';

        $comments.=<<COMM;
        <hr>
    <div id=\"$hash_id_subs{$_}->{'id'}\" name=\"$hash_id_subs{$_}->{'id'}\">
    <span class="nickname">$hash_id_subs{$_}->{'nickname'}</span>
    <span class="date_comment">$hash_id_subs{$_}->{'curr_date'}</span>
    $share_alt_obj
    <br>
    $hash_id_subs{$_}->{'comment'}
COMM

     if( $c->session('client') ){
     
        if( $hash_id_subs{$_}->{'level'} < $max_level ){
            $next_level = $hash_id_subs{$_}->{'level'} + 1;
        }else{
            $next_level = $hash_id_subs{$_}->{'level'};
        }
     
     $comments.=<<COMM;
     <br> 
 <a data-toggle="collapse" data-parent="#accordion" href="#$id_coomment_accord">
          відповісти
        </a>

    <div id="$id_coomment_accord" class="panel-collapse collapse">
      <div class="panel-body">
        <form action="$url" method="post">
        <input type="hidden" name="redirect_to" value=\"$url#$hash_id_subs{$_}->{'id'}\">
        <input type="hidden" name="page_id" value="$page_id">
        <input type="hidden" name="level" value="$next_level">
        <input type="hidden" name="parent_id" value=\"$hash_id_subs{$_}->{'id'}\">
        $response_from_label
        <br>
        <textarea name="answer" class="form-control" rows="5" cols="50" id="textar_answ"></textarea>
        <input type="submit" name="send_answ" class="btn btn-default btn-sm active" id="enter_button" value="$button_val">
        </form>
      </div>
    </div>
COMM

    }
    $comments.="</div>\n";

    if($hash_id_subs{$_}->{subs}){
    
    my $subcomments =__PACKAGE__->select_including( $c, $hash_id_subs{$_}->{subs}, $page_id );
        $comments.=$subcomments;        
    }

} # foreach ------

return $comments;
}#--------------

#------------------------------------------
sub select_next_sub{
#------------------------------------------
my($self, $c, $id, $level, $ref_subs_arr, $ref_hash_id_subs) = @_;
my %hash_id_subs = %{$ref_hash_id_subs};

return $hash_id_subs{$id};
}#-------------

#----------------------------------------
sub select_including{
#----------------------------------------
my($self, $c, $ref_subs_content, $page_id) = @_;
my($comments, $next_level);
my $comments_levels_deep_file = 'conf/comments_deep';
my $file = Mojo::Asset::File->new( path => $comments_levels_deep_file );
my $max_level = $file->slurp; ################################
my $img_path = $c->top_config->{'img_path'};
my @subs_content = @$ref_subs_content;
my $deviation = 30;
my $button_val = $c->lang_config->{'buttons'}->{$c->top_config->{'exist_langs'}}->{'send'};
my $response_from_label = $c->lang_config->{'labels'}->{$c->top_config->{'exist_langs'}}->{'response_from'}.' <b class="nickname">'.$c->session('client')->[1].'</b>:' if($c->session('client'));

my $url = $c->req->url;

foreach my $data(@subs_content){ #---------------

     my $share_alt_obj;
    $share_alt_obj = "<span class=\"parent_nickname\"><img src=\"$img_path/share_alt.png\"> 
    <a href=\"${url}#$data->{'parent_id'}\">$data->{'parent_nickname'}</a></span>\n"
    if( $data->{'parent_id'} != 0 );

    my $id_coomment_accord = $data->{'id'}.'_comment';

    my $level_deviation = $deviation * $data->{level};
        $comments.=<<COMM;
        <hr>
    <div style="margin-left:${level_deviation}px;" id=\"$data->{'id'}\" name=\"$data->{'id'}\">
    <span class="nickname">$data->{'nickname'}</span>
    <span class="date_comment">$data->{'curr_date'}</span>
    $share_alt_obj
    <br>
    $data->{'comment'}
COMM

if( $c->session('client') ){
     
        if( $data->{'level'} < $max_level ){
            $next_level = $data->{'level'} + 1;
        }else{
            $next_level = $data->{'level'};
        }
     
     $comments.=<<COMM; 
     <br>
 <a data-toggle="collapse" data-parent="#accordion" href="#$id_coomment_accord">
          відповісти
        </a>

    <div id="$id_coomment_accord" class="panel-collapse collapse">
      <div class="panel-body">
        <form action="$url" method="post">
        <input type="hidden" name="redirect_to" value=\"$url#$data->{'id'}\">
        <input type="hidden" name="page_id" value="$page_id">
        <input type="hidden" name="level" value="$next_level">
        <input type="hidden" name="parent_id" value=\"$data->{'id'}\">
        $response_from_label
        <br>
        <textarea name="answer" class="form-control" rows="5" cols="50" id="textar_answ"></textarea>
        <input type="submit" name="send_answ" class="btn btn-default btn-sm active" id="enter_button" value="$button_val">
        </form>
      </div>
    </div>
COMM

    }
    $comments.="</div>\n";

    if( $data->{subs} ){
        my $subcomments = __PACKAGE__->select_including( $c, $data->{subs}, $page_id);
		$comments.=$subcomments;
	}
    
} # foreach ----------------------

return $comments;
}#-------------

1;