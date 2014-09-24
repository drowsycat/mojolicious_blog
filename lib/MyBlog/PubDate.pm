package MyBlog::PubDate;
use Mojo::Base 'Mojolicious::Controller';
use Mojo::Util qw(slurp spurt trim);
use Date::DayOfWeek;
use DB::Select;

#---------------------------------
sub pub_date {
#---------------------------------
my($self, $c, $curr_date) = @_;

my $language = $c->top_config->{'exist_langs'};
my $template = $c->top_config->{'routine'};

my %montn_num_name = (
					'01' => "Jan",
              		'02' => "Feb",
              		'03' => "Mar",
              		'04' => "Apr",
              		'05' => "May",
              		'06' => "Jun",
              		'07' => "Jul",
              		'08' => "Aug",
              		'09' => "Sep",
              		'10' => "Oct",
              		'11' => "Nov",
              		'12' => "Dec"
		   			);

my %day_num_name = (
					'1' => 'Mon',
					'2' => 'Tue',
              		'3' => 'Wed',
              		'4' => 'Thu',
              		'5' => 'Fri',
              		'6' => 'Sat',
              		'0' => 'Sun'					
				   );
 
my($y_m_d, $time) = split(/ /, $curr_date);
my($year, $month_num, $day_num) = split(/\-/, $y_m_d);
my $month_name = $montn_num_name{$month_num};
my $day_of_week = dayofweek($day_num, $month_num, $year);
my $dayname = $day_num_name{$day_of_week};

return $dayname.', '."$day_num "."$montn_num_name{$month_num} "."$year "."$time ".$c->top_config->{'grinvich_plus'};                   
}#---------------
1;