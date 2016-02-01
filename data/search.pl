#!usr/bin/perl -w

#主搜索程序
use Encode;
use Switch;
use utf8;
use strict;


if (@ARGV < 3){
   print "Usage: search.pl filename1    filename3 py string \n";
   print "filename1(input) : raw candidate file\n";
   print "filename2(output): exact matched file";
   exit(-1);
} 
our ($rawInpuFile,$obscurMatchedFile,@keywords)=@ARGV;
our $keyString=join("",@keywords);#应该考虑：字符串越长，后面输入的字符的权重则越轻

our $inKeywordLen=length($keyString);
our %ID2NameHash=();
our %keywordsHitType=();
our %scoreHash=();
our %similarDict=();
our %obscurHash=();
our $begintime=();
our $endtime=();
our @U_notTArray=();
our @exactedMatch=();
our %ID2MatchedHZ=();#id 到匹配到的汉字，用于二次排序
our %ID2ObscurHZ=();

#loadSimilarDict();#加载同义词词典,对五百个数据重新进行计算

main();


sub main{
	open RHF,"$rawInpuFile" or die "open file errer $!\n";
	my @rawLines=<RHF>;
	my $obscurHitCount=0;
  for(my $i=0;$i<@rawLines;$i++){
  	my $line=decode("utf8",$rawLines[$i]);
  	chomp $line;
  	my $pNameInfoHash=getNameHashPointer("$line");
  	my %nameInfoHash=%$pNameInfoHash;
  
   # my @HZ_tempSArray=@{$pNameInfoHash->{HZ_SArrayP}};
  #  my @HZ_tempTArray=@{$pNameInfoHash->{HZ_SAP}};
   my %tempUHash       = %{$nameInfoHash{UHashP}}; 
   my %tempTHash       = %{$nameInfoHash{THashP}};  
   my %tempSHash       = %{$nameInfoHash{SHashP}};
   my %tempPHash       = %{$nameInfoHash{PHashP}}; 
   my %HZ_tempUHash   	= %{$nameInfoHash{HZ_UHashP}};   
   my %HZ_tempTHash   	= %{$nameInfoHash{HZ_THashP}};   
   my %HZ_tempSHash   	= %{$nameInfoHash{HZ_SHashP}};    
   my %HZ_tempPHash   	= %{$nameInfoHash{HZ_PHashP}};    
    
  	
  	my $tempID=$nameInfoHash{ID};
  	my $tempName=$nameInfoHash{name};
  	my $temppy=$nameInfoHash{py};
  	my $orig_py=$temppy;
  	if($tempName=~/^深圳市/ && $keywords[$#keywords]!~/^sz[s]/ ) #&& length($tempName)>7
  	{
  		    #$tempPatter=$& ;
  		    if($keywords[0] ne "szs"&&$keywords[0] ne "sz"){
  		          $temppy=~s/^szs//; #substr($temppy,$patLen - 1);#除去深圳市	#
  		    }
  	
  	}
  	#在这里重新定义精确与模糊
  	#如果输入的字段在都是有效关键字，而不管其顺序则也算是精确
  	#当然，如果是按顺序输入的各关键字，则其分值应该更高
  	
  	if(isExactMatch($temppy))#初步判断输入的关键字是全部出现在待匹配的字符串中，由于有缩写与同义词的存在，我们在后面还会进一步判断是否为精确匹配
  	{
  		$obscurHash{$tempID}="exact";
  		#print "ext\n";
  	}
  	else{$obscurHash{$tempID}="obscur";}
  	
  	my $hitCount=0;
  	my $preScore=0;
  	my $tempMatchHZ="";
  	if(index($temppy,$keyString)==0)#如何
  	{
  		$preScore+=20+2*length($keyString);
  	}
  	for(my $i=0;$i<@keywords;$i++)#
  	{
  		if( exists $tempUHash{$keywords[$i]} )
  		{
        my $idx=index($orig_py,$keywords[$i]);
  			#要判断是不是使用了缩写
  			if($idx==-1)
  			{
  				$keywordsHitType{$keywords[$i]}="US";
  				#如果是缩写，那就找到最长的那个U
  				
  			}
  			else
  			{
  				$keywordsHitType{$keywords[$i]}="UA";
  				
  				my $temp=substr($tempName,$idx,length($keywords[$i]));#找到对应的汉字
  				if($i==$#keywords)
  				{$tempMatchHZ.="$temp";}
  				else
  				{
  					$tempMatchHZ.="$temp ";
  				}
  		#		print encode("gbk",$tempMatchHZ)."\n";
  			}
  			$hitCount++;
  			if($idx==0)
  			{
  				$preScore+=36+4*length($keywords[$i])*length($keywords[$i]);
  				next;
  			}
  			$preScore+=26+3*length($keywords[$i])*length($keywords[$i]);
  			next;
  		}
  		if(exists $tempTHash{$keywords[$i]})
  		{
  			my $idx=index($orig_py,$keywords[$i]);
  			if($idx==-1)
  			{
  				$keywordsHitType{$keywords[$i]}="TS";
  			}
  			else{
  			   $keywordsHitType{$keywords[$i]}="TA";
  			   my $temp=substr($tempName,$idx,length($keywords[$i]));#找到对应的汉字
  				if($i==$#keywords)
  				{$tempMatchHZ.="$temp";}
  				else
  				{
  					$tempMatchHZ.="$temp ";
  				}
  		  }
  			$hitCount++;
  			$preScore+=20+1.5*length($keywords[$i])*length($keywords[$i]);
  			next;
  		}
  		if(exists $tempPHash{$keywords[$i]})
  		{
  			$keywordsHitType{$keywords[$i]}="P";
  			$preScore+=26+2.5*length($keywords[$i])*length($keywords[$i]);
  			my $temp=substr($tempName,index($orig_py,$keywords[$i]),length($keywords[$i]));#找到对应的汉字
  				if($i==$#keywords)
  				{$tempMatchHZ.="$temp";}
  				else
  				{
  					$tempMatchHZ.="$temp ";
  				}
  			#	print encode("gbk",$tempMatchHZ)."\n";
  			$hitCount++;
  			next;
  		}
  		if(exists $tempSHash{$keywords[$i]})
  		{
  			$keywordsHitType{$keywords[$i]}="S";
  			$preScore+=20+1.5*length($keywords[$i])*length($keywords[$i]);
  			$hitCount++;
  			my $temp=substr($tempName,index($orig_py,$keywords[$i]),length($keywords[$i]));#找到对应的汉字
  				if($i==$#keywords)
  				{$tempMatchHZ.="$temp";}
  				else
  				{
  					$tempMatchHZ.="$temp ";
  				}
  			next;
  		}
  		if(index($temppy,$keywords[$i])> -1)
  		{
  			$keywordsHitType{$keywords[$i]}="Unk";	
  			$hitCount++;
  			#如果
  			#在这里我们判断，如果当前输入的关键字信息大于等于4，我们就应该分开处理了：如果命中了词
  			#现在先截取字母对应的汉字,
  			 my $len=length($keywords[$i]);
  			my $idx=index($orig_py,$keywords[$i]);
  			my $tempHZ=substr( $tempName , $idx, $len ); #获得与当前输入首字母关键字对应的汉字
  			#my $temp=substr($tempName,index($orig_py,$keywords[$i]),length($keywords[$i]));#找到对应的汉字
  			#print encode("gbk","$temp")."\n";
  			if($i==$#keywords)
  			{
  				$tempMatchHZ=$tempMatchHZ."$tempHZ";
  				#print encode("gbk","$tempMatchHZ")."\n";
  			}
  			else
  			{
  					$tempMatchHZ=$tempMatchHZ."$tempHZ ";
  			}	
  			#print encode("gbk",$tempHZ)."\n";
  			my @tempHZ=split(//,"$tempHZ");
  			if($len>3)
  			{
  				if($len==4)
  				{
  					if(@tempHZ!=4){next;}
  					my $first=join("",@tempHZ[0..1]);
  				#		print encode("gbk",$first)."\n";
  					my $second=join("",@tempHZ[2..3]);
  				#	print encode("gbk",$second)."\n";
  					if(exists $tempPHash{$first})
  					{
  					#	print "get herr\n";
  					}
  					
  					if(exists $HZ_tempPHash{$first} && $HZ_tempUHash{$second} )
  					{
  						 $preScore+=45;
  						 next;
  					}
  					if(exists $HZ_tempUHash{$first} && $HZ_tempTHash{$second} )
  					{
  						 $preScore+=80;
  						 next;
  						 
  					}
  					if(exists $HZ_tempPHash{$first} &&$HZ_tempPHash{$second} )
  					{
  						 $preScore+=60;
  						 next;
  					}
  					if(exists $HZ_tempUHash{$first} && $HZ_tempPHash{$second} )
  					{
  						 $preScore+=30;
  						 next;
  					}
  					if(exists $HZ_tempPHash{$first} &&$HZ_tempTHash{$second} )#地点，
  					{
  						 $preScore+=40;
  						 next;
  					}
  					
  					next;
  					
  				}
  				if($len==5)
  				{
  					my $onetwo=join("",@tempHZ[0..1]);
  					my $onethree=join("",@tempHZ[0..2]);
  					my $threefour=join("",@tempHZ[2..3]);
  					my $threefive=join("",@tempHZ[2..4]);
  					my $fourfive=join("",@tempHZ[3..4]);
  					if(exists $HZ_tempUHash{$onetwo} && $HZ_tempTHash{$threefour}||exists $HZ_tempUHash{$onethree} && $HZ_tempTHash{$fourfive} || exists $HZ_tempUHash{$onetwo} &&$HZ_tempTHash{$threefive})
  					{
  						 $preScore+=80;
  						 next;
  					}
  					if(exists $HZ_tempPHash{$onetwo} && $HZ_tempPHash{$threefour} ||exists $HZ_tempPHash{$onethree} &&$HZ_tempPHash{$fourfive}|| exists $HZ_tempPHash{$onetwo} &&$HZ_tempPHash{$threefive})
  					{
  						  $preScore+=60;
  						  next;
  					} 
  					if(exists $HZ_tempPHash{$onetwo} && $HZ_tempTHash{$threefour} ||exists $HZ_tempPHash{$onethree} && $HZ_tempTHash{$fourfive}|| exists $HZ_tempPHash{$onetwo} &&$HZ_tempTHash{$threefive})
  					{
  						  $preScore+=40;
  						  next;
  					} 
  					if(exists $HZ_tempUHash{$onetwo} && $HZ_tempPHash{$threefour} ||exists $HZ_tempUHash{$onethree} && $HZ_tempPHash{$fourfive}|| exists $HZ_tempUHash{$onetwo} &&$HZ_tempPHash{$threefive})
  					{
  						  $preScore+=40;
  						  next;
  					} 
  					$preScore+=8+length($keywords[$i])*length($keywords[$i]);
  			    $hitCount++;
  			    next;			
  				}
  			 $preScore+=18+1.5*length($keywords[$i])*length($keywords[$i]);
  			 $hitCount++;			
  	     next;
  			}
  			#my $idx=index($orig_py,$keywords[$i]);
  			#my $tempHZ=substr($tempName,$idx,length($keywords[$i]));#获得与当前输入首字母关键字对应的汉字
  			$preScore+=6+length($keywords[$i])*length($keywords[$i]);
  		
  			next;
  		}
  		$keywordsHitType{$keywords[$i]}="No";
  		
  	}
  	#print encode("gbk",$tempMatchHZ)."\n";
  	#print "$hitCount\n";
  	if($hitCount==$#keywords+1)#
  	{
  		$ID2MatchedHZ{$tempID}="$tempMatchHZ";
  		#print $tempID.encode("gbk",$tempMatchHZ)."\n";
  		if( $obscurHash{$tempID} eq "obscur")#修正，如果之前被判为模糊，那么，现在修正。因为用户可能输入缩写与同义词。
  		
  		{$obscurHash{$tempID}="exact";}
  		
  	}
  	if($hitCount>0 && $hitCount!=$#keywords+1)
  	{
  		$ID2ObscurHZ{$tempID}="$tempMatchHZ";
  		$obscurHitCount++;
  	}
  	if(length($keyString)>length($temppy))#如果输入的字符总长度比待匹配的名称串还长，那就要罚分了
  	{
  		$preScore-=70;
  	}
  	
  	
  	$ID2NameHash{$tempID}="${tempName}\t$nameInfoHash{py}";#[@tempArray];
  	$scoreHash{$tempID}	=getScore($pNameInfoHash);
  	$scoreHash{$tempID}+=$preScore;
    }
   
   my @scoreID=sort{$scoreHash{$b}<=>$scoreHash{$a}}keys(%scoreHash);
   my @exactArray=();
   my @obscurArray=();
   my $exactIDs=0;
   my $obscureIDs=0;
   foreach my $ID (@scoreID)
   {
   	 if($obscurHash{$ID} eq "exact")
   	 {
   	 	 #print "$ID\n";
   	 	# if($exactIDs < 1000 )
   	 	# {
   	 	# 	$exactIDs++;
   	 	 	 push( @exactArray,$ID);
   	 	# }
   	 	 
   	 }
   	 else
   	 {
   	 #	 if($obscureIDs < 30)
   	 #	 {
   	 #	 	 $obscureIDs++;
   	 	 	 push(@obscurArray,$ID); 
   	 #	 }
   	 	 
   	 }
    #	print OBHF encode("gbk","$ID")."\t".encode("gbk","$ID2NameHash{$ID}"."\t"."$similarScoreHash{$ID}"."\n");
   } 
   #接下来应该如何按拼音排序？
   #先不考虑缩写的情况：
   my  @tempIDs=sort{$ID2MatchedHZ{$b} cmp $ID2MatchedHZ{$a}}@exactArray;
   #在这里，对已经排好序的部分再进行一次排序，即根据已经计划的分数来排序
  # foreach my $ID (@scoreID)
  #print join(" ",@tempIDs)."\n";
  if(@tempIDs>0){
  	 my $ID=$tempIDs[0];
  	 my $strOut=encode("gbk","$ID")."\t".encode("gbk","$ID2NameHash{$ID}"."\t").encode("gbk","$obscurHash{$ID}\t");
	   $strOut.=encode("gbk","$scoreHash{$ID}"."\n");
	  # print $strOut;
	   if(@tempIDs==1)
	   {
	   	   print $strOut;
	   }
	   my $tempMaxScore=$scoreHash{$ID}; #获得分数
	   my %tempHash=();#对于一个相似
	   for(my $i=1;$i<@tempIDs;$i++)
	   {
	   	  $ID=$tempIDs[$i];
	   	  my  $strOutTemp.=encode("gbk","$ID")."\t".encode("gbk","$ID2NameHash{$ID}")."\t".encode("gbk","$obscurHash{$ID}\t");
	   	  $strOutTemp.=encode("gbk","$scoreHash{$ID}"."\n");
	   	  if("$ID2MatchedHZ{$tempIDs[$i-1]}" eq "$ID2MatchedHZ{$tempIDs[$i]}")
	   	  {
	   	  	
	   	  	if($scoreHash{$ID}>$tempMaxScore)
	   	  	{
	   	  		$tempMaxScore=$scoreHash{$ID};
	   	  		$strOut="$strOutTemp"."$strOut";
	   	  	}
	   	  	else
	   	  	{
	   	  		 $strOut="$strOut"."$strOutTemp";
	   	  	}
	   	  	if($i==$#tempIDs)
	   	  	{
	   	  		 $tempHash{$tempMaxScore}=$strOut;
	   	  		 
	   	  		 $tempMaxScore=-100;
	   	  	}
	   	  }
	   	  else
	   	  {
	   	  	if(! exists $tempHash{$tempMaxScore} )
	   	  	{$tempHash{$tempMaxScore}=$strOut;}
	   	  	else
	   	  	{
	   	  		while(exists $tempHash{$tempMaxScore})
	   	  	  {
	   	  	  	$tempMaxScore-=0.05;
	   	  	  }
	   	  	  $tempHash{$tempMaxScore}=$strOut;
	   	  	}
	   	  	
	   	  #	print $strOut;
	   	  	$tempMaxScore=$scoreHash{$ID};
	   	  	$strOut=$strOutTemp;
	   	  	if($i==$#tempIDs)
	   	  	{
	   	  		
	   	  	if(! exists $tempHash{$tempMaxScore} )
	   	  	{$tempHash{$tempMaxScore}=$strOut;
	   	  		}
	   	  	else
	   	  	{
	   	  		while(exists $tempHash{$tempMaxScore})
	   	  	  {
	   	  	  	 $tempMaxScore-=0.05;
	   	  	  }
	   	  	  $tempHash{$tempMaxScore}=$strOut;
	   	  	}
	   	  	$tempMaxScore=-100;
	   	  	}
	   	  }
	   	  #print $strOut;
	    	#print encode("gbk","$ID")."\t".encode("gbk","$ID2NameHash{$ID}")."\t";
	      #print encode("gbk","$obscurHash{$ID}\t");
	    	#print encode("gbk","$scoreHash{$ID}"."\n");
	   }
	  my @sortedScore=sort{ $b <=> $a }keys(%tempHash);
	   foreach my $score (@sortedScore)
	   {
	   	  print $tempHash{$score};
	   }
	    
  }
   @tempIDs=();
   if($obscurHitCount>0)
   { 
   	
   	@tempIDs=sort{$ID2ObscurHZ{$a} cmp $ID2ObscurHZ{$b}}@obscurArray;
   	if(@tempIDs>0){
  	 my $ID=$tempIDs[0];
  	 my $strOut=encode("gbk","$ID")."\t".encode("gbk","$ID2NameHash{$ID}"."\t").encode("gbk","$obscurHash{$ID}\t");
	   $strOut.=encode("gbk","$scoreHash{$ID}"."\n");
	   if(@tempIDs==1)
	   {
	   	   print $strOut;
	   }
	   my $tempMaxScore=$scoreHash{$ID}; #获得分数
	   my %tempHash=();#对于一个相似
	   for(my $i=1;$i<@tempIDs;$i++)
	   {
	   	  $ID=$tempIDs[$i];
	   	  my  $strOutTemp.=encode("gbk","$ID")."\t".encode("gbk","$ID2NameHash{$ID}")."\t".encode("gbk","$obscurHash{$ID}\t");
	   	  $strOutTemp.=encode("gbk","$scoreHash{$ID}"."\n");
	   	  if("$ID2ObscurHZ{$tempIDs[$i-1]}" eq "$ID2ObscurHZ{$tempIDs[$i]}")
	   	  {
	   	  	
	   	  	if($scoreHash{$ID}>$tempMaxScore)
	   	  	{
	   	  		$tempMaxScore=$scoreHash{$ID};
	   	  		$strOut="$strOutTemp"."$strOut";
	   	  	}
	   	  	else
	   	  	{
	   	  		 $strOut="$strOut"."$strOutTemp";
	   	  	}
	   	  	if($i==$#tempIDs)
	   	  	{
	   	  		 $tempHash{$tempMaxScore}=$strOut; 
	   	  		 $tempMaxScore=-100;
	   	  	}
	   	  }
	   	  else
	   	  {
	   	  	$tempHash{$tempMaxScore}=$strOut;
	   	  	$tempMaxScore=$scoreHash{$ID};
	   	  	$strOut=$strOutTemp;
	   	  	if($i==$#tempIDs)
	   	  	{
	   	  		 $tempHash{$tempMaxScore}=$strOut;
	   	  		 $tempMaxScore=-100;
	   	  	}
	   	  }
	   	  #print $strOut;
	    	#print encode("gbk","$ID")."\t".encode("gbk","$ID2NameHash{$ID}")."\t";
	      #print encode("gbk","$obscurHash{$ID}\t");
	    	#print encode("gbk","$scoreHash{$ID}"."\n");
	   }
	  my @sortedScore=sort{ $b <=> $a }keys(%tempHash);
	   foreach my $score (@sortedScore)
	   {
	   	  print $tempHash{$score};
	   }
	    
  }
   	
   	
   }
   else
   {
   	
	   	@tempIDs=@obscurArray;
	   	foreach my $ID(@tempIDs)
	   {
		   	print encode("gbk","$ID")."\t".encode("gbk","$ID2NameHash{$ID}"."\t");
		    print encode("gbk","$obscurHash{$ID}\t");
		    print encode("gbk","$scoreHash{$ID}"."\n");
	   	
	   	}
   	
   }
   

   
  # open OBHF,">$obscurMatchedFile" or die "$obscurMatchedFile $!\n";
  
  
   #@scoreID=sort{$similarScoreHash{$b}<=>$similarScoreHash{$a}}keys(%similarScoreHash);
   #for(my $i=0;$i<@scoreID;$i++)
   #{}
   
  
 }
sub isExactMatch
{
	my $temppy=shift;
	my $lastIdx=-1;
	my $hitCount=0;
	for(my $i=0;$i<@keywords;$i++)
	{
		my $idx=index($temppy,$keywords[$i]);
		if($idx>-1)
		{	
			if($lastIdx<$idx)
			{
				$hitCount++;
				$lastIdx=$idx;
			}
			#$lastIdx=$idx;
		}

	}
	if($hitCount<scalar(@keywords)){return 0;}
	return 1;
}
 
 sub getNameHashPointer
 {
 	
    my $line=shift;
  	my @tempArray=split(/\,/,$line);
  	splice(@tempArray,11);
  	#取前面个
  	my $tempID=$tempArray[0];
  	my $tempName =$tempArray[1];
  	my $temppy=$tempArray[2];

    #上面还需要考虑Type的同义词，有两种方式加入同义词：
    #第一是在分析程序中加入,同义词间用某个符号如|隔开。
    #第二种方式是在这里，查找同义词，这里做的话就会影响检索速度。

    my @tempUArray=split(/\s+/,$tempArray[3]);
    my %tempUHash=map{$_,1}@tempUArray;
    my @tempTArray=split(/\s+/,$tempArray[4] );
    my %tempTHash=map{$tempTArray[$_],1}0..$#tempTArray;
    my @tempSArray=split(/\s+/,$tempArray[5]);
    my %tempSHash=map{$_,1}@tempSArray;
    my @tempPArray=split(/\s+/,$tempArray[6]);
    my %tempPHash=map{$_,1}@tempPArray;
    my @HZ_tempUArray=split(/\s+/,$tempArray[7]);
    my %HZ_tempUHash=map{$_,1}@HZ_tempUArray;    
    my @HZ_tempTArray=split(/\s+/,$tempArray[8]);
    my %HZ_tempTHash=map{$_,1}@HZ_tempTArray;   
    my @HZ_tempSArray=split(/\s+/,$tempArray[9]);
    my %HZ_tempSHash=map{$_,1}@HZ_tempSArray;    
    my @HZ_tempPArray=split(/\s+/,$tempArray[10]);
    my %HZ_tempPHash=map{$_,1}@HZ_tempPArray;
   
  	#splice(@tempArray,0,1);
  	
  
  	#先要将前面出现的深圳市去掉,如果有必要，可以去掉区
  
  	 my %nameInfoHash=();
  	 $nameInfoHash{ID}=$tempID;
  	 $nameInfoHash{py}=$temppy;
  	 $nameInfoHash{name}="$tempName";
     $nameInfoHash{UArrayP} =[@tempUArray];
     $nameInfoHash{UHashP}  ={%tempUHash};
     $nameInfoHash{TArrayP} =[@tempTArray];
     $nameInfoHash{THashP}  ={%tempTHash};
     $nameInfoHash{SArrayP} =[@tempSArray];
     $nameInfoHash{SHashP}  ={%tempSHash};
     $nameInfoHash{PArrayP} =[@tempPArray];
     $nameInfoHash{PHashP}  ={%tempPHash};    
     $nameInfoHash{HZ_UArrayP}=[@HZ_tempUArray];
     $nameInfoHash{HZ_UHashP} ={%HZ_tempUHash};
     $nameInfoHash{HZ_TArrayP}=[@HZ_tempTArray];
     $nameInfoHash{HZ_THashP} ={%HZ_tempTHash};
     $nameInfoHash{HZ_SArrayP}=[@HZ_tempSArray];
     $nameInfoHash{HZ_SHashP} ={%HZ_tempSHash};
     $nameInfoHash{HZ_PArrayP}=[@HZ_tempPArray];
     $nameInfoHash{HZ_PHashP} ={%HZ_tempPHash};    
  	 return \%nameInfoHash;
  	#先计算输入的各字段在数据当前字符串中是否存在

 }  
 #找一个汉字的所有近义词的拼音数组
  

sub getScore
{   
	  my $pNameInfoHash=shift;
	 # print "key words :".join(" ",@keywords)."\n";
	  my %nameInfoHash=%$pNameInfoHash;
	  my $tempID=$nameInfoHash{ID};
	  my $temppy=$nameInfoHash{py};
	  my $tempName=$nameInfoHash{name};
 	  my @tempUArray   	  = @{$nameInfoHash{UArrayP}};       
 	  my %tempUHash       = %{$nameInfoHash{UHashP}};        
 	 my @tempTArray   	  = @{$nameInfoHash{TArrayP}};       
 	 my %tempTHash       = %{$nameInfoHash{THashP}};    
   my @tempSArray      = @{$nameInfoHash{SArrayP}};    
   my %tempSHash       = %{$nameInfoHash{SHashP}}; 
         
   my @tempPArray   	  = @{$nameInfoHash{PArrayP}};       
   my %tempPHash       = %{$nameInfoHash{PHashP}};        
   
   my @HZ_tempUArray 	= @{$nameInfoHash{HZ_UArrayP}};  
   my %HZ_tempUHash   	= %{$nameInfoHash{HZ_UHashP}};   
   my @HZ_tempTArray 	= @{$nameInfoHash{HZ_TArrayP}};  
   my %HZ_tempTHash   	= %{$nameInfoHash{HZ_THashP}};   
   my @HZ_tempSArray 	= @{$nameInfoHash{HZ_SArrayP}};  
   my %HZ_tempSHash   	= %{$nameInfoHash{HZ_SHashP}};   
   my @HZ_tempPArray 	= @{$nameInfoHash{HZ_PArrayP}};  
   my %HZ_tempPHash   	= %{$nameInfoHash{HZ_PHashP}};   
	  my $tempScore=0;#做为一个流动分值
  	my $tempTotalScore=0;
  	my $tempDisScore=0;
    my $tempUScore=0;
    my $tempTScore=0;
    my $tempSScore=0;
    my $tempPScore=0;
    my $tempPreScore=0;
  	my $hitPre=0;
   # my $idx=index($temppy,$keyString);  
    for(my $i=0;$i<@keywords;$i++)
    {
   	
      my $wordLen=length($keywords[$i]);
par:  		
      #if(index($temppy,$keywords[$i])!=-1)
      if($keywordsHitType{$keywords[$i]} ne "No")
  		{
  
  			if($hitPre==0 )#输入关键字首次匹配上当前名称的中的有字段
  			{ 
  				if($i==0){#输入的第一个关键命中
  					        if(exists $tempUHash{$keywords[$i]} )#如果是U
			  						{ 
			  							$tempPreScore += 40; #- $curEntryLen/2; #)*($wordLen*1.5);	
			  							$hitPre++;
			  							next;
			  						}
			  						if(exists $tempPHash{$keywords[$i]} )#如果是P
			  						{
			  							$tempPreScore += 30; #- $curEntryLen/2 # )*($wordLen*1.5);
			  							$hitPre++;
			  							next;
			  						}	
		  					  $tempPreScore += 14; #- log($curEntryLen))*($wordLen*1.5); 	#第一个匹配的不是U，P		
		  						$hitPre++;
		  				    next;
  					
  					}
  				if($i>0) #首次命中，但不是第一个输入的关键字，其实分析这种情况的价值不高，但还是分析一下
  				{ 
  					   if(exists $tempUHash{$keywords[$i]} )#命中了第一个字段
	  						{
	  							$tempPreScore += 15; # - log($curEntryLen))*(*1.5);
	  							$hitPre++;
	  							next;
	  						}
	  						if(exists $tempTHash{$keywords[$i]} )#命中了第二个字段
	  						{
	  							$tempPreScore += 11 ;#- log($curEntryLen))*($wordLen*1.5);
	  							$hitPre++;
	  							next;
	  						}
	  						if(exists $tempPHash{$keywords[$i]} )
	  						{
	  							$tempPreScore += 7;#- log($curEntryLen))*($wordLen*1.5);
	  							$hitPre++;
	  							next;
	  						}
	  						
	  					  $tempPreScore += 4; # - log($curEntryLen))*($wordLen*1.5); 			
  						  $hitPre++;
  				      next;
  				}
         
  			}
  			if($hitPre==1)
  			{

	      			if(exists $tempPHash{$keywords[$i-1]} &&  exists $tempUHash{$keywords[$i]} )
	  						{
	  							$tempPreScore += 38;#*$wordLen;
	  							$hitPre++;
	  							next;
	  						}
	  						
	  						if(exists $tempUHash{$keywords[$i-1]} && exists $tempTHash{$keywords[$i]}  )
  						  {
  							   $tempPreScore += 48; # *$wordLen;
  							   $hitPre++;
  							   next;
  						  }
  						  if( exists $tempUHash{$keywords[$i-1]} && exists $tempPHash{$keywords[$i]} )
  						  {
  							   $tempPreScore += 25; #*$wordLen;
  							   $hitPre++;
  							   next;
  						  }
  						  if( exists $tempTHash{$keywords[$i-1]} &&  exists $tempPHash{$keywords[$i]})
  						  {
  							   $tempPreScore += 20; 
  							   $hitPre++;
  							   next;
  						  }
  						  if(exists $tempPHash{$keywords[$i-1]} && exists $tempTHash{$keywords[$i]} )
  						  {
  						  	
  							   $tempPreScore += 33;#可能是因为没有找到合适的U,
  							   $hitPre++;
  							   next;
  						  }
  						 if( exists $tempUHash{$keywords[$i-1]}){
  						 	$tempPreScore += 20- length($keywords[$i-1]);
  						 	$hitPre++;
	  						next;
  						 	} 
	  						$tempPreScore += 11;
	  						$hitPre++;
	  						next;
	  		
  			}
  		  if($hitPre==2)#前面已经命中了两个字段;第三个字段又命中了
  			{
	  						if(exists $tempTHash{$keywords[$i]} && exists $tempUHash{$keywords[$i-1]})#可能是P U T
  						  {
  							   $tempPreScore += 40;
  							   $hitPre++;
  							   next;
  						  }
  						  if(exists $tempPHash{$keywords[$i]} && exists $tempUHash{$keywords[$i-1]}) #
  						  {
  							   $tempPreScore += 30; #- log($curEntryLen))*($wordLen*1.5);
  							   $hitPre++;
  							   next;
  						  }
  						 if(exists $tempUHash{$keywords[$i-1] && exists $tempSHash{$keywords[$i]}  }){
  						 	$tempPreScore += 20;
  						 	$hitPre++;
	  						next;
  						 	} 
  						 	if(exists $tempTHash{$keywords[$i-1]} && exists $tempSHash{$keywords[$i]} ){
  						 	$tempPreScore += 20 ;
  						 	$hitPre++;
	  						next;
  						 	} 
	  						$tempPreScore += 11;
	  						$hitPre++;
	  						next;
  			}
  
  			 if($hitPre>2)
  			{
	  						if(exists $tempTHash{$keywords[$i-1]}  && exists $tempTHash{$keywords[$i]} )
  						  {
  							   $tempPreScore += 40; #- log($curEntryLen))*($wordLen*1.5);
  							   $hitPre++;
  							   next;
  						  }
  						  if(exists $tempUHash{$keywords[$i-1]} && exists $tempPHash{$keywords[$i]}  )
  						  {
  							   $tempPreScore += 21;
  							   $hitPre++;
  							   next;
  						  }
  						  if(exists $tempSHash{$keywords[$i-1]} && exists $tempPHash{$keywords[$i]})
  						  {
  							   $tempPreScore += 21;
  							   $hitPre++;
  							   next;
  						  }
  						  if( exists $tempPHash{$keywords[$i-1]} && exists $tempSHash{$keywords[$i]})#某某 深圳 分公司
  						  {
  							   $tempPreScore +=16;
  							   $hitPre++;
  							   next;
  						  }
  						 if(exists $tempTHash{$keywords[$i-1]} && exists $tempSHash{$keywords[$i]} ){
  						 	$tempPreScore += 26;
  						 	$hitPre++;
	  						next;
  						 	}
	  						$tempPreScore += 10; 
	  						$hitPre++;
	  						next;
  			}

  		}
  
    }
	  $tempTotalScore+=$tempPreScore;
  	my $currentLen=length($temppy);
    $tempTotalScore+=getDisScore_1("$temppy","$keyString");

    #现在开始匹配U T S P了,它们拥有不同的权值
    #begin match 

   return $tempTotalScore;
}  	
   
    #<STDIN>;



sub loadSimilarDict
{
	my $similarDictFile= "/home/wei.liu/114/data/similar.dict";
	open HF ,"$similarDictFile" or die "can not open file $similarDictFile\n";
	binmode(HF, ":encoding(gbk)");
	my $curID=1;
	my @tempHZArray=();
	my @tempPYArray=();
	while(my $line=<HF>)
	{ 
		  chomp($line);  
		  $line =~ s/^\s+//;
		  if($line eq ""){next;} 
		 # <STDIN>;
		  #print encode("gbk",$line)."\n";
		  my @array=split(/\s+/,$line);
reb:
		  if( $array[0]==$curID)
		  {
		  	push(@tempHZArray,$array[1]);
		  	push @tempPYArray,$array[2];
		  	next;
		  	
		  }
		  my $pointer=[@tempPYArray];
		 # print join(" ",@tempPYArray)."\n";
		  for(my $i=0;$i<@tempHZArray;$i++)
		  {
		  	$similarDict{$tempHZArray[$i]}=$pointer;
		  }
		  
		  @tempHZArray=();
		  @tempPYArray=();

		  $curID=$array[0];
		  goto reb;
		  
	}
	my $pointer=[@tempPYArray];
	for(my $i=0;$i<@tempHZArray;$i++)
	{
		 $similarDict{$tempHZArray[$i]}=$pointer;
	}
	
}


sub levenshtein
{
    # $s1 and $s2 are the two strings
    # $len1 and $len2 are their respective lengths
    #
    my ($s1, $s2) = @_;
    my ($len1, $len2) = (length $s1, length $s2);

    # If one of the strings is empty, the distance is the length
    # of the other string
    #
    return $len2 if ($len1 == 0);
    return $len1 if ($len2 == 0);

    my %mat;
    for (my $i = 0; $i <= $len1; ++$i)
    {
        for (my $j = 0; $j <= $len2; ++$j)
        {
            $mat{$i}{$j} = 0;
            $mat{0}{$j} = $j;
        }

        $mat{$i}{0} = $i;
    }


    my @ar1 = split(//, $s1);
    my @ar2 = split(//, $s2);

    for (my $i = 1; $i <= $len1; ++$i)
    {
        for (my $j = 1; $j <= $len2; ++$j)
        {

            my $cost = ($ar1[$i-1] eq $ar2[$j-1]) ? 0 : 1;


            $mat{$i}{$j} = min([$mat{$i-1}{$j} + 1,
                                $mat{$i}{$j-1} + 1,
                                $mat{$i-1}{$j-1} + $cost]);
        }
    }


    return $mat{$len1}{$len2};
}


# minimal element of a list
#
sub min
{
    my @list = @{$_[0]};
    my $min = $list[0];

    foreach my $i (@list)
    {
        $min = $i if ($i < $min);
    }

    return $min;
}

sub getDisScore_1
{
	my ($str1,$str2)=@_;
	my $strLen1=length($str1);
	my $strLen2=length($str2);
	my $difLen=abs($strLen1-$strLen2);
	my $tempMinDis=levenshtein($str1,$str2);
	my $tempDisScore=100 - ($tempMinDis+1) * ($tempMinDis+18) /($difLen+1) - 1.5*$difLen;
  return $tempDisScore;
}
 
