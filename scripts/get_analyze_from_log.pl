$log_file = @ARGV[0];
$html_file= @ARGV[1];

open(FILEHANDLE, $log_file);
$content .= $_ while(<FILEHANDLE>); 
close FILEHANDLE;

$items = "<tr style='background:blue'><td></td><td></td><td></td><td></td><td></td></tr>";

$update = 0;
$content = $' if($content =~ /(Analyzer\s+Warnings\:)/);
$content =~ s/\d+\)\s+(YourGolf\/.*|YourGolfTests\/.*)\:(\d+)\:(\d+)\:(.*)\n\-+/save_report($1, $2, $3, $4, $')/ge;

open(FILEHANDLE, $html_file);
$content = "";
$content .= $_ while(<FILEHANDLE>); 
close FILEHANDLE;

$content =~ s/(\<\/tbody\>\<\/table\>\<hr\s+\/\>\<p\>)/${items}.${1}/;

$html_file =~ s/\.html/".edit.html"/e;

if ($update) {
  open(FILEHANDLE, ">${html_file}");
  print FILEHANDLE $content;
  close FILEHANDLE;
}

sub save_report(){
	my ($path, $line, $column, $message, $content_) = @_;
	$message =~ s/\:+$//g;
	$content_ =~ /\-+/;
	$content_ = $`;

	# if ($content_ =~ /(YourGolf|YourGolfTests)/) {
	# 	$content_ = $`;
	# }

	@tokens = split(/\n/, $content_);
	$content_ = "";
	for(@tokens){
		$length = length($1) if($_ =~ /^(\d+)/);

		$_ =~ s/^(\d+)\s+/${1}?/g;
		$_ =~ s/^\s+//g;

		$_ =~ s/^(\d+)\?/$1."\&nbsp\;"x(10)/e;

		if($_ =~ /^(\~|\^)/){
			$_ =~ s/^(\~+\^|\^)/replace_sign($1)/e;
			$length = 0;
		}

    $_ =~ s/^(.*\:)(\d+\:\d+\:)/$2/;

		$content_ .= $_."<br/>";
	}

	$items .= "<tr><td>${path}</td><td>${line}:${column}</td><td>analyze from xcode</td><td class='cmplr-warning'>warning</td><td>";
	$items .= "${message}<p style='background:#E9F4FF'>${content_}</p></td></tr>";
  $update = 1;
}

sub replace_sign(){
  my ($type) = @_;

  return "\&nbsp\;"x(12 + $length).$type if($type =~ /^\^/);
  return "\&nbsp\;"x(13 + $length).$type if($type =~ /^\~{1}\^/);
  return "\&nbsp\;"x(8 + $length).$type
}
